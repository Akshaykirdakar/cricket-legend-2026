extends Node
class_name CricketAudio
## Procedural original audio cues. No third-party recordings or copyrighted commentary.

var players: Dictionary = {}

func _ready() -> void:
	_create_player("crowd", 0.12)
	_create_player("bat", 0.34)
	_create_player("wicket", 0.42)
	_create_player("boundary", 0.28)

func _create_player(key: String, volume: float) -> void:
	var player := AudioStreamPlayer.new()
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050
	generator.buffer_length = 0.18
	player.stream = generator
	player.volume_db = linear_to_db(volume)
	add_child(player)
	player.play()
	players[key] = player

func play_cue(key: String) -> void:
	if not players.has(key):
		return
	var player: AudioStreamPlayer = players[key]
	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var frames := playback.get_frames_available()
	var frequency := 180.0
	var duration := 0.12
	match key:
		"bat": frequency = 680.0
		"wicket": frequency = 125.0
		"boundary": frequency = 420.0
		"crowd": frequency = 95.0
	for i in range(frames):
		var t := float(i) / 22050.0
		var envelope := maxf(0.0, 1.0 - t / duration)
		var sample := sin(TAU * frequency * t) * envelope * 0.16
		playback.push_frame(Vector2(sample, sample))
