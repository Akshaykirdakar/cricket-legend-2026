extends Control
const MATCH_SCENE := "res://scenes/match.tscn"
var team_select: OptionButton
var opponent_select: OptionButton
var format_select: OptionButton
var status_label: Label
var content: VBoxContainer

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.025, 0.07, 0.045)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 720)
	center.add_child(panel)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	var title := Label.new()
	title.text = "CRICKET LEGENDS 26"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	content.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "THE GAME IS YOURS"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	content.add_child(subtitle)
	_add_label("SELECT YOUR TEAM")
	team_select = _option(["India", "Australia"], str(CareerManager.profile.get("selected_team", "India")))
	_add_label("OPPONENT")
	opponent_select = _option(["Australia", "India"], str(CareerManager.profile.get("selected_opponent", "Australia")))
	_add_label("MATCH FORMAT")
	format_select = _option(["T20", "ODI", "TEST"], str(CareerManager.profile.get("selected_format", "T20")))
	_add_button("PLAY MATCH", _play_match)
	_add_button("TOURNAMENT", _show_tournament)
	_add_button("CAREER PROFILE", _show_career)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(status_label)

func _add_label(value: String) -> void:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", 16)
	content.add_child(label)

func _option(items: Array, selected: String) -> OptionButton:
	var option := OptionButton.new()
	for item in items:
		option.add_item(str(item))
	var index := items.find(selected)
	option.select(maxi(0, index))
	option.custom_minimum_size.y = 54
	content.add_child(option)
	return option

func _add_button(label: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size.y = 62
	button.add_theme_font_size_override("font_size", 21)
	button.pressed.connect(callback)
	content.add_child(button)

func _play_match() -> void:
	var team := team_select.get_item_text(team_select.selected)
	var opponent := opponent_select.get_item_text(opponent_select.selected)
	if not TeamRosterManager.validate_matchup(team, opponent):
		status_label.text = "Choose two different teams."
		return
	CareerManager.configure_match(team, opponent, format_select.get_item_text(format_select.selected))
	get_tree().change_scene_to_file(MATCH_SCENE)

func _show_career() -> void:
	var c: Dictionary = CareerManager.profile.get("career", {})
	status_label.text = "CAREER  •  Matches %d  •  Wins %d  •  Losses %d  •  Runs %d  •  Wickets %d  •  Level %d" % [int(c.get("matches", 0)), int(c.get("wins", 0)), int(c.get("losses", 0)), int(c.get("runs", 0)), int(c.get("wickets", 0)), int(c.get("level", 1))]

func _show_tournament() -> void:
	var names := TeamRosterManager.get_team_names()
	if names.size() < 2:
		status_label.text = "At least two valid team rosters are required."
		return
	CareerManager.start_tournament("Legends League", names)
	status_label.text = "TOURNAMENT CREATED  •  %d fixtures  •  Round robin" % (names.size() * (names.size() - 1) / 2)
