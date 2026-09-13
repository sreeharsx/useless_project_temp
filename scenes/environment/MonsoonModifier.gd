## MonsoonModifier.gd
## Environmental node that adds rain particle effect and launch angle deviation.
## Add to a level scene to enable monsoon physics for that level.
##
## Node structure:
##   MonsoonModifier (Node2D)
##   └── RainParticles (CPUParticles2D)

extends Node2D

# ─── Export ───────────────────────────────────────────────────────────────────
@export var deviation_min_deg: float = 2.0
@export var deviation_max_deg: float = 5.0
@export var active: bool = true

# ─── Nodes ────────────────────────────────────────────────────────────────────
@onready var rain_particles: CPUParticles2D = $RainParticles

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	if active:
		_setup_rain()
		rain_particles.emitting = true
		# Register with PlayerHand in scene
		call_deferred("_register_with_player")

func _setup_rain() -> void:
	rain_particles.amount = 300
	rain_particles.lifetime = 1.2
	rain_particles.direction = Vector2(0.15, 1.0)   # Slight wind angle
	rain_particles.spread = 5.0
	rain_particles.gravity = Vector2(50, 980)
	rain_particles.initial_velocity_min = 400.0
	rain_particles.initial_velocity_max = 600.0
	rain_particles.scale_amount_min = 0.3
	rain_particles.scale_amount_max = 0.6
	rain_particles.color = Color(0.6, 0.75, 1.0, 0.6)

	# Cover entire viewport
	var vp := get_viewport_rect()
	rain_particles.position = Vector2(vp.size.x * 0.5, -50)
	rain_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain_particles.emission_rect_extents = Vector2(vp.size.x * 0.6, 10)

func _register_with_player() -> void:
	var players := get_tree().get_nodes_in_group("slingshot")
	for p in players:
		if p.has_method("set_monsoon"):
			p.set_monsoon(self)

# ─── Public API ───────────────────────────────────────────────────────────────
func get_angle_deviation() -> float:
	"""Returns a random signed angle deviation in degrees."""
	var magnitude := randf_range(deviation_min_deg, deviation_max_deg)
	var sign_val := 1.0 if randf() > 0.5 else -1.0
	return magnitude * sign_val

func set_active(value: bool) -> void:
	active = value
	rain_particles.emitting = value
	if not value:
		var players := get_tree().get_nodes_in_group("slingshot")
		for p in players:
			if p.has_method("set_monsoon"):
				p.set_monsoon(null)
