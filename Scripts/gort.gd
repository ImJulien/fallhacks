extends AnimatedSprite2D

@onready var move_tween := create_tween()
@onready var bounce_tween := create_tween()

func _ready() -> void:
	play("walk")  #walk animation
	move_to_center()

func move_to_center():
	var center = get_viewport_rect().size / 2
	var start_pos = position
	var bounce_height = 40
	var duration = 1.5

	#move Gort towards the center
	move_tween.tween_property(self, "position:x", center.x, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	#start bouncing the gyatt
	bounce_tween.set_loops()  #loop the bounce until movement ends
	bounce_tween.tween_property(self, "position:y", start_pos.y - bounce_height, duration / 4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	bounce_tween.tween_property(self, "position:y", start_pos.y, duration / 4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	bounce_tween.tween_callback(Callable(self, "_on_bounce_complete"))

func _on_bounce_complete():
	if abs(position.x - get_viewport_rect().size.x / 2) < 1:
		bounce_tween.kill()  #stop bouncing the gyatt
		play("idle")  #idle anim
