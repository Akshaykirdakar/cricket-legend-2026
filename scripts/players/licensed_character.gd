extends Node3D
## Runtime wrapper for an imported, licensed cricket-player FBX/GLB.
## Expected model: res://assets/characters/Kohli.fbx
## Procedural geometry is used only if the imported scene cannot be loaded.

const FALLBACK = preload("res://scripts/players/procedural_cricketer.gd")
const DEFAULT_MODEL_PATH := "res://assets/characters/Kohli.fbx"

@export_file("*.fbx,*.glb,*.gltf") var model_path := DEFAULT_MODEL_PATH
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
	"catch": "Catch"
}

var imported_model: Node3D
var animation_player: AnimationPlayer
var fallback_actor: Node3D
var active_animation := ""

func _ready() -> void:
	if ResourceLoader.exists(model_path):
		var packed := load(model_path) as PackedScene
		if packed:
			imported_model = packed.instantiate() as Node3D
			if imported_model:
				add_child(imported_model)
				imported_model.position = model_offset
				imported_model.scale = model_scale
				imported_model.rotation_degrees = model_rotation_degrees
				animation_player = _find_animation_player(imported_model)
				if animation_player == null:
					push_warning("Imported cricket player loaded, but no AnimationPlayer was found. Add/retarget cricket animation clips.")
				else:
					_log_available_animations()
				return
	push_warning("Licensed player asset unavailable at %s; using temporary procedural fallback." % model_path)
	_use_temporary_fallback()

func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null

func _log_available_animations() -> void:
	if not animation_player:
		return
	var library_names := animation_player.get_animation_library_list()
	for library_name in library_names:
		var library := animation_player.get_animation_library(library_name)
		for clip_name in library.get_animation_list():
			print("Cricket character animation available: ", library_name, "/", clip_name)

func _use_temporary_fallback() -> void:
	fallback_actor = FALLBACK.new()
	fallback_actor.kit_color = kit_color
	fallback_actor.role = role
	add_child(fallback_actor)

func set_animation(state: String) -> void:
	if fallback_actor and fallback_actor.has_method("set_animation"):
		fallback_actor.set_animation(state)
		return
	if not animation_player:
		return
	var clip_name := str(animation_aliases.get(state, ""))
	if clip_name.is_empty():
		return
	var animation_to_play := clip_name
	if not animation_player.has_animation(animation_to_play):
		var found := false
		for library_name in animation_player.get_animation_library_list():
			var candidate := library_name + "/" + clip_name
			if animation_player.has_animation(candidate):
				animation_to_play = candidate
				found = true
				break
		if not found:
			return
	if active_animation == animation_to_play and animation_player.is_playing():
		return
	active_animation = animation_to_play
	animation_player.play(animation_to_play)
