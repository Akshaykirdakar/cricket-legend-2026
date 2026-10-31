extends CanvasLayer
class_name MatchHUD
signal bowl_pressed
signal swing_pressed
signal shot_selected(shot: String)
var score_label: Label
var detail_label: Label
var message_label: Label

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 16)
	panel.custom_minimum_size = Vector2(470, 92)
	root.add_child(panel)
	var v := VBoxContainer.new()
	panel.add_child(v)
	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 28)
	v.add_child(score_label)
	detail_label = Label.new()
	detail_label.add_theme_font_size_override("font_size", 17)
	v.add_child(detail_label)
	message_label = Label.new()
	message_label.position = Vector2(500, 24)
	message_label.size = Vector2(850, 48)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 22)
	root.add_child(message_label)
	var bar := HBoxContainer.new()
	bar.anchor_top = 1
	bar.anchor_bottom = 1
	bar.offset_left = 18
	bar.offset_right = -18
	bar.offset_top = -100
	bar.offset_bottom = -14
	bar.add_theme_constant_override("separation", 10)
	root.add_child(bar)
	for s in ["DEFEND", "DRIVE", "PULL", "LOFT"]:
		var b := Button.new()
		b.text = s
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 72
		b.add_theme_font_size_override("font_size", 17)
		b.pressed.connect(func(): shot_selected.emit(s))
		bar.add_child(b)
	var swing_button := Button.new()
	swing_button.text = "SWING"
	swing_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	swing_button.custom_minimum_size.y = 72
	swing_button.add_theme_font_size_override("font_size", 21)
	swing_button.pressed.connect(func(): swing_pressed.emit())
	bar.add_child(swing_button)
	var bowl := Button.new()
	bowl.text = "BOWL ▶"
	bowl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bowl.custom_minimum_size.y = 72
	bowl.add_theme_font_size_override("font_size", 21)
	bowl.pressed.connect(func(): bowl_pressed.emit())
	bar.add_child(bowl)

func set_score(s: Dictionary) -> void:
	if score_label == null:
		return
	score_label.text = "%s   %d/%d" % [s.team, s.runs, s.wickets]
	detail_label.text = "OVERS %s   INNINGS %d" % [s.overs, s.innings]
	if int(s.target) > 0:
		detail_label.text += "   TARGET %d" % s.target

func set_message(value: String) -> void:
	if message_label != null:
		message_label.text = value
