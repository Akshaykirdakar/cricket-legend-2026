extends CanvasLayer
class_name MatchHUD

signal bowl_pressed
signal shot_selected(shot: String)

var score_label: Label
var detail_label: Label

func _ready() -> void:
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(root)
    var panel := PanelContainer.new()
    panel.position = Vector2(24, 20)
    panel.size = Vector2(540, 112)
    root.add_child(panel)
    var stack := VBoxContainer.new()
    panel.add_child(stack)
    score_label = Label.new()
    score_label.add_theme_font_size_override("font_size", 30)
    stack.add_child(score_label)
    detail_label = Label.new()
    stack.add_child(detail_label)
    var shots := HBoxContainer.new()
    shots.position = Vector2(700, 900)
    root.add_child(shots)
    for shot in ["DEFEND", "DRIVE", "PULL", "LOFT"]:
        var button := Button.new()
        button.text = shot
        button.custom_minimum_size = Vector2(170, 80)
        button.pressed.connect(func(): shot_selected.emit(shot))
        shots.add_child(button)
    var bowl := Button.new()
    bowl.text = "BOWL"
    bowl.position = Vector2(1650, 900)
    bowl.custom_minimum_size = Vector2(200, 80)
    bowl.pressed.connect(func(): bowl_pressed.emit())
    root.add_child(bowl)

func set_score(snapshot: Dictionary) -> void:
    score_label.text = "%s  %d/%d" % [snapshot.team, snapshot.runs, snapshot.wickets]
    detail_label.text = "Overs %s   Innings %d" % [snapshot.overs, snapshot.innings]
    if int(snapshot.target) > 0:
        detail_label.text += "   Target %d" % snapshot.target
