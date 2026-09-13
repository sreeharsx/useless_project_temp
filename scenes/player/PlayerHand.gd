## PlayerHand.gd
## Slingshot projectile controller (RigidBody2D).
## Handles click-drag aiming, launch physics, monsoon angle deviation,
## drag audio, fall audio, miss dialogue, and timed auto-reset logic.

extends RigidBody2D

# ─── Signals ───────────────────────────────────────────────────────────────────
signal player_launched(velocity: Vector2)
signal projectile_reset()
signal valli_caught()

# ─── Export tweakables ─────────────────────────────────────────────────────────
@export var max_pull_distance: float = 150.0
@export var launch_force_multiplier: float = 10.0
@export var screen_bounds_margin: float = 200.0
@export var stop_velocity_threshold: float = 25.0  # px/s
@export var stop_check_delay: float = 1.0

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
var _falling: bool = false
var _caught: bool = false
var _gravity_vec: Vector2 = Vector2(0.0, float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)))
var _monsoon: Node = null    # Set externally by the level scene if active

const TEX_HAND: Texture2D = preload("res://assets/sprites/stickman.png")

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	freeze = true   # Frozen until launched
	_anchor_world = slingshot_anchor.global_position
	sprite.texture = TEX_HAND
	sprite.scale = Vector2(0.045, 0.045)
	sprite.modulate = Color.WHITE

	# Trajectory line is completely hidden/removed
	trajectory_line.visible = false
	elastic_band.visible = false

	reset_timer.wait_time = stop_check_delay
	reset_timer.one_shot = true
	reset_timer.timeout.connect(_check_stop_and_reset)

	body_entered.connect(_on_body_entered)
	queue_redraw()

func _draw() -> void:
	if sprite and sprite.texture:
		return
	draw_circle(Vector2.ZERO, 18.0, Color(0.92, 0.65, 0.38))
	draw_arc(Vector2.ZERO, 18.0, 0, TAU, 32, Color(0.55, 0.30, 0.12), 3.0)
	draw_circle(Vector2(-4, -4), 4.0, Color(1, 1, 1, 0.7))

func _input(event: InputEvent) -> void:
	if _launched or _falling:
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
	if _launched or _falling:
		return

	# Stop previous dialogue when next try is being placed
	DialogueManager.stop_all_dialogue()

	_anchor_world = slingshot_anchor.global_position
	_drag_start_world = screen_pos
	_is_dragging = true

	# Trajectory line is removed as requested
	trajectory_line.visible = false
	elastic_band.visible = true

	# Play drag sound (alternates between drag and drag01)
	DialogueManager.play_drag()
	_update_drag(screen_pos)

func _update_drag(screen_pos: Vector2) -> void:
	if not _is_dragging:
		return

	var raw_pull: Vector2 = screen_pos - _anchor_world
	var clamped_pull: Vector2 = raw_pull.limit_length(max_pull_distance)

	# Move the stickman hand to clamped drag position
	global_position = _anchor_world + clamped_pull

	# Elastic band: anchor → hand position
	elastic_band.set_point_position(0, to_local(_anchor_world))
	elastic_band.set_point_position(1, Vector2.ZERO)

	var launch_vel: Vector2 = -clamped_pull * launch_force_multiplier
	# Notify Valli AI of aiming vector
	get_tree().call_group("valli_targets", "on_player_aiming", global_position, launch_vel)

func _end_drag() -> void:
	if not _is_dragging:
		return
	_is_dragging = false
	DialogueManager.stop_drag()

	trajectory_line.visible = false
	elastic_band.visible = false

	var raw_pull: Vector2 = global_position - _anchor_world
	if raw_pull.length() < 8.0:
		# Negligible pull — don't launch
		_snap_back_to_anchor()
		return

	# Advance drag sound index so next chance plays alternating drag audio
	DialogueManager.advance_drag_index()

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
	_falling = false
	_caught = false
	GameState.register_launch()
	player_launched.emit(velocity)
	reset_timer.start()

# ─── Collision & Fall Handling ────────────────────────────────────────────────
func _on_body_entered(body: Node) -> void:
	if not _launched or _falling or _caught:
		return

	# fall.mpeg should ONLY be played after hitting the rubber tree!
	if body.is_in_group("rubber_trees"):
		DialogueManager.play_fall()
		if body.has_method("trigger_bounce_effect"):
			body.trigger_bounce_effect(global_position)
		return

	# When stickman hits ground/obstacle without hitting Valli
	if not body.is_in_group("valli_targets"):
		_handle_fall()

func _handle_fall() -> void:
	if _falling or _caught or not _launched:
		return
	_falling = true
	_launched = false

	# Freeze motion cleanly
	var t_freeze := get_tree().create_timer(0.2)
	t_freeze.timeout.connect(func():
		set_deferred("freeze", true)
		set_deferred("linear_velocity", Vector2.ZERO)
		set_deferred("angular_velocity", 0.0)
	)

	# Register miss and play corresponding miss dialogue after short gap
	var t_dialogue := get_tree().create_timer(0.3)
	t_dialogue.timeout.connect(func():
		if not _caught:
			GameState.register_miss()
			DialogueManager.play_miss(GameState.level_pani_kitti)
	)

	# Allow sufficient time for the dialogue audio to play before resetting
	var t_reset := get_tree().create_timer(2.2)
	t_reset.timeout.connect(func():
		if not _caught:
			_trigger_reset()
	)

func handle_bus_hit() -> void:
	if _falling or _caught or not _launched:
		return
	_falling = true
	_launched = false

	# Freeze motion cleanly
	set_deferred("freeze", true)
	set_deferred("linear_velocity", Vector2.ZERO)
	set_deferred("angular_velocity", 0.0)

	# Register miss (deducts 1 health) without playing general miss dialogue
	GameState.register_miss()

	# Allow sufficient time for the bus hit audio to finish before resetting
	var t_reset := get_tree().create_timer(2.4)
	t_reset.timeout.connect(func():
		if not _caught:
			_trigger_reset()
	)

# ─── Movement / Stop Checks ───────────────────────────────────────────────────
func _physics_process(_delta: float) -> void:
	if not _launched or _falling or _caught:
		return

	# Check screen bounds
	var vp := get_viewport_rect()
	if global_position.x < -screen_bounds_margin \
	   or global_position.x > vp.size.x + screen_bounds_margin \
	   or global_position.y > vp.size.y + screen_bounds_margin:
		_handle_fall()

func _check_stop_and_reset() -> void:
	if _launched and not _falling and not _caught:
		if linear_velocity.length() < stop_velocity_threshold:
			_handle_fall()
		else:
			reset_timer.start()

func _trigger_reset() -> void:
	_launched = false
	_falling = false
	set_deferred("freeze", true)
	set_deferred("linear_velocity", Vector2.ZERO)
	set_deferred("angular_velocity", 0.0)
	set_deferred("global_position", _anchor_world)
	projectile_reset.emit()

# ─── External API ─────────────────────────────────────────────────────────────
func set_monsoon(monsoon_node: Node) -> void:
	_monsoon = monsoon_node

func register_valli_caught() -> void:
	_caught = true
	_launched = false
	_falling = false
	set_deferred("freeze", true)
	set_deferred("linear_velocity", Vector2.ZERO)
	set_deferred("angular_velocity", 0.0)
	valli_caught.emit()
