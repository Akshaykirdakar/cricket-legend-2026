extends Node3D

const Resolver = preload("res://scripts/match/delivery_resolver.gd")
var hud: MatchHUD
var input_handler: BattingInput
var delivery_pending := false
var shot_power := 0.65
var shot_aim := Vector2.UP

func _ready() -> void:
    _create_environment()
    _create_camera()
    _create_placeholder_pitch()
    hud = MatchHUD.new()
    add_child(hud)
    input_handler = BattingInput.new()
    add_child(input_handler)
    input_handler.shot_requested.connect(_on_shot_requested)
    hud.shot_selected.connect(input_handler.select_shot)
    hud.bowl_pressed.connect(_bowl)
    MatchState.score_changed.connect(hud.set_score)
    MatchState.start_match(MatchState.Format.T20)

func _create_environment() -> void:
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.025, 0.08, 0.055)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.8, 0.86, 0.82)
    env.ambient_light_energy = 0.9
    world.environment = env
    add_child(world)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -28, 0)
    sun.light_energy = 1.2
    add_child(sun)

func _create_camera() -> void:
    var camera := Camera3D.new()
    camera.position = Vector3(0, 18, 26)
    camera.rotation_degrees = Vector3(-34, 0, 0)
    camera.current = true
    camera.fov = 52
    add_child(camera)

func _create_placeholder_pitch() -> void:
    _add_box(Vector3(0, -0.35, 0), Vector3(52, 0.5, 38), Color(0.08, 0.31, 0.13))
    _add_box(Vector3(0, -0.04, 0), Vector3(3.2, 0.12, 20), Color(0.62, 0.48, 0.31))
    _add_box(Vector3(0, 0.04, 7.4), Vector3(3.2, 0.02, 0.12), Color.WHITE)
    _add_box(Vector3(0, 0.04, -7.4), Vector3(3.2, 0.02, 0.12), Color.WHITE)

func _add_box(pos: Vector3, size: Vector3, color: Color) -> void:
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    mesh.position = pos
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    mesh.material_override = material
    add_child(mesh)

func _bowl() -> void:
    if delivery_pending or MatchState.innings_status != MatchState.InningsStatus.LIVE:
        return
    delivery_pending = true
    await get_tree().create_timer(0.9).timeout
    var result := Resolver.resolve({"timing": randf(), "power": shot_power, "batter_skill": 0.68, "shot": input_handler.selected_shot, "line": randf_range(-0.5, 0.5), "length": randf(), "wicket_roll": randf()})
    MatchState.apply_delivery(result)
    delivery_pending = false

func _on_shot_requested(shot: String, aim: Vector2, power: float) -> void:
    input_handler.selected_shot = shot
    shot_aim = aim
    shot_power = power
