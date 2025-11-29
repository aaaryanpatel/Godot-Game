extends CharacterBody2D

# Constants
const SPEED = 300.0

# Define the exclusive states the player can be in (Must match the player's definition)
enum OpponentState {
	IDLE, MOVING,
	PUNCHING_LEFT, PUNCHING_RIGHT,
	BLOCKING,
	HURT, DEFEATED
}

# Current state variable
var current_state: OpponentState = OpponentState.IDLE
var punch_cooldown: float = 0.0

# Node References
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_opponent: AnimationPlayer = $AnimationPlayer 
@onready var opponent_punch_hitbox: Area2D = $PunchHitBox 
@onready var opponent_hurtbox: Area2D = $OpponentHurtBox
@onready var block_timer: Timer = $BlockTimer
@onready var punch_sound: AudioStreamPlayer2D = $PunchSound

#Hurt handling variables
signal health_changed(new_health: int)
var max_health: int = 100
var current_health: int = 100

# AI Variables
@export var target: CharacterBody2D 
var action_timer: float = 0.0 	 
const AI_DECISION_RATE = 0.5 	
const PUNCH_RANGE = 95.0		# VERTICAL distance to start punching
const SAFE_RANGE = 250.0		# VERTICAL distance to start blocking/dodging

func _ready():
	#when timer is timeout, call the function, ensuring the state flips back to `IDLE` after the block duration is over.
	block_timer.timeout.connect(_on_block_timer_timeout)
	
	if not animation_opponent.animation_finished.is_connected(_on_punch_animation_finished):
		animation_opponent.animation_finished.connect(_on_punch_animation_finished)

func _physics_process(delta: float) -> void:
	
	if current_state == OpponentState.DEFEATED:
		# Stop all movement and prevent the AI from running
		velocity = Vector2.ZERO
		move_and_slide() # Ensure movement is applied to handle velocity=0
		return # Stops all subsequent code in _physics_process
	# --- State Management (Cooldowns/Timers) ---
	# deplay time between consecutive actions (countdown by the cycle time) 
	if punch_cooldown > 0:
		punch_cooldown -= delta
		if punch_cooldown <= 0:
			set_state(OpponentState.IDLE)
	
	# Horizontal velocity is zeroed to prevent horizontal movement
	velocity.x = 0 

	# --- Handle Actions Based on AI/Current State ---
	match current_state:
		# AI is in an active state and can make decisions
		OpponentState.IDLE, OpponentState.MOVING:
			handle_ai_movement() 
			handle_ai_actions(delta)

		OpponentState.PUNCHING_LEFT, OpponentState.PUNCHING_RIGHT:
			# Explicitly set velocity to zero to stop movement during the punch cooldown.
			velocity.y = 0 
			pass

		# Lock all movement and input during defensive/recovery/defeated states
		OpponentState.BLOCKING, OpponentState.HURT, OpponentState.DEFEATED:
			velocity.y = 0 # Lock vertical movement
			pass
			
	move_and_slide()
	

# Handles AI movement decisions
func handle_ai_movement():
	#if the target (player) is not valid (e.g. defeated for removed), opponent stops and return to idle state
	if not is_instance_valid(target):
		velocity.x = 0
		velocity.y = 0
		set_state(OpponentState.IDLE)
		return
		
	# --- Use Y-axis for core fight distance tracking (Vertical movement) ---
	var direction_to_target = target.global_position.y - global_position.y
	var distance_to_target = abs(direction_to_target)
	
	# Lock horizontal movement as we are constrained to the vertical axis
	velocity.x = 0

	# Decide Vertical Movement (Based on Y distance)
	if distance_to_target > PUNCH_RANGE * 1.5:
		# Player is too far (vertically), move toward them (up/down)
		velocity.y = sign(direction_to_target) * SPEED
		set_state(OpponentState.MOVING)
	elif distance_to_target < PUNCH_RANGE * 0.5:
		# Player is too close (vertically), back away a bit
		velocity.y = sign(direction_to_target) * -SPEED * 0.5
		set_state(OpponentState.MOVING)
	else:
		# Player is in punch range, stop and prepare to fight
		velocity.y = 0
		set_state(OpponentState.IDLE)


