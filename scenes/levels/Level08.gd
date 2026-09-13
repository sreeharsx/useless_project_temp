## Level08.gd — Combined chaos: Rain + Trees + Bus + Fake-out Valli
extends "res://scenes/levels/LevelBase.gd"

func _ready() -> void:
	super._ready()
	if hud:
		hud.show_popup("Absolute chaos. ഇതു ജീവിതം.", Color(0.9, 0.2, 0.9))
