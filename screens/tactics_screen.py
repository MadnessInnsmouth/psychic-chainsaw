"""
Tactics Screen for Project Touchline
Handles formation and player management
"""

from typing import Optional, List, Dict
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.narration_engine import NarrationEngine
from core.input_handler import InputHandler, NavigationHelper


class Player:
    """Represents a player in the squad."""
    
    def __init__(self, name: str, position: str, rating: int, age: int, fitness: int):
        """
        Initialize a player.
        
        Args:
            name: Player name
            position: Player position (GK, DEF, MID, FWD)
            rating: Star rating (1-5)
            age: Player age
            fitness: Fitness percentage (0-100)
        """
        self.name = name
        self.position = position
        self.rating = rating
        self.age = age
        self.fitness = fitness
        self.role = "Default"  # Tactical role
    
    def get_summary(self) -> str:
        """Get player summary for reading."""
        stars = "★" * self.rating + "☆" * (5 - self.rating)
        return (
            f"{self.name}, {self.position}, {stars} {self.rating} stars, "
            f"Age {self.age}, Fitness {self.fitness}%, Role: {self.role}"
        )


class Formation:
    """Represents a tactical formation."""
    
    def __init__(self, name: str, positions: List[str]):
        """
        Initialize a formation.
        
        Args:
            name: Formation name (e.g., "4-3-3")
            positions: List of positions in the formation
        """
        self.name = name
        self.positions = positions
    
    def get_description(self) -> str:
        """Get formation description."""
        return f"{self.name} formation with {len(self.positions)} outfield positions plus goalkeeper"


