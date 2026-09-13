## HUD.gd
## CanvasLayer HUD displaying level info, Pani Kitti count,
## comedic Malayalam popup labels, and screen shake support.
##
## Node structure:
##   HUD (CanvasLayer)
##   ├── LevelLabel (Label)
##   ├── PaniKittiContainer (HBoxContainer)
##   │   ├── PaniKittiIcon (TextureRect)
##   │   └── PaniKittiLabel (Label)
##   ├── PopupContainer (Control)  — anchor center-top
##   │   └── PopupLabel (Label)
##   └── ShakeRoot (Node2D)        — parent of camera if used

extends CanvasLayer

# ─── Signals ───────────────────────────────────────────────────────────────────
signal popup_dismissed()

# ─── Constants ─────────────────────────────────────────────────────────────────
const POPUP_DISPLAY_DURATION: float = 2.2
const POPUP_FADE_DURATION: float = 0.5

# ─── Nodes ────────────────────────────────────────────────────────────────────
@onready var level_label: Label = $LevelLabel
@onready var pani_kitti_label: Label = $PaniKittiContainer/PaniKittiLabel
@onready var popup_container: Control = $PopupContainer
@onready var popup_label: Label = $PopupContainer/PopupLabel

# ─── Internal ─────────────────────────────────────────────────────────────────
var _popup_tween: Tween
var _shake_tween: Tween

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("hud")
	popup_container.modulate.a = 0.0
	popup_container.visible = true

	# Connect to singletons
	GameState.pani_kitti_updated.connect(_on_pani_kitti_updated)
	GameState.level_changed.connect(_on_level_changed)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)

	_refresh_labels()

	# Connect to player reset for miss detection
	call_deferred("_connect_player_signals")

func _connect_player_signals() -> void:
	var players := get_tree().get_nodes_in_group("slingshot")
	for p in players:
		if p.has_signal("projectile_reset") and not p.projectile_reset.is_connected(_on_projectile_reset):
			p.projectile_reset.connect(_on_projectile_reset)

# ─── Label Updates ────────────────────────────────────────────────────────────
func _refresh_labels() -> void:
	level_label.text = "Level %d" % GameState.current_level
	_update_pani_kitti_display(GameState.total_pani_kitti)

func _update_pani_kitti_display(count: int) -> void:
	pani_kitti_label.text = "പണി കിട്ടി × %d" % count

func _on_pani_kitti_updated(count: int) -> void:
	_update_pani_kitti_display(count)
	# Bounce animation on label
	_bounce_label(pani_kitti_label)

func _on_level_changed(new_level: int) -> void:
	level_label.text = "Level %d" % new_level

# ─── Popup System ─────────────────────────────────────────────────────────────
func show_popup(text: String, color: Color = Color.WHITE) -> void:
	popup_label.text = text
	popup_label.add_theme_color_override("font_color", color)

	if _popup_tween and _popup_tween.is_valid():
		_popup_tween.kill()

	_popup_tween = create_tween()
	_popup_tween.tween_property(popup_container, "modulate:a", 1.0, 0.15)
	_popup_tween.tween_property(popup_container, "position:y",
		popup_container.position.y - 20, 0.15).as_relative()
	_popup_tween.tween_interval(POPUP_DISPLAY_DURATION)
	_popup_tween.tween_property(popup_container, "modulate:a", 0.0, POPUP_FADE_DURATION)
	_popup_tween.tween_callback(popup_dismissed.emit)

func _on_dialogue_finished(event_type: String) -> void:
	var subtitle := DialogueManager.get_random_subtitle(event_type)
	var color := _color_for_event(event_type)
	show_popup(subtitle, color)

func _color_for_event(event_type: String) -> Color:
	match event_type:
		"MISS": return Color(1.0, 0.6, 0.2)
		"BUS_HIT": return Color(1.0, 0.2, 0.2)
		"TRICKED": return Color(0.4, 0.8, 1.0)
		"HIGH_DEATHS": return Color(0.9, 0.2, 0.9)
		"VICTORY": return Color(0.2, 1.0, 0.5)
		_: return Color.WHITE

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
	tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.08)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.12)

# ─── Event Handlers ───────────────────────────────────────────────────────────
func _on_projectile_reset() -> void:
	# Miss detected — dialogue and popup already handled by DialogueManager
	# Re-connect new player if scene restarted
	call_deferred("_connect_player_signals")
