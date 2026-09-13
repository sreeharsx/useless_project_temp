## PlayerHand.gd
## Slingshot projectile controller (RigidBody2D).
## Handles click-drag aiming, trajectory arc preview, launch physics,
## monsoon angle deviation, and auto-reset logic.
##
## Node structure expected:
##   PlayerHand (RigidBody2D)
##   ├── CollisionShape2D
##   ├── Sprite2D  (the "hand / rock" visual)
##   ├── SlingshotAnchor (Marker2D) — the pivot / fork center
##   ├── TrajectoryLine (Line2D)
##   ├── ElasticBand (Line2D)       — rubber band visual
##   └── ResetTimer (Timer)

extends RigidBody2D

# ─── Signals ───────────────────────────────────────────────────────────────────
signal player_launched(velocity: Vector2)
signal projectile_reset()
signal valli_caught()

# ─── Export tweakables ─────────────────────────────────────────────────────────
@export var max_pull_distance: float = 150.0
@export var launch_force_multiplier: float = 12.0
@export var trajectory_steps: int = 40
@export var trajectory_step_size: float = 0.05     # seconds per step
@export var screen_bounds_margin: float = 200.0
@export var stop_velocity_threshold: float = 20.0  # px/s — treated as "stopped"
@export var stop_check_delay: float = 1.5          # seconds before checking stop

# ─── Node references ──────────────────────────────────────────────────────────
@onready var slingshot_anchor: Marker2D = $SlingshotAnchor
@onready var trajectory_line: Line2D = $TrajectoryLine
@onready var elastic_band: Line2D = $ElasticBand
@onready var reset_timer: Timer = $ResetTimer
@onready var sprite: Sprite2D = $Sprite2D

# ─── Internal state ───────────────────────────────────────────────────────────
var _is_dragging: bool = false
var _drag_start_world: Vector2 = Vector2.ZERO
var _anchor_world: Vector2 = Vector2.ZERO
var _launched: bool = false
var _gravity_vec: Vector2 = Vector2(0.0, float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)))
var _monsoon: Node = null    # Set externally by the level scene if active

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	freeze = true   # Frozen until launched
	_anchor_world = slingshot_anchor.global_position
	trajectory_line.visible = false
	elastic_band.visible = false
	reset_timer.wait_time = stop_check_delay
	reset_timer.one_shot = true
	reset_timer.timeout.connect(_check_stop_and_reset)
	queue_redraw()

func _draw() -> void:
	if sprite and sprite.texture:
		return
	# Visual slingshot projectile pouch & rock
	draw_circle(Vector2.ZERO, 18.0, Color(0.92, 0.65, 0.38))
	draw_arc(Vector2.ZERO, 18.0, 0, TAU, 32, Color(0.55, 0.30, 0.12), 3.0)
	draw_circle(Vector2(-4, -4), 4.0, Color(1, 1, 1, 0.7))

func _input(event: InputEvent) -> void:
	if _launched:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				var dist: float = (mb.global_position - global_position).length()
				var dist_anchor: float = (mb.global_position - _anchor_world).length()
				if dist < 80.0 or dist_anchor < 120.0:
					_begin_drag(mb.global_position)
			else:
				if _is_dragging:
					_end_drag()

	elif event is InputEventMouseMotion and _is_dragging:
		_update_drag(event.global_position)

# ─── Drag Mechanics ───────────────────────────────────────────────────────────
func _begin_drag(screen_pos: Vector2) -> void:
	_anchor_world = slingshot_anchor.global_position
	_drag_start_world = screen_pos
	_is_dragging = true
	trajectory_line.visible = true
	elastic_band.visible = true
	_update_drag(screen_pos)

func _update_drag(screen_pos: Vector2) -> void:
	if not _is_dragging:
		return

	var raw_pull: Vector2 = screen_pos - _anchor_world
	var clamped_pull: Vector2 = raw_pull.limit_length(max_pull_distance)

	# Move the hand to clamped drag position
	global_position = _anchor_world + clamped_pull

	# Elastic band: anchor → hand position
	elastic_band.set_point_position(0, to_local(_anchor_world))
	elastic_band.set_point_position(1, Vector2.ZERO)

	# Launch vector is inverted drag direction
	var launch_vel: Vector2 = -clamped_pull * launch_force_multiplier
	_draw_trajectory(global_position, launch_vel)

	# Notify Valli AI of aiming vector (broadcast via group)
	get_tree().call_group("valli_targets", "on_player_aiming", global_position, launch_vel)

func _end_drag() -> void:
	if not _is_dragging:
		return
	_is_dragging = false
	trajectory_line.visible = false
	elastic_band.visible = false

	var raw_pull: Vector2 = global_position - _anchor_world
	if raw_pull.length() < 5.0:
		# Negligible pull — don't launch
		_snap_back_to_anchor()
		return

	var launch_vel: Vector2 = -raw_pull * launch_force_multiplier

	# Apply monsoon deviation if active
	if _monsoon and _monsoon.has_method("get_angle_deviation"):
		var dev_deg: float = _monsoon.get_angle_deviation()
		launch_vel = launch_vel.rotated(deg_to_rad(dev_deg))

	_launch(launch_vel)

func _snap_back_to_anchor() -> void:
	global_position = _anchor_world

# ─── Launch ───────────────────────────────────────────────────────────────────
func _launch(velocity: Vector2) -> void:
	freeze = false
	linear_velocity = velocity
	_launched = true
	GameState.register_launch()
	player_launched.emit(velocity)
	reset_timer.start()

# ─── Trajectory Preview ───────────────────────────────────────────────────────
func _draw_trajectory(start_pos: Vector2, start_vel: Vector2) -> void:
	var points: PackedVector2Array = []
	var gravity := _gravity_vec

	for i in range(trajectory_steps):
		var t: float = i * trajectory_step_size
		# p(t) = p0 + v0*t + 0.5*g*t²
		var p: Vector2 = start_pos + start_vel * t + 0.5 * gravity * t * t
		points.append(p)

		# Stop drawing if out of screen
		var vp := get_viewport_rect()
		if p.x < -screen_bounds_margin or p.x > vp.size.x + screen_bounds_margin \
		   or p.y > vp.size.y + screen_bounds_margin:
			break

	trajectory_line.points = points

# ─── Reset Logic ──────────────────────────────────────────────────────────────
func _physics_process(_delta: float) -> void:
	if not _launched:
		return

	# Check screen bounds
	var vp := get_viewport_rect()
	if global_position.x < -screen_bounds_margin \
	   or global_position.x > vp.size.x + screen_bounds_margin \
	   or global_position.y > vp.size.y + screen_bounds_margin:
		_trigger_reset()

func _check_stop_and_reset() -> void:
	if _launched and linear_velocity.length() < stop_velocity_threshold:
		_trigger_reset()
	elif _launched:
		# Still moving — check again later
		reset_timer.start()

func _trigger_reset() -> void:
	_launched = false
	set_deferred("freeze", true)
	set_deferred("linear_velocity", Vector2.ZERO)
	set_deferred("angular_velocity", 0.0)
	set_deferred("global_position", _anchor_world)
	projectile_reset.emit()

# ─── External API ─────────────────────────────────────────────────────────────
func set_monsoon(monsoon_node: Node) -> void:
	_monsoon = monsoon_node

func register_valli_caught() -> void:
	_launched = false
	set_deferred("freeze", true)
	set_deferred("linear_velocity", Vector2.ZERO)
	set_deferred("angular_velocity", 0.0)
	valli_caught.emit()
