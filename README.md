<img width="1280" height="640" alt="git (1)" src="https://github.com/user-attachments/assets/8920b256-2ba8-4988-b824-5351134eb4bd" />

# VALLIPIDUTHAM 🎯

## DEPLOY/DEMO VID
https://drive.google.com/file/d/1FQBKySbQezs-7FKz9juXMrZrSreAdWRZ/view?usp=sharing

## Basic Details

### Team Name: Error 404

### Team Members
- Member 1: Sreeharsh G - Mar Athanasius College of Engineering Kothamangalam
- Member 2: Meera V R - Mar Athanasius College of Engineering Kothamangalam

### Project Description
Valli Pidutham (വള്ളിപിടുത്തം) is a hilarious 2D physics-based slingshot comedy game built in Godot 4.x. Players launch a stickman with a slingshot to catch an elusive, sentient green vine ("Valli") that flees, taunts, and dodges across 10 chaotic levels packed with KSRTC buses, rubber trees, monsoon rain, and authentic Malayalam voice roasts.

### The Problem (that doesn't exist)
In everyday life, things can sometimes become too peaceful and comfortable. Human beings have an innate, inexplicable urge to actively seek out unwanted trouble and headaches ("വള്ളി ഇരന്നു വാങ്ങുക"), but until now, there was no dedicated digital simulator to experience the pure joy of inviting catastrophe upon oneself.

### The Solution (that nobody asked for)
We built a game literally based on the Malayalam idiom **"വള്ളിപിടുത്തം"**! Instead of avoiding trouble, players aggressively fling themselves at it. Featuring responsive AI evasion, alternating slingshot drag sounds, bounce mechanics off rubber trees, high-speed KSRTC bus hazards, dynamic health/tries tracking, and a legendary Golden Valli boss encounter.

---

## Technical Details

### Technologies/Components Used

#### For Software:
- **Languages used**: GDScript, Python
- **Frameworks used**: Godot Engine 4.x (GL Compatibility / 2D Physics Engine)
- **Audio & Assets**: 
  - Malayalam Voice Clips (`miss_01`–`05`, `bus_hit_01`–`02`, `victory`)
  - Sound Effects (`drag`, `drag01`, `fall`, `disappear`)
  - Typography: Google Fonts **Manjari-Bold** (Malayalam Unicode support with high-contrast text outlines and drop shadows)
- **Tools used**: Godot 4.x Editor, Git, GitHub

---

### Implementation
For Software:

# Installation

