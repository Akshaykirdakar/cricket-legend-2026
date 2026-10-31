extends Node
class_name MatchStateService

signal score_changed(snapshot: Dictionary)
signal innings_changed(innings_number: int)
signal delivery_recorded(delivery: Dictionary)
signal innings_completed(innings_number: int, scorecard: Dictionary)
signal match_finished(result: Dictionary)

enum Format { T20, ODI, TEST }
enum InningsStatus { NOT_STARTED, LIVE, COMPLETE }

var match_format: Format = Format.T20
var overs_per_innings: int = 20
var max_wickets: int = 10
var innings_number: int = 1
var innings_status: InningsStatus = InningsStatus.NOT_STARTED
var batting_team: String = "India"
var bowling_team: String = "Australia"
var target: int = -1
var innings: Array[Dictionary] = []
var current: Dictionary = {}
var striker_id := "batter_1"
var non_striker_id := "batter_2"
var current_bowler_id := "bowler_1"
var total_deliveries := 0
var max_test_overs := 450
var declared := false

func start_match(format: Format = Format.T20) -> void:
	match_format = format
	overs_per_innings = 20 if format == Format.T20 else (50 if format == Format.ODI else max_test_overs)
	innings_number = 1
	target = -1
	total_deliveries = 0
	declared = false
	innings.clear()
	_start_innings()

func _new_batter() -> Dictionary:
	return {"runs": 0, "balls": 0, "fours": 0, "sixes": 0, "dismissal": "not out"}

func _new_bowler() -> Dictionary:
	return {"balls": 0, "runs": 0, "wickets": 0, "maidens": 0, "wides": 0, "no_balls": 0}

func _start_innings() -> void:
	current = {
		"team": batting_team,
		"runs": 0,
		"wickets": 0,
		"legal_balls": 0,
		"batters": {striker_id: _new_batter(), non_striker_id: _new_batter()},
		"bowlers": {current_bowler_id: _new_bowler()},
		"extras": {"wides": 0, "no_balls": 0, "byes": 0, "leg_byes": 0, "penalty": 0},
		"fall_of_wickets": [],
		"over_log": [],
		"complete": false
	}
	innings_status = InningsStatus.LIVE
	innings_changed.emit(innings_number)
	_emit_score()

func set_batter_ids(striker: String, non_striker: String) -> void:
	if innings_status != InningsStatus.LIVE or striker == non_striker:
		return
	striker_id = striker
	non_striker_id = non_striker
	_ensure_batter(striker_id)
	_ensure_batter(non_striker_id)

func set_bowler_id(bowler: String) -> void:
	if innings_status != InningsStatus.LIVE or bowler.is_empty():
		return
	current_bowler_id = bowler
	var bowlers: Dictionary = current.get("bowlers", {})
	if not bowlers.has(bowler):
		bowlers[bowler] = _new_bowler()
		current["bowlers"] = bowlers

func _ensure_batter(player_id: String) -> void:
	var batters: Dictionary = current.get("batters", {})
	if not batters.has(player_id):
		batters[player_id] = _new_batter()
		current["batters"] = batters

func _ensure_bowler(player_id: String) -> void:
	var bowlers: Dictionary = current.get("bowlers", {})
	if not bowlers.has(player_id):
		bowlers[player_id] = _new_bowler()
		current["bowlers"] = bowlers

