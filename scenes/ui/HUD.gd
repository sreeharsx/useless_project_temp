## HUD.gd
## CanvasLayer HUD displaying level info, 5-health / tries status,
## game over transition, and screen shake support.

extends CanvasLayer

# ─── Signals ───────────────────────────────────────────────────────────────────
signal popup_dismissed()

# ─── Nodes ────────────────────────────────────────────────────────────────────
@onready var level_label: Label = $TopBar/HBoxContainer/LevelLabel
@onready var health_label: Label = $TopBar/HBoxContainer/HealthLabel
@onready var game_over_notice: PanelContainer = $GameOverNotice
@onready var notice_label: Label = $GameOverNotice/NoticeLabel

# ─── Internal ─────────────────────────────────────────────────────────────────
var _shake_tween: Tween

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("hud")
	game_over_notice.visible = false

	# Connect to singletons
	GameState.level_changed.connect(_on_level_changed)
	GameState.health_changed.connect(_on_health_changed)
	GameState.game_over.connect(_on_game_over)

	_refresh_display()

	# Connect to player reset
	call_deferred("_connect_player_signals")

func _connect_player_signals() -> void:
	var players := get_tree().get_nodes_in_group("slingshot")
	for p in players:
		if p.has_signal("projectile_reset") and not p.projectile_reset.is_connected(_on_projectile_reset):
			p.projectile_reset.connect(_on_projectile_reset)

# ─── Display Updates ──────────────────────────────────────────────────────────
func _refresh_display() -> void:
	level_label.text = "Level %d" % GameState.current_level
	_update_health_display(GameState.current_health, GameState.MAX_HEALTH)

func _update_health_display(health: int, max_health: int) -> void:
	var hearts := ""
	for i in range(max_health):
		if i < health:
			hearts += "❤️"
		else:
			hearts += "🖤"
	health_label.text = "Tries: " + hearts
	_bounce_label(health_label)

func _on_health_changed(new_health: int, max_health: int) -> void:
	_update_health_display(new_health, max_health)

func _on_level_changed(new_level: int) -> void:
	level_label.text = "Level %d" % new_level
	_update_health_display(GameState.current_health, GameState.MAX_HEALTH)
	game_over_notice.visible = false

func _on_game_over() -> void:
	notice_label.text = "💔 5 Tries Over! Returning to Level 1..."
	game_over_notice.visible = true
	game_over_notice.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(game_over_notice, "modulate:a", 1.0, 0.2)

# ─── Popup System (Disabled: Audio handles dialogues) ─────────────────────────
func show_popup(_text: String, _color: Color = Color.WHITE) -> void:
	# No text popups needed as audio provides dialogue feedback
	pass

# ─── Screen Shake ─────────────────────────────────────────────────────────────
func trigger_screen_shake(intensity: float = 8.0, duration: float = 0.3) -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	_shake_tween = create_tween()
	var steps := int(duration / 0.05)
	for i in range(steps):
		var off := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		_shake_tween.tween_property(self, "offset", off, 0.05)
	_shake_tween.tween_property(self, "offset", Vector2.ZERO, 0.08)

# ─── Label Bounce ─────────────────────────────────────────────────────────────
func _bounce_label(label: Label) -> void:
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.08)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.12)

# ─── Event Handlers ───────────────────────────────────────────────────────────
func _on_projectile_reset() -> void:
	call_deferred("_connect_player_signals")
