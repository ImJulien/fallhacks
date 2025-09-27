extends Node2D

@onready var conveyor = $AnimatedSprite2D

func _ready():
	conveyor.play()
