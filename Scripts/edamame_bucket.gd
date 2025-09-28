extends Node2D

@onready var area = $Area2D
@onready var parent_node = self.get_parent()

func _ready():
	area.input_event.connect(_on_area_input_event)
	
func spawn_item():
	var item_base = preload("res://Scenes/tomato.tscn")
	var new_edemame = item_base.instantiate()
	var edemame_sprite: Sprite2D = new_edemame.get_node('Sprite2D')
	edemame_sprite.texture = load('res://Assets/Sprites/Foodge/Edamame.png')
	new_edemame.name = "NewTomato"
	new_edemame.global_position = get_viewport().get_mouse_position()
	parent_node.add_child(new_edemame)
	new_edemame.start_drag(get_viewport().get_mouse_position())
	new_edemame.visible = true
	
	print("spawned")

func _on_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		spawn_item()
