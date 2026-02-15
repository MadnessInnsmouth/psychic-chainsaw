"""
Team Overview Screen for Project Touchline
Handles squad list and player details
"""

from typing import Optional, List
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.narration_engine import NarrationEngine
from core.input_handler import InputHandler, NavigationHelper


class SquadPlayer:
    """Represents a player in the squad."""
    
    def __init__(self, name: str, position: str, star_rating: int, age: int, 
                 fitness: int, morale: str, contract_years: int):
        """
        Initialize a squad player.
        
        Args:
            name: Player name
            position: Player position
            star_rating: Star rating (1-5)
            age: Player age
            fitness: Fitness percentage (0-100)
            morale: Morale level (Poor, Okay, Good, Excellent)
            contract_years: Years remaining on contract
        """
        self.name = name
        self.position = position
        self.star_rating = star_rating
        self.age = age
        self.fitness = fitness
        self.morale = morale
        self.contract_years = contract_years
    
    def get_summary(self) -> str:
        """Get player summary for list view."""
        stars = "★" * self.star_rating + "☆" * (5 - self.star_rating)
        return f"{self.name}, {self.position}, {stars} {self.star_rating} stars, Age {self.age}, Fitness {self.fitness}%"
    
    def get_details(self) -> str:
        """Get detailed player information."""
        stars = "★" * self.star_rating + "☆" * (5 - self.star_rating)
        return (
            f"{self.name}. Position: {self.position}. "
            f"Rating: {stars} {self.star_rating} stars. "
            f"Age: {self.age}. "
            f"Fitness: {self.fitness}%. "
            f"Morale: {self.morale}. "
            f"Contract: {self.contract_years} years remaining."
        )


