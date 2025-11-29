extends Control

# Node References
@onready var background_music: AudioStreamPlayer2D = $GamePlayMusicPlayer

# NOTE: The names here must match the node names in your scene tree exactly.
@onready var player_node: CharacterBody2D = $Player 
@onready var opponent_node: CharacterBody2D = $Opponent 


func _ready():
	# Play background music
	background_music.play()
	
	# If you want to force these positions, keep this code. Otherwise, you can delete it
	# and set the positions visually in the editor.
	player_node.global_position = Vector2(550, 640)
	
	var grounded_y_position = 550.0
	opponent_node.global_position = Vector2(550, grounded_y_position)

	# Set starting_y (Clamping Anchor)
	# This ensures the clamping in opponent.gd uses the correct position.
	if "starting_y" in opponent_node:
		opponent_node.starting_y = grounded_y_position
	else:
		push_error("Opponent script is missing 'starting_y' variable for position anchor.")

	# Set the target (AI Tracking)
	opponent_node.target = player_node


func _input(event):
	pass

func _process(delta: float) -> void:
	
	pass
