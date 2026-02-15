#!/usr/bin/env python3
"""
Project Touchline - Main Application
Football Manager 2026 Accessibility Framework

This is a demonstration application showing the core accessibility features.
"""

import sys
import os

# Add project root to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from core.narration_engine import NarrationEngine
from core.input_handler import InputHandler
from core.keyboard_mapper import KeyboardMapper
from screens.main_menu_screen import MainMenuScreen
from screens.inbox_screen import InboxScreen
from screens.matchday_screen import MatchDayScreen
from screens.tactics_screen import TacticsScreen
from screens.club_selection_screen import ClubSelectionScreen
from screens.team_overview_screen import TeamOverviewScreen
from screens.save_load_screen import SaveLoadScreen
from utils.logger import get_logger


class ProjectTouchline:
    """
    Main application class for Project Touchline.
    Coordinates all screens and manages application state.
    """
    
    def __init__(self):
        """Initialize the application."""
        self.logger = get_logger()
        self.logger.info("Initializing Project Touchline")
        
        # Initialize core components
        self.narrator = NarrationEngine({'enabled': True, 'rate': 150})
        self.input_handler = InputHandler()
        self.keyboard_mapper = KeyboardMapper()
        
        # Initialize screens
        self.main_menu = MainMenuScreen(self.narrator, self.input_handler)
        self.inbox = InboxScreen(self.narrator, self.input_handler)
        self.matchday = MatchDayScreen(self.narrator, self.input_handler)
        self.tactics = TacticsScreen(self.narrator, self.input_handler)
        self.club_selection = ClubSelectionScreen(self.narrator, self.input_handler)
        self.team_overview = TeamOverviewScreen(self.narrator, self.input_handler)
        self.save_load = SaveLoadScreen(self.narrator, self.input_handler)
        
        self.current_screen = None
        
        self.logger.info("Project Touchline initialized successfully")
    
    def run_demo(self):
        """Run a demonstration of all screens."""
        print("=" * 60)
        print("PROJECT TOUCHLINE - Accessibility Framework Demo")
        print("Football Manager 2026 for Blind Players")
        print("=" * 60)
        print()
        
        self.narrator.speak("Welcome to Project Touchline demonstration")
        
        # Demo all screens
        self._demo_screen("Main Menu", self.main_menu)
        self._demo_screen("Inbox", self.inbox)
        self._demo_screen("Club Selection", self.club_selection)
        self._demo_screen("Team Overview", self.team_overview)
        self._demo_screen("Tactics", self.tactics)
        self._demo_screen("Match Day", self.matchday)
        self._demo_screen("Save/Load", self.save_load)
        
        print("\n" + "=" * 60)
        print("DEMO COMPLETE")
        print("=" * 60)
        self.narrator.speak("Demonstration complete. Thank you for exploring Project Touchline.")
    
    def _demo_screen(self, name: str, screen):
        """
        Run a brief demo of a screen.
        
        Args:
            name: Screen name
            screen: Screen instance
        """
        print(f"\n{'=' * 60}")
        print(f"DEMO: {name}")
        print(f"{'=' * 60}\n")
        
        self.logger.log_navigation("Demo", name)
        
        # Activate screen
        if hasattr(screen, 'activate'):
            screen.activate()
        
        # Brief pause for narration
        import time
        time.sleep(0.5)
        
        # Show help
        if hasattr(screen, 'show_help'):
            print(f"\n[Showing {name} Help]")
            screen.show_help()
            time.sleep(0.5)
        
        # Deactivate screen
        if hasattr(screen, 'deactivate'):
            screen.deactivate()
        
        print(f"\n[{name} demo complete]")
    
    def show_info(self):
        """Display application information."""
        print("\n" + "=" * 60)
        print("PROJECT TOUCHLINE - Information")
        print("=" * 60)
        print()
        print("Version: 0.1 (MVP)")
        print("Status: Core accessibility features implemented")
        print()
        print("Features:")
        print("  ✓ Main Menu Navigation")
        print("  ✓ Inbox/Email System")
        print("  ✓ Club Selection")
        print("  ✓ Team Overview")
        print("  ✓ Match Day Commentary")
        print("  ✓ Tactics Screen")
        print("  ✓ Save/Load System")
        print()
        print("Core Components:")
        print("  ✓ Text-to-Speech Engine")
        print("  ✓ Keyboard Navigation")
        print("  ✓ Hotkey System")
        print("  ✓ Screen Reader Ready")
        print()
        print("For more information, see README.md")
        print("=" * 60)


def main():
    """Main entry point."""
    app = ProjectTouchline()
    
    # Check for command line arguments
    if len(sys.argv) > 1:
        command = sys.argv[1].lower()
        
        if command == '--info' or command == '-i':
            app.show_info()
        elif command == '--demo' or command == '-d':
            app.run_demo()
        elif command == '--help' or command == '-h':
            print("Project Touchline - Football Manager 2026 Accessibility Framework")
            print()
            print("Usage: python main.py [option]")
            print()
            print("Options:")
            print("  --demo, -d    Run demonstration of all screens")
            print("  --info, -i    Show application information")
            print("  --help, -h    Show this help message")
            print()
            print("Run individual screen demos:")
            print("  python screens/main_menu_screen.py")
            print("  python screens/inbox_screen.py")
            print("  python screens/matchday_screen.py")
            print("  python screens/tactics_screen.py")
            print("  python screens/club_selection_screen.py")
            print("  python screens/team_overview_screen.py")
            print("  python screens/save_load_screen.py")
        else:
            print(f"Unknown command: {command}")
            print("Use --help for available commands")
    else:
        # Default: run demo
        app.run_demo()


if __name__ == "__main__":
    main()