#### 📦 Option 1: Standalone Windows Release (No Godot Required — Recommended)
Download the pre-compiled standalone release directly from GitHub:
- **Direct Link**: **[Download Latest Release (v1.0)](https://github.com/sreeharsx/useless_project_temp/releases)**

**Release Package Contents:**
| File | Description |
|---|---|
| `vallipidutham.exe` (~100 MB) | **Main Game Executable**: Double-click to launch and play directly. |
| `vallipidutham.pck` (~14 MB) | **Game Resource Pack**: Contains all 10 levels, Malayalam voice acting, sounds, and assets. *(Must remain in the same folder as the `.exe`)* |
| `vallipidutham.console.exe` (~161 KB) | **Debug Launcher**: Optional launcher that opens a command-line terminal alongside the game to view debug logs. |

**Installation Steps:**
1. Head to **[Releases](https://github.com/sreeharsx/useless_project_temp/releases)** and download **`vallipidutham.zip`** (or download the files directly).
2. Right-click `vallipidutham.zip` and select **Extract All...** to any folder on your computer (e.g. Desktop or Downloads).
3. Ensure that `vallipidutham.exe` and `vallipidutham.pck` are located in the **same directory**.

---

#### 🛠️ Option 2: Run from Source (For Developers)
1. Clone this repository:
   ```bash
   git clone https://github.com/sreeharsx/useless_project_temp.git
   cd useless_project_temp
   ```
2. Download and install **Godot Engine 4.x** (Standard 64-bit) from [godotengine.org](https://godotengine.org/).

---

# Run

#### 🎮 To Play the Standalone Game:
1. Navigate to your extracted folder.
2. Double-click **`vallipidutham.exe`** to start playing immediately!
3. *(Optional)* If you need to view developer logs or error output, launch **`vallipidutham.console.exe`**.

#### 🛠️ To Run with Godot Editor:
1. Open Godot Engine 4.x.
2. Click **Import**, browse to the cloned `useless_project_temp` folder, and select `project.godot`.
3. Click **Import & Edit**.
4. Press **F5** (or click the **Play** button in the top right) to run the project.

---

## 🎮 Gameplay Features & Mechanics

### 1. ❤️ 5 Health / Tries System
- Players receive **5 tries (Health: ❤️❤️❤️❤️❤️)** per level.
- Each missed shot or hazard collision deducts 1 health (`🖤`).
- If all 5 attempts are exhausted, the game prompts *"💔 5 Tries Over! Returning to Level 1..."* and resets progress back to Level 1.
- Clearing a level replenishes health back to 5 for the next stage.

### 2. 🏹 Authentic Slingshot Controls & Alternating Audio
- **No Trajectory Line**: Aiming relies purely on the visual pull and tension of the elastic rubber band for a raw, skill-based arcade feel.
- **Alternating Drag Sounds**: Pulling the slingshot alternates between `drag.mpeg` and `drag01.mpeg` with an authentic release break between shots.
- **Instant Cutoff**: Starting the next pull immediately silences any lingering voice lines from previous attempts so dialogues never overlap.

### 3. 🔊 Reactive Audio & Malayalam Dialogue Progression
- **Rubber Tree Impact (`fall.mpeg`)**: Triggers exclusively when the projectile collides with and bounces off rubber trees.
- **KSRTC Bus Crash (`bus_hit_01` / `bus_hit_02`)**: Dedicated collision audio when smashed by oncoming Kerala state transport buses.
- **Valli Movement (`disappear.mpeg`)**: Plays when Valli dashes or flees to a new spot.
- **Dynamic Miss Roasts**:
  - **1st Miss**: Randomly plays `miss_01.mpeg` or `miss_02.mpeg`.
  - **2nd & 3rd Miss**: Plays `miss_03.mpeg`.
  - **4th & 5th Miss**: Plays `miss_05.mpeg`.

### 4. 🏆 Final Golden Valli & Victory Screen
- Catching the elusive **Golden Valli** on Level 10 triggers an unmissable, celebratory Victory Screen with stats (shots fired, fails), trophy animations, and Malayalam fanfare: **"🎉 വിജയം! വള്ളി പിടിച്ചു! 🎉"**.

---

## 🎭 Level Progression

| Level | Hazards & Obstacles | Valli AI Behavior | Theme / Challenge |
|---|---|---|---|
| **1** | None | IDLE | Slingshot Tutorial |
| **2** | 1 Rubber Tree | IDLE | Bank shots & tree bounce |
| **3** | 2 Rubber Trees | OTTAM from start | Evasive target |
| **4** | Monsoon Rain | Reactive AI | Slippery angle deviation |
| **5** | Monsoon + 2 Trees | Reactive AI | Combined obstacles |
| **6** | 1 KSRTC Bus | Full AI | Moving traffic hazard |
| **7** | 2 KSRTC Buses | Full AI | Crossing traffic from both sides |
| **8** | Rain + Trees + Bus | Full AI | Absolute Kerala road chaos |
| **9** | Super Fast Bus & Hazards | Aggressive | Rapid dodging AI |
| **10** | Maximum Chaos | Golden Valli | Final Victory Stage |

---

## 🧠 Valli AI State Machine

```
IDLE ──[Player Aims Nearby]──► OTTAM (Flee & Dodge)
  ▲                                │
  └──[Aim Released / Far]─────────┘
  
IDLE / OTTAM ──[Player Launches]──► PATTIKKAL (Disappear & Dash)
  ▲                                       │
  └──[Dash Complete]──────────────────────┘
  
ANY ──[Consecutive Misses]──► TAUNT (Mocking Shakes)
  ▲                                 │
  └──[Timer Expiry]─────────────────┘
```

---

## Project Documentation

### Screenshots

1. **Main Menu**: Malayalam title "വള്ളിപിടുത്തം" with animated vine background.
 <img width="1283" height="753" alt="MENU" src="https://github.com/user-attachments/assets/3154d18b-e23f-4c29-b079-56fd17acb903" />
2. **Gameplay**: Slingshot aiming with elastic band, Kerala rubber trees, and glassmorphic HUD.
<img width="1277" height="750" alt="2" src="https://github.com/user-attachments/assets/2732d593-9db0-4d74-96c3-d1c7865b9eec" />
<img width="1277" height="752" alt="3" src="https://github.com/user-attachments/assets/7eae1086-daf3-47d2-b615-a7c5eb528d76" />


3. **Level 10 Victory Screen**: Golden Valli trophy with celebratory stats and Malayalam victory banner.

---

## Team Contributions
- **Sreeharsh G**: Game design, Godot physics engine integration, slingshot mechanics, Valli AI state machine, level hazard implementations, and audio management pipeline.
- **Meera V R**: UI/UX design, visual asset preparation, Malayalam typography and theme styling, dialogue audio curation, and project documentation.

---

Made with ❤️ at TinkerHub Useless Projects 

![Static Badge](https://img.shields.io/badge/TinkerHub-24?color=%23000000&link=https%3A%2F%2Fwww.tinkerhub.org%2F)
![Static Badge](https://img.shields.io/badge/UselessProjects--26-26?link=https%3A%2F%2Ftinkerhub.org%2Fevents%2F1M8ORET9A1%2Fuseless-projects-3.0)
