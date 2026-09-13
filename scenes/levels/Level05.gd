## Level05.gd — Monsoon + rubber trees combined
extends "res://scenes/levels/LevelBase.gd"

func _ready() -> void:
	super._ready()
	if hud:
		hud.show_popup("Rain + Trees. Good luck.", Color(0.5, 0.8, 1.0))
