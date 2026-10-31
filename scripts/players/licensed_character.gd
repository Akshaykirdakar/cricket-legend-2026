extends Node3D
## Runtime wrapper for licensed GLB/GLTF characters.
## Place the approved character at res://assets/characters/cricket_player.glb.
## If the asset is absent, use the explicitly temporary procedural fallback.

const FALLBACK = preload("res://scripts/players/procedural_cricketer.gd")
const DEFAULT_MODEL_PATH := "res://assets/characters/cricket_player.glb"

@export var model_path := DEFAULT_MODEL_PATH
@export var kit_color: Color = Color(0.08, 0.28, 0.78)
@export var role := "fielder"
@export var animation_aliases := {
	"idle": "Idle",
	"run": "Run",
	"bat": "Batting",
	"bowl": "Bowling",
	"catch": "Catch"
}

var animation_player: AnimationPlayer
var fallback_actor: Node3D
var active_animation := ""

func _ready() -> void:
	if ResourceLoader.exists(model_path):
		var packed := load(model_path) as PackedScene
		if packed:
			var model := packed.instantiate()
			add_child(model)
			animation_player = _find_animation_player(model)
			_apply_role_materials(model)
			set_animation("idle")
			return
	_use_temporary_fallback()

func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null

func _apply_role_materials(root: Node) -> void:
	# Keep imported textures intact. Kit recolouring is intentionally left to
	# authored team material variants rather than flattening source textures.
	pass

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
	if clip_name.is_empty() or not animation_player.has_animation(clip_name):
		# Do not silently play a semantically wrong clip. Preserve the last
		# valid pose until the cricket-specific animation is supplied.
		return
	if active_animation == clip_name and animation_player.is_playing():
		return
	active_animation = clip_name
	animation_player.play(clip_name)
