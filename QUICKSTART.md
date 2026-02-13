# Project Touchline - Quick Start Guide

Get started with the Football Manager 2026 Accessibility Framework in 5 minutes!

## Installation

### Step 1: Install Python
Make sure you have Python 3.7 or higher installed:
```bash
python --version
```

### Step 2: Install Dependencies
```bash
pip install -r requirements.txt
```

The main dependency is `pyttsx3` for text-to-speech. If installation fails, the framework will still work in console-only mode.

## Running the Demo

### Full Demo (All Screens)
```bash
python main.py --demo
```

This runs through all accessibility features:
- Main menu navigation
- Inbox/email system
- Club selection
- Team overview
- Match day commentary
- Tactics screen
- Save/load functionality

### Interactive Demo
```bash
python demo.py
```

Step-by-step interactive demonstration with visual formatting.

### Individual Screen Demos
```bash
# Try any of these:
python screens/main_menu_screen.py
python screens/inbox_screen.py
python screens/matchday_screen.py
python screens/tactics_screen.py
python screens/club_selection_screen.py
python screens/team_overview_screen.py
python screens/save_load_screen.py
```

## Basic Usage

### Main Menu Navigation
- **↑/↓**: Navigate menu items
- **Enter**: Select item
- **R**: Read current item
- **H**: Help

### Match Day
- **Space**: Pause/Resume
- **C**: Read commentary
- **P**: Possession stats
- **T**: All stats
- **G**: Last goal
- **←/→**: Navigate events

### General Controls
- **Escape**: Go back
- **H**: Help (on any screen)
- **R**: Read current item

## Configuration

### Speech Settings
Edit `utils/speech_config.ini`:
```ini
[speech]
enabled = true
rate = 150      # Words per minute
volume = 1.0    # 0.0 to 1.0
```

### Hotkeys
Edit `utils/hotkeys_config.json` to customize keyboard bindings.

## What's Included?

✅ **7 Accessible Screens**
- Main Menu
- Inbox
- Club Selection
- Team Overview
- Match Day
- Tactics
- Save/Load

✅ **3 Core Components**
- Text-to-Speech Engine
- Input Handler
- Keyboard Mapper

✅ **Full Documentation**
- README.md - Complete guide
- roadmap.txt - Development plan
- sample_outputs.txt - Expected behavior

## Need Help?

- Read the full README.md
- Check sample_outputs.txt for expected narration
- Review CONTRIBUTING.md for development info
- Open an issue on GitHub

## Next Steps

1. Try all the demos
2. Read the full documentation
3. Customize hotkeys and speech settings
4. Provide feedback if you're a blind gamer
5. Contribute improvements!

---

**Version**: 0.1 (MVP)  
**Status**: Core features complete  
**Goal**: Full Football Manager accessibility for blind players
