## Level06.gd — KSRTC Bus hazard introduced
extends "res://scenes/levels/LevelBase.gd"

func _ready() -> void:
	super._ready()
	if hud:
		hud.show_popup("KSRTC Bus incoming! Don't get hit!", Color(1.0, 0.5, 0.2))
