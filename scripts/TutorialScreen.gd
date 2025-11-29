extends Control

@onready var anim = $PlayerSprite
enum PLAYER_STATE {IDLE, DODGE_LEFT, PUNCH_RIGHT, PUNCH_LEFT, RECOVERY, DOGDE_RIGHT, BLOCK}
var current_state = PLAYER_STATE.IDLE
@onready var background_music: AudioStreamPlayer2D = $TutorialMusicPlayer
@onready var game_play_button: TextureButton = $GamePlayButton
@onready var button_click_player: AudioStreamPlayer2D = $ButtonClickPlayer
@onready var punch_sound: AudioStreamPlayer2D = $PunchSound


#the below variables are for the coach instructions
# The full sequence of actions to guide the player through
# 1: Punch Left, 2: Punch Right, 3: Dodge Left, 4: Dodge Right, 5: Block
# We will use this sequence to guide the player.
var tutorial_step: int = 0

# Initial instruction text using a dictionary
var instruction_texts = {
	0: "Welcome! I'm your coach. Get ready to follow my lead...",
	1: "Start by using \n your left hook! \n Press Key A.",
	2: "Now follow up with a right cross!\n Press Key D.",
	3: "Incoming! Quickly dodge to the left! \nPress < Arrow.",
	4: "Another one! Dodge to the right! \nPress > Arrow.",
	5: "Block high!\n Press Down Arrow.",
	6: "OK, Tutorial Complete! You're ready to FIGHT!"
}
var instruction_keys = { 
	1: "Press Key A.",
	2: "Press Key D.",
	3: "Press < Arrow.",
	4: "Press > Arrow.",
	5: "Press Down Arrow."
}

#this function runs when we hit play button
func _ready():
	print("PlayerSprite type:", anim.get_class())
	#we define different animations, we call AnimationPlayer object's play method to play
	anim.play("idle")
	#play music
	background_music.play()
	# Set the initial instruction when the game starts
	$Bubble/tutor.text = instruction_texts[tutorial_step]
	
	#create a timere to delay 8 seconds
	var timer = get_tree().create_timer(8.0)
	
	#when time is out, call the method to start the tutorial
	timer.timeout.connect(self.on_tutorial_start)

func on_tutorial_start():
	#move to step 1
	tutorial_step = 1
	$Bubble/tutor.text = instruction_texts[tutorial_step]

func _input(event):
	
	# This ignores key releases and non-key events like mouse motion/touch.
	if not event.is_pressed():
		return
	# Now, check if this pressed event corresponds to ANY of your five actions
	# This prevents the logic from running on every single key pressed.
	if Input.is_action_pressed("punch_left") or Input.is_action_pressed("punch_right") or Input.is_action_pressed("dodge_left") or Input.is_action_pressed("dodge_right") or Input.is_action_pressed("block"):
		# The core tutorial logic
		update_tutorial_state()
		
func update_tutorial_state():
	var is_correct_action = false
	var expected_action_name = ""
	var pressed_action = "" # Variable to store the action that was actually pressed
	
	# Check which action was pressed *right now*
	# We check all five actions to see what the player did.
	if Input.is_action_pressed("punch_left"):
		pressed_action = "punch_left"
	elif Input.is_action_pressed("punch_right"):
		pressed_action = "punch_right"
	elif Input.is_action_pressed("dodge_left"):
		pressed_action = "dodge_left"
	elif Input.is_action_pressed("dodge_right"):
		pressed_action = "dodge_right"
	elif Input.is_action_pressed("block"):
		pressed_action = "block"

	# --- Match Tutorial Step to Expected Action ---
	match tutorial_step:
		1:
			expected_action_name = "punch_left"
		2:
			expected_action_name = "punch_right"
		3:
			expected_action_name = "dodge_left"
		4:
			expected_action_name = "dodge_right"
		5:
			expected_action_name = "block"
		_:
			# Tutorial is finished
			return

	# --- Update State ---
	if pressed_action == expected_action_name:
		# Correct move! Advance step.
		tutorial_step += 1
		$Bubble/tutor.text = instruction_texts.get(tutorial_step, "Tutorial Complete! You're ready to FIGHT!")
	else:
		# Wrong move! Repeat current instruction
		$Bubble/tutor.text = "Wrong move! \nI need the " + expected_action_name.replace("_", " ") + "! " + instruction_keys.get(tutorial_step)
				
#this is like the main class in java, it runs the entire game	
func _process(delta):
	match current_state:
		PLAYER_STATE.IDLE:
			#check for dodge input
			if Input.is_action_pressed("dodge_left"): #the keypress action is defined in Project/Settings/Input Map
				anim.play("dodge_left")
				current_state = PLAYER_STATE.DODGE_LEFT
			#check for punch input
			elif Input.is_action_pressed("punch_left"):
				anim.play("punch_left")
				current_state = PLAYER_STATE.PUNCH_LEFT
			elif Input.is_action_pressed("punch_right"):
				anim.play("punch_right")
				current_state = PLAYER_STATE.PUNCH_RIGHT
			elif Input.is_action_pressed("dodge_right"):
				anim.play("dodge_right")
				current_state = PLAYER_STATE.PUNCH_RIGHT
			elif Input.is_action_pressed("block"):
				anim.play("block")
				current_state = PLAYER_STATE.BLOCK	
			elif not anim.is_playing():
				anim.play("idle")

#each time when the animation is played (it is passed with a parameter, e.g. punch_righ), when the animation completes,
#this triggers this signal/event function (we set up this link in node) passing the name of the animation
#AnimatedSprite2D does not have the argument in this function
func _on_player_sprite_animation_finished():
	print("Animation finished signal received for:", anim.animation)
	if anim.animation in ["punch_left", "punch_right"]:
		punch_sound.play()
	if anim.animation in ["dodge_left", "punch_left", "punch_right", "dodge_right", "block"]:
		current_state = PLAYER_STATE.IDLE
		anim.play("idle")

func _on_PlayButton_pressed():
	"""
	Handles the click of the Start button.
	1. Stops the background music.
	2. Plays the click sound effect.
	3. Uses the SceneManager to move to the Main Menu.
	"""
	
	# Stop music before switching, or it will continue until the next scene loads
	if background_music.playing:
		background_music.stop()
		
	if button_click_player:
		button_click_player.play()
	
	# Wait briefly for the click sound to start playing before switching scenes
	await get_tree().create_timer(0.6).timeout
		
	# Use the global SceneManager AutoLoad to switch the scene
	SceneManager.change_scene(SceneManager.SCENE_GAMEPLAY)


func _on_again_button_pressed() -> void:
	if background_music.playing:
		background_music.stop()
	
	if button_click_player:
		button_click_player.play()
	
	# Wait briefly for the click sound to start playing before switching scenes
	await get_tree().create_timer(0.6).timeout
		
	# Use the global SceneManager AutoLoad to switch the scene
	SceneManager.change_scene(SceneManager.SCENE_TUTORIAL)
