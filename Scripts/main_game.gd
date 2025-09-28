extends Node2D

@onready var camera := $Camera2D
@onready var desk = $TableUp
var camera_up_position: float
var camera_down_position: float

func _ready():
	#store the initial camera position as the "up" position
	camera_up_position = camera.position.y
	#down position is one screen height below
	camera_down_position = camera_up_position + get_viewport().get_visible_rect().size.y
	desk.play()

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
	if Input.is_action_just_pressed("Jumpscare"):
		var js_scene = preload("res://Scenes/jumpscare.tscn")
		var jumpscare_sound = preload('res://Assets/Sounds/jumpscare.ogg')
		var gort = $Gort
		var gort_audio = gort.get_node("AnimatedSprite2D").get_node("AudioStreamPlayer2D")
		var js: AnimatedSprite2D = js_scene.instantiate()
		js.global_position = Vector2(get_viewport().get_visible_rect().size.x/2, get_viewport().get_visible_rect().size.y/2)
		gort.visible = false
		self.add_child(js)
		js.play()
		gort_audio.stream = jumpscare_sound
		gort_audio.play()
		

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
