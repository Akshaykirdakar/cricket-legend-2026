extends Node3D
## Original procedural low-poly cricketer. This is a temporary in-engine model
## system; production release must replace it with authored rigged character art.

@export var kit_color: Color = Color(0.08, 0.28, 0.78)
@export var role: String = "fielder"

var animation_state := "idle"
var animation_time := 0.0
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var bat_pivot: Node3D

func _ready() -> void:
	_build_player()

func _process(delta: float) -> void:
	animation_time += delta
	var stride := sin(animation_time * 9.0) * 0.48 if animation_state == "run" else 0.0
	left_leg.rotation.x = stride
	right_leg.rotation.x = -stride
	left_arm.rotation.x = -stride * 0.7
	right_arm.rotation.x = stride * 0.7
	if animation_state == "idle":
		rotation.y += sin(animation_time * 1.3) * delta * 0.025
	elif animation_state == "bat":
		right_arm.rotation.x = -0.9
		if bat_pivot:
			bat_pivot.rotation.x = sin(animation_time * 8.0) * 0.35
	elif animation_state == "bowl":
		right_arm.rotation.x = -2.2 + sin(animation_time * 8.0) * 0.25
	elif animation_state == "catch":
		left_arm.rotation.x = -2.0
		right_arm.rotation.x = -2.0

func set_animation(state: String) -> void:
	animation_state = state

func _material(color: Color, roughness: float = 0.82) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m

func _mesh(parent: Node3D, mesh: Mesh, pos: Vector3, material: Material, scale_value: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	node.scale = scale_value
	node.material_override = material
	parent.add_child(node)
	return node

func _capsule(parent: Node3D, radius: float, height: float, pos: Vector3, material: Material) -> MeshInstance3D:
	var shape := CapsuleMesh.new()
	shape.radius = radius
	shape.height = height
	return _mesh(parent, shape, pos, material)

func _limb(parent: Node3D, length: float, radius: float, material: Material, pos: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pos
	parent.add_child(pivot)
	var shape := CapsuleMesh.new()
	shape.radius = radius
	shape.height = length
	_mesh(pivot, shape, Vector3(0, -length * 0.5, 0), material)
	return pivot

func _build_player() -> void:
	var skin := _material(Color(0.68, 0.43, 0.29))
	var shirt := _material(kit_color)
	var dark_kit := _material(kit_color.darkened(0.28))
	var trousers := _material(Color(0.88, 0.89, 0.91))
	var shoe := _material(Color(0.08, 0.09, 0.11))
	var pad := _material(Color(0.91, 0.91, 0.86))
	var helmet := _material(Color(0.06, 0.09, 0.13), 0.42)
	var glove := _material(Color(0.92, 0.88, 0.78))

	# Pelvis and torso have separate proportions and visible waist seam.
	_capsule(self, 0.25, 0.48, Vector3(0, 0.93, 0), trousers)
	_capsule(self, 0.34, 0.78, Vector3(0, 1.48, 0), shirt)
	_mesh(self, SphereMesh.new(), Vector3(0, 1.91, 0), skin, Vector3(0.23, 0.25, 0.22))

	# Helmet shell, peak and face grille for batting/keeping roles.
	if role == "batter" or role == "keeper":
		_mesh(self, SphereMesh.new(), Vector3(0, 2.08, 0), helmet, Vector3(0.27, 0.22, 0.25))
		_mesh(self, BoxMesh.new(), Vector3(0, 1.99, 0.19), helmet, Vector3(0.42, 0.045, 0.20))
		for x in [-0.12, 0.0, 0.12]:
			var bar := _mesh(self, CylinderMesh.new(), Vector3(x, 1.83, 0.25), glove)
			bar.scale = Vector3(0.025, 0.17, 0.025)
	else:
		_capsule(self, 0.24, 0.17, Vector3(0, 2.08, 0), shirt)

	# Arms pivot at shoulder level; forearms and gloves are distinct pieces.
	left_arm = _limb(self, 0.53, 0.105, shirt, Vector3(-0.39, 1.72, 0))
	right_arm = _limb(self, 0.53, 0.105, shirt, Vector3(0.39, 1.72, 0))
	_capsule(left_arm, 0.09, 0.20, Vector3(0, -0.49, 0), glove)
	_capsule(right_arm, 0.09, 0.20, Vector3(0, -0.49, 0), glove)

	# Legs and cricket shoes.
	left_leg = _limb(self, 0.72, 0.13, trousers, Vector3(-0.17, 0.76, 0))
	right_leg = _limb(self, 0.72, 0.13, trousers, Vector3(0.17, 0.76, 0))
	_mesh(self, BoxMesh.new(), Vector3(-0.17, 0.08, 0.10), shoe, Vector3(0.22, 0.13, 0.38))
	_mesh(self, BoxMesh.new(), Vector3(0.17, 0.08, 0.10), shoe, Vector3(0.22, 0.13, 0.38))

	# Front batting pad gives the striker a recognizable cricket silhouette.
	if role == "batter":
		_mesh(self, BoxMesh.new(), Vector3(-0.17, 0.55, 0.16), pad, Vector3(0.20, 0.56, 0.16))
		_mesh(self, BoxMesh.new(), Vector3(0.17, 0.55, 0.16), pad, Vector3(0.20, 0.56, 0.16))
		bat_pivot = Node3D.new()
		bat_pivot.position = Vector3(0.48, 1.20, 0.12)
		add_child(bat_pivot)
		var blade := _mesh(bat_pivot, BoxMesh.new(), Vector3(0, -0.48, 0), _material(Color(0.72, 0.48, 0.24)), Vector3(0.13, 0.82, 0.055))
		_mesh(bat_pivot, CylinderMesh.new(), Vector3(0, -0.03, 0), glove, Vector3(0.045, 0.15, 0.045))
