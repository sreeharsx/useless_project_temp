## RubberTree.gd
## StaticBody2D rubber tree obstacle with high-bounce physics material.
## Projectiles bounce off cleanly — perfect for bank shots.
##
## Node structure:
##   RubberTree (StaticBody2D)
##   ├── CollisionShape2D (CapsuleShape2D — trunk)
##   ├── CollisionShape2D (CircleShape2D — canopy, no collision mask)
##   ├── Sprite2D (tree graphic)
##   └── BounceParticles (CPUParticles2D)

extends StaticBody2D

# ─── Export ───────────────────────────────────────────────────────────────────
@export var bounce_value: float = 0.85

# ─── Nodes ────────────────────────────────────────────────────────────────────
@onready var bounce_particles: CPUParticles2D = $BounceParticles

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Apply physics material with high bounce
	var mat := PhysicsMaterial.new()
	mat.bounce = bounce_value
	mat.friction = 0.1
	physics_material_override = mat

	bounce_particles.one_shot = true
	bounce_particles.emitting = false

# ─── Called when a RigidBody2D hits this body ─────────────────────────────────
# Connect via body_entered signal on an adjacent Area2D, or use
# the built-in _integrate_forces contact monitor on the projectile.
func trigger_bounce_effect(contact_pos: Vector2) -> void:
	bounce_particles.global_position = contact_pos
	bounce_particles.emitting = true
	# Slight tree sway tween
	var tween := create_tween()
	tween.tween_property(self, "rotation_degrees", 3.0, 0.1)
	tween.tween_property(self, "rotation_degrees", -3.0, 0.1)
	tween.tween_property(self, "rotation_degrees", 0.0, 0.1)
