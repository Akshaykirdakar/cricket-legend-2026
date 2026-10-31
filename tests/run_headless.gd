extends SceneTree
## Run with: godot --headless --path . --script res://tests/run_headless.gd

const Ballistics = preload("res://scripts/physics/cricket_ballistics.gd")
const Rules = preload("res://scripts/match/rules_engine.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		push_error("FAIL: " + label)

func _run() -> void:
	var india := _load_roster("res://data/teams/india.json")
	var australia := _load_roster("res://data/teams/australia.json")
	_check(india.size() == 11, "India roster has eleven players")
	_check(australia.size() == 11, "Australia roster has eleven players")
	_check(_unique_ids(india), "India roster IDs are unique")
	_check(_unique_ids(australia), "Australia roster IDs are unique")

	var ball := Ballistics.new()
	ball.launch(Vector3(0, 1.0, 0), Vector3(0, -8, 20), 22.0, 0.5, 0.4)
	var bounced := false
	for i in range(120):
		var state: Dictionary = ball.step(1.0 / 60.0)
		if bool(state.get("bounced", false)):
			bounced = true
			break
	_check(bounced, "Ballistics detects pitch bounce")

	var contact: Dictionary = ball.segment_sphere_contact(Vector3(-1, 1, 0), Vector3(1, 1, 0), Vector3.ZERO, 1.1)
	_check(bool(contact.get("hit", false)), "Swept bat collision detects ball contact")

	var impulse := ball.apply_bat_impulse(Vector3(0, -10, 0), Vector3(0, 0, -1), 7.0)
	_check(impulse.is_finite(), "Bat impulse returns finite velocity")

	var wide: Dictionary = Rules.normalize_delivery(0, Rules.ExtraType.WIDE, 1, false)
	_check(not bool(wide.get("legal", true)), "Wide is not a legal ball")
	var no_ball: Dictionary = Rules.normalize_delivery(0, Rules.ExtraType.NO_BALL, 1, false)
	_check(not bool(no_ball.get("legal", true)), "No-ball is not a legal ball")
	var bye: Dictionary = Rules.normalize_delivery(0, Rules.ExtraType.BYE, 2, false)
	_check(bool(bye.get("legal", false)), "Bye is a legal ball")

	print("TEST SUMMARY: %d passed, %d failed" % [12 - failures.size(), failures.size()])
	quit(1 if not failures.is_empty() else 0)

func _load_roster(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	return parsed.get("roster", [])

func _unique_ids(roster: Array) -> bool:
	var seen := {}
	for player in roster:
		var id := str(player.get("id", ""))
		if id.is_empty() or seen.has(id):
			return false
		seen[id] = true
	return true
