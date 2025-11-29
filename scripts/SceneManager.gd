extends Node

# --- Scene Path Constants ---
# Define the path for every scene in your game flow.
# Using constants makes it easy to update paths later if needed.
const SCENE_INTRO 	 = "res://scenes/intro_screen.tscn"
const SCENE_MAIN_MENU = "res://scenes/main_menu.tscn" # Renamed from SCENE_MENU for clarity
const SCENE_TUTORIAL = "res://scenes/tutorial_screen.tscn"
const SCENE_GAMEPLAY = "res://scenes/gameplay_screen.tscn"
const SCENE_CREDITS	 = "res://scenes/credits_screen.tscn"
const SCENE_WIN		 = "res://scenes/win_screen.tscn"
const SCENE_GAMEOVER = "res://scenes/game_over_screen.tscn"
const SCENE_PLAYERWIN = "res://scenes/player_win.tscn"
const SCENE_PLAYERLOSE = "res://scenes/player_lose.tscn"


# --- Core Function for Scene Switching ---

# Changes the currently running scene to the specified target scene path.
# This function includes robust checks to prevent crashes from missing scenes.
func change_scene(target_scene_path: String) -> void:
	if target_scene_path.is_empty():
		print("SCENE MANAGER ERROR: Target scene path is empty.")
		return

	# Use ResourceLoader.exists() to check if the scene file is available before loading
	if not ResourceLoader.exists(target_scene_path):
		# FIX: Switched from f-string to % formatting to avoid a potential Parse Error
		print("SCENE MANAGER ERROR: Scene file not found at path: %s" % target_scene_path)
		return
		
	# Attempt to change the active scene in the SceneTree
	# Using change_scene_to_file is correct here as the constants are file paths.
	var error = get_tree().change_scene_to_file(target_scene_path)
	
	if error != OK:
		# FIX: Switched from f-string to % formatting for robustness
		# If the error is not OK (0), print the error code.
		print("SCENE MANAGER ERROR changing scene to %s. Error code: %d" % [target_scene_path, error])
	else:
		# FIX: Switched from f-string to % formatting for robustness
		print("Scene successfully changed to: %s" % target_scene_path)

# --- Core Function for Exiting the Game ---

# Closes the entire application.
func quit_game() -> void:
	get_tree().quit()
