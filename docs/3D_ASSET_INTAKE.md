# 3D Character Asset Intake & Integration

## Supplied character

The owner supplied an archive containing:
- `Kohli.fbx` (FBX binary version 7400, 1,315,580 bytes)
- six texture files, now organized under `assets/characters/textures/`

The FBX binary includes geometry and skeleton-related records. It does not show obvious FBX AnimationStack/AnimationCurve records, so do not assume it contains animation clips. Godot must import it before skeleton/material validation can be completed.

**Licence status: NOT VERIFIED.** The ZIP did not contain a licence or attribution document. The asset must not be treated as commercially cleared until its creator, source URL and redistribution licence are confirmed and recorded in `assets/characters/LICENSES.md`.

## Import package

Use the supplied import package and copy its `assets/` directory into the Godot project root. The runtime loader path is:

`res://assets/characters/Kohli.fbx`

Texture paths are relative to the FBX folder and should resolve from `assets/characters/textures/` after import.

## Runtime loader

`scripts/players/licensed_character.gd`:
- loads the FBX as a PackedScene,
- supports configurable model scale, rotation and offset,
- discovers Skeleton3D and AnimationPlayer recursively,
- prints imported clip names,
- exposes `get_character_diagnostics()`,
- uses the procedural model only if the FBX cannot be loaded.

No cricket action is mapped to a generic clip unless the exact clip name exists. Configure `animation_aliases` to match the imported AnimationPlayer library.

## Cricket animation requirements

A professional game needs custom/authored or properly licensed clips:
- batting stance, guard, backlift, front-foot defence, drives, pull, hook, sweep, loft and follow-through
- fast-bowling run-up, gather, bound, delivery stride, release and follow-through
- spin-bowling approach, gather, release and follow-through
- wicketkeeper crouch, take, gather and return
- fielding ready stance, sprint, slide, pickup, throws, high/low catches and dives
- umpire signals

Generic locomotion can be retargeted for run/jog/idle, but is not a substitute for cricket-specific batting/bowling/keeping.

## Godot validation checklist

1. Open the project in Godot 4.4+ and wait for FBX import.
2. Open `res://assets/characters/Kohli.fbx` as a scene.
3. Verify mesh visibility, skeleton skin binding, material slots and all six textures.
4. Inspect AnimationPlayer/AnimationLibrary; record exact clip names.
5. Check the character's forward axis, scale and ground pivot; adjust exported loader properties.
6. Run Android export and test import, memory and frame time on a physical device.

Do not mark the asset milestone complete until the actual binary and textures are in the repository/approved asset store, licence is cleared, import checks pass and the player animates correctly in match gameplay.
