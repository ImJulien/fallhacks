extends AnimatedSprite2D

@onready var burner = $"."

func _ready():
	burner.play()
