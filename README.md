# Valli Pidutham — വള്ളിപിടുത്തം
### A 2D Physics-Based Slingshot Comedy Game in Godot 4.x

> **"Inviting unwanted trouble"** — turned into the most frustratingly funny arcade experience.

---

## 🎮 Game Concept

You wield a slingshot. The target is a **sentient, elusive vine** ("Valli") that:
- Flees when it detects your aim
- Fakes you out the moment you release
- Taunts you after 3 consecutive misses
- Dodges KSRTC buses better than you do

Catch the Valli. Survive 10 levels. Meet your fate.

---

## 📁 Project Structure

```
Valli catcher/
├── project.godot              ← Open this in Godot 4.x
├── icon.svg
├── autoloads/
│   ├── GameState.gd           ← Persistent state & save system
│   ├── DialogueManager.gd     ← Audio bus, overlap protection, subtitles
│   └── LevelManager.gd        ← Level loading & transition
├── scenes/
│   ├── main/
│   │   ├── MainMenu.tscn / .gd
│   ├── player/
│   │   ├── PlayerHand.tscn / .gd  ← Slingshot RigidBody2D
│   ├── valli/
│   │   ├── ValliTarget.tscn / .gd
│   │   └── ValliStateController.gd ← FSM: IDLE/OTTAM/PATTIKKAL/TAUNT
│   ├── hazards/
│   │   ├── RubberTree.tscn / .gd
│   │   └── KSRTCBus.tscn / .gd
│   ├── environment/
│   │   └── MonsoonModifier.tscn / .gd
│   ├── ui/
│   │   ├── HUD.tscn / .gd
│   │   └── MetaEnding.tscn / .gd
│   └── levels/
│       ├── LevelBase.tscn / .gd
│       └── Level01–10.tscn / .gd
└── assets/
    ├── audio/dialogue/        ← Add .ogg files here (see below)
    ├── fonts/                 ← Add Manjari/Chilanka .ttf here
    └── sprites/               ← Add sprite PNGs here
```

---

## 🚀 Getting Started

### 1. Open in Godot 4.x
```
File → Open Project → select project.godot
```

### 2. Add Required Assets

#### Fonts (Malayalam support required)
Download from Google Fonts and place in `assets/fonts/`:
- **Manjari** → https://fonts.google.com/specimen/Manjari
- **Chilanka** → https://fonts.google.com/specimen/Chilanka

In Godot: `Import → FontFile`, set as theme default for HUD/popup labels.

#### Audio (Optional but recommended)
Place `.ogg` files in `assets/audio/dialogue/`:

| Filename | Trigger | Suggested Content |
|---|---|---|
| `miss_01.ogg` – `miss_03.ogg` | Player misses shot | "Aiyyo!", "Ivide alla!", "Ithenthu paattiyaa?" |
| `bus_hit_01.ogg` – `bus_hit_02.ogg` | Hit by KSRTC bus | "KSRTC-yle kayiri!", "Oyyyyy BUS!" |
| `tricked_01.ogg` – `tricked_03.ogg` | Valli fake-out | "Ettaaaa! Valli odi!", "Ha! Caught nothing!" |
| `high_deaths_01.ogg` | 10+ fails in level | "Ini nee padam kaanuka..." |
| `victory_01.ogg` | Valli caught | "OTTHO! Pidichi!", "Valli caught!" |

> **Without audio files:** The game still fully works — subtitle text popups appear automatically as fallback via `DialogueManager.SUBTITLE_MAP`.

#### Sprites
Create or source (CC0) PNGs and assign to each scene's `Sprite2D`:
- `hand_projectile.png` (32×32) → PlayerHand/Sprite2D
- `valli_idle.png` (64×64) → ValliTarget/Sprite2D  
- `rubber_tree.png` (80×160) → RubberTree/Sprite2D
- `ksrtc_bus.png` (180×70) → KSRTCBus/Sprite2D

> **Without sprites:** Each node's modulate color acts as a colored placeholder.

### 3. Run the Game
Press `F5` or `Run → Play` in Godot.

---

## 🎭 Level Progression

| Level | Hazards | Valli State | Difficulty |
|-------|---------|-------------|------------|
| 1 | None | IDLE | Tutorial |
| 2 | 1 Rubber Tree | IDLE | Easy |
| 3 | 2 Rubber Trees | OTTAM from start | Easy+ |
| 4 | Monsoon rain | Reactive AI | Medium |
| 5 | Monsoon + 2 Trees | Reactive AI | Medium+ |
| 6 | 1 KSRTC Bus | Full AI | Hard |
| 7 | 2 Buses (opposite) | Full AI | Hard+ |
| 8 | Rain + Trees + Bus | Full AI | Very Hard |
| 9 | All + faster hazards | Aggressive | Brutal |
| 10 | All (maximum) | Golden Valli | Meta Ending |

---

## 🧠 AI State Machine

The Valli FSM (`ValliStateController.gd`) operates across 4 states:

```
IDLE ──[aim enters radius]──► OTTAM (flee, sine-wave movement)
  ▲                               │
  └──[aim exits radius]───────────┘
  
IDLE/OTTAM ──[player_launched signal]──► PATTIKKAL (diagonal dash)
  ▲                                           │
  └──[dash complete]──────────────────────────┘
  
ANY ──[3 consecutive misses]──► TAUNT (mock shake)
  ▲                                   │
  └──[3 second timer]─────────────────┘
```

---

## 🔊 Signal Architecture

| Signal | Emitter | Listeners |
|--------|---------|-----------|
| `player_launched(velocity)` | PlayerHand | ValliStateController, HUD |
| `projectile_reset()` | PlayerHand | LevelBase, HUD |
| `valli_caught(position)` | ValliTarget | LevelManager |
| `bus_collision(position)` | KSRTCBus | LevelManager, HUD |
| `pani_kitti_updated(count)` | GameState | HUD, ValliTarget |
| `level_complete(num)` | LevelManager | LevelBase, HUD |
| `level_failed(num)` | LevelManager | LevelBase |
| `game_complete()` | LevelManager | (triggers MetaEnding) |
| `dialogue_finished(type)` | DialogueManager | HUD (subtitle popup) |

---

## 🎬 Meta Ending (Level 10)

When the Golden Valli is caught:
1. All audio cuts instantly
2. Black overlay fades in
3. Fake Godot engine crash log terminal appears
4. Green typewriter text animates character by character
5. Your total **Pani Kitti Count** (fails) is displayed
6. Restart button appears

---

## 🛠 Architecture Notes

- **Autoloads**: `GameState`, `DialogueManager`, `LevelManager` — always available globally
- **Groups**: `"slingshot"` (PlayerHand), `"valli_targets"` (ValliTarget), `"hud"` (HUD), `"ksrtc_buses"` (KSRTCBus)
- **Save file**: `user://valli_save.cfg` — stores level progress and pani kitti count
- **Physics layers**: Ground/Trees = layer 1, Player = layer 2, Valli = layer 4

---

## 📜 Credits

- **Game Design & Code**: Built with Godot 4.x + GDScript  
- **Font**: Manjari / Chilanka (Google Fonts, OFL License)  
- **Concept**: Malayalam idiom "വള്ളിപിടുത്തം" — inviting your own trouble

---

*"Ningal ithinu irangiyathu enthinu?" — Why did you even start this?*
