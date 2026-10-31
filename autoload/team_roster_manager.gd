extends Node
class_name TeamRosterManager
## Loads original fictional 11-player squads from JSON data files.

const TEAM_FILES := {
	"India": "res://data/teams/india.json",
	"Australia": "res://data/teams/australia.json"
}

var teams: Dictionary = {}

func _ready() -> void:
	load_all()

func load_all() -> void:
	for team_name in TEAM_FILES:
		var path: String = TEAM_FILES[team_name]
		if not FileAccess.file_exists(path):
			push_error("Missing team roster: " + path)
			continue
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_error("Unable to read team roster: " + path)
			continue
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(parsed) != TYPE_DICTIONARY:
			push_error("Invalid team roster JSON: " + path)
			continue
		var roster: Array = parsed.get("roster", [])
		if roster.size() != 11:
			push_error("Team %s must contain exactly 11 players; found %d" % [team_name, roster.size()])
			continue
		teams[team_name] = parsed

func get_team_names() -> PackedStringArray:
	var names := PackedStringArray()
	for name in teams.keys():
		names.append(str(name))
	names.sort()
	return names

func get_roster(team_name: String) -> Array:
	if not teams.has(team_name):
		return []
	return (teams[team_name].get("roster", []) as Array).duplicate(true)

func get_player(team_name: String, player_id: String) -> Dictionary:
	for player in get_roster(team_name):
		if str(player.get("id", "")) == player_id:
			return player
	return {}

func get_starting_xi(team_name: String) -> Array:
	var roster := get_roster(team_name)
	var selected: Array = []
	for player in roster:
		if selected.size() >= 11:
			break
		selected.append(player)
	return selected

func validate_matchup(home: String, away: String) -> bool:
	return teams.has(home) and teams.has(away) and home != away
