## Level03.gd — Rubber Estate: Two trees, Valli in OTTAM state from start
extends "res://scenes/levels/LevelBase.gd"

func _ready() -> void:
	super._ready()
	# Valli starts in OTTAM state immediately
	var vallis := get_tree().get_nodes_in_group("valli_targets")
	for v in vallis:
		if v.has_node("ValliStateController"):
			v.get_node("ValliStateController").current_state = \
				v.get_node("ValliStateController").ValliState.OTTAM
