## MetaEnding.gd
## Level 10 meta ending sequence:
##  1. Black screen overlay
##  2. Fake Godot crash log terminal window
##  3. Typewriter green text animation
##  4. Pani Kitti total score summary
##  5. Restart button
##
## Node structure:
##   MetaEnding (CanvasLayer)
##   ├── BlackOverlay (ColorRect)          — full screen black
##   ├── TerminalWindow (PanelContainer)   — centered fake terminal
##   │   └── VBoxContainer
##   │       ├── TitleBar (HBoxContainer)
##   │       │   ├── TitleLabel (Label)    — "ERROR - Engine crashed"
##   │       │   └── CloseBtn (Button)     — decoration only
##   │       ├── ScrollContainer
##   │       │   └── TerminalText (RichTextLabel)
##   │       ├── ScoreLine (Label)
##   │       └── RestartBtn (Button)

extends CanvasLayer

# ─── Constants ─────────────────────────────────────────────────────────────────
const TYPEWRITER_SPEED: float = 0.03    # Seconds per character
const CRASH_HEADER: String = """
================================================================
  ENGINE: ValliPidutham v4.2.stable
  FATAL: Uncaught exception in _catch_vine()
  STACK TRACE:
    #0 ValliTarget.gd:88 -> _handle_caught()
    #1 PlayerHand.gd:112 -> _launch()
    #2 GameWorld.gd:55 -> _physics_process()
  
  ERROR: VineEvasionException — Vine caught after %d failed attempts
================================================================

Congratulations! You literally pulled the plug on your own trouble.
Game over.
"""

# ─── Nodes ────────────────────────────────────────────────────────────────────
@onready var black_overlay: ColorRect = $BlackOverlay
@onready var terminal_window: PanelContainer = $TerminalWindow
@onready var terminal_text: RichTextLabel = $TerminalWindow/VBoxContainer/ScrollContainer/TerminalText
@onready var score_line: Label = $TerminalWindow/VBoxContainer/ScoreLine
@onready var restart_btn: Button = $TerminalWindow/VBoxContainer/RestartBtn

# ─── Internal ─────────────────────────────────────────────────────────────────
var _full_text: String = ""
var _char_index: int = 0
var _typewriter_timer: float = 0.0
var _typing_active: bool = false

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Cut all audio
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), -80.0)

	black_overlay.visible = true
	black_overlay.color = Color(0, 0, 0, 0)
	terminal_window.visible = false
	restart_btn.visible = false
	score_line.visible = false

	restart_btn.pressed.connect(_on_restart_pressed)

	# Fade in black overlay first
	var tween := create_tween()
	tween.tween_property(black_overlay, "color:a", 1.0, 0.6)
	tween.tween_callback(_show_terminal)

func _process(delta: float) -> void:
	if not _typing_active:
		return
	_typewriter_timer += delta
	if _typewriter_timer >= TYPEWRITER_SPEED:
		_typewriter_timer = 0.0
		_type_next_char()

# ─── Terminal Sequence ────────────────────────────────────────────────────────
func _show_terminal() -> void:
	terminal_window.visible = true
	terminal_window.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(terminal_window, "modulate:a", 1.0, 0.3)
	tween.tween_callback(_start_typewriter)

func _start_typewriter() -> void:
	var pani_count := GameState.total_pani_kitti
	_full_text = CRASH_HEADER % pani_count
	terminal_text.clear()
	terminal_text.push_color(Color(0.1, 1.0, 0.2))   # Green terminal text
	_char_index = 0
	_typing_active = true

func _type_next_char() -> void:
	if _char_index >= _full_text.length():
		_typing_active = false
		_show_score_and_restart()
		return
	terminal_text.add_text(_full_text[_char_index])
	_char_index += 1
	# Auto-scroll
	var scroll := terminal_text.get_parent() as ScrollContainer
	if scroll:
		scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func _show_score_and_restart() -> void:
	score_line.visible = true
	score_line.text = "📊 Total Pani Kitti Count: %d  |  Total Shots: %d" % [
		GameState.total_pani_kitti,
		GameState.total_shots_fired
	]

	var tween := create_tween()
	tween.tween_interval(0.8)
	tween.tween_callback(func():
		restart_btn.visible = true
		# Restore audio
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), 0.0)
	)

# ─── Restart ──────────────────────────────────────────────────────────────────
func _on_restart_pressed() -> void:
	GameState.full_reset()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), 0.0)
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
