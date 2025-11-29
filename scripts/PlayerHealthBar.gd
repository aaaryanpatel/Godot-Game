extends TextureProgressBar

@onready var player: CharacterBody2D = $"../../Player"


func _ready():
	player.health_changed.connect(update) #when player's health_changed emits, call the update()
	update()

func update(current_health: int = -1):
	if current_health == -1:
		current_health = player.current_health
	value = float(current_health) * 100 / player.max_health #the property of Texture Progress Bar
	
