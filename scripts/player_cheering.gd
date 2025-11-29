extends AnimatedSprite2D

@onready var player_cheering: AnimatedSprite2D = $"."
@onready var win_music: AudioStreamPlayer2D = $"../WinMusic"
@onready var button_click: AudioStreamPlayer2D = $"../ButtonClick"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if win_music:
		win_music.play()
	player_cheering.play("player_cheering")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	


func _on_menu_button_pressed() -> void:
	"""
	Handles the click of the Start button.
	1. Plays the click sound effect.
	2. Stops the background music.
	3. Uses the SceneManager to move to the Main Menu.
	"""
	
	# Stop music before switching, or it will continue until the next scene loads
	if win_music.playing:
		win_music.stop()
		
	if button_click:
		button_click.play()
	
	# Wait briefly for the click sound to start playing before switching scenes
	await get_tree().create_timer(0.6).timeout
		
	# Use the global SceneManager AutoLoad to switch the scene
	SceneManager.change_scene(SceneManager.SCENE_MAIN_MENU)
