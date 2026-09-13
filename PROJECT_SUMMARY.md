# Project Summary: Valli Pidutham (വള്ളിപിടുത്തം)

## 1. Game Concept & Premise
* **Title**: *Valli Pidutham* (വള്ളിപിടുത്തം) — based on the Malayalam idiom meaning *"inviting unwanted trouble"*.
* **Genre**: 2D Physics-based Slingshot Comedy Arcade game in **Godot 4.x (GDScript)**.
* **Core Gameplay**: 
  * The player uses a slingshot drag-and-release mechanism to launch a projectile hand to catch a sentient, elusive vine ("Valli").
  * The Valli actively dodges, taunts in Malayalam, and fakes out the player based on predictive trajectory calculations.
  * Hitting environmental hazards results in comedic failure states ("പണി കിട്ടി" / *Pani Kitti*).
  * Features 10 progressive levels culminating in a meta fourth-wall-breaking finale in Level 10.

---

## 2. Technical Stack & Architecture
* **Engine**: Godot 4.x (Pure GDScript).
* **Workspace Path**: `d:/Valli catcher/`
* **Pattern**: Decoupled, signal-driven architecture without external backend dependencies.
* **Autoload Singletons (`res://autoloads/`)**:
  * `GameState.gd`: Saves/loads player progression, high scores, unlock states, and tracks total *Pani Kitti* count using `ConfigFile`.
  * `DialogueManager.gd`: Manages Malayalam subtitle overlays and dynamic voice/audio lines with anti-overlap queue logic.
  * `ScreenShaker.gd`: Global camera shake utility with intensity falloff for impacts and hazard triggers.

---

## 3. Project File Structure & Key Components

### Player Mechanics (`res://scenes/player/`)
* `PlayerHand.tscn` & `PlayerHand.gd`:
  * Drag-to-aim slingshot system.
  * Parabolic `Line2D` trajectory preview with physics step simulation.
  * Elastic band visual rendering.
  * Force impulse on release, screen-boundary checks, and automatic reset timers.

### Valli Target & AI (`res://scenes/valli/`)
* `ValliTarget.tscn` & `ValliTarget.gd`:
  * Target collision detection, wiggle animations, audio triggers, catch celebrations, and state transitions.
* `ValliStateController.gd` (`class_name ValliStateController`):
  * Finite State Machine (`IDLE`, `OTTAM` [flee], `PATTIKKAL` [fake-out / dash], `TAUNT`).
  * Predicts projectile landing point based on trajectory math and flees if landing falls within evasion radius.

### Hazards (`res://scenes/hazards/`)
* `ElectricWire`: Shocks player hand, triggers screen flash and buzz dialogue.
* `CoconutDrop`: Falling coconuts triggered by proximity or timers.
* `MudPuddle`: Slows down and swallows projectile momentum.
* `BeeHive`: Spawns chasing bees if disturbed.
* `BananaPeel`: Deflects projectile trajectory at unpredictable angles.
* `ChaverDog` & `AmmachiBroom`: Dynamic moving obstacles with patrol logic.

### UI & Menus (`res://scenes/ui/`)
* `HUD.tscn` & `HUD.gd`: Shot counter, score, *Pani Kitti* tally, and Malayalam subtitle banner.
* `MainMenu.tscn`, `LevelSelect.tscn`, `PauseMenu.tscn`, and `GameOverDialog.tscn`.

### Levels (`res://scenes/levels/`)
* Full stage scenes from `Level01.tscn` through `Level10.tscn` (with matching GDScript logic for each stage).
* **Level 10 (Meta Ending)**: Near-black background with golden glow, max-speed hazards, and catching the golden Valli breaks the fourth wall to trigger the satirical comedy credits sequence.

---

## 4. Issues Diagnosed & Resolved

1. **`ValliStateController` Scope Error**:
   * *Issue*: `ValliTarget.gd` threw `Identifier "ValliStateController" not declared in current scope`.
   * *Fix*: Added `class_name ValliStateController` to `res://scenes/valli/ValliStateController.gd`.
2. **`PlayerHand.tscn` Resource Parsing Error**:
   * *Issue*: `Line2D` was declared inside a `[sub_resource]` block in `PlayerHand.tscn` (Godot requires `Line2D` to be a `[node]`).
   * *Fix*: Cleaned `PlayerHand.tscn` header, removed invalid `sub_resource`, and updated `load_steps`.
3. **GDScript Static Type Inference from `Variant`**:
   * *Issue*: Line 72 of `ValliStateController.gd` used `var gravity := ProjectSettings.get_setting(...)`, triggering static type inference errors from `Variant`.
   * *Fix*: Explicitly typed as `var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0))`.

---

## 5. Current Status & Next Steps

* **Current Status**: All 47 core code and scene files are complete. The project opens cleanly in Godot 4.x with zero script compilation errors.
* **Next Implementation Steps**:
  1. **Assets & Sprites**: Replace default placeholder color shapes with real sprite textures (`assets/sprites/` — see `REPLACE_WITH_SPRITES.txt`).
  2. **Typography**: Drop Malayalam fonts (e.g., *Manjari* or *Chilanka*) into `assets/fonts/` for native script rendering.
  3. **Audio**: Drop `.ogg` comedic dialogue lines and sfx into `assets/audio/dialogue/` and `assets/audio/sfx/`.
  4. **Playtesting & Polish**: Run the game (`F5`), verify slingshot drag sensitivity, and tune evasive AI difficulty curve across levels 1–10.
