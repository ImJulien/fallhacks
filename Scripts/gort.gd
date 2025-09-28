extends AnimatedSprite2D

@onready var move_tween := create_tween()
@onready var bounce_tween := create_tween()
@onready var jumpscare_sound := preload('res://Assets/Sounds/Gort/zombie1.wav')

var is_talking: bool = false

func _ready() -> void:
	play("walk")  #walk animation
	#connect to dialogue finished signal
	Dialogue.dialogue_finished.connect(_on_dialogue_finished)
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
		#call the dialogue system singleton with desired aggression level
		is_talking = true
		Dialogue.start_dialogue(Enums.AggressionLevel.PASSIVE, Enums.Customers.GORT)
		$AudioStreamPlayer2D.stream = jumpscare_sound
		$AudioStreamPlayer2D.play()

func stop_talking():
	is_talking = false
	print("Gort stopped talking")

func get_is_talking() -> bool:
	return is_talking

func _on_dialogue_finished():
	is_talking = false
	print("Gort finished talking (dialogue completed)")
