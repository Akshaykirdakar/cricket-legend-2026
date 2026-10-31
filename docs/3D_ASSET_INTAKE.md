# 3D Character Asset Intake & Integration

This project must ship with authored, rigged 3D cricket characters. The procedural cricketer remains a temporary development fallback and is **not** an accepted release asset.

## Selected asset candidates

1. **Indian Cricket Player Rigged — numaan.k99**
   - Source: https://sketchfab.com/3d-models/indian-cricket-player-rigged-a1001b602e4f430bb9de68c24d9a4aa7
   - Listed by Sketchfab as downloadable and CC Attribution (CC BY).
   - 10.7k triangles / 5.5k vertices per the listing.
   - Download the source file from Sketchfab and retain the exact licence and creator attribution with the project. Confirm the current model page still says CC BY before shipping.
   - This is the first cricket-specific candidate, but its rig, skeleton hierarchy, textures, and included clips must be inspected after download.

2. **3D Character Rigged (Diesel) — THEUNSEENVULGA**
   - Source: https://theunseenvulga.itch.io/3d-charater-riggeddiesel
   - Source page states CC0 and provides GLB/FBX.
   - Generic humanoid, not a cricket player. Use only for pipeline/retargeting tests, not as the final cricket character.

3. **Adobe Mixamo**
   - Source: https://www.mixamo.com/
   - Adobe states Mixamo is free with an Adobe ID and allows royalty-free use in commercial video games.
   - Source: https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html
   - Downloading requires a human Adobe account session. Mixamo raw files must not be redistributed as standalone assets. Keep the files within the game project and ship only as integrated game content in accordance with Adobe's terms.

## Required asset delivery

Create this folder and place the inspected/import-ready files here:

```
assets/
  characters/
    cricket_player.glb
    LICENSES.md
    source/
  animations/
    LICENSES.md
    source/
```

The GLB must contain a skinned humanoid mesh, skeleton, materials, and named clips. Keep source archives and licence text in the project team's private asset store if a source licence restricts redistribution.

## Cricket-specific animation list

Generic Mixamo movement is useful for locomotion and basic reactions, but a credible cricket game needs custom/authored cricket motions:

- batting stance, guard, backlift, front-foot defence, forward drive, cover drive, pull, hook, sweep, lofted shot, follow-through
- fast bowling run-up, gather, bound, delivery stride, release, follow-through
- spin bowling approach, gather, release, follow-through
- wicketkeeper crouch, take, gather, underarm return
- fielding ready stance, sprint, slide, pickup, overarm throw, underarm throw, high catch, low catch, dive
- umpire signals for four, six, out, wide and no-ball

## Runtime integration

`scripts/players/licensed_character.gd` loads `res://assets/characters/cricket_player.glb` when present and drives its AnimationPlayer using the aliases in the script. Until the file is supplied, the project explicitly falls back to the procedural development model.

Do not mark the character milestone complete until:
- the real GLB is committed to the project's approved asset storage,
- the source licence and attribution are recorded,
- skeleton and animation clips are inspected in Godot,
- all required player roles render and animate correctly,
- Android import and runtime memory/performance are checked.

## Download and account boundary

Sketchfab downloads and Mixamo exports may require a logged-in user session. Do not bypass those controls or scrape private downloads. If the project maintainer downloads the files and uploads them to the repository or an approved private asset store, they can be integrated and validated in the Godot project.
