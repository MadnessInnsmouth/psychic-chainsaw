"""
Save/Load Screen for Project Touchline
Handles saving and loading game state
"""

from typing import Optional, List
import sys
import os
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.narration_engine import NarrationEngine
from core.input_handler import InputHandler, NavigationHelper


class SaveGame:
    """Represents a saved game."""
    
    def __init__(self, name: str, club: str, date: str, season: str, position: str):
        """
        Initialize a saved game.
        
        Args:
            name: Save name
            club: Club name
            date: Save date
            season: Current season
            position: League position
        """
        self.name = name
        self.club = club
        self.date = date
        self.season = season
        self.position = position
    
    def get_summary(self) -> str:
        """Get save game summary."""
        return f"{self.name}, {self.club}, {self.season}, {self.position}, Saved: {self.date}"


class SaveLoadScreen:
    """
    Save/Load screen for managing game saves.
    Supports listing saves, loading, and creating new saves.
    """
    
    def __init__(self, narrator: NarrationEngine, input_handler: InputHandler):
        """
        Initialize the save/load screen.
        
        Args:
            narrator: Narration engine instance
            input_handler: Input handler instance
        """
        self.narrator = narrator
        self.input_handler = input_handler
        self.active = False
        self.mode = 'load'  # 'load' or 'save'
        
        # Sample saved games
        self.saved_games = self._create_sample_saves()
        
        # Navigation
        self.navigator = NavigationHelper([s.get_summary() for s in self.saved_games])
        
        # Setup key bindings
        self._setup_bindings()
    
    def _create_sample_saves(self) -> List[SaveGame]:
        """Create sample saved games."""
        return [
            SaveGame(
                "Career 1 - Season 1",
                "Manchester Rovers",
                "15 Jan 2026",
                "2025/26",
                "3rd in Premier League"
            ),
            SaveGame(
                "Career 1 - Season 2",
                "Manchester Rovers",
                "10 Mar 2027",
                "2026/27",
                "1st in Premier League"
            ),
            SaveGame(
                "Career 2 - Start",
                "Barcelona FC",
                "1 Jul 2025",
                "2025/26",
                "Pre-season"
            ),
        ]
    
    def _setup_bindings(self):
        """Setup keyboard bindings for save/load screen."""
        self.input_handler.bind('up', 'Previous save', self.previous_save)
        self.input_handler.bind('down', 'Next save', self.next_save)
        self.input_handler.bind('enter', 'Load/Save', self.confirm_action)
        self.input_handler.bind('r', 'Read current save', self.read_current)
        self.input_handler.bind('delete', 'Delete save', self.delete_save)
        self.input_handler.bind('escape', 'Back to menu', self.back)
        self.input_handler.bind('h', 'Help', self.show_help)
    
    def activate(self, mode: str = 'load'):
        """
        Activate the save/load screen.
        
        Args:
            mode: 'load' or 'save'
        """
        self.active = True
        self.mode = mode
        self.input_handler.set_navigation_mode('list')
        
        if mode == 'load':
            welcome = f"Load Game. {len(self.saved_games)} saved games available."
        else:
            welcome = "Save Game. Select a save slot or create new save."
        
        self.narrator.speak(welcome)
        if self.saved_games:
            self.read_current()
    
    def deactivate(self):
        """Deactivate the save/load screen."""
        self.active = False
    
    def next_save(self):
        """Navigate to next save."""
        if self.active:
            summary = self.navigator.next()
            self.narrator.speak(summary)
    
    def previous_save(self):
        """Navigate to previous save."""
        if self.active:
            summary = self.navigator.previous()
            self.narrator.speak(summary)
    
    def read_current(self):
        """Read current save details."""
        if self.active and self.saved_games:
            index = self.navigator.get_current_index()
            summary = self.navigator.get_current()
            text = f"Save {index + 1} of {len(self.saved_games)}: {summary}"
            self.narrator.speak(text)
    
    def confirm_action(self):
        """Confirm load or save action."""
        if self.active and self.saved_games:
            index = self.navigator.get_current_index()
            save = self.saved_games[index]
            
            if self.mode == 'load':
                text = f"Loading {save.name}. {save.club}, {save.season}."
                self.narrator.speak(text)
                print(f"[SaveLoad] Loading: {save.name}")
                # TODO: Implement actual load logic
            else:
                text = f"Saving game as {save.name}. Saved successfully."
                self.narrator.speak(text)
                print(f"[SaveLoad] Saved: {save.name}")
                # TODO: Implement actual save logic
    
    def delete_save(self):
        """Delete the current save."""
        if self.active and self.saved_games:
            index = self.navigator.get_current_index()
            save = self.saved_games[index]
            
            text = f"Delete {save.name}? This action cannot be undone. Deleted."
            self.narrator.speak(text)
            
            # Remove save
            self.saved_games.pop(index)
            
            # Update navigator
            if self.saved_games:
                self.navigator = NavigationHelper([s.get_summary() for s in self.saved_games])
                self.read_current()
            else:
                self.narrator.speak("No saved games available.")
            
            print(f"[SaveLoad] Deleted: {save.name}")
    
    def show_help(self):
        """Show help information."""
        if self.active:
            action = "load" if self.mode == 'load' else "save"
            help_text = (
                f"Save/Load Screen Help. Mode: {action}. "
                "Use up and down arrows to navigate saves. "
                f"Press Enter to {action} selected game. "
                "Press R to read current save details. "
                "Press Delete to remove a save. "
                "Press Escape to return to menu."
            )
            self.narrator.speak(help_text)
    
    def back(self):
        """Return to main menu."""
        self.narrator.speak("Returning to main menu")
        self.deactivate()
        print("[SaveLoad] Back to main menu")


def main():
    """Demo function to test save/load screen."""
    print("=== Save/Load Screen Demo ===\n")
    
    # Create instances
    narrator = NarrationEngine({'enabled': True})
    input_handler = InputHandler()
    save_load = SaveLoadScreen(narrator, input_handler)
    
    # Activate in load mode
    print("--- Load Mode ---")
    save_load.activate(mode='load')
    
    # Simulate interactions
    print("\n--- Next save (Down arrow) ---")
    save_load.next_save()
    
    print("\n--- Load game (Enter) ---")
    save_load.confirm_action()
    
    # Switch to save mode
    print("\n\n--- Save Mode ---")
    save_load.activate(mode='save')
    
    print("\n--- Help (H key) ---")
    save_load.show_help()


if __name__ == "__main__":
    main()
