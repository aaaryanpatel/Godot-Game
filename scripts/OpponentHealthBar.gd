extends TextureProgressBar

@onready var opponent: CharacterBody2D = $"../../Opponent"



func _ready():
	opponent.health_changed.connect(update)
	update()

func update(current_health: int = -1):
	if current_health == -1:
		current_health = opponent.current_health
	value = float(current_health) * 100 / opponent.max_health
