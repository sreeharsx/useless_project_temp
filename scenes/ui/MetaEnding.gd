## MetaEnding.gd
## Celebratory Game Complete screen shown when Level 10 Golden Valli is caught.

extends Control

# ─── Nodes ────────────────────────────────────────────────────────────────────
@onready var victory_card: PanelContainer = $CenterContainer/VictoryCard
@onready var stats_label: Label = $CenterContainer/VictoryCard/VBoxContainer/StatsLabel
@onready var restart_btn: Button = $CenterContainer/VictoryCard/VBoxContainer/ButtonRow/RestartBtn
@onready var menu_btn: Button = $CenterContainer/VictoryCard/VBoxContainer/ButtonRow/MenuBtn
@onready var trophy: TextureRect = $CenterContainer/VictoryCard/VBoxContainer/TrophyTexture

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Ensure master audio is unmuted and at full volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), 0.0)

	# Populate stats
	stats_label.text = "🏆 All 10 Levels Completed!\n🎯 Total Shots: %d   |   💥 Pani Kitti: %d" % [
		GameState.total_shots_fired,
		GameState.total_pani_kitti
	]

	# Connect buttons
	restart_btn.pressed.connect(_on_restart_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)

	# Victory celebration animation
	_animate_victory()

	# Play victory dialogue audio
	DialogueManager.play_dialogue("VICTORY")

func _animate_victory() -> void:
	victory_card.scale = Vector2(0.6, 0.6)
	victory_card.pivot_offset = victory_card.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(victory_card, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Gentle trophy floating bob
	var t := create_tween().set_loops()
	t.tween_property(trophy, "position:y", trophy.position.y - 8.0, 1.2).set_trans(Tween.TRANS_SINE)
	t.tween_property(trophy, "position:y", trophy.position.y + 8.0, 1.2).set_trans(Tween.TRANS_SINE)

# ─── Button Actions ───────────────────────────────────────────────────────────
func _on_restart_pressed() -> void:
	GameState.full_reset()
	LevelManager.load_level(1)

func _on_menu_pressed() -> void:
	GameState.full_reset()
	LevelManager.go_to_main_menu()
