extends Node3D
const Resolver = preload("res://scripts/match/delivery_resolver.gd")
const Cricketer = preload("res://scripts/players/licensed_character.gd")
const Presentation = preload("res://scripts/match/match_presentation.gd")
const GRAVITY := 9.81
const BALL_RADIUS := 0.13
const BOUNDARY_X := 28.0
const BOUNDARY_Z := 21.0

var hud: MatchHUD
var input_handler: BattingInput
var ball: MeshInstance3D
var match_camera: Camera3D
var phase := "ready"
var elapsed := 0.0
var swing := false
var swing_at := 0.0
var power := 0.7
var aim := Vector2(0, -1)
var shot := "DRIVE"
var rng := RandomNumberGenerator.new()
var ball_velocity := Vector3.ZERO
var ball_bounced := false
var ball_travelled := 0.0
var contact_quality := 0.0
var fielders: Array[Node3D] = []
var wicketkeeper: Node3D
var striker: Node3D
var bowler: Node3D
var non_striker: Node3D
var presentation: Node
var run_requested := false
var run_elapsed := 0.0

func _ready() -> void:
	rng.randomize()
	environment_setup()
	camera_setup()
	stadium_setup()
	pitch_setup()
	striker = player_setup(Vector3(0.6, 0, 5.3), Color(0.05, 0.25, 0.8), "batter")
	non_striker = player_setup(Vector3(-0.6, 0, -7.2), Color(0.05, 0.25, 0.8), "batter")
	bowler = player_setup(Vector3(-0.6, 0, -8.3), Color(0.1, 0.55, 0.25), "bowler")
	fielding_setup()
	presentation = Presentation.new()
	add_child(presentation)
	ball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = BALL_RADIUS
	ball.mesh = sphere
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(0.85, 0.06, 0.04)
	ball.material_override = red
	ball.visible = false
	add_child(ball)
	hud = MatchHUD.new()
	add_child(hud)
	presentation.commentary_line.connect(hud.set_message)
	input_handler = BattingInput.new()
	add_child(input_handler)
	input_handler.shot_requested.connect(_on_swipe)
	hud.shot_selected.connect(_on_shot)
	hud.bowl_pressed.connect(_bowl)
	hud.swing_pressed.connect(_swing)
	MatchState.score_changed.connect(hud.set_score)
	MatchState.match_finished.connect(_match_over)
	var selected_format := str(CareerManager.profile.get("selected_format", "T20"))
	MatchState.batting_team = str(CareerManager.profile.get("selected_team", "India"))
	MatchState.bowling_team = str(CareerManager.profile.get("selected_opponent", "Australia"))
	var format_value := MatchState.Format.T20
	if selected_format == "ODI":
		format_value = MatchState.Format.ODI
	elif selected_format == "TEST":
		format_value = MatchState.Format.TEST
	MatchState.start_match(format_value)
	MatchState.match_finished.connect(CareerManager.record_match)
	hud.set_score({"team":"India","runs":0,"wickets":0,"overs":"0.0","target":-1,"innings":1})
	hud.set_message("%s vs %s  •  %s  •  BOWL TO START" % [MatchState.batting_team.to_upper(), MatchState.bowling_team.to_upper(), selected_format])

func _process(delta: float) -> void:
	elapsed += delta
	_update_broadcast_camera(delta)
	if phase == "bowling":
		var t := clampf(elapsed / 1.15, 0.0, 1.0)
		# Ball travels through a delivery corridor; lateral line and release
		# height are fixed for this ball rather than decided by the shot roll.
		var delivery_line := float(ball.get_meta("delivery_line", 0.0))
		var release_height := float(ball.get_meta("release_height", 1.15))
		ball.position = Vector3(delivery_line * t, release_height + sin(t * PI) * 0.28, lerpf(-8.0, 6.9, t))
		if t >= 1.0:
			_resolve()
	elif phase == "flight":
		presentation.record_ball_frame(ball.position, ball_velocity, phase)
		_simulate_ball(delta)
	elif phase == "reset" and elapsed > 0.9:
		phase = "ready"
		ball.visible = false
		if striker and striker.has_method("set_animation"):
			striker.set_animation("idle")
		if bowler and bowler.has_method("set_animation"):
			bowler.set_animation("idle")
		hud.set_message("Ready — choose a shot and bowl")

