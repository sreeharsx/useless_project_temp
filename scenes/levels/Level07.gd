## Level07.gd — Two KSRTC Buses crossing in opposite directions
extends "res://scenes/levels/LevelBase.gd"

func _ready() -> void:
	super._ready()
	if hud:
		hud.show_popup("TWO Buses. കഷ്ടം!", Color(1.0, 0.3, 0.2))
