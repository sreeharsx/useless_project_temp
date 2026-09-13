## ScreenShaker.gd
## Autoload singleton — shakes the active Camera2D when called.
## Usage: ScreenShaker.shake(intensity, duration)

extends Node

var _camera: Camera2D = null
var _shake_intensity: float = 0.0
var _shake_timer: float = 0.0
var _origin: Vector2 = Vector2.ZERO

func _ready() -> void:
	set_process(false)

# ─── Public API ───────────────────────────────────────────────────────────────
func shake(intensity: float = 8.0, duration: float = 0.3) -> void:
	_camera = _find_camera()
	if not _camera:
		return
	_origin = _camera.offset
	_shake_intensity = intensity
	_shake_timer = duration
	set_process(true)

# ─── Process ──────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if _shake_timer > 0.0:
		_shake_timer -= delta
		var decay := _shake_timer / (_shake_timer + delta)
		_camera.offset = _origin + Vector2(
			randf_range(-_shake_intensity, _shake_intensity) * decay,
			randf_range(-_shake_intensity, _shake_intensity) * decay
		)
	else:
		if _camera:
			_camera.offset = _origin
		set_process(false)

# ─── Helpers ──────────────────────────────────────────────────────────────────
func _find_camera() -> Camera2D:
	# Walk the scene tree to find an active Camera2D
	var root := get_tree().current_scene
	if root:
		return _search_for_camera(root)
	return null

func _search_for_camera(node: Node) -> Camera2D:
	if node is Camera2D:
		return node as Camera2D
	for child in node.get_children():
		var result := _search_for_camera(child)
		if result:
			return result
	return null
