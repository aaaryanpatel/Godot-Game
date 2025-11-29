extends CharacterBody2D

# Constants
const SPEED = 300.0
const DODGE_DISTANCE = 35.0 # Reverted to 100.0 to make movement clearly visible
# Define the exclusive states the player can be in
enum PlayerState {
	IDLE, MOVING,
	PUNCHING_LEFT, PUNCHING_RIGHT,
	DODGING_LEFT, DODGING_RIGHT,
	BLOCKING,
	HURT, DEFEATED
}

# Current state variable
var current_state: PlayerState = PlayerState.IDLE
var dodge_duration: float = 1.0 	# The fixed duration for the entire dodge sequence
var punch_cooldown: float = 0.0		# time amount for the current action to complete before new action

# New: Variables for Dodge Movement and Control
var original_x: float = 0.0      # Stores the X position before the dodge begins
var dodge_tween: Tween = null    # Tracks the dodge movement sequence

# Node References (Ensure these match your scene tree names)
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer 
@onready var punch_hitbox: Area2D = $PunchHitBox 
@onready var player_hurtbox: Area2D = $PlayerHurtBox
@onready var punch_sound: AudioStreamPlayer2D = $PunchSound

#Hurt handling variables
signal health_changed(new_health: int)
var max_health: int = 100
var current_health: int = 100

func _ready() -> void:
	# Ensure player starts in the idle state
	set_state(PlayerState.IDLE)
	animated_sprite.play("idle")

func _physics_process(delta: float) -> void:
	#$PunchHitBox.monitoring = true	
	# --- State Management (Cooldowns/Timers) ---
	if punch_cooldown > 0:
		punch_cooldown -= delta
		if punch_cooldown <= 0:
			set_state(PlayerState.IDLE)
	
	# Always zero velocity, as movement is handled by Tweens (dodge) or state logic (punch decay)
	velocity.y = 0
	velocity.x = 0
	
	# --- Handle Actions Based on Input/Current State ---
	match current_state:
		PlayerState.IDLE, PlayerState.MOVING:
			# Player is stationary, only check for action inputs
			handle_action_input()
		
		PlayerState.PUNCHING_LEFT, PlayerState.PUNCHING_RIGHT:
			# Decays momentum but maintains current state until cooldown ends
			velocity.x = move_toward(velocity.x, 0, SPEED * 2) 
			pass

		PlayerState.DODGING_LEFT, PlayerState.DODGING_RIGHT:
			# Dodge movement is handled by the Tween
			pass

		PlayerState.BLOCKING:
			# BLOCKING State: Player must remain still
			
			# Check if the block button has been released
			if not Input.is_action_pressed("block"):
				set_state(PlayerState.IDLE)
				animated_sprite.play("idle")
			
			pass # End of BLOCKING logic
			
	move_and_slide()

# Checks for punch, dodge, and block inputs
func handle_action_input():
	# If the current state is not IDLE or MOVING, we ignore action inputs
	if current_state != PlayerState.IDLE and current_state != PlayerState.MOVING:
		return
		
	if Input.is_action_just_pressed("punch_right"):
		start_punch(PlayerState.PUNCHING_RIGHT, "punch_right", "player_punchright_hitbox") #need CHANGE
	elif Input.is_action_just_pressed("punch_left"):
		start_punch(PlayerState.PUNCHING_LEFT, "punch_left", "player_punchleft_hitbox")
	elif Input.is_action_just_pressed("dodge_left"):
		start_dodge(PlayerState.DODGING_LEFT, "dodge_left")
	elif Input.is_action_just_pressed("dodge_right"):
		start_dodge(PlayerState.DODGING_RIGHT, "dodge_right")	
	# Block should start on JUST_PRESSED and is intended to be held.
	elif Input.is_action_just_pressed("block"):
		start_block()
		
# --- Action Execution Functions ---
func start_punch(punch_state: PlayerState, visual_anim: String, hitbox_anim: String):
	set_state(punch_state)
	
	# 1. Start the visual animation
	animated_sprite.play(visual_anim) 
	
	# Added robust check to prevent crash if animation is missing
	var hitbox_anim_ref = animation_player.get_animation(hitbox_anim)
	#animation_player.play(hitbox_anim)
	if hitbox_anim_ref:
		# 2. Start the hitbox animation (Synchronization)
		animation_player.play(hitbox_anim) 
		# if animation exits, use its exact time as cooldown
		punch_cooldown = hitbox_anim_ref.length
	else:
		push_error("ERROR: Hitbox animation '" + hitbox_anim + "' not found in AnimationPlayer. Using default cooldown.")
		punch_cooldown = 0.5 # Default duration to avoid locking the player
	
	# listen to the signal of animation_finished
	if animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.disconnect(_on_animation_finished)
	# Connect signal to automatically reset state when punch animation finishes
	animation_player.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)

