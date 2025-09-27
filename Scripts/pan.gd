extends Area2D

#pan that can cook ingredients when they're dropped on it

signal ingredient_cooked(ingredient_name: String)
signal cooking_started
signal cooking_finished

@onready var cooking_timer: Timer = Timer.new()
@onready var sprite: Sprite2D = $Sprite2D

var is_cooking: bool = false
var cooking_time: float = 3.0  #time to cook in seconds
var ingredients_in_pan: Array = []

func _ready():
	# Set up timer
	add_child(cooking_timer)
	cooking_timer.wait_time = cooking_time
	cooking_timer.one_shot = true
	cooking_timer.timeout.connect(_on_cooking_finished)

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
