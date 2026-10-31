extends Node3D
## Runtime loader for the owner-supplied cricket player FBX.
## The procedural actor is used only when the FBX cannot be imported.

const FALLBACK = preload("res://scripts/players/procedural_cricketer.gd")
const DEFAULT_MODEL_PATH := "res://assets/characters/Kohli.fbx"

@export_file("*.fbx", "*.glb", "*.gltf") var model_path := DEFAULT_MODEL_PATH
@export var model_scale := Vector3.ONE
@export var model_rotation_degrees := Vector3.ZERO
@export var model_offset := Vector3.ZERO
@export var kit_color: Color = Color(0.08, 0.28, 0.78)
@export var role := "fielder"
@export var animation_aliases := {
	"idle": "Idle",
	"run": "Run",
	"bat": "Batting",
	"bowl": "Bowling",
	"catch": "Catch",
	"throw": "Throw",
	"pickup": "Pickup"
}

var animation_player: AnimationPlayer
var skeleton: Skeleton3D
var imported_model: Node3D
var fallback_actor: Node3D
var active_animation := ""
var available_animation_clips: PackedStringArray = []

func _ready() -> void:
	_load_character()

func _load_character() -> void:
	if not ResourceLoader.exists(model_path):
		push_warning("Character asset not found at %s; using temporary procedural fallback." % model_path)
		_use_temporary_fallback()
		return

	var packed := load(model_path) as PackedScene
	if packed == null:
		push_error("Character asset exists but did not import as a PackedScene: %s" % model_path)
		_use_temporary_fallback()
		return

	imported_model = packed.instantiate() as Node3D
	if imported_model == null:
		push_error("Imported character root is not Node3D: %s" % model_path)
		_use_temporary_fallback()
		return

	imported_model.name = "ImportedCricketCharacter"
	imported_model.position = model_offset
	imported_model.rotation_degrees = model_rotation_degrees
	imported_model.scale = model_scale
	add_child(imported_model)

	animation_player = _find_animation_player(imported_model)
	skeleton = _find_skeleton(imported_model)
	available_animation_clips = _collect_animation_names(animation_player)

	if skeleton == null:
		push_warning("FBX loaded, but no Skeleton3D was found. Verify that the source mesh is skinned.")
	if animation_player == null:
		push_warning("FBX loaded without an AnimationPlayer. Cricket animation clips still need to be authored/imported.")
	else:
		print("Cricket character imported. Skeleton: %s | Clips: %s" % [
			"present" if skeleton else "missing",
			", ".join(available_animation_clips)
		])
	set_animation("idle")

func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null

func _find_skeleton(root: Node) -> Skeleton3D:
	if root is Skeleton3D:
		return root as Skeleton3D
	for child in root.get_children():
		var found := _find_skeleton(child)
		if found:
			return found
	return null

func _collect_animation_names(player: AnimationPlayer) -> PackedStringArray:
	var names := PackedStringArray()
	if player == null:
		return names
	for clip_name in player.get_animation_list():
		names.append(str(clip_name))
	return names

func _use_temporary_fallback() -> void:
	if fallback_actor != null:
		return
	fallback_actor = FALLBACK.new()
	fallback_actor.kit_color = kit_color
	fallback_actor.role = role
	add_child(fallback_actor)

func set_animation(state: String) -> void:
	if fallback_actor and fallback_actor.has_method("set_animation"):
		fallback_actor.set_animation(state)
		return
	if animation_player == null:
		return

	var clip_name := str(animation_aliases.get(state, ""))
	if clip_name.is_empty() or not animation_player.has_animation(clip_name):
		# Never map a generic movement clip to a cricket action incorrectly.
		return
	if active_animation == clip_name and animation_player.is_playing():
		return
	active_animation = clip_name
	animation_player.play(clip_name)

func get_character_diagnostics() -> Dictionary:
	return {
		"model_path": model_path,
		"model_loaded": imported_model != null,
		"skeleton_found": skeleton != null,
		"animation_player_found": animation_player != null,
		"animation_clips": Array(available_animation_clips),
		"using_temporary_fallback": fallback_actor != null
	}