func start_dodge(dodge_state: PlayerState, visual_anim: String):
	
	# Kill any existing dodge tween to prevent conflicts
	if dodge_tween and dodge_tween.is_running():
		dodge_tween.kill()
	
	# CRITICAL: Clear velocity to ensure move_and_slide() doesn't interfere
	velocity = Vector2.ZERO

	# 1. Start the state and animation
	set_state(dodge_state)
	
	#Use .sprite_frames.has_animation() for Godot 4
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(visual_anim):
		animated_sprite.play(visual_anim)
	else:
		# If you see this, the animation name is the problem.
		push_error("ERROR: Dodge animation '" + visual_anim + "' or its SpriteFrames resource not found in AnimatedSprite2D. Check spelling!")
		# We continue execution here so the movement still runs, even without animation
		
	# 2. Grant Invulnerability (I-Frame)
	player_hurtbox.monitorable = false 
	
	# 3. Movement: Setup Tween for move-out and snap-back
	original_x = position.x # Save the original position
	
	var target_x: float = original_x
	
	# Calculate target based on direction
	if dodge_state == PlayerState.DODGING_LEFT:
		target_x = original_x - DODGE_DISTANCE 
	elif dodge_state == PlayerState.DODGING_RIGHT:
		target_x = original_x + DODGE_DISTANCE
		
		
	var half_duration = dodge_duration / 2.0

	# Create tween
	dodge_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Tween position property (local position)
	dodge_tween.tween_property(self, "position:x", target_x, half_duration)
	dodge_tween.tween_property(self, "position:x", original_x, half_duration)
	
	dodge_tween.finished.connect(_end_dodge, CONNECT_ONE_SHOT)

func _end_dodge() -> void:
	player_hurtbox.monitoring = true #set this to true so that the hurtbox is vunerable
	if current_state in [PlayerState.DODGING_LEFT, PlayerState.DODGING_RIGHT]:
		set_state(PlayerState.IDLE)
		animated_sprite.play("idle")
	# Failsafe: Ensure the player is exactly at the starting position
	position.x = original_x


func start_block():
	# Only enter block state if not already doing an action that blocks movement
	if current_state != PlayerState.PUNCHING_LEFT and current_state != PlayerState.PUNCHING_RIGHT and current_state != PlayerState.DODGING_LEFT and current_state != PlayerState.DODGING_RIGHT and current_state != PlayerState.HURT:
		set_state(PlayerState.BLOCKING)
		animated_sprite.play("block")

# --- State and Animation Handling ---
func set_state(new_state: PlayerState):
	if current_state != new_state:
		current_state = new_state
		

func _on_animation_finished(anim_name: String) -> void:
	# This signal only handles the end of the PUNCH animation tracks
	if anim_name.begins_with("punch"):
		# Ensure the visual sprite returns to the basic state immediately
		if animated_sprite.animation.begins_with("punch"):
			animated_sprite.play("idle")
	
func _on_player_hurt_box_area_entered(area: Area2D) -> void:

	# ---  Ignore self-collisions ---
	if area.get_parent() == self:
		return

	# ---  Only react to attack hitboxes (Layer 2) ---
	if area.collision_layer != 2:
		return

	# ---  Skip if already hurt or defeated ---
	if current_state == PlayerState.HURT or current_state == PlayerState.DEFEATED:
		return

	# ---  Blocking or dodging cancels damage ---
	if current_state == PlayerState.BLOCKING:
		print("Player: Attack blocked!")
		area.monitoring = false
		return

	if current_state == PlayerState.DODGING_LEFT or current_state == PlayerState.DODGING_RIGHT:
		print("Player: Attack dodged!")
		area.monitoring = false
		return
	
	# ---  Successful hit detected ---
	print("Player was hit! Taking damage.")

	# Disable the opponent’s hitbox to prevent multi-hit
	area.monitoring = false

	set_state(PlayerState.HURT)

	# ---  Determine direction of hurt animation ---
	var hurt_anim = "hurt_right"	# default

	var opponent = area.get_parent()
	if opponent.has_node("AnimatedSprite2D"):
		var opponent_sprite = opponent.get_node("AnimatedSprite2D")
		var opponent_anim = opponent_sprite.animation

		if opponent_anim == "punch_left":
			hurt_anim = "hurt_left"
		elif opponent_anim == "punch_right":
			hurt_anim = "hurt_right"

	print("Playing hurt animation:", hurt_anim)

	# ---  Connect to recovery callback ---
	if animated_sprite.animation_finished.is_connected(_on_hurt_animation_finished):
		animated_sprite.animation_finished.disconnect(_on_hurt_animation_finished)
	animated_sprite.animation_finished.connect(_on_hurt_animation_finished, CONNECT_ONE_SHOT)

	# ---  Play the animation and apply damage ---
	animated_sprite.play(hurt_anim)
	take_damage(10)
	punch_sound.play()


# ---  Damage & gameover logic ---
func take_damage(damage_amount: int) -> void:
	current_health = max(0, current_health - damage_amount)
	health_changed.emit(current_health)

	if current_health <= 0:
		set_state(PlayerState.DEFEATED)
		print("Player gameover!!!!!!") #add the win/lose screen here
		SceneManager.change_scene(SceneManager.SCENE_PLAYERLOSE)
		#var opponent = get_tree().get_first_node_in_group("opponent")
		#opponent.trigger_win_animation()
		# Example: get_tree().paused = true
		# Or emit_signal("game_over")
		
		


# ---  Hurt recovery ---
func _on_hurt_animation_finished() -> void:
	if animated_sprite.animation in ["hurt_left", "hurt_right"]:
		if current_health > 0:
			set_state(PlayerState.IDLE)
			animated_sprite.play("idle")
	
	# --- Re-enable opponent hitbox ---
		# Adjust the path to your opponent node as needed
		var opponent = get_node("../Opponent")
		if opponent and opponent.has_node("PunchHitBox"):
			var opp_hitbox = opponent.get_node("PunchHitBox")
			opp_hitbox.monitoring = true
	
	if animated_sprite.animation_finished.is_connected(_on_hurt_animation_finished):
		animated_sprite.animation_finished.disconnect(_on_hurt_animation_finished)

func trigger_win_animation():
	# Stop player control
	set_process(false)
	set_physics_process(false)
	# 3. Use the correct node to play the animation
	animated_sprite.play("winning")
