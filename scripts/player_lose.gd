extends Control
@onready var opponent_cheering: AnimatedSprite2D = $OpponentCheering
@onready var lose_music: AudioStreamPlayer2D = $LoseMusic
@onready var button_click: AudioStreamPlayer2D = $ButtonClick

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if lose_music:
		lose_music.play()
	opponent_cheering.play("cheering")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	

func _on_menu_button_pressed():
	"""
	Handles the click of the Start button.
	1. Plays the click sound effect.
	2. Stops the background music.
	3. Uses the SceneManager to move to the Main Menu.
	"""
	
	# Stop music before switching, or it will continue until the next scene loads
	if lose_music.playing:
		lose_music.stop()
		
	if button_click:
		button_click.play()
	
	# Wait briefly for the click sound to start playing before switching scenes
	await get_tree().create_timer(0.6).timeout
		
	# Use the global SceneManager AutoLoad to switch the scene
	SceneManager.change_scene(SceneManager.SCENE_MAIN_MENU)
