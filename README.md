# Project Touchline

**Making Football Manager 2026 Fully Accessible for Blind Players**

Project Touchline is an accessibility framework designed to make Football Manager 2026 playable for blind and visually impaired users through NVDA/JAWS screen readers or custom speech/keyboard-based interfaces.

## 🎯 Project Goal

Enable blind players to fully experience Football Manager 2026 through:
- Text-to-speech narration of all game elements
- Comprehensive keyboard navigation
- Audio cues and feedback
- Screen reader integration (NVDA/JAWS)

## ✨ Features (Phase 1 - MVP)

### Core Accessibility Components

1. **Main Menu Access**
   - Keyboard-navigable menu (Career, Load Game, Preferences, Quit)
   - Speech narration of focused items
   - Arrow key navigation + Enter to select

2. **Inbox Screen**
   - Navigate emails with up/down arrows
   - Read sender, subject, date, and content
   - Hotkey to read full email content

3. **Club Selection**
   - Browse clubs with keyboard
   - Filter by country and division
   - Read club details (name, league, reputation, finances)

4. **Team Overview**
   - Squad list navigation
   - Read player details (name, position, rating, age, fitness)
   - Filter players by position

5. **Match Day - Text Commentary**
   - Real-time text commentary with speech
   - Adjustable commentary speed
   - Hotkeys for match stats, possession, goals
   - Navigate through match events

6. **Tactics Screen**
   - Navigate formations and players
   - Change formations via keyboard
   - Assign players to positions
   - Substitution menu access

7. **Save/Load Game**
   - Navigate saved games list
   - Save and load with keyboard
   - Confirmation messages

## 🚀 Quick Start

### Requirements

- Python 3.7 or higher
- pyttsx3 (for text-to-speech)

### Installation

```bash
# Clone the repository
git clone https://github.com/MadnessInnsmouth/psychic-chainsaw.git
cd psychic-chainsaw

# Install dependencies
pip install pyttsx3
```

### Running Demo Screens

Each screen module can be run independently for testing:

```bash
# Main menu demo
python screens/main_menu_screen.py

# Inbox demo
python screens/inbox_screen.py

# Match day demo
python screens/matchday_screen.py

# Tactics demo
python screens/tactics_screen.py

# Club selection demo
python screens/club_selection_screen.py

# Team overview demo
python screens/team_overview_screen.py

# Save/Load demo
python screens/save_load_screen.py
```

## 📁 Project Structure

```
project-touchline/
├── core/
│   ├── narration_engine.py      # Text-to-speech engine
│   ├── input_handler.py         # Keyboard input management
│   └── keyboard_mapper.py       # Hotkey configuration
├── screens/
│   ├── main_menu_screen.py      # Main menu navigation
│   ├── inbox_screen.py          # Email/inbox system
│   ├── matchday_screen.py       # Match commentary & stats
│   ├── tactics_screen.py        # Formation & tactics
│   ├── club_selection_screen.py # Club database
│   ├── team_overview_screen.py  # Squad management
│   └── save_load_screen.py      # Save/load games
├── utils/
│   ├── logger.py                # Logging system
│   ├── hotkeys_config.json      # Hotkey mappings
│   └── speech_config.ini        # TTS configuration
├── testing/
│   └── sample_outputs.txt       # Example outputs
├── README.md
└── roadmap.txt
```

## ⌨️ Default Hotkeys

### General Navigation
- **Arrow Keys**: Navigate items/menus
- **Enter**: Select/Confirm
- **Escape**: Back/Cancel
- **R**: Read current item
- **H**: Help/Show available commands
- **Space**: Toggle/Pause (context-dependent)

### Match Day Specific
- **C**: Read latest commentary
- **P**: Read possession stats
- **T**: Read all match stats
- **G**: Read last goal
- **E**: Read last event
- **F**: Faster commentary
- **S**: Slower commentary
- **Left/Right**: Navigate through events

### Tactics Screen
- **F**: Change formation
- **R**: Read current formation
- **S**: Substitution menu
- **I**: Player instructions

### Filtering (Club/Team screens)
- **P**: Filter by position (team overview)
- **C**: Filter by country (club selection)
- **D**: Filter by division (club selection)
- **X**: Clear filters

## 🔧 Configuration

### Speech Settings

Edit `utils/speech_config.ini`:

```ini
[speech]
enabled = true
rate = 150          # Words per minute (100-300)
volume = 1.0        # Volume (0.0-1.0)
voice =             # Leave empty for default
```

### Hotkey Customization

Edit `utils/hotkeys_config.json` to customize keyboard bindings for different screens.

## 🎮 Usage Examples

### Starting a Career

1. Run the main menu
2. Navigate with arrow keys to "Career Mode"
3. Press Enter to select
4. Choose a club from the database
5. Press Enter to start

### Reading Match Commentary

1. During a match, press **C** for latest commentary
2. Press **T** for full match statistics
3. Press **G** to hear details of the last goal
4. Use **Left/Right arrows** to browse through events

### Managing Squad

1. Access Team Overview from main menu
2. Use **Up/Down** arrows to browse players
3. Press **Enter** for detailed player information
4. Press **P** to filter by position

## 📊 Accessibility Features

- **Full Keyboard Navigation**: No mouse required
- **Text-to-Speech**: All interface elements are narrated
- **Adjustable Speech Speed**: Customize reading speed to preference
- **Audio Cues**: Important events announced with audio feedback
- **Context-Sensitive Help**: Press H on any screen for available commands
- **Filter & Search**: Quickly find specific items (clubs, players, saves)

## 🗺️ Development Roadmap

### Phase 1: Core Accessibility (MVP) ✅
- Main menu navigation
- Inbox/email system
- Club selection
- Team overview
- Match day commentary
- Tactics screen
- Save/load functionality

### Phase 2: Quality-of-Life Enhancements (Planned)
- Player search & scouting
- Transfer market
- Training overview
- Finances & club info
- Press conferences

### Phase 3: Extended Features (Experimental)
- NVDA/JAWS direct integration
- Audio cues & sound effects
- Mod manager UI
- Multiplayer accessibility
- Custom hotkey mapping system

## 🤝 Contributing

Contributions are welcome! Areas where help is needed:

- Testing with real screen readers (NVDA, JAWS)
- Additional accessibility features
- Bug fixes and improvements
- Documentation enhancements
- User experience feedback from blind users

## 📝 License

This project is open source and available for use in making games more accessible.

## 🙏 Acknowledgments

Project Touchline is dedicated to making gaming accessible to everyone, regardless of visual ability.

## 📞 Contact & Support

For questions, feedback, or support:
- Open an issue on GitHub
- Contribute improvements via pull requests

---

**Version**: 0.1 (MVP)  
**Status**: Core functionality implemented  
**Last Updated**: December 2025
