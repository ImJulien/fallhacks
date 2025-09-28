extends Node2D

@onready var area = $Area2D
@onready var parent_node = self.get_parent()

func _ready():
	area.input_event.connect(_on_area_input_event)
	
func spawn_item():
	var item_base = preload("res://Scenes/tomato.tscn")
	var new_corn = item_base.instantiate()
	var corn_sprite: Sprite2D = new_corn.get_node('Sprite2D')
	corn_sprite.texture = load('res://Assets/Sprites/Foodge/Corn.png')
	new_corn.name = "Corn"
	new_corn.global_position = get_viewport().get_mouse_position()
	parent_node.add_child(new_corn)
	new_corn.start_drag(get_viewport().get_mouse_position())
	new_corn.visible = true
	
	print("spawned")

func _on_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		spawn_item()
