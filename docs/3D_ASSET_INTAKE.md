# 3D Character Asset Intake & Integration

The project owner supplied `indian-cricket-player-rigged.zip`. The archive has been inspected locally.

## Supplied archive contents

- `source/Kohli.fbx` — 1,315,580-byte FBX binary, FBX version 7400, created with Blender 3.6.3 FBX IO.
- Six texture images: `baseColor.001.jpg`, `baseColor.003.jpg`, outfit top/bottom/footwear maps, and `glasses_id_12_D.png`.
- The FBX binary contains identifiers including `Armature`, `Hips`, `Spine`, `Spine1`, and `Spine2`, which are evidence of a skeletal rig. Godot import must still confirm a valid `Skeleton3D` and skin bindings.
- No standalone licence file was included. The original source page and exact creator/licence must be checked and preserved before commercial release.

## Import package

Use the latest package `cricket-legends-character-import-v2.zip`. Extract its `assets/` folder into the Godot project root. It places textures under `assets/characters/textures/` beside the FBX to make relative texture resolution more reliable.

Expected layout:

```
assets/
  characters/
    Kohli.fbx
    ASSET_README.md
    textures/
      baseColor.001.jpg
      baseColor.003.jpg
      outfit-m-indiancricket-01-v2-top-D.jpg
      outfit-m-indiancricket-01-v2-bottom-D.jpg
      outfit-m-indiancricket-01-v2-footwear-D.jpg
      glasses_id_12_D.png
```

## Runtime integration

`scripts/players/licensed_character.gd` now loads `res://assets/characters/Kohli.fbx`. It exposes scale, rotation and offset properties for correcting the imported asset's orientation and size. It logs imported animation clip names. If the FBX loads but has no AnimationPlayer, the actual model remains visible and a warning is emitted; it does not silently replace a valid model with a procedural character.

The procedural model is only a fallback when the FBX cannot be loaded. The binary FBX and textures are not yet committed to GitHub because the connected GitHub file-write interface accepts text files only. The import ZIP is supplied separately for copying into the repository.

## Godot import validation

1. Copy the package's `assets/` folder into the project root.
2. Open the project in Godot 4.4+ and wait for FBX import.
3. Open `res://assets/characters/Kohli.fbx` as a scene.
4. Confirm `MeshInstance3D`, `Skeleton3D`, skin bindings, texture/material assignments, scale and forward orientation.
5. Inspect the AnimationPlayer and animation libraries. The archive is not assumed to contain any animation clips.
6. Map exact imported clip names in `animation_aliases`; do not assume names such as `Idle` or `Run` exist.
7. Verify commercial licence, creator attribution and redistribution permission.
8. Export Android and validate the imported model on a physical device.

## Required cricket animation set

- batting stance, guard, backlift, front-foot defence, forward drive, cover drive, pull, hook, sweep, lofted shot, follow-through
- fast bowling run-up, gather, bound, delivery stride, release, follow-through
- spin bowling approach, gather, release, follow-through
- wicketkeeper crouch, take, gather, underarm return
- fielding ready stance, sprint, slide, pickup, overarm throw, underarm throw, high catch, low catch, dive
- umpire signals for four, six, out, wide and no-ball

Generic locomotion animation can be retargeted for movement, but it does not satisfy the cricket-specific animation requirement.

## Release gate

Do not mark this milestone complete until the actual FBX and textures are in the project, Godot import validation succeeds, exact licensing is recorded, required cricket clips are integrated, and Android rendering/performance are checked.
