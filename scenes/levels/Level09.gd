## Level09.gd — Full chaos with faster bus and aggressive Valli AI
extends "res://scenes/levels/LevelBase.gd"

func _ready() -> void:
	super._ready()
	# Speed up bus
	var buses := get_tree().get_nodes_in_group("ksrtc_buses")
	for bus in buses:
		bus.travel_speed = 380.0
	# Speed up Valli flee
	var vallis := get_tree().get_nodes_in_group("valli_targets")
	for v in vallis:
		if v.has_node("ValliStateController"):
			v.get_node("ValliStateController").flee_speed = 280.0

	if hud:
		hud.show_popup("The Valli is ANGRY. RUN.", Color(1.0, 0.2, 0.2))
