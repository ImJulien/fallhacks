extends Node2D

@onready var camera := $Camera2D
var camera_up_position: float
var camera_down_position: float

func _ready():
	# Store the initial camera position as the "up" position
	camera_up_position = camera.position.y
	# Down position is one screen height below
	camera_down_position = camera_up_position + get_viewport().get_visible_rect().size.y
	
	# Debug ingredient and pan setup
	call_deferred("debug_scene_setup")

func _process(_delta):
	if Input.is_action_just_pressed("Down"):
		# camera down to cook surface
		var tween_down := create_tween()
		tween_down.tween_property(camera, "position:y", camera_down_position, 0.3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tween_down.play()
	if Input.is_action_just_pressed("Up"):
		# camera up to monster
		var tween_down := create_tween()
		tween_down.tween_property(camera, "position:y", camera_up_position, 0.3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tween_down.play()

#func calc_perf(ingredients: Array[Ingredient]):
	# calculate the final perfection of the dish
	# later expand to compare ingredients
	#var total_doneness: float = 0
	#for ingredient in ingredients:
		#total_doneness += ingredient.doneness
	#var avg_doneness: float = total_doneness / ingredients.size()
	#return avg_doneness

func find_nodes_by_script(script_path: String) -> Array:
	var nodes = []
	find_nodes_recursive(get_tree().current_scene, script_path, nodes)
	return nodes

func find_nodes_recursive(node: Node, script_path: String, result: Array):
	if node.get_script() and node.get_script().resource_path == script_path:
		result.append(node)
	
	for child in node.get_children():
		find_nodes_recursive(child, script_path, result)
