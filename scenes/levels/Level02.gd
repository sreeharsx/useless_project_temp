## Level02.gd — Rubber Estate: One rubber tree as cover
extends "res://scenes/levels/LevelBase.gd"

func _ready() -> void:
	super._ready()
	if hud:
		hud.show_popup("Bounce off the rubber tree!", Color(0.4, 1.0, 0.4))
