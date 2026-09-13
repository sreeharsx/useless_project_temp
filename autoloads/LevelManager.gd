## LevelManager.gd
## Autoloaded singleton responsible for loading and transitioning between levels.
## Emits clean signals so HUD, DialogueManager, and other systems can react.

extends Node

# ─── Signals ───────────────────────────────────────────────────────────────────
signal level_load_started(level_num: int)
signal level_ready(level_num: int)
signal level_complete(level_num: int)
signal level_failed(level_num: int)
signal game_complete()

# ─── Constants ─────────────────────────────────────────────────────────────────
const LEVEL_SCENE_PATHS: Array[String] = [
	"",                                        # index 0 unused
	"res://scenes/levels/Level01.tscn",
	"res://scenes/levels/Level02.tscn",
	"res://scenes/levels/Level03.tscn",
	"res://scenes/levels/Level04.tscn",
	"res://scenes/levels/Level05.tscn",
	"res://scenes/levels/Level06.tscn",
	"res://scenes/levels/Level07.tscn",
	"res://scenes/levels/Level08.tscn",
	"res://scenes/levels/Level09.tscn",
	"res://scenes/levels/Level10.tscn",
]

const MAIN_MENU_SCENE: String = "res://scenes/main/MainMenu.tscn"
const META_ENDING_SCENE: String = "res://scenes/ui/MetaEnding.tscn"

# ─── State ─────────────────────────────────────────────────────────────────────
var _is_transitioning: bool = false

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Listen to GameState for level advance requests
	pass

# ─── Public API ────────────────────────────────────────────────────────────────
func load_level(level_num: int) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	level_load_started.emit(level_num)
	GameState.current_level = level_num
	GameState.reset_level_state()

	var path := _get_level_path(level_num)
	if path.is_empty():
		push_error("LevelManager: No scene path for level %d" % level_num)
		_is_transitioning = false
		return

	_transition_to_scene(path, level_num)

func load_current_level() -> void:
	load_level(GameState.current_level)

func restart_level() -> void:
	load_level(GameState.current_level)

func advance_to_next_level() -> void:
	var next := GameState.current_level + 1
	if next > GameState.MAX_LEVELS:
		_trigger_game_complete()
	else:
		GameState.advance_level()
		load_level(next)

func go_to_main_menu() -> void:
	_is_transitioning = true
	_fade_and_change_scene(MAIN_MENU_SCENE)

func notify_level_complete() -> void:
	level_complete.emit(GameState.current_level)
	if GameState.current_level == GameState.MAX_LEVELS:
		_trigger_game_complete()
	else:
		# Small delay then advance
		var t := get_tree().create_timer(1.5)
		t.timeout.connect(advance_to_next_level)

func notify_level_failed() -> void:
	GameState.register_miss()
	level_failed.emit(GameState.current_level)
	DialogueManager.play_dialogue("MISS")

# ─── Internals ─────────────────────────────────────────────────────────────────
func _get_level_path(level_num: int) -> String:
	if level_num < 1 or level_num >= LEVEL_SCENE_PATHS.size():
		return ""
	return LEVEL_SCENE_PATHS[level_num]

func _trigger_game_complete() -> void:
	game_complete.emit()
	_fade_and_change_scene(META_ENDING_SCENE)

func _transition_to_scene(path: String, level_num: int = -1) -> void:
	get_tree().change_scene_to_file(path)
	_is_transitioning = false
	if level_num > 0:
		level_ready.emit(level_num)

func _fade_and_change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)
	_is_transitioning = false
