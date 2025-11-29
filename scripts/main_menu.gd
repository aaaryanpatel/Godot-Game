extends Control

# --- Node References ---
# These paths are automatically linked in the Godot editor after attaching the script
@onready var background_music = $MainMenuMusicPlayer
@onready var button_click_sound = $ButtonClickSound
# The buttons should be linked via their signals, but referencing them explicitly
# can be useful for dynamic styling or disabling, so we'll keep them here.
@onready var tutorial_button = $VBoxContainer/TutorialButton
@onready var gameplay_button = $VBoxContainer/GamePlayButton
@onready var credits_button = $VBoxContainer/CreditsButton
@onready var exit_button = $VBoxContainer/ExitButton

# --- keyboard navigation state ---
var _menu_buttons: Array = []    
var _idx := 0      



# --- Initialization ---
#inin
func _ready():
	# Start the background music when the main menu scene loads
	background_music.play()
##

	# --- prepare focusable buttons and default focus ---
	_menu_buttons = [tutorial_button, gameplay_button, credits_button, exit_button]  #  ordered list
	for b in _menu_buttons:                                                          
		if b:                                                                     
			b.focus_mode = Control.FOCUS_ALL                                         
			b.focus_entered.connect(_on_button_focus.bind(b))  # keep _idx synced with UI focus
	#  set initial focus to first button (if present)
	if _menu_buttons.size() > 0 and _menu_buttons[0]:                                 
		_menu_buttons[0].grab_focus()                                              
		_refresh_focus_visuals()                               #  draw initial highlight

# --- handle Up/Down arrows and Enter/Return (ui_accept) ---
func _unhandled_input(event):                                                       
	if _menu_buttons.is_empty():                                                    
		return                                                                       
	if event.is_action_pressed("ui_down"):                                          
		_idx = (_idx + 1) % _menu_buttons.size()                                    
		_menu_buttons[_idx].grab_focus()                                             
	elif event.is_action_pressed("ui_up"):                                          
		_idx = (_idx - 1 + _menu_buttons.size()) % _menu_buttons.size()              
		_menu_buttons[_idx].grab_focus()                                             
	elif event.is_action_pressed("ui_accept"):   
		
		var owner = get_viewport().gui_get_focus_owner()  
		if owner and owner is BaseButton:                 
			owner.emit_signal("pressed")                  
		else:                                             
			_menu_buttons[_idx].emit_signal("pressed") 

func _on_button_focus(b):                       
	_idx = _menu_buttons.find(b)                 
	_refresh_focus_visuals()                                     # update highlight when focus changes

# lightweight visual highlight for the focused button
func _refresh_focus_visuals():                                   
	for i in _menu_buttons.size():                                
		var b: BaseButton = _menu_buttons[i]                     
		if not b:                                                 
			continue                                             
		var t := create_tween()                                   
		if i == _idx:                                             
			# Focused: full brightness and a tiny scale pop       
			t.tween_property(b, "self_modulate", Color(1, 1, 1, 1), 0.08)  
			t.parallel().tween_property(b, "scale", Vector2(1.06, 1.06), 0.08) 
		else:                                                    
			# Unfocused: slightly dim and normal scale            
			t.tween_property(b, "self_modulate", Color(0.8, 0.8, 0.8, 1), 0.08) 
			t.parallel().tween_property(b, "scale", Vector2(1, 1), 0.08)        

##
# --- Button Signal Handlers ---
# These functions are called when the corresponding buttons emit the 'pressed()' signal.

func _on_tutorial_button_pressed():
	#stop background music
	background_music.stop()
	#play button sound	
	button_click_sound.play()
	# Wait briefly for the click sound to start playing before switching scenes
	await get_tree().create_timer(0.6).timeout
	call_deferred("transition_to_tutorial")

func _on_gameplay_button_pressed():
	background_music.stop()
	button_click_sound.play()
	await get_tree().create_timer(0.6).timeout
	call_deferred("transition_to_gameplay")

func _on_credits_button_pressed():
	background_music.stop()
	button_click_sound.play()
	await get_tree().create_timer(0.6).timeout
	call_deferred("transition_to_credits")

func _on_exit_button_pressed():
	background_music.stop()
	button_click_sound.play()
	await get_tree().create_timer(0.6).timeout
	SceneManager.quit_game()

# --- Deferred Scene Transitions ---

# Calls the global SceneManager AutoLoad to navigate.
func transition_to_tutorial():
	SceneManager.change_scene(SceneManager.SCENE_TUTORIAL)

func transition_to_gameplay():
	SceneManager.change_scene(SceneManager.SCENE_GAMEPLAY)

func transition_to_credits():
	SceneManager.change_scene(SceneManager.SCENE_CREDITS)
	#SceneManager.change_scene(SceneManager.SCENE_GAMEOVER)
