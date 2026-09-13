## GameState.gd
## Global singleton tracking all persistent game state.
## Autoloaded as "GameState" in project settings.

extends Node

# ─── Signals ───────────────────────────────────────────────────────────────────
signal pani_kitti_updated(new_count: int)
signal level_changed(new_level: int)

# ─── State Variables ───────────────────────────────────────────────────────────
var current_level: int = 1
var total_pani_kitti: int = 0        # Persistent death / fail counter across all levels
var level_pani_kitti: int = 0        # Fails in the current level session
var consecutive_misses: int = 0      # Resets on any Valli hit or level change
var total_shots_fired: int = 0

const SAVE_PATH: String = "user://valli_save.cfg"
const MAX_LEVELS: int = 10

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	load_state()

# ─── Public API ────────────────────────────────────────────────────────────────
func register_miss() -> void:
	total_pani_kitti += 1
	level_pani_kitti += 1
	consecutive_misses += 1
	total_shots_fired += 1
	pani_kitti_updated.emit(total_pani_kitti)
	save_state()

func register_launch() -> void:
	total_shots_fired += 1

func register_catch() -> void:
	consecutive_misses = 0

func advance_level() -> void:
	current_level = min(current_level + 1, MAX_LEVELS)
	level_pani_kitti = 0
	consecutive_misses = 0
	level_changed.emit(current_level)
	save_state()

func reset_level_state() -> void:
	level_pani_kitti = 0
	consecutive_misses = 0

func full_reset() -> void:
	current_level = 1
	total_pani_kitti = 0
	level_pani_kitti = 0
	consecutive_misses = 0
	total_shots_fired = 0
	pani_kitti_updated.emit(0)
	level_changed.emit(1)
	save_state()

# ─── Persistence ───────────────────────────────────────────────────────────────
func save_state() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "current_level", current_level)
	cfg.set_value("progress", "total_pani_kitti", total_pani_kitti)
	cfg.set_value("progress", "total_shots_fired", total_shots_fired)
	cfg.save(SAVE_PATH)

func load_state() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		current_level = cfg.get_value("progress", "current_level", 1)
		total_pani_kitti = cfg.get_value("progress", "total_pani_kitti", 0)
		total_shots_fired = cfg.get_value("progress", "total_shots_fired", 0)
