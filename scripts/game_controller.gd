extends Node3D
const Resolver = preload("res://scripts/match/delivery_resolver.gd")
var hud: MatchHUD
var input_handler: BattingInput
var ball: MeshInstance3D
var phase := "ready"
var elapsed := 0.0
var swing := false
var swing_at := 0.0
var power := 0.7
var aim := Vector2(0, -1)
var shot := "DRIVE"
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	environment_setup()
	camera_setup()
	stadium_setup()
	pitch_setup()
	player_setup(Vector3(0.6, 0, 5.3), Color(0.05, 0.25, 0.8))
	player_setup(Vector3(-0.6, 0, -8.3), Color(0.1, 0.55, 0.25))
	ball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.13
	ball.mesh = sphere
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(0.85, 0.06, 0.04)
	ball.material_override = red
	ball.visible = false
	add_child(ball)
	hud = MatchHUD.new()
	add_child(hud)
	input_handler = BattingInput.new()
	add_child(input_handler)
	input_handler.shot_requested.connect(_on_swipe)
	hud.shot_selected.connect(_on_shot)
	hud.bowl_pressed.connect(_bowl)
	hud.swing_pressed.connect(_swing)
	MatchState.score_changed.connect(hud.set_score)
	MatchState.match_finished.connect(_match_over)
	MatchState.start_match(MatchState.Format.T20)
	hud.set_score({"team":"India","runs":0,"wickets":0,"overs":"0.0","target":-1,"innings":1})
	hud.set_message("INDIA vs AUSTRALIA  •  T20  •  BOWL TO START")

func _process(delta: float) -> void:
	elapsed += delta
	if phase == "bowling":
		var t := clampf(elapsed / 1.15, 0.0, 1.0)
		ball.position = Vector3(0, 1.0 + sin(t * PI), lerpf(-8.0, 4.5, t))
		if t >= 1.0:
			_resolve()
	elif phase == "flight":
		var t := clampf(elapsed / 0.9, 0.0, 1.0)
		var dest := Vector3(aim.x * (9.0 + power * 15.0), 0.3 + sin(t * PI) * (2.0 + power * 3.0), 4.0 - aim.y * (10.0 + power * 17.0))
		ball.position = ball.position.lerp(dest, minf(delta * 5.0, 1.0))
		if t >= 1.0:
			_flight_done()
	elif phase == "reset" and elapsed > 0.9:
		phase = "ready"
		ball.visible = false
		hud.set_message("Ready — choose a shot and bowl")

func _add_box(pos: Vector3, size: Vector3, color: Color) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	m.material_override = mat
	add_child(m)

func environment_setup() -> void:
	var w := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.025, 0.08, 0.055)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.86, 0.82)
	e.ambient_light_energy = 0.9
	w.environment = e
	add_child(w)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_energy = 1.3
	add_child(sun)

func camera_setup() -> void:
	var c := Camera3D.new()
	c.position = Vector3(0, 16, 24)
	c.rotation_degrees = Vector3(-32, 0, 0)
	c.fov = 54
	c.current = true
	add_child(c)

func stadium_setup() -> void:
	_add_box(Vector3(0, -0.7, 0), Vector3(62, 0.6, 48), Color(0.07, 0.32, 0.13))
	for side in [-1.0, 1.0]:
		_add_box(Vector3(side * 25.5, 2, 0), Vector3(2, 5, 47), Color(0.13, 0.18, 0.24))
		_add_box(Vector3(0, 2, side * 19.5), Vector3(52, 5, 2), Color(0.16, 0.2, 0.26))
		for row in range(4):
			_add_box(Vector3(side * (22.0 - row * 1.5), 4.5 + row * 0.45, 0), Vector3(0.65, 0.5, 43), Color(0.72, 0.25 + row * 0.08, 0.12))
			_add_box(Vector3(0, 4.5 + row * 0.45, side * (16.0 - row)), Vector3(47, 0.5, 0.65), Color(0.15, 0.35 + row * 0.08, 0.68))

func pitch_setup() -> void:
	_add_box(Vector3(0, -0.27, 0), Vector3(3.4, 0.18, 20), Color(0.58, 0.43, 0.27))
	for z in [-7.4, 7.4]:
		_add_box(Vector3(0, -0.16, z), Vector3(3.4, 0.025, 0.12), Color.WHITE)
		for x in [-0.22, 0.0, 0.22]:
			_add_box(Vector3(x, 0.35, z), Vector3(0.07, 0.75, 0.07), Color(0.92, 0.88, 0.72))

func player_setup(pos: Vector3, shirt: Color) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.34
	cap.height = 1.55
	body.mesh = cap
	body.position.y = 0.95
	var mat := StandardMaterial3D.new()
	mat.albedo_color = shirt
	body.material_override = mat
	root.add_child(body)
	var head := MeshInstance3D.new()
	var h := SphereMesh.new()
	h.radius = 0.24
	head.mesh = h
	head.position.y = 1.92
	root.add_child(head)

func _on_shot(s: String) -> void:
	shot = s
	input_handler.select_shot(s)

func _on_swipe(s: String, direction: Vector2, strength: float) -> void:
	shot = s
	aim = direction.normalized()
	power = strength
	_swing()

func _bowl() -> void:
	if phase != "ready" or MatchState.innings_status != MatchState.InningsStatus.LIVE:
		return
	phase = "bowling"
	elapsed = 0.0
	swing = false
	ball.position = Vector3(0, 1, -8)
	ball.visible = true
	hud.set_message("Bowler running in — SWING at the right moment!")

func _swing() -> void:
	if phase != "bowling" or swing:
		return
	swing = true
	swing_at = elapsed / 1.15
	hud.set_message("Shot played!")

func _resolve() -> void:
	var result: Dictionary
	if not swing:
		result = {"bat_runs":0,"total_runs":0,"legal":true,"wicket":rng.randf() < 0.07}
	else:
		var timing := clampf(1.0 - absf(swing_at - 0.78) / 0.78, 0, 1)
		result = Resolver.resolve({"timing":timing,"power":power,"batter_skill":0.72,"shot":shot,"line":rng.randf_range(-0.3,0.3),"length":rng.randf(),"wicket_roll":rng.randf()})
		if result.wicket:
			result.total_runs = 0
		elif result.bat_runs > 0:
			phase = "flight"
			elapsed = 0
			hud.set_message("Contact! Ball in the field…")
			return
	MatchState.apply_delivery(result)
	hud.set_message("WICKET!" if result.wicket else "Dot ball")
	phase = "reset"
	elapsed = 0

func _flight_done() -> void:
	var d := Vector2(ball.position.x, ball.position.z).length()
	var runs := 1 if d < 8 else (2 if d < 13 else (3 if d < 19 else (4 if d < 24 else 6)))
	MatchState.apply_delivery({"bat_runs":runs,"total_runs":runs,"legal":true,"wicket":false})
	hud.set_message("SIX!" if runs == 6 else ("FOUR!" if runs == 4 else "%d RUN(S)" % runs))
	phase = "reset"
	elapsed = 0

func _match_over(result: Dictionary) -> void:
	hud.set_message("MATCH OVER  •  %s" % str(result.get("winner", "Result")))
	phase = "finished"
