extends Control

@onready var intro_music_player: AudioStreamPlayer2D = $IntroMusicPlayer
@onready var button_start_player: AudioStreamPlayer2D = $ButtonClickPlayer
@onready var intro_texts: RichTextLabel = $ScrollContainer/IntroTexts
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var start_button: BaseButton = $StartButton  
const SCROLL_SPEED = 15 # Pixels per second

# Called when the node enters the scene tree for the first time.
func _ready():
	# 1. Start the main intro music immediately
	if intro_music_player:
		intro_music_player.play()

	# Start at top of scroll
	var vbar := scroll_container.get_v_scroll_bar()
	vbar.value = 0
	if start_button:
		start_button.focus_mode = Control.FOCUS_ALL  
		start_button.grab_focus()
	

func _process(delta):
	var vbar := scroll_container.get_v_scroll_bar()
	vbar.value += SCROLL_SPEED * delta

	# Stop scrolling when reached bottom
	if vbar.value >= vbar.max_value:
		#print("Scrolling finished.")
		set_process(false)
		
func _unhandled_input(event):                       
	if event.is_action_pressed("ui_accept"):        
		_on_StartButton_pressed()      

# --- Button Handler ---
func _on_StartButton_pressed():
	"""
	Handles the click of the Start button.
	1. Plays the click sound effect.
	2. Stops the background music.
	3. Uses the SceneManager to move to the Main Menu.
	"""
	# Stop music before switching, or it will continue until the next scene loads
	if intro_music_player.playing:
		intro_music_player.stop()

	if button_start_player:
		button_start_player.play()
	
	# Wait briefly for the click sound to start playing before switching scenes
	await get_tree().create_timer(0.6).timeout
	
		
	# Use the global SceneManager AutoLoad to switch the scene
	SceneManager.change_scene(SceneManager.SCENE_MAIN_MENU)