func apply_delivery(result: Dictionary) -> void:
	if innings_status != InningsStatus.LIVE:
		return
	var bat_runs := maxi(0, int(result.get("bat_runs", 0)))
	var extras := maxi(0, int(result.get("extras", 0)))
	var total := maxi(0, int(result.get("total_runs", bat_runs + extras)))
	var legal := bool(result.get("legal", true))
	var wicket := bool(result.get("wicket", false))
	var extra_type := int(result.get("extra_type", CricketRulesEngine.ExtraType.NONE))
	var batter_id := str(result.get("batter_id", striker_id))
	var bowler_id := str(result.get("bowler_id", current_bowler_id))
	_ensure_batter(batter_id)
	_ensure_bowler(bowler_id)

	var batters: Dictionary = current["batters"]
	var batter: Dictionary = batters[batter_id]
	batter["runs"] = int(batter["runs"]) + bat_runs
	if extra_type != CricketRulesEngine.ExtraType.WIDE and extra_type != CricketRulesEngine.ExtraType.NO_BALL:
		batter["balls"] = int(batter["balls"]) + (1 if legal or extra_type == CricketRulesEngine.ExtraType.BYE or extra_type == CricketRulesEngine.ExtraType.LEG_BYE else 0)
	if bat_runs == 4:
		batter["fours"] = int(batter["fours"]) + 1
	elif bat_runs == 6:
		batter["sixes"] = int(batter["sixes"]) + 1
	batters[batter_id] = batter
	current["batters"] = batters

	var bowlers: Dictionary = current["bowlers"]
	var bowler: Dictionary = bowlers[bowler_id]
	bowler["runs"] = int(bowler["runs"]) + total - int(result.get("byes_or_leg_byes", 0))
	if legal:
		bowler["balls"] = int(bowler["balls"]) + 1
	if extra_type == CricketRulesEngine.ExtraType.WIDE:
		bowler["wides"] = int(bowler["wides"]) + extras
	elif extra_type == CricketRulesEngine.ExtraType.NO_BALL:
		bowler["no_balls"] = int(bowler["no_balls"]) + extras
	if wicket and str(result.get("dismissal", "bowled")) not in ["run_out", "retired_out", "obstructing_field"]:
		bowler["wickets"] = int(bowler["wickets"]) + 1
	bowlers[bowler_id] = bowler
	current["bowlers"] = bowlers

	var extra_map: Dictionary = current["extras"]
	match extra_type:
		CricketRulesEngine.ExtraType.WIDE:
			extra_map["wides"] = int(extra_map["wides"]) + extras
		CricketRulesEngine.ExtraType.NO_BALL:
			extra_map["no_balls"] = int(extra_map["no_balls"]) + extras
		CricketRulesEngine.ExtraType.BYE:
			extra_map["byes"] = int(extra_map["byes"]) + extras
		CricketRulesEngine.ExtraType.LEG_BYE:
			extra_map["leg_byes"] = int(extra_map["leg_byes"]) + extras
	current["extras"] = extra_map

	current["runs"] = int(current["runs"]) + total
	if legal:
		current["legal_balls"] = int(current["legal_balls"]) + 1
	total_deliveries += 1

	if wicket and int(current["wickets"]) < max_wickets:
		current["wickets"] = int(current["wickets"]) + 1
		var dismissal := str(result.get("dismissal", "bowled"))
		batter["dismissal"] = dismissal
		batters[batter_id] = batter
		current["batters"] = batters
		current["fall_of_wickets"].append({"score": current["runs"], "over": over_string(), "player": batter_id, "dismissal": dismissal})
		var next_batter := str(result.get("next_batter_id", "batter_%d" % (int(current["wickets"]) + 2)))
		if int(current["wickets"]) < max_wickets:
			if batter_id == striker_id:
				striker_id = next_batter
			else:
				non_striker_id = next_batter
			_ensure_batter(next_batter)

	var delivery_log := {
		"ball": over_string(),
		"total_runs": total,
		"bat_runs": bat_runs,
		"extras": extras,
		"legal": legal,
		"wicket": wicket,
		"dismissal": str(result.get("dismissal", "")),
		"bowler": bowler_id,
		"batter": batter_id
	}
	var over_log: Array = current["over_log"]
	over_log.append(delivery_log)
	current["over_log"] = over_log
	delivery_recorded.emit(delivery_log)
	if legal and int(current["legal_balls"]) % 6 == 0:
		var swap := striker_id
		striker_id = non_striker_id
		non_striker_id = swap

	_emit_score()
	if _chase_complete():
		_finish_match(true)
	elif _innings_complete():
		_complete_innings()

func _chase_complete() -> bool:
	if match_format == Format.TEST:
		return innings_number == 4 and target > 0 and int(current["runs"]) >= target
	return innings_number == 2 and target > 0 and int(current["runs"]) >= target

