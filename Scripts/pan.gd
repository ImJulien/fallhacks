extends Area2D

#pan that can cook ingredients when they're dropped on it

signal ingredient_cooked(ingredient_name: String)
signal cooking_started
signal cooking_finished

@onready var cooking_timer: Timer = Timer.new()
@onready var animated_sprite: AnimatedSprite2D = $Sprite2D

var is_cooking: bool = false
var fresh_time = 3.0 #time to reach fresh state
var cooking_time: float = 3.0  #time to reach cooked state
var burn_time: float = 2.0    #time to reach burnt state
var ingredients_in_pan: Array = []
var ingredient_nodes: Array = []
var cooking_timers: Array = []  #individual timer for each ingredient

func _ready():
	#animation should autoplay from Inspector, but ensure it's playing
	if animated_sprite and not animated_sprite.is_playing():
		animated_sprite.play()  #play current animation
		print("Pan animation started")

#this function will be called by ingredients when they're dropped on it
func receive_ingredient(ingredient_name: String, ingredient_node: Node):
	#create individual timers for this ingredient  
	var start_cooking_timer = Timer.new()
	var cooked_timer = Timer.new()
	var burnt_timer = Timer.new()
	add_child(start_cooking_timer)
	add_child(cooked_timer)
	add_child(burnt_timer)
	
	#set up cooking timer (fresh_time seconds to start cooking)
	start_cooking_timer.wait_time = fresh_time
	start_cooking_timer.one_shot = true
	start_cooking_timer.timeout.connect(func(): _make_ingredient_cooking(ingredient_node))
	
	#set up cooked timer (fresh_time + cooking_time seconds total)
	cooked_timer.wait_time = fresh_time + cooking_time
	cooked_timer.one_shot = true
	cooked_timer.timeout.connect(func(): _make_ingredient_cooked(ingredient_node))
	
	#set up burnt timer (fresh_time + cooking_time + burn_time seconds total)
	burnt_timer.wait_time = fresh_time + cooking_time + burn_time
	burnt_timer.one_shot = true
	burnt_timer.timeout.connect(func(): _make_ingredient_burnt(ingredient_node))
	
	#start all timers
	start_cooking_timer.start()
	cooked_timer.start()
	burnt_timer.start()
	
	#store everything
	ingredients_in_pan.append(ingredient_name)
	ingredient_nodes.append(ingredient_node)
	cooking_timers.append([start_cooking_timer, cooked_timer, burnt_timer])
	
	print("Started cooking ", ingredient_name, " - cooking in ", fresh_time, "s, cooked in ", fresh_time + cooking_time, "s, burnt in ", fresh_time + cooking_time + burn_time, "s")
	return true

func _make_ingredient_cooking(ingredient_node: Node):
	if ingredient_node and is_instance_valid(ingredient_node):
		if ingredient_node.current_state == ingredient_node.IngredientState.FRESH:
			ingredient_node.change_state(ingredient_node.IngredientState.COOKING, "started cooking on pan")
			ingredient_node.is_cooking = true  #set cooking flag without calling set_cooking()
			ingredient_node.modulate = Color.YELLOW  #cooking color
			print("Ingredient ", ingredient_node.ingredient_name, " started cooking!")

func _make_ingredient_cooked(ingredient_node: Node):
	if ingredient_node and is_instance_valid(ingredient_node):
		if ingredient_node.current_state == ingredient_node.IngredientState.COOKING:
			ingredient_node.change_state(ingredient_node.IngredientState.COOKED, "finished cooking")
			ingredient_node.modulate = Color.ORANGE  #cooked color
			print("Ingredient ", ingredient_node.ingredient_name, " is now cooked!")

func _make_ingredient_burnt(ingredient_node: Node):
	if ingredient_node and is_instance_valid(ingredient_node):
		if ingredient_node.current_state != ingredient_node.IngredientState.BURNT:
			ingredient_node.set_burnt()
			print("Ingredient ", ingredient_node.ingredient_name, " is now burnt!")

func _on_cooking_finished():
	#this function is now used when all cooking is complete
	is_cooking = false
	
	#create cooked result
	var cooked_dish = create_cooked_dish()
	print("Finished all cooking: ", cooked_dish)
	
	cooking_finished.emit()
	ingredient_cooked.emit(cooked_dish)
	
	#clear the ingredient lists after cooking
	ingredients_in_pan.clear()
	ingredient_nodes.clear()

func create_cooked_dish() -> String:
	#simple cooking logic, you can change this for certain dishes later
	if ingredients_in_pan.has("meat") and ingredients_in_pan.has("vegetables"):
		return "Stir Fry"
	elif ingredients_in_pan.has("meat"):
		return "Cooked Meat"
	elif ingredients_in_pan.has("vegetables"):
		return "Cooked Vegetables"
	else:
		return "Mystery Dish"

func get_cooking_progress() -> float:
	#just check if we have ingredients
	if ingredients_in_pan.size() > 0:
		return 0.5  #cooking in progress
	return 0.0

func remove_ingredient(ingredient_name: String):
	if ingredients_in_pan.has(ingredient_name):
		var index = ingredients_in_pan.find(ingredient_name)
		
		# Stop the individual timers for this specific ingredient
		if index >= 0 and index < cooking_timers.size():
			var timer_set = cooking_timers[index]
			if timer_set[0]:  # start cooking timer
				timer_set[0].stop()
				timer_set[0].queue_free()
			if timer_set[1]:  # cooked timer
				timer_set[1].stop()
				timer_set[1].queue_free()
			if timer_set[2]:  # burnt timer
				timer_set[2].stop()
				timer_set[2].queue_free()
			
			# Remove the timer set from the array
			cooking_timers.remove_at(index)
		
		# Remove from ingredient arrays
		ingredients_in_pan.erase(ingredient_name)
		if index >= 0 and index < ingredient_nodes.size():
			ingredient_nodes.remove_at(index)
		
		print("Removed ", ingredient_name, " from pan and stopped its timers")
		
		#if no ingredients left, stop cooking
		if ingredients_in_pan.is_empty():
			print("No ingredients left in pan, stopping cooking")
			stop_cooking()

func stop_cooking():
	#stop all individual timers
	for timer_set in cooking_timers:
		if timer_set[0]:  #start cooking timer
			timer_set[0].stop()
			timer_set[0].queue_free()
		if timer_set[1]:  #cooked timer
			timer_set[1].stop()
			timer_set[1].queue_free()
		if timer_set[2]:  #burnt timer
			timer_set[2].stop()
			timer_set[2].queue_free()
	
	cooking_timers.clear()
	ingredients_in_pan.clear()
	ingredient_nodes.clear()
	
	#return to idle animation
	if animated_sprite:
		animated_sprite.play("default")  #back to idle animation
		print("Pan returned to idle animation")
	
	print("Pan stopped cooking")

func start_hover_cooking(ingredient_name: String, ingredient_node: Node):
	print("Starting hover cooking for ", ingredient_name)
	#for hover cooking, just set the ingredient to cooking state visually
	#don't create timers since this is temporary hover cooking
	ingredient_node.is_cooking = true
	ingredient_node.change_state(ingredient_node.IngredientState.COOKING, "hover cooking on pan")
	ingredient_node.modulate = Color.YELLOW  # cooking color

func stop_hover_cooking(ingredient_name: String):
	print("Stopping hover cooking for ", ingredient_name)
	#hover cooking stops immediately when leaving pan area
	#the ingredient will handle its own state reset
