extends Resource
class_name PlayerProfile

@export var player_id: String
@export var display_name: String
@export_range(1, 100) var batting: int = 60
@export_range(1, 100) var timing: int = 60
@export_range(1, 100) var power: int = 60
@export_range(1, 100) var bowling: int = 40
@export_range(1, 100) var pace: int = 40
@export_range(1, 100) var spin: int = 20
@export_range(1, 100) var fielding: int = 60
@export_range(1, 100) var fitness: int = 80

func batting_skill() -> float:
    return clampf((float(batting) * 0.45 + float(timing) * 0.4 + float(power) * 0.15) / 100.0, 0.0, 1.0)
