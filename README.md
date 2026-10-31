# Cricket Legends 26 — Production Project

Original Godot 4.4+ cricket game targeting Android landscape and offline-first play.

## Current milestone
This commit establishes the project foundation: match state, T20 innings progression, delivery outcome model, batting input abstraction, HUD, fictional sample team data and Android build workflow.

**This is not a commercially finished game yet.** The current match scene uses placeholder geometry and simplified delivery resolution. Real player/stadium assets, collision-driven bat/ball physics, full fielding AI, animation, audio, comprehensive rules and device QA remain production milestones.

## Engine and target
- Godot 4.4+
- GDScript
- Mobile Compatibility renderer
- Android ARM64
- Landscape orientation

## Run
1. Install Godot 4.4 or later.
2. Import project.godot.
3. Run scenes/main.tscn.

## Controls
- Select DEFEND, DRIVE, PULL or LOFT.
- Press BOWL to simulate the next delivery.
- BattingInput exposes swipe direction and power signals for touch integration.

## Structure
- autoload/match_state.gd: innings and score state
- scripts/match/rules_engine.gd: legal-ball and extras normalization
- scripts/match/delivery_resolver.gd: shot outcome model
- scripts/input/batting_input.gd: swipe and shot selection abstraction
- scripts/players/player_profile.gd: player attributes
- scripts/ui/match_hud.gd: match HUD
- data/teams/: fictional sample rosters
- .github/workflows/android-apk.yml: Android debug export workflow

## Production roadmap
1. Replace placeholder geometry with optimized original 3D pitch, stadium, crowd and player assets.
2. Add player rigs, animation state machines and motion quality.
3. Implement physical ball flight, bat collision, timing windows, bounce, swing and spin.
4. Build bowling, fielding, wicketkeeper, umpire and tactical AI.
5. Complete cricket laws and format-specific match rules.
6. Add commentary, sound, replay cameras, tournaments, career and progression.
7. Add automated gameplay tests, Android device profiling, release signing and QA.

## Legal
Use original or properly licensed player likenesses, team branding, kits, stadiums, broadcast graphics and audio for commercial distribution. Sample rosters are fictional.
