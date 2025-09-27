extends Node2D

@onready var area = $Area2D

func _ready():
	area.input_event.connect(_on_area_input_event)
	
func spawn_item():
	var tomato_scene = load("res://Scenes/tomato.tscn")
	var new_tomato = tomato_scene.instantiate()
	new_tomato.name = "NewTomato"
	new_tomato.global_position = Vector2(100, 100)
	new_tomato.visible = true
	print("spawned")

func _on_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("edemame")
		spawn_item()
