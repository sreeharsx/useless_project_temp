## ValliTarget.gd
## The main Valli target script. Attached to an Area2D.
## Delegates all AI movement to ValliStateController.
## Detects collision with the player projectile.
##
## Node structure:
##   ValliTarget (Area2D)
##   ├── CollisionShape2D (CircleShape2D radius=30)
##   ├── Sprite2D          (vine / vine-face graphic)
##   ├── AnimationPlayer
##   ├── DustParticles (CPUParticles2D)
##   └── ValliStateController (Node, script=ValliStateController.gd)

extends Area2D

# ─── Signals ───────────────────────────────────────────────────────────────────
signal valli_caught(position: Vector2)

# ─── Export ───────────────────────────────────────────────────────────────────
@export var is_golden: bool = false   # Set true for Level 10 final target

# ─── Nodes ────────────────────────────────────────────────────────────────────
@onready var state_controller: Node = $ValliStateController
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var dust_particles: CPUParticles2D = $DustParticles
@onready var sprite: Sprite2D = $Sprite2D

# ─── Sprite Textures ──────────────────────────────────────────────────────────
const TEX_IDLE: Texture2D = preload("res://assets/sprites/valli_idle.png")
const TEX_FLEE: Texture2D = preload("res://assets/sprites/valli_flee.png")
const TEX_TAUNT: Texture2D = preload("res://assets/sprites/valli_taunt.png")
const TEX_GOLDEN: Texture2D = preload("res://assets/sprites/valli_golden.png")
const TEX_CATCHED: Texture2D = preload("res://assets/sprites/catched.png")

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("valli_targets")
	body_entered.connect(_on_body_entered)

	# Connect state controller signals
	state_controller.state_changed.connect(_on_state_changed)
	state_controller.pattikkal_executed.connect(_on_pattikkal)
	state_controller.taunt_started.connect(_on_taunt_started)

	# Monitor consecutive misses for taunt trigger
	GameState.pani_kitti_updated.connect(_on_pani_kitti_updated)

	sprite.scale = Vector2(0.07, 0.07)
	sprite.modulate = Color.WHITE
	_set_visual_for_state(ValliStateController.ValliState.IDLE)

	if is_golden:
		_apply_golden_effect()
	queue_redraw()

func _draw() -> void:
	if sprite and sprite.texture:
		return
	var body_col := Color(1.0, 0.85, 0.2) if is_golden else Color(0.25, 0.85, 0.35)
	var outline_col := Color(0.7, 0.55, 0.1) if is_golden else Color(0.12, 0.50, 0.20)
	# Body
	draw_circle(Vector2.ZERO, 30.0, body_col)
	draw_arc(Vector2.ZERO, 30.0, 0, TAU, 32, outline_col, 3.5)
	# Big cartoon eyes
	draw_circle(Vector2(-10, -8), 8.0, Color.WHITE)
	draw_circle(Vector2(10, -8), 8.0, Color.WHITE)
	draw_circle(Vector2(-8, -8), 4.0, Color.BLACK)
	draw_circle(Vector2(12, -8), 4.0, Color.BLACK)
	# Smirk mouth
	draw_arc(Vector2(0, 4), 12.0, 0.2, PI - 0.2, 16, Color(0.1, 0.1, 0.1), 2.5)
	# Leaf / stem on top
	draw_line(Vector2(0, -30), Vector2(6, -42), outline_col, 3.0)
	draw_circle(Vector2(6, -42), 5.0, body_col)

func _physics_process(delta: float) -> void:
	state_controller.process_movement(delta)

# ─── External API (called via group) ─────────────────────────────────────────
func on_player_aiming(player_pos: Vector2, aim_vel: Vector2) -> void:
	state_controller.on_player_aiming(player_pos, aim_vel)

# ─── Collision Detection ──────────────────────────────────────────────────────
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("slingshot") and body.get("_launched"):
		_handle_caught(body)

func _handle_caught(projectile: Node) -> void:
	# Disable collisions immediately so it only triggers once
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	var col := get_node_or_null("CollisionShape2D")
	if col:
		col.set_deferred("disabled", true)

	# Notify projectile
	if projectile.has_method("register_valli_caught"):
		projectile.register_valli_caught()

	GameState.register_catch()

	# Stop any playing animation first
	if anim_player.is_playing():
		anim_player.stop()

	# Change texture to caught state
	sprite.texture = TEX_CATCHED
	sprite.modulate = Color.WHITE
	sprite.scale = Vector2(0.07, 0.07)
	sprite.rotation = 0.0

	# Play catch celebration: scale pop + sparkle
	dust_particles.emitting = true
	var catch_tween := create_tween()
	catch_tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.15).set_trans(Tween.TRANS_BACK)
	catch_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BOUNCE)
	catch_tween.tween_interval(0.4)
	catch_tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.35)

	valli_caught.emit(global_position)

	# Play victory audio
	DialogueManager.play_dialogue("VICTORY")

	# Notify level manager
	if is_golden or GameState.current_level >= GameState.MAX_LEVELS:
		LevelManager.notify_game_complete()
	else:
		LevelManager.notify_level_complete()

	# Hide after brief delay
	var t := get_tree().create_timer(1.2)
	t.timeout.connect(func(): queue_free())

# ─── State Visual Reactions ───────────────────────────────────────────────────
func _on_state_changed(_old_state: int, new_state: int) -> void:
	_set_visual_for_state(new_state as ValliStateController.ValliState)

func _set_visual_for_state(state: ValliStateController.ValliState) -> void:
	if anim_player.is_playing():
		anim_player.stop()
	sprite.rotation = 0.0
	sprite.scale = Vector2(0.07, 0.07)

	match state:
		ValliStateController.ValliState.IDLE:
			sprite.texture = TEX_GOLDEN if is_golden else TEX_IDLE
			modulate = Color.WHITE if not is_golden else Color(1.0, 0.9, 0.3)
		ValliStateController.ValliState.OTTAM:
			sprite.texture = TEX_FLEE
			modulate = Color.WHITE
		ValliStateController.ValliState.PATTIKKAL:
			sprite.texture = TEX_FLEE
			modulate = Color.WHITE
		ValliStateController.ValliState.TAUNT:
			sprite.texture = TEX_TAUNT
			modulate = Color.WHITE

func _on_pattikkal(_dash_to: Vector2) -> void:
	dust_particles.global_position = global_position
	dust_particles.emitting = true

func _on_taunt_started() -> void:
	# Play a taunt sound / dialogue
	pass

func _on_pani_kitti_updated(_count: int) -> void:
	# Trigger taunt after consecutive misses in this level
	if GameState.consecutive_misses >= state_controller.taunt_trigger_miss_count:
		if state_controller.current_state != ValliStateController.ValliState.TAUNT:
			state_controller.trigger_taunt()
			# Auto-exit taunt after 3 seconds
			var t := get_tree().create_timer(3.0)
			t.timeout.connect(func(): state_controller.trigger_idle())

func _apply_golden_effect() -> void:
	# Apply a glowing golden modulate — visual effect for Level 10
	modulate = Color(1.0, 0.85, 0.2)
	var tween := create_tween().set_loops()
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 0.5), 0.7)
	tween.tween_property(self, "modulate", Color(0.9, 0.7, 0.1), 0.7)
