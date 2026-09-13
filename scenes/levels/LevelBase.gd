## LevelBase.gd
## Base script inherited by all level scenes.
## Provides common wiring: connects PlayerHand, Valli, HUD, and handles
## level reset / retry logic with a brief UI overlay.

extends Node2D

# ─── Nodes (expected in every level scene) ────────────────────────────────────
@onready var player_hand: Node = $PlayerHand
@onready var hud: Node = $HUD
@onready var retry_overlay: CanvasLayer = $RetryOverlay

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_wire_player()
	_wire_level_manager()
	retry_overlay.visible = false

func _wire_player() -> void:
	if player_hand == null:
		return
	player_hand.add_to_group("slingshot")
	if player_hand.has_signal("projectile_reset"):
		player_hand.projectile_reset.connect(_on_projectile_reset)

func _wire_level_manager() -> void:
	LevelManager.level_failed.connect(_on_level_failed)
	LevelManager.level_complete.connect(_on_level_complete)

# ─── Event Handlers ───────────────────────────────────────────────────────────
func _on_projectile_reset() -> void:
	pass

func _on_level_failed(_level_num: int) -> void:
	pass

func _on_level_complete(_level_num: int) -> void:
	pass

func _show_retry_overlay() -> void:
	retry_overlay.visible = true

# ─── Retry Overlay Buttons (connected in scene) ───────────────────────────────
func _on_retry_pressed() -> void:
	LevelManager.restart_level()

func _on_menu_pressed() -> void:
	LevelManager.go_to_main_menu()