func _simulate_ball(delta: float) -> void:
	if run_requested:
		run_elapsed += delta
		if striker and non_striker:
			striker.set_animation("run")
			non_striker.set_animation("run")
	var previous_position := ball.position
	ball_velocity.y -= GRAVITY * delta
	ball.position += ball_velocity * delta
	ball_travelled += previous_position.distance_to(ball.position)

	_update_fielding_ai(delta)
	if phase != "flight":
		return

	if ball.position.y <= BALL_RADIUS:
		ball.position.y = BALL_RADIUS
		if not ball_bounced and absf(ball_velocity.y) > 2.0:
			ball_bounced = true
			ball_velocity.y = absf(ball_velocity.y) * 0.42
			ball_velocity.x *= 0.78
			ball_velocity.z *= 0.78
		else:
			ball_velocity = Vector3.ZERO
			_finish_ball_in_field()
			return

	if absf(ball.position.x) >= BOUNDARY_X or absf(ball.position.z) >= BOUNDARY_Z:
		_finish_boundary()
		return

	if elapsed > 5.5:
		_finish_ball_in_field()

func _launch_ball(quality: float) -> void:
	var horizontal := Vector3(aim.x, 0.0, aim.y).normalized()
	if horizontal.length_squared() < 0.01:
		horizontal = Vector3(0, 0, -1)
	var shot_lift := 0.0
	match shot:
		"LOFT":
			shot_lift = 0.48
		"PULL":
			shot_lift = 0.18
		"DEFEND":
			shot_lift = 0.04
		_:
			shot_lift = 0.12
	var speed := lerpf(8.0, 25.0, clampf(quality * power, 0.0, 1.0))
	ball_velocity = horizontal * speed
	ball_velocity.y = lerpf(2.0, 12.0, clampf(shot_lift + quality * 0.42, 0.0, 1.0)) * (0.55 + power * 0.45)
	ball_bounced = false
	ball_travelled = 0.0
	contact_quality = quality
	phase = "flight"
	elapsed = 0.0
	hud.set_message("Clean contact!" if quality > 0.78 else "Ball in play — run!")

func fielding_setup() -> void:
	var positions := [Vector3(0, 0, 7.8), Vector3(-7, 0, 4), Vector3(7, 0, 4), Vector3(-13, 0, 0), Vector3(13, 0, 0), Vector3(-18, 0, -8), Vector3(18, 0, -8), Vector3(-9, 0, -15), Vector3(9, 0, -15)]
	wicketkeeper = player_setup(Vector3(0, 0, 8.5), Color(0.08, 0.35, 0.18), "keeper")
	for p in positions:
		fielders.append(player_setup(p, Color(0.08, 0.35, 0.18)))

