# Space Trash

Space Trash is a high-octane, top-down "survivors-like" shooter built with the [LÖVE (love2d)](https://love2d.org/) framework. Navigate through asteroid belts and cosmic ruins, collect XP from fallen enemies, and evolve your ship with powerful weapon synergies to survive the onslaught.

## Key Features

- **High-Octane Survival:** Face increasingly difficult waves and epic bosses in timed survival runs.
- **Arsenal & Evolutions:** Master **10 base weapons** and unlock **10 powerful evolutions** through strategic synergies.
- **Deep Customization:** Build your perfect run with **20 unique passive upgrades** across **5 playable ships**.
- **Challenging Encounters:** Battle **6 distinct enemy types** and **3 massive bosses** with multi-phase behaviors.
- **Procedural Visuals:** Unique retro-modern aesthetic using layered vector-style drawing and dynamic glow effects—no external sprite assets for entities.
- **Library & Stats:** Track your progress, view unlocked content, and check your run statistics.

## Getting Started

### Prerequisites

You will need to have [LÖVE](https://love2d.org/) installed on your system. This project is designed for LÖVE 11.x.

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/spacetrash.git
   cd spacetrash
   ```

2. Run the game:
   - **Windows:** Drag the project folder onto `love.exe` or run `love .` from the command line if LÖVE is in your PATH.
   - **macOS:** Run `open -a love .` from the project directory.
   - **Linux:** Run `love .` from the project directory.

## Controls

| Action | Control |
| :--- | :--- |
| **Movement** | WASD or Arrow Keys |
| **Select / Confirm** | Enter or Z |
| **Back / Cancel** | X|
| **Pause Game** | P or Escape |

## Project Structure

The project follows a modular, state-driven architecture:

- `main.lua`: Entry point and initialization.
- `conf.lua`: Window and engine configuration.
- `states/`: Contains logic for different game states (menu, gameplay, game over, library).
- `entities/`: Logic and procedural visuals for players, enemies, bosses, and bullets.
- `systems/`: Core engine components (audio, data loading, screen scaling, particles, saving).
- `data/`: JSON files defining game content and balance.
- `ui/`: Modular UI components and layout systems.
- `assets/`: Game assets including fonts, music, and sound effects.

## Customization & Modding

Since the game is data-driven, you can easily tweak balance or add new content by modifying the JSON files in the `data/` directory.

- `weapons.json`: Define new weapon types and their base stats.
- `enemies.json` / `bosses.json`: Customize enemy behaviors and health.
- `ships.json`: Add new playable ship types.
- `stages.json`: Create new levels with unique enemy sets and backgrounds.


