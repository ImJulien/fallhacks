extends Area2D

#pan that can cook ingredients when they're dropped on it

signal ingredient_cooked(ingredient_name: String)
signal cooking_started
signal cooking_finished

@onready var cooking_timer: Timer = Timer.new()
@onready var animated_sprite: AnimatedSprite2D = $Sprite2D

var is_cooking: bool = false
var cooking_time: float = 3.0  #time to cook in seconds
var ingredients_in_pan: Array = []

func _ready():
	#set up timer
	add_child(cooking_timer)
	cooking_timer.wait_time = cooking_time
	cooking_timer.one_shot = true
	cooking_timer.timeout.connect(_on_cooking_finished)
	
	#animation should autoplay from Inspector, but ensure it's playing
	if animated_sprite and not animated_sprite.is_playing():
		animated_sprite.play()  # play current animation
		print("Pan animation started")

#this function will be called by ingredients when they're actually dropped
func receive_ingredient(ingredient_name: String, ingredient_node: Node):
	if is_cooking:
		print("Pan is already cooking!")
		return false
	
	#leave ingredient where it was dropped, just disable dragging
	ingredient_node.set_cooking(true)  #tell ingredient it's cooking
	
	add_ingredient(ingredient_name)
	return true

func add_ingredient(ingredient_name: String):
	if is_cooking:
		print("Pan is already cooking!")
		return
	
	ingredients_in_pan.append(ingredient_name)
	print("Added ", ingredient_name, " to pan")
	
	#start cooking immediately
	start_cooking()

func start_cooking():
	if ingredients_in_pan.is_empty():
		print("No ingredients to cook!")
		return
	
	if is_cooking:
		return
	
	is_cooking = true
	cooking_started.emit()
	cooking_timer.start()
	
	#play cooking animation
	if animated_sprite:
		animated_sprite.play("cooking")  # change to cooking animation
		print("Pan cooking animation started")
	
	print("Started cooking: ", ingredients_in_pan)

func _on_cooking_finished():
	is_cooking = false
	
	#create cooked result
	var cooked_dish = create_cooked_dish()
	print("Finished cooking: ", cooked_dish)
	
	cooking_finished.emit()
	ingredient_cooked.emit(cooked_dish)

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
	if not is_cooking:
		return 0.0
	return 1.0 - (cooking_timer.time_left / cooking_time)

func remove_ingredient(ingredient_name: String):
	if ingredients_in_pan.has(ingredient_name):
		ingredients_in_pan.erase(ingredient_name)
		print("Removed ", ingredient_name, " from pan")
		
		#if no ingredients left, stop cooking
		if ingredients_in_pan.is_empty():
			print("No ingredients left in pan, stopping cooking")
			stop_cooking()

func stop_cooking():
	if is_cooking:
		is_cooking = false
		cooking_timer.stop()
		
		#return to idle animation
		if animated_sprite:
			animated_sprite.play("default")  # back to idle animation
			print("Pan returned to idle animation")
		
		print("Pan stopped cooking")

func start_hover_cooking(ingredient_name: String, ingredient_node: Node):
	print("Starting hover cooking for ", ingredient_name)
	#don't add to ingredients_in_pan (this is temporary hover cooking)
	#just tell the ingredient it's cooking
	ingredient_node.set_cooking(true)
	
	#start a cooking timer if not already cooking
	if not is_cooking:
		is_cooking = true
		cooking_timer.start()
		cooking_started.emit()

func stop_hover_cooking(ingredient_name: String):
	print("Stopping hover cooking for ", ingredient_name)
	#since hover cooking doesn't add to ingredients_in_pan, just stop the timer if no real ingredients
	if ingredients_in_pan.is_empty() and is_cooking:
		stop_cooking()