func _update_fielding_ai(delta: float) -> void:
	if fielders.is_empty() or phase != "flight":
		return
	var nearest: Node3D = null
	var nearest_distance := INF
	for fielder in fielders:
		var d := Vector2(fielder.position.x - ball.position.x, fielder.position.z - ball.position.z).length()
		if d < nearest_distance:
			nearest_distance = d
			nearest = fielder
	if nearest == null:
		return
	var target := Vector3(ball.position.x, 0.0, ball.position.z)
	var direction := target - nearest.position
	direction.y = 0.0
	if nearest_distance > 1.15:
		nearest.position += direction.normalized() * minf(7.5 * delta, nearest_distance - 1.0)
	if ball.position.y > 1.0 and nearest_distance < 0.72 and ball_velocity.y < 0.0:
		# Catch is awarded only when the fielder reaches the descending ball.
		if ball.position.y > 1.45 and contact_quality > 0.38:
			MatchState.apply_delivery({"bat_runs": 0, "total_runs": 0, "legal": true, "wicket": true, "dismissal": "caught"})
			presentation.announce_event("catch")
			presentation.finish_replay()
			phase = "reset"
			elapsed = 0.0
			return
	if nearest_distance < 0.72 and ball.position.y < 0.65:
		ball_velocity = Vector3.ZERO
		ball.position = nearest.position + Vector3(0, 0.25, 0)
		if run_requested:
			if run_elapsed > 2.35:
				MatchState.apply_delivery({"bat_runs": 0, "total_runs": 0, "legal": true, "wicket": true, "dismissal": "run_out"})
				presentation.announce_event("runout")
			else:
				MatchState.apply_delivery({"bat_runs": 1, "total_runs": 1, "legal": true, "wicket": false})
				presentation.announce_event("run")
		else:
			_finish_ball_in_field()
		presentation.finish_replay()
		phase = "reset"
		elapsed = 0.0

func _finish_boundary() -> void:
	var runs := 4 if ball_bounced else 6
	presentation.announce_event("four" if runs == 4 else "six")
	presentation.finish_replay()
	MatchState.apply_delivery({"bat_runs":runs,"total_runs":runs,"legal":true,"wicket":false})
	hud.set_message("FOUR!" if runs == 4 else "SIX!")
	phase = "reset"
	elapsed = 0.0

func _finish_ball_in_field() -> void:
	var runs := 0
	if ball_travelled > 17.0:
		runs = 3
	elif ball_travelled > 10.0:
		runs = 2
	elif ball_travelled > 4.5:
		runs = 1
	MatchState.apply_delivery({"bat_runs":runs,"total_runs":runs,"legal":true,"wicket":false})
	presentation.announce_event("dot" if runs == 0 else "run")
	presentation.finish_replay()
	hud.set_message("DOT BALL" if runs == 0 else "%d RUN(S)" % runs)
	phase = "reset"
	elapsed = 0.0

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
	match_camera = Camera3D.new()
	match_camera.name = "BroadcastCamera"
	match_camera.position = Vector3(0, 15.5, 24.0)
	match_camera.fov = 52.0
	match_camera.current = true
	add_child(match_camera)
	match_camera.look_at(Vector3(0, 0.8, -1.5), Vector3.UP)

func _update_broadcast_camera(delta: float) -> void:
	if match_camera == null:
		return
	var desired_position := Vector3(0, 15.5, 24.0)
	var target := Vector3(0, 0.8, -1.5)
	var desired_fov := 52.0
	if phase == "bowling":
		desired_position = Vector3(0.0, 8.2, 15.8)
		target = Vector3(0.0, 1.0, -1.0)
		desired_fov = 43.0
	elif phase == "flight":
		desired_position = Vector3(ball.position.x * 0.28, 12.0 + minf(ball.position.y * 0.12, 2.0), 20.0)
		target = ball.position.lerp(Vector3.ZERO, 0.32)
		desired_fov = 48.0
	elif phase == "reset":
		desired_position = Vector3(0.0, 12.5, 21.0)
		target = Vector3.ZERO
		desired_fov = 50.0
	var blend := 1.0 - exp(-delta * 2.8)
	match_camera.position = match_camera.position.lerp(desired_position, blend)
	match_camera.fov = lerpf(match_camera.fov, desired_fov, blend)
	match_camera.look_at(target, Vector3.UP)

