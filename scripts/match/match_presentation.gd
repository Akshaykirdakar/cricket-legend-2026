extends Node
class_name MatchPresentation
## Lightweight event commentary and ball-path replay buffer for offline matches.
signal commentary_line(text: String)
signal replay_ready(frames: Array)

var commentary_enabled := true
var replay_frames: Array[Dictionary] = []
var max_frames := 360
var last_event := ""

func record_ball_frame(position: Vector3, velocity: Vector3, phase: String) -> void:
	replay_frames.append({
		"position": [position.x, position.y, position.z],
		"velocity": [velocity.x, velocity.y, velocity.z],
		"phase": phase
	})
	while replay_frames.size() > max_frames:
		replay_frames.pop_front()

func clear_replay() -> void:
	replay_frames.clear()

func announce_event(event: String, detail: String = "") -> void:
	last_event = event
	if not commentary_enabled:
		return
	var lines := {
		"bowled": "Clean run-up. The bowler is in.",
		"contact": "That's timed beautifully!",
		"miss": "Beaten outside the line.",
		"four": "FOUR! Finds the gap and races away.",
		"six": "SIX! That's gone all the way!",
		"catch": "Taken cleanly! The batter has to go.",
		"dot": "No run. Good fielding.",
		"run": "They come back for another run.",
		"runout": "Direct hit! That's a run out.",
		"stumped": "Quick work behind the stumps. Stumped!",
		"wicket": "The fielding side strikes."
	}
	var text := str(lines.get(event, event.capitalize()))
	if not detail.is_empty():
		text += " " + detail
	commentary_line.emit(text)

func finish_replay() -> void:
	replay_ready.emit(replay_frames.duplicate(true))
