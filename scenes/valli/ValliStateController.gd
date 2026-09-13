## ValliStateController.gd
## Finite State Machine controller for the Valli target.
## States: IDLE → OTTAM (flee) → PATTIKKAL (fake-out) → TAUNT
## Attach to ValliTarget (Area2D) or call from it.

class_name ValliStateController
extends Node

# ─── Signals ───────────────────────────────────────────────────────────────────
signal state_changed(old_state: int, new_state: int)
signal pattikkal_executed(dash_to: Vector2)
signal taunt_started()
signal taunt_ended()

# ─── State Enum ───────────────────────────────────────────────────────────────
enum ValliState {
	IDLE       = 0,
	OTTAM      = 1,   # Flee
	PATTIKKAL  = 2,   # Fake-out
	TAUNT      = 3,   # Mock taunt
}

# ─── Export configuration ─────────────────────────────────────────────────────
@export var evasion_radius: float = 300.0          # Radius within which aim triggers OTTAM
@export var flee_speed: float = 160.0
@export var sine_amplitude: float = 50.0
@export var sine_frequency: float = 2.5
@export var pattikkal_dash_speed: float = 450.0
@export var pattikkal_dash_distance: float = 180.0
@export var taunt_shake_amplitude: float = 8.0
@export var taunt_shake_speed: float = 15.0
@export var taunt_trigger_miss_count: int = 3

# ─── Playable boundary (world coordinates, 1280×720 viewport) ─────────────────
# Valli's sprite is ~88px at scale 0.07 (1254px * 0.07 ≈ 88). Half = 44.
# Keep Valli fully visible and away from slingshot area.
const PLAY_LEFT:   float = 380.0    # Right of slingshot area
const PLAY_RIGHT:  float = 1220.0   # Left of right edge
const PLAY_TOP:    float = 80.0     # Below HUD
const PLAY_BOTTOM: float = 670.0    # Above ground (ground at y=718)

# ─── Internal ─────────────────────────────────────────────────────────────────
var current_state: ValliState = ValliState.IDLE
var _owner_node: Node2D           # The ValliTarget Area2D
var _flee_direction: Vector2 = Vector2.ZERO
var _flee_time: float = 0.0
var _pattikkal_target: Vector2 = Vector2.ZERO
var _is_dashing: bool = false
var _taunt_time: float = 0.0
var _base_position: Vector2 = Vector2.ZERO
var _last_player_launch_vel: Vector2 = Vector2.ZERO
var _position_ready: bool = false   # True once spawn position is confirmed

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_owner_node = get_parent() as Node2D
	# Defer _base_position initialization so the level scene has fully applied
	# the ValliTarget's spawn position before we read global_position.
	call_deferred("_init_position")
	call_deferred("_connect_signals")

func _init_position() -> void:
	_base_position = _owner_node.global_position
	# Safety check: warn if Valli spawned outside play area
	if not _is_in_bounds(_base_position):
		push_warning("ValliStateController: spawn position %s is outside play area — clamping." % _base_position)
		_base_position = _clamp_to_bounds(_base_position)
		_owner_node.global_position = _base_position
	_position_ready = true

func _connect_signals() -> void:
	# Find PlayerHand in scene and connect its signal
	var players := get_tree().get_nodes_in_group("slingshot")
	for p in players:
		if p.has_signal("player_launched"):
			if not p.player_launched.is_connected(_on_player_launched):
				p.player_launched.connect(_on_player_launched)

# ─── Public API ───────────────────────────────────────────────────────────────
func on_player_aiming(player_pos: Vector2, aim_vel: Vector2) -> void:
	"""Called every frame while player drags. Checks evasion radius."""
	if current_state == ValliState.TAUNT:
		return
	if current_state == ValliState.PATTIKKAL:
		return

	# Predict landing point from player position
	var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0))
	var landing := _predict_landing(player_pos, aim_vel, gravity)
	var dist_to_landing := (_owner_node.global_position - landing).length()

	if dist_to_landing < evasion_radius:
		# Calculate flee direction away from landing point
		_flee_direction = (_owner_node.global_position - landing).normalized()
		if _flee_direction == Vector2.ZERO:
			_flee_direction = Vector2(1, 0)
		_change_state(ValliState.OTTAM)
	else:
		if current_state == ValliState.OTTAM:
			_change_state(ValliState.IDLE)

func trigger_taunt() -> void:
	if current_state != ValliState.TAUNT:
		_change_state(ValliState.TAUNT)

func trigger_idle() -> void:
	_change_state(ValliState.IDLE)

# ─── Physics Update ───────────────────────────────────────────────────────────
func process_movement(delta: float) -> void:
	# Do not move until spawn position has been confirmed via _init_position
	if not _position_ready:
		return
	match current_state:
		ValliState.IDLE:
			_process_idle(delta)
		ValliState.OTTAM:
			_process_ottam(delta)
		ValliState.PATTIKKAL:
			_process_pattikkal(delta)
		ValliState.TAUNT:
			_process_taunt(delta)

func _process_idle(_delta: float) -> void:
	# Subtle vertical wiggle driven by code (not animation) to preserve spawn position
	var wiggle := sin(Time.get_ticks_msec() * 0.003) * 3.0
	_owner_node.global_position = _base_position + Vector2(0, wiggle)

