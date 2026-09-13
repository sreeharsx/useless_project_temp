## DialogueManager.gd
## Autoloaded singleton managing all comedic audio triggers, sound effects,
## drag audio, fall audio, disappear effects, and miss dialogue progression.

extends Node

# ─── Signals ───────────────────────────────────────────────────────────────────
signal dialogue_started(event_type: String)
signal dialogue_finished(event_type: String)

# ─── Constants ─────────────────────────────────────────────────────────────────
const DIALOGUE_BUS: String = "Dialogue"
const SFX_BUS: String = "SFX"
const AUDIO_DIR: String = "res://assets/audio/dialogue/"

# ─── Nodes ─────────────────────────────────────────────────────────────────────
var _dialogue_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _drag_player: AudioStreamPlayer
var _stream_cache: Dictionary = {}
var _current_event: String = ""

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_ensure_audio_buses()

	_dialogue_player = AudioStreamPlayer.new()
	_dialogue_player.bus = DIALOGUE_BUS
	add_child(_dialogue_player)
	_dialogue_player.finished.connect(_on_dialogue_finished)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = SFX_BUS
	add_child(_sfx_player)

	_drag_player = AudioStreamPlayer.new()
	_drag_player.bus = SFX_BUS
	add_child(_drag_player)

func _ensure_audio_buses() -> void:
	if AudioServer.get_bus_index(DIALOGUE_BUS) == -1:
		AudioServer.add_bus()
		var idx := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, DIALOGUE_BUS)
	if AudioServer.get_bus_index(SFX_BUS) == -1:
		AudioServer.add_bus()
		var idx := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, SFX_BUS)

# ─── Audio Stream Loader ───────────────────────────────────────────────────────
func get_sound_stream(sound_name: String) -> AudioStream:
	if _stream_cache.has(sound_name):
		return _stream_cache[sound_name]

	var candidates: Array[String] = [
		AUDIO_DIR + sound_name + ".mp3",
		AUDIO_DIR + sound_name + ".mpeg",
		AUDIO_DIR + sound_name + ".ogg",
		AUDIO_DIR + sound_name + ".wav",
	]

	for path in candidates:
		if ResourceLoader.exists(path):
			var res = load(path)
			if res is AudioStream:
				_stream_cache[sound_name] = res
				return res

		if FileAccess.file_exists(path):
			var bytes := FileAccess.get_file_as_bytes(path)
			if bytes.size() > 0:
				var mp3 := AudioStreamMP3.new()
				mp3.data = bytes
				_stream_cache[sound_name] = mp3
				return mp3

	return null

var _drag_index: int = 0

# ─── Drag Sound (Alternating drag and drag01) ─────────────────────────────────
func play_drag() -> void:
	var sound_name := "drag" if (_drag_index % 2 == 0) else "drag01"
	var stream := get_sound_stream(sound_name)
	if stream:
		if stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = true
		_drag_player.stream = stream
		if not _drag_player.playing:
			_drag_player.play()

func advance_drag_index() -> void:
	_drag_index += 1

func stop_drag() -> void:
	if _drag_player.playing:
		_drag_player.stop()

func stop_all_dialogue() -> void:
	if _dialogue_player.playing:
		_dialogue_player.stop()

# ─── Sound Effects (Fall & Disappear) ─────────────────────────────────────────
func play_fall() -> void:
	var stream := get_sound_stream("fall")
	if stream:
		_sfx_player.stream = stream
		_sfx_player.play()

func play_disappear() -> void:
	var stream := get_sound_stream("disappear")
	if stream:
		_sfx_player.stream = stream
		_sfx_player.play()

# ─── Miss Dialogue Progression ─────────────────────────────────────────────────
# 1st miss: miss_01 or miss_02
# 2-3 misses: miss_03
# More misses (4+): miss_05
func play_miss(miss_count: int) -> void:
	var sound_name: String = ""
	if miss_count <= 1:
		sound_name = "miss_01" if randf() < 0.5 else "miss_02"
	elif miss_count == 2 or miss_count == 3:
		sound_name = "miss_03"
	else:
		sound_name = "miss_05"

	_play_dialogue_sound(sound_name, "MISS")

func play_victory() -> void:
	_play_dialogue_sound("victory", "VICTORY")

func play_bus_hit() -> void:
	var sound_name := "bus_hit_01" if randf() < 0.5 else "bus_hit_02"
	_play_dialogue_sound(sound_name, "BUS_HIT")

func _play_dialogue_sound(sound_name: String, event_type: String) -> void:
	if _dialogue_player.playing:
		_dialogue_player.stop()

	_current_event = event_type
	var stream := get_sound_stream(sound_name)
	if stream:
		_dialogue_player.stream = stream
		_dialogue_player.play()
		dialogue_started.emit(event_type)
	else:
		dialogue_finished.emit(event_type)

func _on_dialogue_finished() -> void:
	dialogue_finished.emit(_current_event)
	_current_event = ""

# ─── Legacy/Compatibility API ─────────────────────────────────────────────────
func play_dialogue(event_type: String) -> String:
	match event_type:
		"MISS":
			play_miss(GameState.level_pani_kitti)
		"BUS_HIT":
			play_bus_hit()
		"VICTORY":
			play_victory()
		"DISAPPEAR":
			play_disappear()
		_:
			pass
	return ""

func is_playing() -> bool:
	return _dialogue_player.playing

func stop() -> void:
	if _dialogue_player.playing:
		_dialogue_player.stop()
