extends Node
class_name MatchStateService

signal score_changed(snapshot: Dictionary)
signal innings_changed(innings_number: int)
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

func start_match(format: Format = Format.T20) -> void:
    match_format = format
    overs_per_innings = 20 if format == Format.T20 else (50 if format == Format.ODI else 90)
    innings_number = 1
    target = -1
    innings.clear()
    _start_innings()

func _start_innings() -> void:
    current = {"runs": 0, "wickets": 0, "legal_balls": 0, "batters": {}, "bowlers": {}, "extras": {"wides": 0, "no_balls": 0, "byes": 0, "leg_byes": 0}, "fall_of_wickets": [], "over_log": []}
    innings_status = InningsStatus.LIVE
    innings_changed.emit(innings_number)
    _emit_score()

func apply_delivery(result: Dictionary) -> void:
    if innings_status != InningsStatus.LIVE:
        return
    var total: int = int(result.get("total_runs", result.get("bat_runs", 0)))
    var legal: bool = bool(result.get("legal", true))
    var wicket: bool = bool(result.get("wicket", false))
    current["runs"] = int(current["runs"]) + total
    if legal:
        current["legal_balls"] = int(current["legal_balls"]) + 1
    if wicket and int(current["wickets"]) < max_wickets:
        current["wickets"] = int(current["wickets"]) + 1
        current["fall_of_wickets"].append({"score": current["runs"], "over": over_string()})
    _emit_score()
    if innings_number == 2 and target > 0 and int(current["runs"]) >= target:
        _finish_match(true)
    elif int(current["wickets"]) >= max_wickets or int(current["legal_balls"]) >= overs_per_innings * 6:
        _complete_innings()

func _complete_innings() -> void:
    innings_status = InningsStatus.COMPLETE
    innings.append(current.duplicate(true))
    if innings_number == 1:
        target = int(current["runs"]) + 1
        innings_number = 2
        var swap := batting_team
        batting_team = bowling_team
        bowling_team = swap
        _start_innings()
    else:
        _finish_match(false)

func _finish_match(chase_won: bool) -> void:
    innings_status = InningsStatus.COMPLETE
    innings.append(current.duplicate(true))
    var first := int(innings[0].get("runs", 0))
    var second := int(current.get("runs", 0))
    var result := {"first_innings": first, "second_innings": second, "target": target}
    if chase_won:
        result["winner"] = batting_team
        result["margin"] = max_wickets - int(current["wickets"])
        result["margin_type"] = "wickets"
    elif second == first:
        result["winner"] = "Tie"
    else:
        result["winner"] = bowling_team
        result["margin"] = first - second
        result["margin_type"] = "runs"
    match_finished.emit(result)

func over_string() -> String:
    return "%d.%d" % [int(current["legal_balls"] / 6), int(current["legal_balls"] % 6)]

func _emit_score() -> void:
    score_changed.emit({"team": batting_team, "runs": current["runs"], "wickets": current["wickets"], "overs": over_string(), "target": target, "innings": innings_number})