func _process_ottam(delta: float) -> void:
	_flee_time += delta
	# Sine-wave lateral drift during flee
	var perp := _flee_direction.rotated(PI * 0.5)
	var lateral := sin(_flee_time * sine_frequency) * sine_amplitude
	var move := (_flee_direction * flee_speed + perp * lateral) * delta
	var new_pos := _owner_node.global_position + move
	# Clamp so Valli never leaves the play area
	new_pos = _clamp_to_bounds(new_pos)
	_owner_node.global_position = new_pos
	_base_position = new_pos  # update base so idle doesn't snap back
	# If Valli hits a boundary while fleeing, reverse the flee direction on that axis
	if new_pos.x <= PLAY_LEFT or new_pos.x >= PLAY_RIGHT:
		_flee_direction.x = -_flee_direction.x
	if new_pos.y <= PLAY_TOP or new_pos.y >= PLAY_BOTTOM:
		_flee_direction.y = -_flee_direction.y

func _process_pattikkal(delta: float) -> void:
	if not _is_dashing:
		return
	var dist := _owner_node.global_position.distance_to(_pattikkal_target)
	if dist < 5.0:
		var final_pos := _clamp_to_bounds(_pattikkal_target)
		_owner_node.global_position = final_pos
		_base_position = final_pos
		_is_dashing = false
		_change_state(ValliState.IDLE)
	else:
		var dir := (_pattikkal_target - _owner_node.global_position).normalized()
		var new_pos := _owner_node.global_position + dir * pattikkal_dash_speed * delta
		_owner_node.global_position = _clamp_to_bounds(new_pos)

func _process_taunt(delta: float) -> void:
	_taunt_time += delta
	var shake := sin(_taunt_time * taunt_shake_speed) * taunt_shake_amplitude
	_owner_node.global_position = _clamp_to_bounds(_base_position + Vector2(shake, 0))

# ─── State Transitions ────────────────────────────────────────────────────────
func _change_state(new_state: ValliState) -> void:
	if new_state == current_state:
		return
	var old := current_state
	current_state = new_state
	_on_state_exit(old)
	_on_state_enter(new_state)
	state_changed.emit(old, new_state)

func _on_state_enter(state: ValliState) -> void:
	match state:
		ValliState.IDLE:
			_flee_time = 0.0
		ValliState.OTTAM:
			_flee_time = 0.0
			DialogueManager.play_disappear()
		ValliState.PATTIKKAL:
			_execute_pattikkal()
		ValliState.TAUNT:
			_taunt_time = 0.0
			_base_position = _owner_node.global_position
			taunt_started.emit()

func _on_state_exit(state: ValliState) -> void:
	match state:
		ValliState.TAUNT:
			taunt_ended.emit()

# ─── Pattikkal (Fake-out) ─────────────────────────────────────────────────────
func _execute_pattikkal() -> void:
	# Dash diagonally to a random nearby anchor — clamped to play area
	var angle := randf_range(0.0, TAU)
	var raw_target := _base_position + Vector2(cos(angle), sin(angle)) * pattikkal_dash_distance
	_pattikkal_target = _clamp_to_bounds(raw_target)
	_is_dashing = true
	DialogueManager.play_disappear()
	pattikkal_executed.emit(_pattikkal_target)

func _on_player_launched(velocity: Vector2) -> void:
	_last_player_launch_vel = velocity
	if current_state != ValliState.TAUNT:
		_change_state(ValliState.PATTIKKAL)

# ─── Helper: Landing Prediction ───────────────────────────────────────────────
func _predict_landing(start: Vector2, vel: Vector2, gravity: float) -> Vector2:
	"""Simple ballistic landing estimate (when y-velocity would bring it to ground level)."""
	if vel.y >= 0:
		# Already going down — estimate ground as viewport height
		return start + vel * 0.5
	# t when vertical component brings y to ~viewport bottom
	var vp_h := float(ProjectSettings.get_setting("display/window/size/viewport_height", 720))
	var dy := vp_h - start.y
	# dy = vy*t + 0.5*g*t^2 → solve quadratic
	var a := 0.5 * gravity
	var b := vel.y
	var c := -dy
	var disc := b * b - 4 * a * c
	if disc < 0:
		return start + vel * 1.0
	var t := (-b + sqrt(disc)) / (2 * a)
	if t < 0:
		t = (-b - sqrt(disc)) / (2 * a)
	t = max(t, 0.0)
	return start + Vector2(vel.x * t, vel.y * t + 0.5 * gravity * t * t)

# ─── Boundary Helpers ─────────────────────────────────────────────────────────
func _clamp_to_bounds(pos: Vector2) -> Vector2:
	return Vector2(
		clampf(pos.x, PLAY_LEFT, PLAY_RIGHT),
		clampf(pos.y, PLAY_TOP, PLAY_BOTTOM)
	)

func _is_in_bounds(pos: Vector2) -> bool:
	return pos.x >= PLAY_LEFT and pos.x <= PLAY_RIGHT \
		and pos.y >= PLAY_TOP and pos.y <= PLAY_BOTTOM