func stadium_setup() -> void:
	# Full-size stylised 3D ground with alternating mowing bands.
	_add_box(Vector3(0, -0.72, 0), Vector3(78, 0.55, 68), Color(0.035, 0.19, 0.075))
	for band in range(12):
		var z := -27.5 + float(band) * 5.0
		_add_box(Vector3(0, -0.425, z), Vector3(74, 0.025, 2.5), Color(0.075, 0.34, 0.12) if band % 2 == 0 else Color(0.055, 0.29, 0.10))
	# Tiered grandstands wrap the far side and both long sides.
	for row in range(9):
		var rise := 1.0 + float(row) * 0.72
		var depth := -28.5 - float(row) * 1.35
		var tier := Color(0.10 + row * 0.012, 0.14 + row * 0.012, 0.22 + row * 0.014)
		_add_box(Vector3(0, rise, depth), Vector3(70, 0.62, 1.2), tier)
		for side in [-1.0, 1.0]:
			_add_box(Vector3(side * (34.0 + row * 1.15), rise, 0), Vector3(1.2, 0.62, 58), tier)
	# Stadium roof fascia and illuminated advertising ribbon.
	_add_box(Vector3(0, 8.2, -41.0), Vector3(76, 0.75, 1.1), Color(0.025, 0.045, 0.075))
	for side in [-1.0, 1.0]:
		_add_box(Vector3(side * 44.0, 8.2, 0), Vector3(1.0, 0.75, 72), Color(0.025, 0.045, 0.075))
	# Crowd instances: coloured seats/people are batched into a few MultiMeshes.
	var crowd_colors := [Color(0.88,0.82,0.64), Color(0.72,0.78,0.88), Color(0.72,0.16,0.12), Color(0.12,0.52,0.30), Color(0.92,0.92,0.92)]
	for color_index in range(crowd_colors.size()):
		var crowd_mesh := CapsuleMesh.new()
		crowd_mesh.radius = 0.105
		crowd_mesh.height = 0.38
		var crowd_material := StandardMaterial3D.new()
		crowd_material.albedo_color = crowd_colors[color_index]
		var crowd := MultiMesh.new()
		crowd.transform_format = MultiMesh.TRANSFORM_3D
		crowd.mesh = crowd_mesh
		var transforms: Array[Transform3D] = []
		for row in range(8):
			for index in range(145):
				var x := -33.0 + float(index) * 0.46
				var z := -29.0 - float(row) * 1.35
				var y := 1.65 + float(row) * 0.72
				if (index + row * 7) % crowd_colors.size() == color_index:
					transforms.append(Transform3D(Basis.IDENTITY, Vector3(x, y, z)))
				var sx := -34.0 - float(row) * 1.15
				if (index + row * 3) % crowd_colors.size() == color_index:
					transforms.append(Transform3D(Basis.IDENTITY, Vector3(sx, y, -26.0 + float(index) * 0.36)))
		crowd.instance_count = transforms.size()
		for i in range(transforms.size()):
			crowd.set_instance_transform(i, transforms[i])
		var crowd_node := MultiMeshInstance3D.new()
		crowd_node.multimesh = crowd
		crowd_node.material_override = crowd_material
		add_child(crowd_node)
	# Floodlight towers and lamps frame the stadium skyline.
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			var tower_pos := Vector3(x * 36.0, 8.0, z * 25.0)
			_add_box(tower_pos, Vector3(0.32, 16.0, 0.32), Color(0.22,0.24,0.27))
			_add_box(tower_pos + Vector3(0, 8.0, 0), Vector3(3.8, 0.5, 1.1), Color(0.86,0.91,1.0))
	# Continuous oval boundary rope, built from short 3D segments.
	var rope_mat := StandardMaterial3D.new()
	rope_mat.albedo_color = Color(0.96, 0.88, 0.62)
	for i in range(128):
		var a := TAU * float(i) / 128.0
		var b := TAU * float(i + 1) / 128.0
		var p1 := Vector3(cos(a) * 28.0, 0.08, sin(a) * 21.0)
		var p2 := Vector3(cos(b) * 28.0, 0.08, sin(b) * 21.0)
		var segment := MeshInstance3D.new()
		var capsule := BoxMesh.new()
		capsule.size = Vector3(0.16, 0.10, p1.distance_to(p2) + 0.08)
		segment.mesh = capsule
		segment.position = (p1 + p2) * 0.5
		segment.look_at(p2, Vector3.UP)
		segment.material_override = rope_mat
		add_child(segment)

