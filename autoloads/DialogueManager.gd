## DialogueManager.gd
## Autoloaded singleton managing all comedic audio triggers, dialogue bus ducking,
## and Malayalam voice/sound clip playback with overlap protection.
##
## Audio files should be placed in res://assets/audio/dialogue/
## Expected files: miss_01..03.ogg, bus_hit_01..02.ogg, tricked_01..03.ogg,
##                 high_deaths_01.ogg, victory_01.ogg

extends Node

# ─── Signals ───────────────────────────────────────────────────────────────────
signal dialogue_started(event_type: String)
signal dialogue_finished(event_type: String)

# ─── Constants ─────────────────────────────────────────────────────────────────
const DIALOGUE_BUS: String = "Dialogue"
const MUSIC_BUS: String = "Music"
const DUCK_VOLUME_DB: float = -12.0
const RESTORE_TWEEN_DURATION: float = 0.4

# Audio event → array of resource paths (fallback: empty plays silence gracefully)
const AUDIO_MAP: Dictionary = {
	"MISS": [
		"res://assets/audio/dialogue/miss_01.ogg",
		"res://assets/audio/dialogue/miss_02.ogg",
		"res://assets/audio/dialogue/miss_03.ogg",
	],
	"BUS_HIT": [
		"res://assets/audio/dialogue/bus_hit_01.ogg",
		"res://assets/audio/dialogue/bus_hit_02.ogg",
	],
	"TRICKED": [
		"res://assets/audio/dialogue/tricked_01.ogg",
		"res://assets/audio/dialogue/tricked_02.ogg",
		"res://assets/audio/dialogue/tricked_03.ogg",
	],
	"HIGH_DEATHS": [
		"res://assets/audio/dialogue/high_deaths_01.ogg",
	],
	"VICTORY": [
		"res://assets/audio/dialogue/victory_01.ogg",
	],
}

# Fallback subtitle text when no audio file exists (shown as popup instead)
const SUBTITLE_MAP: Dictionary = {
	"MISS": ["Aiyyo!", "Missed again!", "Avide alla!", "Ithenthu paattiyaa?"],
	"BUS_HIT": ["KSRTC-yle kayiri!", "Oyyyyy BUS!"],
	"TRICKED": ["Ettaaaa! Valli odi!", "Ha! Caught nothing!", "Ayyy trickster vine!"],
	"HIGH_DEATHS": ["Ini nee padam kaanuka...", "Ithu game alle, ithu life aanu!"],
	"VICTORY": ["OTTHO! Pidichi!", "Valli caught! Ningal jejichu!"],
}

# ─── Nodes ─────────────────────────────────────────────────────────────────────
var _player: AudioStreamPlayer
var _music_restore_tween: Tween
var _current_event: String = ""

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = DIALOGUE_BUS
	add_child(_player)
	_player.finished.connect(_on_dialogue_finished)
	_ensure_audio_buses()

func _ensure_audio_buses() -> void:
	# Ensure Dialogue bus exists (runtime creation for robustness)
	if AudioServer.get_bus_index(DIALOGUE_BUS) == -1:
		AudioServer.add_bus()
		var idx := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, DIALOGUE_BUS)
	if AudioServer.get_bus_index(MUSIC_BUS) == -1:
		AudioServer.add_bus()
		var idx := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, MUSIC_BUS)

# ─── Public API ────────────────────────────────────────────────────────────────
func play_dialogue(event_type: String) -> String:
	"""
	Play a random audio clip for the given event type.
	Stops any currently playing dialogue first (overlap protection).
	Returns the subtitle string that was selected.
	"""
	# Overlap protection
	if _player.playing:
		_player.stop()

	_current_event = event_type
	var subtitle := _pick_subtitle(event_type)

	var audio_paths: Array = AUDIO_MAP.get(event_type, [])
	if audio_paths.size() > 0:
		var path: String = audio_paths[randi() % audio_paths.size()]
		if ResourceLoader.exists(path):
			var stream := load(path) as AudioStream
			if stream:
				_player.stream = stream
				_duck_music()
				_player.play()
				dialogue_started.emit(event_type)
				return subtitle

	# No audio available — emit finished immediately so UI can still show popup
	dialogue_finished.emit(event_type)
	return subtitle

func get_random_subtitle(event_type: String) -> String:
	return _pick_subtitle(event_type)

func is_playing() -> bool:
	return _player.playing

func stop() -> void:
	if _player.playing:
		_player.stop()

# ─── Internals ─────────────────────────────────────────────────────────────────
func _pick_subtitle(event_type: String) -> String:
	var subs: Array = SUBTITLE_MAP.get(event_type, ["..."])
	return subs[randi() % subs.size()]

func _duck_music() -> void:
	var music_idx := AudioServer.get_bus_index(MUSIC_BUS)
	if music_idx == -1:
		return
	if _music_restore_tween and _music_restore_tween.is_valid():
		_music_restore_tween.kill()
	AudioServer.set_bus_volume_db(music_idx, DUCK_VOLUME_DB)

func _restore_music() -> void:
	var music_idx := AudioServer.get_bus_index(MUSIC_BUS)
	if music_idx == -1:
		return
	_music_restore_tween = create_tween()
	_music_restore_tween.tween_method(
		func(vol: float): AudioServer.set_bus_volume_db(music_idx, vol),
		DUCK_VOLUME_DB, 0.0, RESTORE_TWEEN_DURATION
	)

func _on_dialogue_finished() -> void:
	_restore_music()
	dialogue_finished.emit(_current_event)
	_current_event = ""
