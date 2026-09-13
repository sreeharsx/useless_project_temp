## GameState.gd
## Global singleton tracking all persistent game state.
## Autoloaded as "GameState" in project settings.

extends Node

# ─── Signals ───────────────────────────────────────────────────────────────────
signal pani_kitti_updated(new_count: int)
signal level_changed(new_level: int)
signal health_changed(new_health: int, max_health: int)
signal game_over()

# ─── State Variables ───────────────────────────────────────────────────────────
var current_level: int = 1
var total_pani_kitti: int = 0        # Persistent death / fail counter across all levels
var level_pani_kitti: int = 0        # Fails in the current level session
var consecutive_misses: int = 0      # Resets on any Valli hit or level change
var total_shots_fired: int = 0

const MAX_HEALTH: int = 5
var current_health: int = 5

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
	current_health = max(0, current_health - 1)
	pani_kitti_updated.emit(total_pani_kitti)
	health_changed.emit(current_health, MAX_HEALTH)
	save_state()

	if current_health <= 0:
		game_over.emit()
		_handle_out_of_health()

func register_launch() -> void:
	total_shots_fired += 1

func register_catch() -> void:
	consecutive_misses = 0

func advance_level() -> void:
	current_level = min(current_level + 1, MAX_LEVELS)
	level_pani_kitti = 0
	consecutive_misses = 0
	current_health = MAX_HEALTH
	health_changed.emit(current_health, MAX_HEALTH)
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
	current_health = MAX_HEALTH
	pani_kitti_updated.emit(0)
	health_changed.emit(current_health, MAX_HEALTH)
	level_changed.emit(1)
	save_state()

func _handle_out_of_health() -> void:
	# After 5 failed tries, return to Level 1
	var t := get_tree().create_timer(1.4)
	t.timeout.connect(func():
		current_level = 1
		current_health = MAX_HEALTH
		reset_level_state()
		health_changed.emit(current_health, MAX_HEALTH)
		level_changed.emit(1)
		save_state()
		LevelManager.load_level(1)
	)

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