func pitch_setup() -> void:
	_add_box(Vector3(0, -0.27, 0), Vector3(3.4, 0.18, 20), Color(0.58, 0.43, 0.27))
	for z in [-7.4, 7.4]:
		_add_box(Vector3(0, -0.16, z), Vector3(3.4, 0.025, 0.12), Color.WHITE)
		for x in [-0.22, 0.0, 0.22]:
			_add_box(Vector3(x, 0.35, z), Vector3(0.07, 0.75, 0.07), Color(0.92, 0.88, 0.72))

func player_setup(pos: Vector3, shirt: Color, role: String = "fielder") -> Node3D:
	var root := Cricketer.new()
	root.kit_color = shirt
	root.role = role
	root.position = pos
	add_child(root)
	return root

func _on_shot(s: String) -> void:
	shot = s
	input_handler.select_shot(s)

func _on_swipe(s: String, direction: Vector2, strength: float) -> void:
	if phase == "flight":
		run_requested = true
		run_elapsed = 0.0
		return
	shot = s
	aim = direction.normalized()
	power = strength
	_swing()

func _bowl() -> void:
	if phase != "ready" or MatchState.innings_status != MatchState.InningsStatus.LIVE:
		return
	phase = "bowling"
	run_requested = false
	run_elapsed = 0.0
	presentation.clear_replay()
	presentation.announce_event("bowled")
	if bowler and bowler.has_method("set_animation"):
		bowler.set_animation("bowl")
	if striker and striker.has_method("set_animation"):
		striker.set_animation("idle")
	elapsed = 0.0
	swing = false
	ball.position = Vector3(0, 1, -8)
	ball.set_meta("delivery_line", rng.randf_range(-0.42, 0.42))
	ball.set_meta("release_height", rng.randf_range(0.72, 1.62))
	ball.visible = true
	hud.set_message("Bowler running in — SWING at the right moment!")

func _swing() -> void:
	if phase != "bowling" or swing:
		return
	swing = true
	if striker and striker.has_method("set_animation"):
		striker.set_animation("bat")
	swing_at = elapsed / 1.15
	hud.set_message("Shot played!")

func _resolve() -> void:
	var line := float(ball.get_meta("delivery_line", 0.0))
	var release_height := float(ball.get_meta("release_height", 1.15))
	var timing_error := absf(swing_at - 0.90)
	var contact_window := swing and timing_error <= 0.19
	var bat_reach := absf(line - 0.55) <= 0.72
	var bat_height := release_height >= 0.35 and release_height <= 2.05
	var result: Dictionary
	if contact_window and bat_reach and bat_height:
		var timing_quality := clampf(1.0 - timing_error / 0.19, 0.0, 1.0)
		result = Resolver.resolve({
			"timing": timing_quality,
			"power": power,
			"batter_skill": 0.72,
			"shot": shot,
			"line": line,
			"length": 0.55,
			"wicket_roll": 1.0
		})
		_launch_ball(float(result.get("quality", 0.0)))
		return

	# A missed delivery only hits the wicket if its actual line and height
	# intersect the stumps. No random wicket roll is used for a missed shot.
	var hits_stumps := absf(line) <= 0.34 and release_height <= 0.78
	result = {
		"bat_runs": 0,
		"total_runs": 0,
		"legal": true,
		"wicket": hits_stumps,
		"dismissal": "bowled" if hits_stumps else ""
	}
	MatchState.apply_delivery(result)
	hud.set_message("BOWLED!" if hits_stumps else ("MISSED — DOT BALL" if not swing else "MISSED — DOT BALL"))
	phase = "reset"
	elapsed = 0.0

func _match_over(result: Dictionary) -> void:
	hud.set_message("MATCH OVER  •  %s" % str(result.get("winner", "Result")))
	phase = "finished"
