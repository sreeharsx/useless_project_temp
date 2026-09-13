## Level10.gd — Meta Ending Stage: Golden Valli, all hazards
## Catching the golden Valli triggers the meta ending sequence.

extends "res://scenes/levels/LevelBase.gd"

func _ready() -> void:
	super._ready()
	# Enable golden effect on Valli
	var vallis := get_tree().get_nodes_in_group("valli_targets")
	for v in vallis:
		v.is_golden = true
		if v.has_method("_apply_golden_effect"):
			v._apply_golden_effect()

	if hud:
		hud.show_popup("✨ The Golden Valli. End this.", Color(1.0, 0.9, 0.2))

func _on_level_complete(_level_num: int) -> void:
	# Override — go directly to meta ending
	# (LevelManager handles this for level 10 automatically)
	pass
