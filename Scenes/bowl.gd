extends Node2D

@onready var bowl_area: Area2D = $Area2D

const ACCEPTED := {"Corn": true, "Edamame": true, "Salmon": true, "Tuna": true}
var in_bowl: Array[String] = []

func _ready() -> void:
	bowl_area.monitoring = true
	bowl_area.monitorable = true
	bowl_area.set_collision_layer_value(1, true)
	bowl_area.set_collision_mask_value(1, true)

	bowl_area.area_entered.connect(_on_area_entered)
	print("Bowl ready")

func _on_area_entered(area: Area2D) -> void:
	print("Entered:", area.name)
	if ACCEPTED.has(area.name):
		in_bowl.append(area.name)
		area.queue_free()
		print("Bowl contents:", in_bowl)
