## Level10.gd — Meta Ending Stage: Golden Valli, all hazards
## Catching the golden Valli triggers the meta ending sequence.

extends "res://scenes/levels/LevelBase.gd"

func _ready() -> void:
	GameState.current_level = 10
	super._ready()
	# Enable golden effect on Valli
	var vallis := get_tree().get_nodes_in_group("valli_targets")
	for v in vallis:
		v.is_golden = true
		if v.has_method("_apply_golden_effect"):
			v._apply_golden_effect()

func _on_level_complete(_level_num: int) -> void:
	LevelManager.notify_game_complete()

