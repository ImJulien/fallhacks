extends Node2D

# Bowl that can hold ingredients when they're dropped on it

signal ingredient_added(ingredient_name: String)
signal bowl_full()

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: Area2D = $Area2D

var max_ingredients: int = 5  # maximum ingredients the bowl can hold
var ingredients_in_bowl: Array = []
var ingredient_nodes: Array = []  # Keep track of ingredient node references
var ingredient_positions: Array = []  # Store relative positions of ingredients

# Bowl dragging variables
var is_dragging: bool = false
var drag_offset: Vector2
var original_position: Vector2

func _ready():
	original_position = global_position
	
	# Connect to Area2D child's input_event signal
	if area_2d:
		area_2d.input_event.connect(_on_input_event)
		area_2d.z_index = 50
		area_2d.input_pickable = true
	
	# Debug prints for bowl setup
	print("=== BOWL SETUP DEBUG ===")
	print("Bowl Area2D found: ", area_2d != null)
	if area_2d:
		print("Area2D input_pickable: ", area_2d.input_pickable)
		print("Area2D z_index: ", area_2d.z_index)
	print("Bowl position: ", global_position)
	print("Bowl has CollisionShape2D child in Area2D: ", area_2d.get_node_or_null("CollisionShape2D") != null if area_2d else false)
	
	# Animation should autoplay from Inspector, but ensure it's playing
	if animated_sprite and not animated_sprite.is_playing():
		animated_sprite.play()  # play current animation
		print("Bowl animation started")

# Handle bowl dragging
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	print("Bowl received input event: ", event)
	if event is InputEventMouseButton:
		print("Bowl mouse event - button: ", event.button_index, " pressed: ", event.pressed)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				print("Bowl left click pressed - starting drag")
				start_drag(event.global_position)
			else:
				print("Bowl left click released - stopping drag")
				stop_drag()
			get_viewport().set_input_as_handled()

func start_drag(_mouse_pos: Vector2):
	is_dragging = true
	drag_offset = global_position - get_global_mouse_position()
	z_index = 10  # Bring to front
	print("Started dragging bowl")

func stop_drag():
	is_dragging = false
	z_index = 0  # Return to normal layer
	print("Stopped dragging bowl")

func _process(_delta):
	if is_dragging:
		# Safety check: if left mouse button is not pressed, stop dragging
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			stop_drag()
			return
		
		# Calculate new position and move bowl
		# Ingredients will automatically move with the bowl since they're children
		global_position = get_global_mouse_position() + drag_offset

# Add unhandled input as backup for bowl dragging
func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Check if mouse is over this bowl's Area2D
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = get_global_mouse_position()
		query.collide_with_areas = true
		
		var results = space_state.intersect_point(query)
		for result in results:
			if result.collider == area_2d:
				print("Bowl detected via unhandled input!")
				if event.pressed:
					start_drag(event.global_position)
				else:
					stop_drag()
				get_viewport().set_input_as_handled()
				break

# This function will be called by ingredients when they're dropped on the bowl
func receive_ingredient(ingredient_name: String, ingredient_node: Node):
	if ingredients_in_bowl.size() >= max_ingredients:
		print("Bowl is full! Cannot add more ingredients.")
		return false
	
	# Store current parent and remove from it
	var old_parent = ingredient_node.get_parent()
	if old_parent:
		old_parent.remove_child(ingredient_node)
	
	# Add ingredient as child of this bowl (Node2D)
	add_child(ingredient_node)
	
	# Add to our tracking arrays
	ingredients_in_bowl.append(ingredient_name)
	ingredient_nodes.append(ingredient_node)
	
	# Position ingredient in bowl (stack them slightly offset) - now using local position since it's a child
	var stack_offset = Vector2(ingredients_in_bowl.size() * 8, ingredients_in_bowl.size() * -5)
	ingredient_node.position = stack_offset  # Local position relative to bowl
	
	# Store the local position
	ingredient_positions.append(ingredient_node.position)
	
	# Reset ingredient to fresh state and white color
	ingredient_node.change_state(ingredient_node.IngredientState.FRESH, "added to bowl")
	ingredient_node.modulate = Color.WHITE
	ingredient_node.is_cooking = false
	ingredient_node.is_dragging = false
	
	# COMPLETELY DISABLE ingredient input - it's now a child so bowl handles all input
	ingredient_node.input_pickable = false
	ingredient_node.process_mode = Node.PROCESS_MODE_DISABLED  # Disable processing entirely
	
	# Disconnect any cooking connections
	if ingredient_node.connected_pan:
		ingredient_node.connected_pan = null
	
	print("Added ", ingredient_name, " as child to bowl at local position ", stack_offset, " (", ingredients_in_bowl.size(), "/", max_ingredients, ")")
	ingredient_added.emit(ingredient_name)
	
	# Check if bowl is full
	if ingredients_in_bowl.size() >= max_ingredients:
		bowl_full.emit()
		print("Bowl is now full!")
	
	return true

