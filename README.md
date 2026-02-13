<div align="center">
  <h1 style="border-bottom: none; margin-bottom: 10px;">Top-Down F1 Game</h1>
  <p>A Formula 1 themed top-down racing game built with <b>Godot 4.5</b><br>
  featuring realistic lap timing, penalty systems, and competitive racing modes.</p>
    <img src="assets/imgs/logo_vertical_color_dark.png" alt="Godot Logo" width="80"><br>
    <a href="https://godotengine.org/"><strong>Godot 4.5 Engine »</strong></a>
</div>


<div align="center">
    <img src="assets/imgs/Screenshot 2026-02-13 234257.png" alt="gif1" width="300" style="padding: 10px;">
    <img src="assets/imgs/Screenshot 2026-02-13 235355 - Copy.png" alt="gif2" width="300" style="padding: 10px;">
</div>

<div align="center" style="margin-top: 50px;">
    <p style="margin-bottom: 0; font-size: 14px; color: #666; letter-spacing: 2px; text-transform: uppercase;">Made by</p>
    <h2 style="margin-top: 5px; font-size: 32px; background: linear-gradient(to right, #ffffff, #888); -webkit-background-clip: text; -webkit-text-fill-color: transparent;">
      Tomasz Dziób
    </h2>
  </div>
</div>


<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#features">Features</a></li>
    <li>
      <a href="#game-modes">Game Modes</a>
      <ul>
        <li><a href="#race-mode">Race Mode</a></li>
        <li><a href="#time-trial-mode">Time Trial Mode</a></li>
      </ul>
    </li>
    <li>
      <a href="#game-mechanics">Game Mechanics</a>
      <ul>
        <li><a href="#penalty-system">Penalty System</a></li>
        <li><a href="#lap-timing">Lap Timing</a></li>
      </ul>
    </li>
    <li><a href="#requirements">Requirements</a></li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#installation">Installation</a></li>
        <li><a href="#running-the-game">Running the Game</a></li>
        <li><a href="#controls">Controls</a></li>
      </ul>
    </li>
    <li><a href="#architecture">Architecture</a></li>
  </ol>
</details>

---

## Features

- **Advanced Penalty System**
  - Real-time detection of off-track violations
  - Time penalties for exceeding track boundaries
  - Progressive penalty system with violation tracking
  - Automatic disqualification after excessive off-track time

- **Ghost Car Technology**
  - Record and replay your best lap performances
  - Compare your driving against previous runs
  - Visual reference for optimal racing lines

- **Performance Tracking**
  - Detailed lap timing and sector splits
  - Best lap time saving and comparison
  - Lap completion statistics
  - Race results with final standings

- **Realistic Vehicle Physics**
  - Player-controlled car with keyboard input
  - AI-controlled opponent vehicles
  - Dynamic track boundaries and collision detection
  - Sector tracking for performance analysis

## Game Modes
#### Race Mode

- Compete against multiple AI-controlled opponents
- Complete a set number of laps (default: 3 laps)
- Receive time penalties for driving off-track
- Final standings displayed after race completion
- Best lap time recorded for future comparison

<div align="center">
    <img align="center" src="C:\DaneTomka\Programming\Godot\f1-game\assets\imgs\Screenshot 2026-02-14 000713.png" alt="gif1" width="300" style="padding: 10px;">
        <img align="center" src="C:\DaneTomka\Programming\Godot\f1-game\assets\imgs\Screenshot 2026-02-13 235043.png" alt="gif1" width="450" style="padding: 10px;">
</div>
<div align="center">

</div>

#### Time Trial Mode
- Solo competitive mode with no AI opponents
- Set your fastest lap times
- Unlimited laps to improve your performance
- Ghost car replay shows your best lap
- Compare sector times for optimization


<div align="center">
    <img align="center" src="C:\DaneTomka\Programming\Godot\f1-game\assets\imgs\Screenshot 2026-02-14 000311.png" alt="gif1" width="300" style="padding: 10px;">
    <img align="center" src="C:\DaneTomka\Programming\Godot\f1-game\assets\imgs\Screenshot 2026-02-13 235355.png" alt="gif2" width="300" style="padding: 10px;">
</div>

## Game Mechanics

### Penalty System

The penalty system enforces strict adherence to track boundaries:

- **Off-Track Detection**: Continuous monitoring every 0.5 seconds
- **Penalty Threshold**: 3 seconds of off-track driving triggers a penalty
- **Penalty Amount**: 5 seconds added to final race time per violation
- **Disqualification**: >15 seconds total off-track time results in race being over

<div align="center">
    <img align="center" src="C:\DaneTomka\Programming\Godot\f1-game\assets\imgs\Screenshot 2026-02-13 234326.png" alt="gif1" width="300" style="padding: 10px;">
    <img align="center" src="C:\DaneTomka\Programming\Godot\f1-game\assets\imgs\Screenshot 2026-02-13 234356.png"alt="gif2" width="300" style="padding: 10px;">
</div>

### Lap Timing


<table border="0" cellspacing="0" cellpadding="20" align="center">
  <tr>
    <td align="left" style="border: none;">
      <ul>
        <li>Real-time lap timer with millisecond precision</li>
        <li>Sector split timing for performance analysis</li>
        <li>Automatic lap detection via waypoint system</li>
        <li>Best lap tracking across multiple sessions</li>
      </ul>
    </td>
    <td align="right" valign="top" style="border: none; padding-left: 100px;">
      <img src="assets/imgs/Screenshot 2026-02-14 003829.png" width="150">
    </td>
  </tr>
</table>





## Requirements

- **Godot Engine**: 4.5 or later
- **Rendering**: Forward Plus renderer
- **Plugins**: Curved Lines 2D (included in addons)


## Getting Started

### Installation

1. Open Godot 4.5 or later
2. Open the project folder: `f1-game`
3. The project will auto-load with the main menu scene

### Running the Game

- **From Editor**: Press Play button
- **Main Menu**: Select between Race Mode or Time Trial
- **Track Selection**: Choose your preferred circuit

### Controls

- **Throttle**: Up Arrow
- **Brake**: Down Arrow, CTRL
- **Left Turn**: Left Arrow
- **Right Turn**: Right Arrow

## Architecture

The game follows a modular architecture with clear separation of concerns:

**`Event Hub`** — Central event system for inter-system communication

**`Game Manager`** — High-level game state and scene navigation

**`Car System`** — Handles all vehicle logic (player, AI, ghost)

**`Track System`** — Manages track layout, waypoints, and sectors

**`Controller Classes`** — Mode-specific logic (race vs. time trial)

<div>
<br>
<br>
</div>

**Ready to race?** 🏎️

---
<div align="right">
    <img align="center" src=assets/imgs/F1.svg.png alt="gif1" width="100" style="padding: 10px;">
</div>