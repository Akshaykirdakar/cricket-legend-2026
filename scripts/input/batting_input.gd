extends Node
class_name BattingInput

signal shot_requested(shot: String, aim: Vector2, power: float)

var selected_shot := "DRIVE"
var swipe_origin := Vector2.ZERO
var aim := Vector2.UP
var swipe_active := false

func select_shot(shot: String) -> void:
    selected_shot = shot.to_upper()

func begin_swipe(position: Vector2) -> void:
    swipe_origin = position
    swipe_active = true

func end_swipe(position: Vector2) -> void:
    if not swipe_active:
        return
    swipe_active = false
    var delta := position - swipe_origin
    if delta.length() >= 24.0:
        aim = delta.normalized()
    var power := clampf(delta.length() / 220.0, 0.2, 1.0)
    shot_requested.emit(selected_shot, aim, power)
