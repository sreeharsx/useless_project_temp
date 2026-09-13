## Level04.gd — Monsoon introduction: rain + slippery controls
extends "res://scenes/levels/LevelBase.gd"

func _ready() -> void:
	super._ready()
	if hud:
		hud.show_popup("⛈ Monsoon! Controls will slip!", Color(0.5, 0.7, 1.0))