# Handles AI combat decisions (punch, block, idle)
func handle_ai_actions(delta: float):
	if not is_instance_valid(target):
		return
	
	# delay the next call of the function for a period of AI_DECISION_RATE	
	action_timer -= delta		#count down the timer for a cycle of a physics frame
	if action_timer > 0:		#if still within the allowed time period, return, else reset the timers and run the next move
		return	
	action_timer = AI_DECISION_RATE
	
	#get the player state and store it to the target_state (so the opponent knows what the player is doing
	var target_state: OpponentState = OpponentState.IDLE
	if "current_state" in target:
		target_state = target.current_state
	
	#determine the distance between the opponent and the player
	var distance_to_target = abs(target.global_position.y - global_position.y)
	
	#generate a random number between [0,1)
	var decision = randf()

	# --- 1. REACTIVE DEFENSE ---
	
	if target_state == OpponentState.PUNCHING_LEFT or target_state == OpponentState.PUNCHING_RIGHT:
		
		# Determine the required counter-punch hand
		var use_right_punch: bool = (target_state == OpponentState.PUNCHING_RIGHT)
		
		# Set up the counter-punch variables
		var punch_state = OpponentState.PUNCHING_RIGHT if use_right_punch else OpponentState.PUNCHING_LEFT
		var anim_name = "punch_right" if use_right_punch else "punch_left"
		var hitbox_name = "opponent_hitbox" 
		
		# 50% chance to block
		if decision < 0.5: 
			start_block()
			return
		
		# 40% chance to execute a directed counter-punch (0.5 to <0.9)
		elif decision < 0.6:
			# Launch the opposite punch as a counter-attack
			start_punch(punch_state, anim_name, hitbox_name)
			return
		
		# 10% chance to fail to react (remain IDLE and take the hit)
		else:
			return 
	
	# --- 2. OFFENSIVE & GENERAL ACTIONS (If idle and in range) ---
	# The AI is not currently being attacked.
	if distance_to_target < PUNCH_RANGE and current_state == OpponentState.IDLE:
		
		# Use a new random decision for this section to ensure independence
		var general_decision = randf()
		
		# A. Aggressive Punch: If target is idle, attack more often. (60% chance)
		if target_state == OpponentState.IDLE and general_decision < 0.6: 
			
			var use_right_punch = randi() % 2 == 0
			var punch_state = OpponentState.PUNCHING_RIGHT if use_right_punch else OpponentState.PUNCHING_LEFT
			var anim_name = "punch_right" if use_right_punch else "punch_left"
			#var hitbox_name = "opponent_hitbox"
			var hitbox_name = "opponent_punchleft_hitbox" if use_right_punch else "opponent_punchright_hitbox"
			
			start_punch(punch_state, anim_name, hitbox_name)
			return
		
		# B. General Block (0.6 to <0.75) - 15% chance
		elif general_decision < 0.75:
			start_block()
			return

		# C. Remain IDLE (0.75 to 1.0) - 25% chance
		# The AI decides to intentionally do nothing.
		else:
			return
	
	# --- 3. MOVEMENT/IDLE (If out of range) ---
	# If the AI is out of range, it has no offensive options, so it remains IDLE.
	if distance_to_target >= PUNCH_RANGE and current_state == OpponentState.IDLE:
		return # Remain IDLE
		
	# If the AI is currently punching or blocking, it also remains IDLE (until the action completes).		
	
#--- Action Execution Functions ---

func start_punch(punch_state: OpponentState, visual_anim: String, hitbox_anim: String):
	#if the opponent is doing some actions (e.g. punch, dogde, block), do not punch
	if current_state != OpponentState.IDLE and current_state != OpponentState.MOVING: return

	#stop all vertical movement when initiating a punch
	velocity.y = 0 
	
	opponent_punch_hitbox.monitoring = false
	#set the punch state and animate the opponent and its hit box 
	set_state(punch_state)
	animated_sprite.play(visual_anim) 
	animation_opponent.play(hitbox_anim)
	# --- Disable hitbox at the start of the punch ---
		
	
	# Synchronize the time for visual punch animation and the punch hitbox animation
	var anim_hit = animation_opponent.get_animation(hitbox_anim)
	if anim_hit:
		#set cooldown time equal to the length of the animation
		punch_cooldown = anim_hit.length
	else:
		push_error("Opponent punch animation missing: " + hitbox_anim)
		punch_cooldown = 0.5
	
	#Disconnect before connecting to prevent error
	if animation_opponent.animation_finished.is_connected(_on_animation_finished):
		animation_opponent.animation_finished.disconnect(_on_animation_finished)
		
	animation_opponent.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)


