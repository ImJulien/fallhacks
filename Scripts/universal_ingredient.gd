extends Area2D
#draggable ingredient that player can drop on pan

@export var ingredient_name: String = "generic_ingredient"
@export var ingredient_state: IngredientState = IngredientState.FRESH
@onready var sprite: Sprite2D = $Sprite2D

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
	
	#check if ingredient is set up correctly
	print("=== INGREDIENT SETUP DEBUG ===")
	print("Ingredient name: ", ingredient_name)
	print("Has CollisionShape2D: ", get_node_or_null("CollisionShape2D") != null)
	print("Input pickable: ", input_pickable)
	print("Position: ", global_position)
	print("Z-index: ", z_index)
	print("Script attached: ", get_script() != null)
	
	#force this ingredient to have higher priority
	z_index = 100
	input_pickable = true

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
	print("Ingredient ", ingredient_name, " received input: ", event)
	#you can drag ingredients in any state
	if event is InputEventMouseButton:
		print("Mouse button event: ", event.button_index, " pressed: ", event.pressed)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				print("Starting drag for ", ingredient_name)
				start_drag(event.global_position)
			else:
				print("Stopping drag for ", ingredient_name)
				stop_drag()

func start_drag(mouse_pos: Vector2):
	print("start_drag called for ", ingredient_name, " at mouse pos: ", mouse_pos)
	is_dragging = true
	#store the offset between ingredient and mouse
	drag_offset = global_position - get_global_mouse_position()
	z_index = 10  #bring to front
	
	#if ingredient is cooking, stop cooking immediately when dragging starts
	if current_state == IngredientState.COOKING and connected_pan:
		print("Ingredient was cooking, stopping cooking due to drag")
		#tell the pan to stop cooking this ingredient
		if connected_pan.has_method("remove_ingredient"):
			connected_pan.remove_ingredient(ingredient_name)
		stop_cooking()
	
	print("Dragging started, is_dragging: ", is_dragging, " z_index: ", z_index)

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
		#if left mouse button is not pressed, stop dragging
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			print("Safety stop: Mouse button not pressed, stopping drag")
			stop_drag()
			return
		
		#follow mouse with stored offset
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
	var pan_node = null
	
	for result in results:
		var collider = result.collider
		if collider != self and collider.has_method("receive_ingredient"):
			over_pan = true
			pan_node = collider
			print("Hovering over pan: ", collider.name)  #debug
			break
	
	#handle cooking while hovering over pan
	if over_pan and pan_node:
		#if ingredient can cook (fresh or was previously cooking) and not burnt
		if (current_state == IngredientState.FRESH or current_state == IngredientState.COOKING) and not is_burnt_food:
			#start cooking if not already connected to this pan
			if connected_pan != pan_node:
				#disconnect from previous pan if any
				if connected_pan and connected_pan.has_signal("cooking_finished"):
					if connected_pan.cooking_finished.is_connected(_on_cooking_finished):
						connected_pan.cooking_finished.disconnect(_on_cooking_finished)
				
				#connect to new pan and start cooking
				connected_pan = pan_node
				if pan_node.has_method("start_hover_cooking"):
					pan_node.start_hover_cooking(ingredient_name, self)
				else:
					#just set cooking state
					set_cooking(true)
				pan_node.cooking_finished.connect(_on_cooking_finished)
				print("Started hover cooking on ", pan_node.name)
	else:
		#not over pan - stop cooking if we were hover cooking
		if connected_pan and current_state == IngredientState.COOKING:
			print("Left pan area, stopping hover cooking")
			if connected_pan.has_method("stop_hover_cooking"):
				connected_pan.stop_hover_cooking(ingredient_name)
			stop_cooking()
	
	#visual highlighting
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
