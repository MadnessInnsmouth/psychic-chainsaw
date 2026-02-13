"""
Club Selection Screen for Project Touchline
Handles club database navigation and selection
"""

from typing import Optional, List, Dict
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.narration_engine import NarrationEngine
from core.input_handler import InputHandler, NavigationHelper


class Club:
    """Represents a football club."""
    
    def __init__(self, name: str, league: str, country: str, reputation: int, 
                 budget: str, division: int):
        """
        Initialize a club.
        
        Args:
            name: Club name
            league: League name
            country: Country
            reputation: Reputation level (1-5)
            budget: Transfer budget
            division: Division tier
        """
        self.name = name
        self.league = league
        self.country = country
        self.reputation = reputation
        self.budget = budget
        self.division = division
    
    def get_summary(self) -> str:
        """Get club summary for reading."""
        stars = "★" * self.reputation + "☆" * (5 - self.reputation)
        return (
            f"{self.name}, {self.league}, {self.country}, "
            f"Reputation: {stars} {self.reputation} stars, "
            f"Budget: {self.budget}, Division {self.division}"
        )


class ClubSelectionScreen:
    """
    Club selection screen for choosing a team to manage.
    Supports browsing, filtering, and searching clubs.
    """
    
    def __init__(self, narrator: NarrationEngine, input_handler: InputHandler):
        """
        Initialize the club selection screen.
        
        Args:
            narrator: Narration engine instance
            input_handler: Input handler instance
        """
        self.narrator = narrator
        self.input_handler = input_handler
        self.active = False
        
        # Sample clubs
        self.all_clubs = self._create_sample_clubs()
        self.filtered_clubs = self.all_clubs.copy()
        
        # Navigation
        self.navigator = NavigationHelper([c.get_summary() for c in self.filtered_clubs])
        
        # Filters
        self.country_filter = None
        self.division_filter = None
        
        # Setup key bindings
        self._setup_bindings()
    
    def _create_sample_clubs(self) -> List[Club]:
        """Create sample clubs for demonstration."""
        return [
            Club("Manchester Rovers", "Premier League", "England", 5, "£150M", 1),
            Club("Liverpool United", "Premier League", "England", 5, "£140M", 1),
            Club("Barcelona FC", "La Liga", "Spain", 5, "£120M", 1),
            Club("Real Madrid", "La Liga", "Spain", 5, "£130M", 1),
            Club("Bayern Munich", "Bundesliga", "Germany", 5, "£110M", 1),
            Club("Paris SG", "Ligue 1", "France", 4, "£100M", 1),
            Club("AC Milan", "Serie A", "Italy", 4, "£80M", 1),
            Club("Inter Milan", "Serie A", "Italy", 4, "£85M", 1),
            Club("Newcastle City", "Championship", "England", 3, "£20M", 2),
            Club("Leeds Town", "Championship", "England", 3, "£18M", 2),
            Club("Valencia CF", "La Liga", "Spain", 3, "£25M", 1),
            Club("Sevilla FC", "La Liga", "Spain", 3, "£22M", 1),
        ]
    
    def _setup_bindings(self):
        """Setup keyboard bindings for club selection."""
        self.input_handler.bind('up', 'Previous club', self.previous_club)
        self.input_handler.bind('down', 'Next club', self.next_club)
        self.input_handler.bind('enter', 'Select club', self.select_club)
        self.input_handler.bind('r', 'Read current club', self.read_current)
        self.input_handler.bind('c', 'Filter by country', self.filter_by_country)
        self.input_handler.bind('d', 'Filter by division', self.filter_by_division)
        self.input_handler.bind('x', 'Clear filters', self.clear_filters)
        self.input_handler.bind('escape', 'Back to menu', self.back)
        self.input_handler.bind('h', 'Help', self.show_help)
    
    def activate(self):
        """Activate the club selection screen."""
        self.active = True
        self.input_handler.set_navigation_mode('list')
        
        welcome = f"Club Selection. {len(self.filtered_clubs)} clubs available."
        self.narrator.speak(welcome)
        self.read_current()
    
    def deactivate(self):
        """Deactivate the club selection screen."""
        self.active = False
    
    def next_club(self):
        """Navigate to next club."""
        if self.active:
            summary = self.navigator.next()
            self.narrator.speak(summary)
    
    def previous_club(self):
        """Navigate to previous club."""
        if self.active:
            summary = self.navigator.previous()
            self.narrator.speak(summary)
    
    def read_current(self):
        """Read current club details."""
        if self.active:
            index = self.navigator.get_current_index()
            summary = self.navigator.get_current()
            text = f"Club {index + 1} of {len(self.filtered_clubs)}: {summary}"
            self.narrator.speak(text)
    
    def select_club(self):
        """Select the current club."""
        if self.active:
            index = self.navigator.get_current_index()
            club = self.filtered_clubs[index]
            
            text = f"Selected {club.name}. Starting new career."
            self.narrator.speak(text)
            print(f"[ClubSelection] Selected: {club.name}")
            # TODO: Transition to team overview or game start
    
    def filter_by_country(self):
        """Filter clubs by country (cycle through available countries)."""
        if self.active:
            # Get unique countries
            countries = list(set(c.country for c in self.all_clubs))
            countries.sort()
            
            if self.country_filter is None:
                self.country_filter = countries[0]
            else:
                try:
                    current_idx = countries.index(self.country_filter)
                    self.country_filter = countries[(current_idx + 1) % len(countries)]
                except ValueError:
                    self.country_filter = countries[0]
            
            self._apply_filters()
            self.narrator.speak(f"Filtering by country: {self.country_filter}. {len(self.filtered_clubs)} clubs found.")
    
    def filter_by_division(self):
        """Filter clubs by division."""
        if self.active:
            divisions = [1, 2, 3]
            
            if self.division_filter is None:
                self.division_filter = 1
            else:
                current_idx = divisions.index(self.division_filter)
                self.division_filter = divisions[(current_idx + 1) % len(divisions)]
            
            self._apply_filters()
            self.narrator.speak(f"Filtering by division: {self.division_filter}. {len(self.filtered_clubs)} clubs found.")
    
    def clear_filters(self):
        """Clear all filters."""
        if self.active:
            self.country_filter = None
            self.division_filter = None
            self._apply_filters()
            self.narrator.speak(f"Filters cleared. {len(self.filtered_clubs)} clubs available.")
    
    def _apply_filters(self):
        """Apply current filters to club list."""
        self.filtered_clubs = self.all_clubs.copy()
        
        if self.country_filter:
            self.filtered_clubs = [c for c in self.filtered_clubs if c.country == self.country_filter]
        
        if self.division_filter:
            self.filtered_clubs = [c for c in self.filtered_clubs if c.division == self.division_filter]
        
        # Update navigator
        self.navigator = NavigationHelper([c.get_summary() for c in self.filtered_clubs])
        
        if self.filtered_clubs:
            self.read_current()
    
    def show_help(self):
        """Show help information."""
        if self.active:
            help_text = (
                "Club Selection Help. "
                "Use up and down arrows to navigate clubs. "
                "Press Enter to select a club. "
                "Press R to read current club details. "
                "Press C to filter by country. "
                "Press D to filter by division. "
                "Press X to clear filters. "
                "Press Escape to return to menu."
            )
            self.narrator.speak(help_text)
    
    def back(self):
        """Return to main menu."""
        self.narrator.speak("Returning to main menu")
        self.deactivate()
        print("[ClubSelection] Back to main menu")


def main():
    """Demo function to test club selection screen."""
    print("=== Club Selection Screen Demo ===\n")
    
    # Create instances
    narrator = NarrationEngine({'enabled': True})
    input_handler = InputHandler()
    club_selection = ClubSelectionScreen(narrator, input_handler)
    
    # Activate screen
    club_selection.activate()
    
    # Simulate interactions
    print("\n--- Next club (Down arrow) ---")
    club_selection.next_club()
    
    print("\n--- Filter by country (C key) ---")
    club_selection.filter_by_country()
    
    print("\n--- Next club (Down arrow) ---")
    club_selection.next_club()
    
    print("\n--- Help (H key) ---")
    club_selection.show_help()


if __name__ == "__main__":
    main()
