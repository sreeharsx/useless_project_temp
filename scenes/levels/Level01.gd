## Level01.gd — Tutorial: Static target, no hazards
## Player learns basic slingshot controls.

extends "res://scenes/levels/LevelBase.gd"

func _ready() -> void:
	super._ready()
	if hud and hud.has_method("show_popup"):
		hud.show_popup("Drag & release to catch the Valli!", Color(0.9, 0.9, 0.4))