class TacticsScreen:
    """
    Tactics screen for managing formation and player assignments.
    Supports formation selection, player positioning, and substitutions.
    """
    
    def __init__(self, narrator: NarrationEngine, input_handler: InputHandler):
        """
        Initialize the tactics screen.
        
        Args:
            narrator: Narration engine instance
            input_handler: Input handler instance
        """
        self.narrator = narrator
        self.input_handler = input_handler
        self.active = False
        
        # Sample formations
        self.formations = [
            Formation("4-3-3", ["GK", "RB", "CB", "CB", "LB", "CM", "CM", "CM", "RW", "ST", "LW"]),
            Formation("4-4-2", ["GK", "RB", "CB", "CB", "LB", "RM", "CM", "CM", "LM", "ST", "ST"]),
            Formation("4-2-3-1", ["GK", "RB", "CB", "CB", "LB", "CDM", "CDM", "CAM", "RW", "LW", "ST"]),
            Formation("3-5-2", ["GK", "CB", "CB", "CB", "RWB", "CM", "CM", "CM", "LWB", "ST", "ST"]),
        ]
        self.current_formation_index = 0
        self.current_formation = self.formations[0]
        
        # Sample squad
        self.squad = self._create_sample_squad()
        self.starting_eleven: List[Player] = self.squad[:11]
        
        # Navigation
        self.player_navigator = NavigationHelper([p.get_summary() for p in self.starting_eleven])
        
        # Setup key bindings
        self._setup_bindings()
    
    def _create_sample_squad(self) -> List[Player]:
        """Create a sample squad for demonstration."""
        return [
            Player("John Smith", "GK", 4, 28, 95),
            Player("Mike Jones", "DEF", 3, 25, 92),
            Player("Tom Brown", "DEF", 4, 27, 90),
            Player("David Wilson", "DEF", 3, 24, 88),
            Player("James Taylor", "DEF", 3, 26, 91),
            Player("Robert Davies", "MID", 4, 23, 93),
            Player("Chris Evans", "MID", 3, 29, 87),
            Player("Paul Thomas", "MID", 4, 22, 95),
            Player("Mark White", "FWD", 5, 24, 89),
            Player("Steve Martin", "FWD", 4, 26, 92),
            Player("Andy Clark", "FWD", 3, 21, 94),
            # Substitutes
            Player("Gary Lewis", "GK", 2, 31, 90),
            Player("Sam Walker", "DEF", 3, 23, 85),
            Player("Ben Hall", "MID", 3, 20, 88),
            Player("Luke Young", "FWD", 3, 19, 91),
        ]
    
    def _setup_bindings(self):
        """Setup keyboard bindings for tactics screen."""
        self.input_handler.bind('up', 'Previous player', self.previous_player)
        self.input_handler.bind('down', 'Next player', self.next_player)
        self.input_handler.bind('f', 'Change formation', self.change_formation)
        self.input_handler.bind('r', 'Read formation', self.read_formation)
        self.input_handler.bind('s', 'Substitute menu', self.substitute_menu)
        self.input_handler.bind('i', 'Player instructions', self.player_instructions)
        self.input_handler.bind('escape', 'Back to menu', self.back)
        self.input_handler.bind('h', 'Help', self.show_help)
    
    def activate(self):
        """Activate the tactics screen."""
        self.active = True
        self.input_handler.set_navigation_mode('tactics')
        
        welcome = "Tactics screen. Current formation and starting eleven."
        self.narrator.speak(welcome)
        self.read_formation()
    
    def deactivate(self):
        """Deactivate the tactics screen."""
        self.active = False
    
    def next_player(self):
        """Navigate to next player."""
        if self.active:
            summary = self.player_navigator.next()
            self.narrator.speak(summary)
    
    def previous_player(self):
        """Navigate to previous player."""
        if self.active:
            summary = self.player_navigator.previous()
            self.narrator.speak(summary)
    
    def read_formation(self):
        """Read current formation."""
        if self.active:
            description = self.current_formation.get_description()
            self.narrator.speak(description)
            
            # List positions
            positions_text = ", ".join(self.current_formation.positions)
            self.narrator.speak(f"Positions: {positions_text}")
    
    def change_formation(self):
        """Change to next formation."""
        if self.active:
            self.current_formation_index = (self.current_formation_index + 1) % len(self.formations)
            self.current_formation = self.formations[self.current_formation_index]
            
            text = f"Formation changed to {self.current_formation.name}"
            self.narrator.speak(text)
            self.read_formation()
    
    def substitute_menu(self):
        """Open substitution menu."""
        if self.active:
            text = "Substitution menu. Select a player to substitute."
            self.narrator.speak(text)
            # TODO: Implement substitution logic
            print("[Tactics] Substitution menu opened")
    
    def player_instructions(self):
        """Show player instructions."""
        if self.active:
            index = self.player_navigator.get_current_index()
            player = self.starting_eleven[index]
            
            text = f"Player instructions for {player.name}. Current role: {player.role}."
            self.narrator.speak(text)
            # TODO: Implement instruction changing
            print(f"[Tactics] Instructions for {player.name}")
    
    def show_help(self):
        """Show help information."""
        if self.active:
            help_text = (
                "Tactics Screen Help. "
                "Use up and down arrows to navigate players. "
                "Press F to change formation. "
                "Press R to read current formation. "
                "Press S for substitution menu. "
                "Press I for player instructions. "
                "Press Escape to return to menu."
            )
            self.narrator.speak(help_text)
    
    def back(self):
        """Return to main menu."""
        self.narrator.speak("Returning to main menu")
        self.deactivate()
        print("[Tactics] Back to main menu")


def main():
    """Demo function to test tactics screen."""
    print("=== Tactics Screen Demo ===\n")
    
    # Create instances
    narrator = NarrationEngine({'enabled': True})
    input_handler = InputHandler()
    tactics = TacticsScreen(narrator, input_handler)
    
    # Activate tactics screen
    tactics.activate()
    
    # Simulate interactions
    print("\n--- Next player (Down arrow) ---")
    tactics.next_player()
    
    print("\n--- Change formation (F key) ---")
    tactics.change_formation()
    
    print("\n--- Player instructions (I key) ---")
    tactics.player_instructions()
    
    print("\n--- Help (H key) ---")
    tactics.show_help()


if __name__ == "__main__":
    main()
