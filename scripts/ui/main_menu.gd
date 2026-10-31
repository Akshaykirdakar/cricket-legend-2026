extends Control
const MATCH_SCENE := "res://scenes/match.tscn"

var team_select: OptionButton
var opponent_select: OptionButton
var format_select: OptionButton
var status_label: Label
var content: VBoxContainer

const BG := Color("#07150f")
const PANEL := Color("#13251c")
const TEXT := Color("#f4f7f4")
const MUTED := Color("#b9c9be")
const ACCENT := Color("#f0b33e")
const BUTTON := Color("#244b37")
const BUTTON_HOVER := Color("#32684b")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	get_viewport().size_changed.connect(_layout_ui)

func _layout_ui() -> void:
	if content == null:
		return
	var viewport_size := get_viewport_rect().size
	var compact := viewport_size.x < 1000.0 or viewport_size.y < 650.0
	var panel := content.get_parent() as PanelContainer
	if panel:
		panel.custom_minimum_size = Vector2(minf(viewport_size.x * 0.88, 760.0), minf(viewport_size.y * 0.90, 820.0))
	content.add_theme_constant_override("separation", 9 if compact else 14)
	for child in content.get_children():
		if child is Button:
			child.custom_minimum_size.y = 48 if compact else 60
		elif child is OptionButton:
			child.custom_minimum_size.y = 42 if compact else 52

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var center := CenterContainer.new()
	center.name = "MenuCenter"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.name = "MenuPanel"
	panel.custom_minimum_size = Vector2(760, 800)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = PANEL
	panel_style.border_color = Color("#55745f")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(18)
	panel_style.content_margin_left = 28
	panel_style.content_margin_right = 28
	panel_style.content_margin_top = 24
	panel_style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	content = VBoxContainer.new()
	content.name = "MenuContent"
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)

	var title := Label.new()
	title.text = "CRICKET LEGENDS 26"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", ACCENT)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "THE GAME IS YOURS"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.add_theme_color_override("font_color", MUTED)
	content.add_child(subtitle)

	_add_label("SELECT YOUR TEAM")
	team_select = _option(["India", "Australia"], str(CareerManager.profile.get("selected_team", "India")))
	_add_label("OPPONENT")
	opponent_select = _option(["Australia", "India"], str(CareerManager.profile.get("selected_opponent", "Australia")))
	_add_label("MATCH FORMAT")
	format_select = _option(["T20", "ODI", "TEST"], str(CareerManager.profile.get("selected_format", "T20")))
	_add_button("PLAY MATCH", _play_match, true)
	_add_button("TOURNAMENT", _show_tournament)
	_add_button("CAREER PROFILE", _show_career)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", TEXT)
	status_label.add_theme_font_size_override("font_size", 15)
	content.add_child(status_label)
	_layout_ui()

func _add_label(value: String) -> void:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", MUTED)
	content.add_child(label)

func _option(items: Array, selected: String) -> OptionButton:
	var option := OptionButton.new()
	for item in items:
		option.add_item(str(item))
	var index := items.find(selected)
	option.select(maxi(0, index))
	option.custom_minimum_size = Vector2(0, 52)
	option.add_theme_font_size_override("font_size", 18)
	option.add_theme_color_override("font_color", TEXT)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#20372a")
	normal.border_color = Color("#54745d")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(8)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	option.add_theme_stylebox_override("normal", normal)
	option.add_theme_stylebox_override("hover", normal)
	option.add_theme_stylebox_override("pressed", normal)
	content.add_child(option)
	return option

func _add_button(label: String, callback: Callable, primary := false) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(0, 60)
	button.add_theme_font_size_override("font_size", 20 if primary else 17)
	button.add_theme_color_override("font_color", Color("#101a12") if primary else TEXT)
	button.add_theme_color_override("font_hover_color", Color("#101a12") if primary else TEXT)
	var normal := StyleBoxFlat.new()
	normal.bg_color = ACCENT if primary else BUTTON
	normal.border_color = ACCENT if primary else Color("#54745d")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#ffd06c") if primary else BUTTON_HOVER
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
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
