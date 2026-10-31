extends Node
signal profile_changed(profile: Dictionary)
signal save_failed(message: String)

const SAVE_PATH := "user://cricket_legends_profile.json"
var profile: Dictionary = {}

func _ready() -> void:
	load_profile()

func load_profile() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		profile = _default_profile()
		save_profile()
		profile_changed.emit(profile.duplicate(true))
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		profile = _default_profile()
		save_failed.emit("Unable to open career save. A new profile was created.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		profile = _default_profile()
		save_failed.emit("Career save was invalid. A new profile was created.")
		save_profile()
		return
	profile = parsed
	_merge_defaults()
	profile_changed.emit(profile.duplicate(true))

func _default_profile() -> Dictionary:
	return {
		"schema_version": 1,
		"player_name": "Rookie",
		"selected_team": "India",
		"selected_opponent": "Australia",
		"selected_format": "T20",
		"selected_venue": "International Cricket Stadium",
		"difficulty": "Pro",
		"career": {"matches": 0, "wins": 0, "losses": 0, "draws": 0, "runs": 0, "wickets": 0, "experience": 0, "level": 1},
		"tournament": {"active": false, "name": "", "played": 0, "points": 0},
		"settings": {"music": 0.7, "sfx": 0.8, "commentary": true, "haptics": true}
	}

func _merge_defaults() -> void:
	var defaults := _default_profile()
	for key in defaults:
		if not profile.has(key):
			profile[key] = defaults[key]
	if typeof(profile.get("career")) != TYPE_DICTIONARY:
		profile["career"] = defaults["career"]
	if typeof(profile.get("settings")) != TYPE_DICTIONARY:
		profile["settings"] = defaults["settings"]

func save_profile() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		save_failed.emit("Could not write career save: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(profile, "\t"))
	file.flush()
	file.close()
	return true

func configure_match(team: String, opponent: String, format: String, venue: String = "", difficulty: String = "Pro") -> void:
	profile["selected_team"] = team
	profile["selected_opponent"] = opponent
	profile["selected_format"] = format.to_upper()
	if not venue.is_empty():
		profile["selected_venue"] = venue
	profile["difficulty"] = difficulty
	save_profile()
	profile_changed.emit(profile.duplicate(true))

func record_match(result: Dictionary) -> void:
	var career: Dictionary = profile.get("career", _default_profile()["career"])
	career["matches"] = int(career.get("matches", 0)) + 1
	var winner := str(result.get("winner", "Draw"))
	var selected_team := str(profile.get("selected_team", "India"))
	if winner == selected_team:
		career["wins"] = int(career.get("wins", 0)) + 1
	elif winner == "Draw" or winner == "Tie":
		career["draws"] = int(career.get("draws", 0)) + 1
	else:
		career["losses"] = int(career.get("losses", 0)) + 1
	for innings_data in result.get("innings", []):
		if str(innings_data.get("team", "")) == selected_team:
			career["runs"] = int(career.get("runs", 0)) + int(innings_data.get("runs", 0))
			career["wickets"] = int(career.get("wickets", 0)) + int(innings_data.get("wickets", 0))
	career["experience"] = int(career.get("experience", 0)) + 100
	career["level"] = 1 + int(career["experience"]) / 500
	profile["career"] = career
	save_profile()
	profile_changed.emit(profile.duplicate(true))

func update_setting(setting: String, value: Variant) -> void:
	var settings: Dictionary = profile.get("settings", {})
	if settings.has(setting):
		settings[setting] = value
		profile["settings"] = settings
		save_profile()

func start_tournament(name: String, teams: Array) -> void:
	profile["tournament"] = {
		"active": true,
		"name": name,
		"teams": teams.duplicate(),
		"fixtures": _build_round_robin(teams),
		"played": 0,
		"points": {},
		"results": []
	}
	for team in teams:
		profile["tournament"]["points"][str(team)] = 0
	save_profile()
	profile_changed.emit(profile.duplicate(true))

func _build_round_robin(teams: Array) -> Array:
	var fixtures: Array = []
	for i in range(teams.size()):
		for j in range(i + 1, teams.size()):
			fixtures.append({"home": str(teams[i]), "away": str(teams[j]), "played": false})
	return fixtures

func record_tournament_result(home: String, away: String, winner: String) -> void:
	var tournament: Dictionary = profile.get("tournament", {})
	if not bool(tournament.get("active", false)):
		return
	var fixtures: Array = tournament.get("fixtures", [])
	for fixture in fixtures:
		if not bool(fixture.get("played", false)) and str(fixture.get("home", "")) == home and str(fixture.get("away", "")) == away:
			fixture["played"] = true
			fixture["winner"] = winner
			tournament["played"] = int(tournament.get("played", 0)) + 1
			var points: Dictionary = tournament.get("points", {})
			if winner == "Draw" or winner == "Tie":
				points[home] = int(points.get(home, 0)) + 1
				points[away] = int(points.get(away, 0)) + 1
			elif not winner.is_empty():
				points[winner] = int(points.get(winner, 0)) + 2
			tournament["points"] = points
			break
	tournament["fixtures"] = fixtures
	profile["tournament"] = tournament
	save_profile()
	profile_changed.emit(profile.duplicate(true))

func get_tournament_standings() -> Array:
	var tournament: Dictionary = profile.get("tournament", {})
	var points: Dictionary = tournament.get("points", {})
	var standings: Array = []
	for team in points.keys():
		standings.append({"team": str(team), "points": int(points[team])})
	standings.sort_custom(func(a, b): return int(a["points"]) > int(b["points"]))
	return standings