func _innings_complete() -> bool:
	return int(current["wickets"]) >= max_wickets or int(current["legal_balls"]) >= overs_per_innings * 6

func _complete_innings() -> void:
	if innings_status != InningsStatus.LIVE:
		return
	innings_status = InningsStatus.COMPLETE
	current["complete"] = true
	innings.append(current.duplicate(true))
	innings_completed.emit(innings_number, current.duplicate(true))
	if match_format == Format.TEST:
		_advance_test_match()
	elif innings_number == 1:
		target = int(current["runs"]) + 1
		innings_number = 2
		_swap_teams()
		_start_innings()
	else:
		_finish_match(false)

func _advance_test_match() -> void:
	if innings_number < 4:
		if innings_number == 1:
			innings_number = 2
		elif innings_number == 2:
			var first_total := int(innings[0]["runs"])
			var second_total := int(innings[1]["runs"])
			if second_total < first_total - 200:
				innings_number = 3
				target = -1
			else:
				innings_number = 3
				_swap_teams()
		elif innings_number == 3:
			innings_number = 4
			_swap_teams()
			target = int(innings[0]["runs"]) + int(innings[2]["runs"]) - int(innings[1]["runs"]) + 1
			if target < 1:
				target = 1
		_start_innings()
	else:
		_finish_test_match()

func _swap_teams() -> void:
	var swap := batting_team
	batting_team = bowling_team
	bowling_team = swap

func _finish_match(chase_won: bool) -> void:
	if innings_status == InningsStatus.COMPLETE and current.get("result_recorded", false):
		return
	innings_status = InningsStatus.COMPLETE
	current["complete"] = true
	current["result_recorded"] = true
	if innings.is_empty() or innings[innings.size() - 1] != current:
		innings.append(current.duplicate(true))
	var first := int(innings[0].get("runs", 0))
	var second := int(current.get("runs", 0))
	var result := {"winner": "Tie", "first_innings": first, "second_innings": second, "target": target, "innings": innings.duplicate(true)}
	if chase_won:
		result["winner"] = batting_team
		result["margin"] = max_wickets - int(current["wickets"])
		result["margin_type"] = "wickets"
	elif second != first:
		result["winner"] = bowling_team
		result["margin"] = absi(first - second)
		result["margin_type"] = "runs"
	match_finished.emit(result)

func _finish_test_match() -> void:
	var team_a := "India"
	var team_b := "Australia"
	var a_runs := 0
	var b_runs := 0
	for i in range(innings.size()):
		if str(innings[i].get("team", "")) == team_a:
			a_runs += int(innings[i].get("runs", 0))
		elif str(innings[i].get("team", "")) == team_b:
			b_runs += int(innings[i].get("runs", 0))
	var result := {"winner": "Draw", "team_a": team_a, "team_b": team_b, "team_a_runs": a_runs, "team_b_runs": b_runs, "innings": innings.duplicate(true)}
	if innings_number == 4 and target > 0 and int(current["runs"]) >= target:
		result["winner"] = batting_team
		result["margin"] = max_wickets - int(current["wickets"])
		result["margin_type"] = "wickets"
	elif a_runs != b_runs:
		result["winner"] = team_a if a_runs > b_runs else team_b
		result["margin"] = absi(a_runs - b_runs)
		result["margin_type"] = "runs"
	match_finished.emit(result)

func over_string() -> String:
	return "%d.%d" % [int(current["legal_balls"] / 6), int(current["legal_balls"] % 6)]

func _emit_score() -> void:
	score_changed.emit({
		"team": batting_team,
		"runs": int(current.get("runs", 0)),
		"wickets": int(current.get("wickets", 0)),
		"overs": over_string(),
		"target": target,
		"innings": innings_number,
		"format": ["T20", "ODI", "TEST"][match_format],
		"run_rate": 0.0 if int(current["legal_balls"]) == 0 else float(current["runs"]) * 6.0 / float(current["legal_balls"]),
		"extras": current["extras"].duplicate(true)
	})
