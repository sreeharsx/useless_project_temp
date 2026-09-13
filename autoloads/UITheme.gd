## UITheme.gd
## Autoload singleton — creates and injects a global Theme for all UI controls.
## Provides styled normal, hover, pressed, and disabled states.

extends Node

const C_BTN_NORMAL := Color(0.10, 0.55, 0.30, 1.0)   # Kerala green
const C_BTN_HOVER  := Color(0.15, 0.72, 0.40, 1.0)   # Brighter hover green
const C_BTN_PRESS  := Color(0.08, 0.38, 0.22, 1.0)   # Pressed dark green
const C_BTN_DIS    := Color(0.20, 0.24, 0.22, 0.60)  # Disabled muted
const C_TEXT_MAIN  := Color(0.95, 0.98, 0.90, 1.0)   # Clean light
const C_TEXT_HOVER := Color(1.00, 1.00, 0.80, 1.0)   # Highlight yellow-white
const C_TEXT_DIS   := Color(0.50, 0.55, 0.50, 0.70)
const C_BORDER     := Color(0.25, 0.88, 0.50, 1.0)   # Lime border
const C_BORDER_HOV := Color(0.95, 0.85, 0.25, 1.0)   # Gold border on hover
const C_BORDER_PRE := Color(1.00, 0.90, 0.35, 1.0)   # Bright gold pressed

const FONT_MANJARI_BOLD: Font = preload("res://assets/fonts/Manjari/Manjari-Bold.ttf")

var global_theme: Theme

func _ready() -> void:
	global_theme = _build_theme()
	get_tree().node_added.connect(_on_node_added)
	var root := get_tree().root
	if root:
		_apply_theme_recursive(root)

func _build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = FONT_MANJARI_BOLD
	t.default_font_size = 18

	# ── Label Styling (High Visibility Outline & Shadow) ──
	t.set_font("font", "Label", FONT_MANJARI_BOLD)
	t.set_color("font_color", "Label", Color(1.0, 1.0, 1.0, 1.0))
	t.set_color("font_outline_color", "Label", Color(0.0, 0.0, 0.0, 0.95))
	t.set_constant("outline_size", "Label", 5)
	t.set_color("font_shadow_color", "Label", Color(0.0, 0.0, 0.0, 0.7))
	t.set_constant("shadow_offset_x", "Label", 2)
	t.set_constant("shadow_offset_y", "Label", 2)

	# ── Button Styling ──
	t.set_font("font", "Button", FONT_MANJARI_BOLD)
	t.set_color("font_outline_color", "Button", Color(0.0, 0.0, 0.0, 0.9))
	t.set_constant("outline_size", "Button", 3)

	# ── Normal StyleBox ──
	var sn := StyleBoxFlat.new()
	sn.bg_color = C_BTN_NORMAL
	sn.border_width_left   = 2
	sn.border_width_right  = 2
	sn.border_width_top    = 2
	sn.border_width_bottom = 3
	sn.border_color = C_BORDER
	sn.corner_radius_top_left     = 8
	sn.corner_radius_top_right    = 8
	sn.corner_radius_bottom_left  = 8
	sn.corner_radius_bottom_right = 8
	sn.content_margin_left   = 16
	sn.content_margin_right  = 16
	sn.content_margin_top    = 8
	sn.content_margin_bottom = 8
	sn.shadow_color = Color(0, 0, 0, 0.35)
	sn.shadow_size  = 3
	sn.shadow_offset = Vector2(0, 2)

	# ── Hover StyleBox ──
	var sh := StyleBoxFlat.new()
	sh.bg_color = C_BTN_HOVER
	sh.border_width_left   = 2
	sh.border_width_right  = 2
	sh.border_width_top    = 2
	sh.border_width_bottom = 3
	sh.border_color = C_BORDER_HOV
	sh.corner_radius_top_left     = 8
	sh.corner_radius_top_right    = 8
	sh.corner_radius_bottom_left  = 8
	sh.corner_radius_bottom_right = 8
	sh.content_margin_left   = 16
	sh.content_margin_right  = 16
	sh.content_margin_top    = 8
	sh.content_margin_bottom = 8
	sh.shadow_color = Color(0.25, 0.88, 0.50, 0.40)
	sh.shadow_size  = 6
	sh.shadow_offset = Vector2(0, 3)

	# ── Pressed StyleBox ──
	var sp := StyleBoxFlat.new()
	sp.bg_color = C_BTN_PRESS
	sp.border_width_left   = 2
	sp.border_width_right  = 2
	sp.border_width_top    = 3
	sp.border_width_bottom = 1
	sp.border_color = C_BORDER_PRE
	sp.corner_radius_top_left     = 8
	sp.corner_radius_top_right    = 8
	sp.corner_radius_bottom_left  = 8
	sp.corner_radius_bottom_right = 8
	sp.content_margin_left   = 16
	sp.content_margin_right  = 16
	sp.content_margin_top    = 10
	sp.content_margin_bottom = 6

	# ── Disabled StyleBox ──
	var sd := StyleBoxFlat.new()
	sd.bg_color = C_BTN_DIS
	sd.border_width_bottom = 2
	sd.border_color = Color(0.30, 0.35, 0.30, 0.4)
	sd.corner_radius_top_left     = 8
	sd.corner_radius_top_right    = 8
	sd.corner_radius_bottom_left  = 8
	sd.corner_radius_bottom_right = 8
	sd.content_margin_left   = 16
	sd.content_margin_right  = 16
	sd.content_margin_top    = 8
	sd.content_margin_bottom = 8

	# ── Focus StyleBox ──
	var sf := StyleBoxFlat.new()
	sf.draw_center = false
	sf.border_width_left   = 2
	sf.border_width_right  = 2
	sf.border_width_top    = 2
	sf.border_width_bottom = 2
	sf.border_color = C_BORDER_PRE
	sf.corner_radius_top_left     = 8
	sf.corner_radius_top_right    = 8
	sf.corner_radius_bottom_left  = 8
	sf.corner_radius_bottom_right = 8

	t.set_stylebox("normal",   "Button", sn)
	t.set_stylebox("hover",    "Button", sh)
	t.set_stylebox("pressed",  "Button", sp)
	t.set_stylebox("disabled", "Button", sd)
	t.set_stylebox("focus",    "Button", sf)

	t.set_color("font_color",          "Button", C_TEXT_MAIN)
	t.set_color("font_hover_color",    "Button", C_TEXT_HOVER)
	t.set_color("font_pressed_color",  "Button", C_TEXT_MAIN)
	t.set_color("font_disabled_color", "Button", C_TEXT_DIS)
	t.set_color("font_focus_color",    "Button", C_TEXT_MAIN)

	t.set_font_size("font_size", "Button", 18)

	return t

func _on_node_added(node: Node) -> void:
	if node is Control and not (node as Control).theme:
		(node as Control).theme = global_theme

func _apply_theme_recursive(node: Node) -> void:
	if node is Control and not (node as Control).theme:
		(node as Control).theme = global_theme
	for child in node.get_children():
		_apply_theme_recursive(child)
