## MainMenu.gd
## Animated main menu for Valli Pidutham.
## Handles new game, continue, and quit.

extends Control

# ─── Nodes ────────────────────────────────────────────────────────────────────
@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/VBoxContainer/SubtitleLabel
@onready var new_game_btn: Button = $CenterContainer/VBoxContainer/ButtonRow/NewGameBtn
@onready var continue_btn: Button = $CenterContainer/VBoxContainer/ButtonRow/ContinueBtn
@onready var quit_btn: Button = $CenterContainer/VBoxContainer/QuitBtn
@onready var bg_valli: Node2D = $BackgroundValli
@onready var version_label: Label = $VersionLabel

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	quit_btn.pressed.connect(_on_quit)

	# Disable continue if no save
	var cfg := ConfigFile.new()
	continue_btn.disabled = (cfg.load("user://valli_save.cfg") != OK)

	_animate_title()
	_animate_bg_valli()

	version_label.text = "v1.0  |  Made with Godot 4.x"

# ─── Button Handlers ──────────────────────────────────────────────────────────
func _on_new_game() -> void:
	GameState.full_reset()
	LevelManager.load_level(1)

func _on_continue() -> void:
	var lvl: int = maxi(GameState.current_level, 1)
	LevelManager.load_level(lvl)

func _on_quit() -> void:
	get_tree().quit()

# ─── Animations ───────────────────────────────────────────────────────────────
func _animate_title() -> void:
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	var tween := create_tween().set_parallel(false)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.6)
	tween.tween_interval(0.15)
	tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.5)

func _animate_bg_valli() -> void:
	if not bg_valli:
		return
	var t := create_tween().set_loops()
	t.tween_property(bg_valli, "position:x", bg_valli.position.x + 40.0, 2.0).set_trans(Tween.TRANS_SINE)
	t.tween_property(bg_valli, "position:x", bg_valli.position.x - 40.0, 2.0).set_trans(Tween.TRANS_SINE)
