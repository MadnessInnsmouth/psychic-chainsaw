"""
Main Menu Screen for Project Touchline
Handles main menu navigation and selection
"""

from typing import Optional, List
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.narration_engine import NarrationEngine
from core.input_handler import InputHandler, NavigationHelper


class MainMenuScreen:
    """
    Main menu screen with accessible navigation.
    Provides Career, Load Game, Preferences, and Quit options.
    """
    
    def __init__(self, narrator: NarrationEngine, input_handler: InputHandler):
        """
        Initialize the main menu screen.
        
        Args:
            narrator: Narration engine instance
            input_handler: Input handler instance
        """
        self.narrator = narrator
        self.input_handler = input_handler
        self.menu_items = [
            "Career Mode - Start a new game",
            "Load Game - Continue a saved game",
            "Preferences - Adjust settings",
            "Quit - Exit the game"
        ]
        self.navigator = NavigationHelper(self.menu_items)
        self.active = False
        
        # Setup key bindings
        self._setup_bindings()
    
    def _setup_bindings(self):
        """Setup keyboard bindings for menu navigation."""
        self.input_handler.bind('up', 'Previous menu item', self.previous_item)
        self.input_handler.bind('down', 'Next menu item', self.next_item)
        self.input_handler.bind('enter', 'Select menu item', self.select_item)
        self.input_handler.bind('escape', 'Quit', self.quit)
        self.input_handler.bind('r', 'Read current item', self.read_current)
        self.input_handler.bind('h', 'Help', self.show_help)
    
    def activate(self):
        """Activate the main menu screen."""
        self.active = True
        self.input_handler.set_navigation_mode('menu')
        welcome_text = "Welcome to Football Manager 2026. Main Menu."
        self.narrator.speak(welcome_text)
        self.read_current()
    
    def deactivate(self):
        """Deactivate the main menu screen."""
        self.active = False
    
    def next_item(self):
        """Navigate to next menu item."""
        if self.active:
            item = self.navigator.next()
            self.narrator.speak(item)
    
    def previous_item(self):
        """Navigate to previous menu item."""
        if self.active:
            item = self.navigator.previous()
            self.narrator.speak(item)
    
    def read_current(self):
        """Read the current menu item."""
        if self.active:
            item = self.navigator.get_current()
            index = self.navigator.get_current_index()
            text = f"Item {index + 1} of {len(self.menu_items)}: {item}"
            self.narrator.speak(text)
    
    def select_item(self):
        """Select the current menu item."""
        if self.active:
            index = self.navigator.get_current_index()
            item = self.navigator.get_current()
            
            if index == 0:  # Career Mode
                self.narrator.speak("Opening Career Mode")
                print("[MainMenu] Selected: Career Mode")
                # TODO: Transition to club selection screen
            elif index == 1:  # Load Game
                self.narrator.speak("Opening Load Game")
                print("[MainMenu] Selected: Load Game")
                # TODO: Transition to save/load screen
            elif index == 2:  # Preferences
                self.narrator.speak("Opening Preferences")
                print("[MainMenu] Selected: Preferences")
                # TODO: Transition to preferences screen
            elif index == 3:  # Quit
                self.quit()
    
    def show_help(self):
        """Show help information."""
        if self.active:
            help_text = (
                "Main Menu Help. "
                "Use up and down arrows to navigate. "
                "Press Enter to select. "
                "Press R to read current item. "
                "Press H for help. "
                "Press Escape to quit."
            )
            self.narrator.speak(help_text)
    
    def quit(self):
        """Quit the application."""
        self.narrator.speak("Exiting Football Manager. Goodbye!")
        self.deactivate()
        print("[MainMenu] Quit selected")
        # TODO: Implement proper exit


def main():
    """Demo function to test main menu screen."""
    print("=== Main Menu Screen Demo ===")
    print("This is a simulation. In a real implementation, this would be integrated with the game.")
    print("Keyboard navigation would be active.\n")
    
    # Create instances
    narrator = NarrationEngine({'enabled': True})
    input_handler = InputHandler()
    menu = MainMenuScreen(narrator, input_handler)
    
    # Activate menu
    menu.activate()
    
    # Simulate some navigation
    print("\n--- Simulating down arrow ---")
    menu.next_item()
    
    print("\n--- Simulating down arrow ---")
    menu.next_item()
    
    print("\n--- Simulating up arrow ---")
    menu.previous_item()
    
    print("\n--- Simulating read current (R key) ---")
    menu.read_current()
    
    print("\n--- Simulating help (H key) ---")
    menu.show_help()


if __name__ == "__main__":
    main()
