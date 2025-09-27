extends Area2D
#draggable ingredient that player can drop on pan

@export var ingredient_name: String = "generic_ingredient"
@onready var sprite: Sprite2D = $Sprite2D
var is_on_plate: bool = false

enum IngredientState { #states for ingredients
	FRESH,
	COOKING,
	COOKED,
	BURNT
}

var is_dragging: bool = false
var is_cooking: bool = false
var is_burnt_food: bool = false
var current_state: IngredientState = IngredientState.FRESH
var connected_pan: Node = null
var drag_offset: Vector2
var original_position: Vector2

func _ready():
	original_position = global_position
	input_event.connect(_on_input_event)

func change_state(new_state: IngredientState, reason: String = ""):
	var old_state_name = get_state_name(current_state)
	var new_state_name = get_state_name(new_state)
	current_state = new_state
	
	var reason_text = " (" + reason + ")" if reason != "" else ""
	print(ingredient_name + " state changed: " + old_state_name + " → " + new_state_name + reason_text)

func get_state_name(state: IngredientState) -> String:
	match state:
		IngredientState.FRESH:
			return "FRESH"
		IngredientState.COOKING:
			return "COOKING"
		IngredientState.COOKED:
			return "COOKED"
		IngredientState.BURNT:
			return "BURNT"
		_:
			return "UNKNOWN"



func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	#you can drag ingredients in any state
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_drag(event.global_position)
			else:
				stop_drag()

func start_drag(mouse_pos: Vector2):
	is_dragging = true
	drag_offset = global_position - mouse_pos
	print("started dragging")

func stop_drag():
	is_dragging = false
	
	#store the position where we dropped it
	var drop_position = global_position

	#check if dropped on something that can receive ingredients
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = global_position
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var results = space_state.intersect_point(query)
	var dropped_on_pan = false
	
	print("Checking drop at position: ", global_position)  #debug
	print("Found ", results.size(), " colliders")
	
	for result in results:
		var collider = result.collider
		print("Collider: ", collider.name, " has receive_ingredient: ", collider.has_method("receive_ingredient"))  #debug
		if collider != self and collider.has_method("receive_ingredient"):
			#if ingredient is already burnt, just drop it without cooking
			if is_burnt_food:
				dropped_on_pan = true
				global_position = drop_position
				print("dropped burnt food on pan")
				return  #just stay as burnt food
			
			#otherwise, try to cook fresh ingredient
			if collider.receive_ingredient(ingredient_name, self):
				dropped_on_pan = true
				#make sure ingredient stays exactly where dropped
				global_position = drop_position
				#connect to pan's cooking_finished signal and store reference
				connected_pan = collider
				collider.cooking_finished.connect(_on_cooking_finished)
				print("dropped on pan at position: ", drop_position)
				return  #ingredient is now cooking on pan
			break
	
	#if not dropped on pan, just stay where dropped
	if not dropped_on_pan:
		#stop cooking if it was cooking and moved off pan
		if current_state == IngredientState.COOKING:
			stop_cooking()
		
		print("not dropped on pan")

func _process(_delta):
	if is_dragging:
		global_position = get_global_mouse_position() + drag_offset
		update_hover_highlight()

func update_hover_highlight():
	if not is_dragging:
		return
	
	#check if currently over a pan while dragging
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = global_position
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var results = space_state.intersect_point(query)
	var over_pan = false
	
	for result in results:
		var collider = result.collider
		if collider != self and collider.has_method("receive_ingredient"):
			over_pan = true
			print("Hovering over pan: ", collider.name)  #debug
			break
	
	#only highlight fresh ingredients green, keep cooked/burnt ingredients their color
	if over_pan and current_state == IngredientState.FRESH:
		modulate = Color.GREEN
		print("Highlighting ingredient green")
	elif current_state == IngredientState.FRESH:
		modulate = Color.WHITE
	elif current_state == IngredientState.COOKING:
		modulate = Color.ORANGE  #keep orange while dragging
	elif current_state == IngredientState.BURNT:
		modulate = Color(0.3, 0.2, 0.1)  #keep burnt color while dragging
	#don't change color for non-fresh ingredients

func get_ingredient_name() -> String:
	return ingredient_name

func set_cooking(cooking: bool):
	is_cooking = cooking
	if cooking:
		change_state(IngredientState.COOKING, "dropped on pan")
		modulate = Color.ORANGE  #show it's cooking
	else:
		modulate = Color.WHITE

func stop_cooking():
	if current_state == IngredientState.COOKING:
		is_cooking = false
		#disconnect from pan's cooking_finished signal to prevent turning burnt
		if connected_pan and connected_pan.has_signal("cooking_finished"):
			if connected_pan.cooking_finished.is_connected(_on_cooking_finished):
				connected_pan.cooking_finished.disconnect(_on_cooking_finished)
			connected_pan = null
		
		#don't change state, keep it as COOKING but paused
		print("paused cooking (removed from pan)")
		#keep orange color to show it's still in cooking state
		modulate = Color.ORANGE

func set_burnt():
	is_cooking = false  #no longer actively cooking
	is_burnt_food = true  #mark as burnt
	change_state(IngredientState.BURNT, "cooking timer finished")
	modulate = Color(0.3, 0.2, 0.1)  #dark brown/black burnt color

func is_burnt() -> bool:
	return is_burnt_food

func _on_cooking_finished():
	#don't remove ingredient, make it burnt instead
	set_burnt()
	

	
