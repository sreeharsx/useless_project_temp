## KSRTCBus.gd
## Moving bus obstacle traversing horizontally on a Path2D.
## Colliding with the bus triggers immediate level failure.
##
## Node structure:
##   KSRTCBus (PathFollow2D child inside Path2D)
##     OR use AnimatableBody2D with Tween for simpler setup:
##
##   KSRTCBus (AnimatableBody2D)
##   ├── CollisionShape2D (RectangleShape2D — bus body)
##   ├── Sprite2D          (bus graphic)
##   ├── HazardArea (Area2D) — detects projectile
##   │   └── CollisionShape2D (same rect, slightly larger)
##   └── HornParticles (CPUParticles2D)

extends AnimatableBody2D

# ─── Signals ───────────────────────────────────────────────────────────────────
signal bus_collision(position: Vector2)

# ─── Export ───────────────────────────────────────────────────────────────────
@export var travel_speed: float = 250.0          # Pixels per second
@export var travel_direction: float = 1.0         # 1 = left→right, -1 = right→left
@export var loop: bool = true
@export var horn_interval: float = 8.0            # Seconds between honks

# ─── Nodes ────────────────────────────────────────────────────────────────────
@onready var hazard_area: Area2D = $HazardArea
@onready var horn_particles: CPUParticles2D = $HornParticles
@onready var sprite: Sprite2D = $Sprite2D

# ─── Internal ─────────────────────────────────────────────────────────────────
var _viewport_width: float = 1280.0
var _spawn_x: float = 0.0
var _horn_timer: float = 0.0

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_viewport_width = float(ProjectSettings.get_setting("display/window/size/viewport_width", 1280))
	_spawn_x = global_position.x
	hazard_area.body_entered.connect(_on_hazard_area_body_entered)
	# Flip sprite based on direction
	sprite.flip_h = (travel_direction < 0)

func _physics_process(delta: float) -> void:
	# Move
	global_position.x += travel_speed * travel_direction * delta

	# Horn honk timer
	_horn_timer += delta
	if _horn_timer >= horn_interval:
		_horn_timer = 0.0
		_play_horn()

	# Loop / wrap around screen edges
	if loop:
		if travel_direction > 0 and global_position.x > _viewport_width + 200:
			global_position.x = -200
		elif travel_direction < 0 and global_position.x < -200:
			global_position.x = _viewport_width + 200

# ─── Collision ────────────────────────────────────────────────────────────────
func _on_hazard_area_body_entered(body: Node) -> void:
	if body.is_in_group("slingshot"):
		bus_collision.emit(body.global_position)
		DialogueManager.play_dialogue("BUS_HIT")
		GameState.register_miss()
		LevelManager.notify_level_failed()
		_play_horn()

# ─── VFX ──────────────────────────────────────────────────────────────────────
func _play_horn() -> void:
	horn_particles.emitting = true
	# Screen shake via group call
	get_tree().call_group("hud", "trigger_screen_shake", 8.0, 0.3)