class TeamOverviewScreen:
    """
    Team overview screen for viewing squad and player details.
    Supports browsing squad, filtering by position, and viewing player stats.
    """
    
    def __init__(self, narrator: NarrationEngine, input_handler: InputHandler):
        """
        Initialize the team overview screen.
        
        Args:
            narrator: Narration engine instance
            input_handler: Input handler instance
        """
        self.narrator = narrator
        self.input_handler = input_handler
        self.active = False
        
        # Create sample squad
        self.full_squad = self._create_sample_squad()
        self.filtered_squad = self.full_squad.copy()
        
        # Navigation
        self.navigator = NavigationHelper([p.get_summary() for p in self.filtered_squad])
        
        # Position filter
        self.position_filter = None
        
        # Setup key bindings
        self._setup_bindings()
    
    def _create_sample_squad(self) -> List[SquadPlayer]:
        """Create a sample squad for demonstration."""
        return [
            SquadPlayer("John Smith", "GK", 4, 28, 95, "Good", 3),
            SquadPlayer("Gary Lewis", "GK", 2, 31, 90, "Okay", 1),
            SquadPlayer("Mike Jones", "DEF", 3, 25, 92, "Excellent", 4),
            SquadPlayer("Tom Brown", "DEF", 4, 27, 90, "Good", 2),
            SquadPlayer("David Wilson", "DEF", 3, 24, 88, "Good", 3),
            SquadPlayer("James Taylor", "DEF", 3, 26, 91, "Excellent", 2),
            SquadPlayer("Sam Walker", "DEF", 3, 23, 85, "Okay", 1),
            SquadPlayer("Robert Davies", "MID", 4, 23, 93, "Excellent", 4),
            SquadPlayer("Chris Evans", "MID", 3, 29, 87, "Good", 2),
            SquadPlayer("Paul Thomas", "MID", 4, 22, 95, "Excellent", 3),
            SquadPlayer("Ben Hall", "MID", 3, 20, 88, "Good", 2),
            SquadPlayer("Mark White", "FWD", 5, 24, 89, "Excellent", 5),
            SquadPlayer("Steve Martin", "FWD", 4, 26, 92, "Good", 3),
            SquadPlayer("Andy Clark", "FWD", 3, 21, 94, "Good", 2),
            SquadPlayer("Luke Young", "FWD", 3, 19, 91, "Excellent", 1),
        ]
    
    def _setup_bindings(self):
        """Setup keyboard bindings for team overview."""
        self.input_handler.bind('up', 'Previous player', self.previous_player)
        self.input_handler.bind('down', 'Next player', self.next_player)
        self.input_handler.bind('enter', 'Player details', self.show_player_details)
        self.input_handler.bind('r', 'Read current player', self.read_current)
        self.input_handler.bind('p', 'Filter by position', self.filter_by_position)
        self.input_handler.bind('x', 'Clear filters', self.clear_filters)
        self.input_handler.bind('escape', 'Back to menu', self.back)
        self.input_handler.bind('h', 'Help', self.show_help)
    
    def activate(self):
        """Activate the team overview screen."""
        self.active = True
        self.input_handler.set_navigation_mode('list')
        
        welcome = f"Team Overview. Squad of {len(self.filtered_squad)} players."
        self.narrator.speak(welcome)
        self.read_current()
    
    def deactivate(self):
        """Deactivate the team overview screen."""
        self.active = False
    
    def next_player(self):
        """Navigate to next player."""
        if self.active:
            summary = self.navigator.next()
            self.narrator.speak(summary)
    
    def previous_player(self):
        """Navigate to previous player."""
        if self.active:
            summary = self.navigator.previous()
            self.narrator.speak(summary)
    
    def read_current(self):
        """Read current player summary."""
        if self.active:
            index = self.navigator.get_current_index()
            summary = self.navigator.get_current()
            text = f"Player {index + 1} of {len(self.filtered_squad)}: {summary}"
            self.narrator.speak(text)
    
    def show_player_details(self):
        """Show detailed information for current player."""
        if self.active:
            index = self.navigator.get_current_index()
            player = self.filtered_squad[index]
            details = player.get_details()
            self.narrator.speak(details)
    
    def filter_by_position(self):
        """Filter squad by position (cycle through positions)."""
        if self.active:
            positions = ["GK", "DEF", "MID", "FWD"]
            
            if self.position_filter is None:
                self.position_filter = positions[0]
            else:
                try:
                    current_idx = positions.index(self.position_filter)
                    self.position_filter = positions[(current_idx + 1) % len(positions)]
                except ValueError:
                    self.position_filter = positions[0]
            
            self._apply_filters()
            self.narrator.speak(f"Filtering by position: {self.position_filter}. {len(self.filtered_squad)} players found.")
    
    def clear_filters(self):
        """Clear all filters."""
        if self.active:
            self.position_filter = None
            self._apply_filters()
            self.narrator.speak(f"Filters cleared. {len(self.filtered_squad)} players in squad.")
    
    def _apply_filters(self):
        """Apply current filters to squad list."""
        self.filtered_squad = self.full_squad.copy()
        
        if self.position_filter:
            self.filtered_squad = [p for p in self.filtered_squad if p.position == self.position_filter]
        
        # Update navigator
        self.navigator = NavigationHelper([p.get_summary() for p in self.filtered_squad])
        
        if self.filtered_squad:
            self.read_current()
    
    def show_help(self):
        """Show help information."""
        if self.active:
            help_text = (
                "Team Overview Help. "
                "Use up and down arrows to navigate players. "
                "Press Enter to hear detailed player information. "
                "Press R to read current player. "
                "Press P to filter by position. "
                "Press X to clear filters. "
                "Press Escape to return to menu."
            )
            self.narrator.speak(help_text)
    
    def back(self):
        """Return to main menu."""
        self.narrator.speak("Returning to main menu")
        self.deactivate()
        print("[TeamOverview] Back to main menu")


def main():
    """Demo function to test team overview screen."""
    print("=== Team Overview Screen Demo ===\n")
    
    # Create instances
    narrator = NarrationEngine({'enabled': True})
    input_handler = InputHandler()
    team_overview = TeamOverviewScreen(narrator, input_handler)
    
    # Activate screen
    team_overview.activate()
    
    # Simulate interactions
    print("\n--- Next player (Down arrow) ---")
    team_overview.next_player()
    
    print("\n--- Player details (Enter) ---")
    team_overview.show_player_details()
    
    print("\n--- Filter by position (P key) ---")
    team_overview.filter_by_position()
    
    print("\n--- Help (H key) ---")
    team_overview.show_help()


if __name__ == "__main__":
    main()
