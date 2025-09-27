extends Node2D

@onready var ui_container := $tbaleplaceholder
# 250 / -125

func _process(_delta):
	if Input.is_action_pressed("Down"):
		var tween_down := create_tween()
		tween_down.tween_property(ui_container, "position:y", -125, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tween_down.play()
	if Input.is_action_pressed("Up"):
		var tween_down := create_tween()
		tween_down.tween_property(ui_container, "position:y", 250, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tween_down.play()