func start_block():
	if current_state != OpponentState.IDLE and current_state != OpponentState.MOVING: return

	set_state(OpponentState.BLOCKING)
	animated_sprite.play("block")
	#Start the timer when the block begins
	block_timer.start() 

#timer starts countdown and the function is called when it reaches zero
func _on_block_timer_timeout():
	current_state = OpponentState.IDLE

# --- State and Animation Handling ---

func set_state(new_state: OpponentState):
	if current_state != new_state:
		current_state = new_state

func _on_animation_finished(anim_name: String) -> void:
	if anim_name.begins_with("punch"):
		if animated_sprite.animation.begins_with("punch"):
			animated_sprite.play("idle")

# Damage Detection and Handling
func _on_player_hurt_box_area_entered(area: Area2D) -> void:
	# Debug
	print("Opponent hit by: " + area.name)

	if area.collision_layer != 2:
		return

	# BLOCK CHECK
	if current_state == OpponentState.BLOCKING:
		print("Opponent blocked attack!")
		return

	# Prevent multi-hit from the same attack instance
	area.monitoring = false
	
	# Apply damage
	take_damage(10)
	punch_sound.play()

	# Play hurt animation if not already playing
	if animated_sprite.animation != "hurt":
		set_state(OpponentState.HURT)
		animated_sprite.play("hurt")
		if animated_sprite.animation_finished.is_connected(_on_hurt_animation_finished):
			animated_sprite.animation_finished.disconnect(_on_hurt_animation_finished)
		animated_sprite.animation_finished.connect(_on_hurt_animation_finished, CONNECT_ONE_SHOT)
	
func take_damage(damage_amount: int) -> void:
	# Deduct health no matter the state
	current_health = max(0, current_health - damage_amount)
	health_changed.emit(current_health)

	# Check for defeat
	if current_health <= 0 and current_state != OpponentState.DEFEATED:
		set_state(OpponentState.DEFEATED)
		#animated_sprite.play("defeated")  # optional defeated animation

		# Stop any ongoing animation or punch timer
		if animated_sprite.is_playing():
			animated_sprite.stop()
		
		# Stop and disconnect BlockTimer
		if block_timer and not block_timer.is_stopped():
			block_timer.stop()
		var callable_ref1 = Callable(self, "_on_block_timer_timeout")
		if block_timer.is_connected("timeout", callable_ref1):
			block_timer.disconnect("timeout", callable_ref1)

		if opponent_punch_hitbox.monitorable:
			opponent_punch_hitbox.monitorable = false

		if has_node("PunchTimer"):
			var punch_timer = $PunchTimer
			if punch_timer.is_stopped() == false:
				punch_timer.stop()

	# Disconnect animation_finished if it's connected
		var callable_ref = Callable(self, "_on_animation_finished")
		if animated_sprite.is_connected("animation_finished", callable_ref):
			animated_sprite.disconnect("animation_finished", callable_ref)

		animated_sprite.play("defeated")
		print("Opponent Defeated! Player Wins.")
		SceneManager.change_scene(SceneManager.SCENE_PLAYERWIN)
		#add the Win/Lose screen
		#access the player node from the group and call a function on it
		#var player = get_tree().get_first_node_in_group("player")
		#player.trigger_win_animation()
		
		

func _on_hurt_animation_finished(anim_name: String) -> void:
	if anim_name != "hurt":
		return

	# Only reset if opponent is alive
	if current_health > 0:
		set_state(OpponentState.IDLE)
		animated_sprite.play("idle")
		print("Opponent recovered from being hurt!")

	# Disconnect the signal to avoid duplicate connections
	if animated_sprite.animation_finished.is_connected(_on_hurt_animation_finished):
		animated_sprite.animation_finished.disconnect(_on_hurt_animation_finished)

func _on_punch_animation_finished(anim_name: String) -> void:
	if anim_name in ["opponent_punchleft_hitbox", "opponent_punchright_hitbox"]:
		if opponent_punch_hitbox:
			opponent_punch_hitbox.monitoring = true;

func trigger_win_animation():
	# Stop opponent control
	set_process(false)
	set_physics_process(false)
	# 3. Use the correct node to play the animation
	animated_sprite.play("winning")

func _on_punch_hit_box_area_entered(area: Area2D) -> void:
	if area.name == "PlayerHurtBox":
		print("HHHH")
		
		
