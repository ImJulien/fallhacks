extends Node2D

@onready var ui_container := $tbaleplaceholder
# 250 / -125

func _process(_delta):
	if Input.is_action_just_pressed("Down"):
		# camera down to cook surface
		var tween_down := create_tween()
		tween_down.tween_property(ui_container, "position:y", -125, 0.3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tween_down.play()
	if Input.is_action_just_pressed("Up"):
		# camera up to monster
		var tween_down := create_tween()
		tween_down.tween_property(ui_container, "position:y", 250, 0.3).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tween_down.play()

#func calc_perf(ingredients: Array[Ingredient]):
	# calculate the final perfection of the dish
	# later expand to compare ingredients
	#var total_doneness: float = 0
	#for ingredient in ingredients:
		#total_doneness += ingredient.doneness
	#var avg_doneness: float = total_doneness / ingredients.size()
	#return avg_doneness
