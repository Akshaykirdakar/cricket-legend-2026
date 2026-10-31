# Cricket Legends 26 — Production Development Plan

## Product target
A premium-feeling, offline-first 3D cricket game for Android, built in Godot 4.4.1. The first release target is a polished India vs Australia T20 match. The project must earn the word "realistic" through repeatable simulation, animation, readable controls, credible presentation and tested performance—not through placeholder geometry or random score rolls.

## Current baseline (honest status)
The current repository is an early playable foundation:
- Godot 4.4.1 Android ARM64 debug export pipeline.
- Basic pitch/stadium geometry and capsule/sphere placeholder players.
- Simple delivery timing, shot buttons, swipe input and score HUD.
- Simplified T20 innings state.

It is NOT production-ready. It does not yet contain production player art, rigged animation, a complete fielding system, proper ball/bat collision, broadcast presentation, complete cricket laws, audio/commentary, or device-performance certification. Do not describe it as complete.

## Technical direction
Keep gameplay deterministic and data-driven. Separate match rules, delivery simulation, player decision-making, presentation, input, and platform services. Use Godot physics for collision-driven play; do not award boundaries or wickets from random score tables. Use authored, licensed or original assets only. Never copy EA Sports Cricket assets, names, logos, commentary, or proprietary animations.

## Milestone 1 — Core match simulation
Acceptance criteria:
- Ball is a physical object with collision shape, mass, gravity, drag, seam/swing/spin parameters and turf bounce.
- Bowler delivery types: fast, medium, off-spin and leg-spin, with line/length and release variation.
- Bat has a collision volume and animation-driven contact window; shot timing, footwork, bat face, power and shot direction affect launch velocity.
- Ball trajectory determines boundary, fielder interception, catch, ground fielding and return throw.
- Legal delivery/extras/wicket rules are unit-tested; over count, strike rotation, batter/bowler figures and innings transitions are correct.
- No score or wicket is decided by an unseeded random shortcut.

## Milestone 2 — Players and animation
- Replace primitive capsules with rigged, proportioned original 3D cricketers.
- Full skeletons with idle, run-up, bowling action, batting stance, front/back-foot shots, defensive shot, running, dive, catch, throw, wicketkeeping and celebration clips.
- Animation state machines blend by speed, intent and ball state; feet should not slide visibly.
- Team kits, helmets, pads, gloves, shoes and player identity data are configurable.

## Milestone 3 — Fielding and cricket intelligence
- Field placements vary by format, batter handedness, bowler type and match situation.
- Fielders predict ball landing/interception using reachable trajectories, then move, dive, collect and throw.
- Keeper handles takes, byes, stumpings and run-out opportunities.
- Running between wickets has two-end batter control, turn radius, calling, hesitation and run-out checks.
- Wickets include bowled, caught, LBW, run out, stumped, hit wicket and applicable modes.

## Milestone 4 — Broadcast presentation
- Stadium environment with boundary rope, stands, crowd variation, pitch wear, lighting and weather presets.
- Broadcast camera, batter view, bowler view, ball-follow camera, wicket replay and boundary replay.
- Score strip, over summary, wagon wheel, pitch map, player cards, innings break and result screen.
- Original commentary system with event-driven lines and optional crowd/umpire audio.

## Milestone 5 — Modes and content
- T20, ODI and Test with correct innings counts, follow-on, declarations, draws, ties and super overs where applicable.
- Teams and player database, squads, toss, batting order, bowling rotation and substitutions as rules permit.
- Tournament, quick match, practice nets and career progression.
- Offline save slots and robust recovery after app interruption.

## Milestone 6 — Android quality
- Graphics presets and adaptive resolution; stable frame pacing on representative low/mid/high Android devices.
- Memory and thermal profiling, loading screens, asset streaming and graceful low-memory recovery.
- Touch controls with configurable layout, sensitivity, haptics and accessibility.
- Automated rule tests, deterministic simulation tests, scene smoke tests and release build validation.
- Signed release build, versioning, privacy disclosures and crash diagnostics policy.

## Definition of done for the first public release
A complete T20 match can be played from toss to result with no softlocks; every delivery is resolved by simulation; scorecard and player figures reconcile; core dismissals and extras are correct; all major player actions are animated; the game runs reliably on the declared Android device matrix; no placeholder capsules or random-run outcome logic remains in the release path.

## Delivery discipline
Every milestone must land as a tested, reviewable commit. Build success only proves the APK exports; it does not prove gameplay correctness or production readiness. Publish a new APK only after the workflow passes and the build has been smoke-tested on a physical Android device.
