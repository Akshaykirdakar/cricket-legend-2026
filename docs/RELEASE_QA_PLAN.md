# Release verification and device test plan

## Automated checks
Run the headless test harness from the repository root:

```sh
godot --headless --path . --script res://tests/run_headless.gd
```

The harness validates roster cardinality and unique IDs, ball bounce, swept collision math, finite bat impulse output, and legal-ball handling for wides, no-balls and byes.

## Physical Android validation (required before release)
A CI APK export is not a substitute for device validation. Record device model, Android version, RAM, GPU, APK commit SHA, average FPS, 1% low FPS, memory peak, thermal state and battery drain.

Test matrix:
- Fresh install, upgrade install, uninstall/reinstall and offline launch.
- Landscape orientation, touch input, swipe gestures and button hit targets.
- Complete T20 innings and match result; repeat for ODI and Test.
- Wide, no-ball, byes, leg-byes, bowled, caught, run-out, stumped and LBW.
- Save/load career, app force-stop during save, low-storage behavior.
- 30-minute soak test, thermal throttling, background/resume and audio focus.
- Low-end Android device at 30 FPS target and mid/high-tier device at 60 FPS target.

## Current known release blockers
- Character meshes are procedural placeholders, not professionally authored skinned meshes or motion-captured animation.
- The ballistics helper is a deterministic simulation component; it is not yet wired as the sole authoritative ball and bat collision system in the match controller.
- Match adjudication still needs a full laws implementation and crease/stump geometry checks; run-out/stumping/LBW are not accepted as complete.
- Tournament/career UI and match setup exist only as an initial menu layer; fixture progression and player-level career depth need more work.
- Commentary cues are procedural tones and text event hooks, not recorded commentary or a licensed sound library.
- Replay frames are recorded, but a user-facing replay playback/camera director is not complete.
- No physical Android device has been available to this workflow; device validation remains a manual release gate.

Do not publish a production release until every blocker is resolved and the device matrix is signed off.