func remove_ingredient(ingredient_name: String):
	if ingredients_in_bowl.has(ingredient_name):
		var index = ingredients_in_bowl.find(ingredient_name)
		
		# Re-enable dragging and move ingredient back to scene
		if index >= 0 and index < ingredient_nodes.size():
			var ingredient_node = ingredient_nodes[index]
			if ingredient_node and is_instance_valid(ingredient_node):
				# Remove from bowl and add back to scene
				remove_child(ingredient_node)
				get_tree().current_scene.add_child(ingredient_node)
				
				# Re-enable ingredient
				ingredient_node.input_pickable = true
				ingredient_node.process_mode = Node.PROCESS_MODE_INHERIT
				
				# Convert local position back to global
				ingredient_node.global_position = global_position + ingredient_node.position
			
			ingredient_nodes.remove_at(index)
			ingredient_positions.remove_at(index)
		
		ingredients_in_bowl.erase(ingredient_name)
		print("Removed ", ingredient_name, " from bowl")

func empty_bowl():
	# Re-enable dragging for all ingredients and move them back to scene
	for i in range(ingredient_nodes.size()):
		var ingredient_node = ingredient_nodes[i]
		if ingredient_node and is_instance_valid(ingredient_node):
			# Remove from bowl and add back to scene
			remove_child(ingredient_node)
			get_tree().current_scene.add_child(ingredient_node)
			
			# Re-enable ingredient
			ingredient_node.input_pickable = true
			ingredient_node.process_mode = Node.PROCESS_MODE_INHERIT
			
			# Convert local position back to global
			ingredient_node.global_position = global_position + ingredient_node.position
	
	ingredients_in_bowl.clear()
	ingredient_nodes.clear()
	ingredient_positions.clear()
	print("Bowl emptied")

func get_ingredients() -> Array:
	return ingredients_in_bowl.duplicate()

func get_ingredient_count() -> int:
	return ingredients_in_bowl.size()

func is_full() -> bool:
	return ingredients_in_bowl.size() >= max_ingredients

func is_empty() -> bool:
	return ingredients_in_bowl.is_empty()

# Create a dish from the bowl contents
func create_dish() -> String:
	if ingredients_in_bowl.is_empty():
		return "Empty Bowl"
	
	# Simple dish creation logic - you can expand this
	if ingredients_in_bowl.has("meat") and ingredients_in_bowl.has("vegetables"):
		return "Mixed Salad"
	elif ingredients_in_bowl.has("vegetables") and ingredients_in_bowl.size() >= 2:
		return "Vegetable Medley"
	elif ingredients_in_bowl.has("meat"):
		return "Meat Bowl"
	else:
		return "Ingredient Mix"

func get_bowl_info() -> String:
	return "Bowl: " + str(ingredients_in_bowl.size()) + "/" + str(max_ingredients) + " ingredients"

# Check if an ingredient should be prevented from dragging due to bowl overlap
func should_prevent_ingredient_drag(ingredient_node: Node) -> bool:
	if not ingredient_node:
		return false
	
	# Only prevent dragging if ingredient is already locked in this bowl
	if ingredient_nodes.has(ingredient_node):
		return true
	
	# Don't prevent dragging for ingredients just overlapping - let them be dropped normally
	return false
