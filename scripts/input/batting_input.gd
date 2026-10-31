extends Node
class_name BattingInput
signal shot_requested(shot: String, aim: Vector2, power: float)
var selected_shot := "DRIVE"
var swipe_origin := Vector2.ZERO
var aim := Vector2(0, -1)
var active := false

func select_shot(shot: String) -> void:
	selected_shot = shot.to_upper()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_origin = event.position
			active = true
		elif active:
			_finish_swipe(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			swipe_origin = event.position
			active = true
		elif active:
			_finish_swipe(event.position)

func _finish_swipe(position: Vector2) -> void:
	active = false
	var delta := position - swipe_origin
	if delta.length() > 24:
		aim = Vector2(delta.x, -delta.y).normalized()
	shot_requested.emit(selected_shot, aim, clampf(delta.length() / 220.0, 0.2, 1.0))
