"""
Match Day Screen for Project Touchline
Handles live match commentary and statistics
"""

from typing import Optional, List, Dict
import sys
import os
import time
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.narration_engine import NarrationEngine
from core.input_handler import InputHandler


class MatchEvent:
    """Represents a match event (goal, foul, card, etc.)."""
    
    def __init__(self, minute: int, event_type: str, description: str, team: str = ""):
        """
        Initialize a match event.
        
        Args:
            minute: Minute of the event
            event_type: Type of event (goal, yellow_card, substitution, etc.)
            description: Description of the event
            team: Team involved (home/away)
        """
        self.minute = minute
        self.event_type = event_type
        self.description = description
        self.team = team


class MatchStats:
    """Stores match statistics."""
    
    def __init__(self):
        """Initialize match stats."""
        self.home_team = "Your Team"
        self.away_team = "Opposition"
        self.home_score = 0
        self.away_score = 0
        self.possession_home = 50
        self.possession_away = 50
        self.shots_home = 0
        self.shots_away = 0
        self.shots_on_target_home = 0
        self.shots_on_target_away = 0
        self.corners_home = 0
        self.corners_away = 0
        self.fouls_home = 0
        self.fouls_away = 0
        self.yellow_cards_home = 0
        self.yellow_cards_away = 0
        self.red_cards_home = 0
        self.red_cards_away = 0
    
    def get_summary(self) -> str:
        """Get a summary of match stats."""
        return (
            f"{self.home_team} {self.home_score}, {self.away_team} {self.away_score}. "
            f"Possession: {self.home_team} {self.possession_home}%, {self.away_team} {self.possession_away}%. "
            f"Shots: {self.home_team} {self.shots_home}, {self.away_team} {self.shots_away}. "
            f"Shots on target: {self.home_team} {self.shots_on_target_home}, {self.away_team} {self.shots_on_target_away}."
        )


class MatchDayScreen:
    """
    Match day screen with accessible text commentary.
    Provides real-time commentary, match stats, and event tracking.
    """
    
    def __init__(self, narrator: NarrationEngine, input_handler: InputHandler):
        """
        Initialize the match day screen.
        
        Args:
            narrator: Narration engine instance
            input_handler: Input handler instance
        """
        self.narrator = narrator
        self.input_handler = input_handler
        self.active = False
        self.paused = False
        self.commentary_speed = 'normal'  # 'slow', 'normal', 'fast'
        
        self.stats = MatchStats()
        self.events: List[MatchEvent] = []
        self.commentary: List[str] = []
        self.current_minute = 0
        self.current_event_index = 0
        
        # Load sample match data
        self._load_sample_match()
        
        # Setup key bindings
        self._setup_bindings()
    
    def _load_sample_match(self):
        """Load sample match data for demonstration."""
        self.stats.home_team = "Manchester Rovers"
        self.stats.away_team = "Liverpool United"
        
        # Sample events
        self.events = [
            MatchEvent(5, "chance", "Good attacking play down the right wing. Cross is cleared.", "home"),
            MatchEvent(12, "goal", "GOAL! Johnson scores for Manchester Rovers! 1-0!", "home"),
            MatchEvent(18, "yellow_card", "Yellow card for Smith - reckless challenge.", "away"),
            MatchEvent(23, "chance", "Liverpool United with a dangerous free kick. Saved by the keeper!", "away"),
            MatchEvent(35, "corner", "Corner kick for Manchester Rovers.", "home"),
            MatchEvent(45, "half_time", "Half time. Manchester Rovers 1, Liverpool United 0.", ""),
            MatchEvent(52, "substitution", "Substitution: Williams on for Johnson.", "home"),
            MatchEvent(67, "goal", "GOAL! Liverpool United equalize! 1-1!", "away"),
            MatchEvent(75, "yellow_card", "Yellow card for Davies.", "home"),
            MatchEvent(88, "goal", "GOAL! Williams with a stunning strike! Manchester Rovers 2-1!", "home"),
            MatchEvent(90, "full_time", "Full time. Manchester Rovers 2, Liverpool United 1.", ""),
        ]
        
        # Sample commentary
        self.commentary = [
            "Welcome to today's match between Manchester Rovers and Liverpool United.",
            "The teams are lining up in the tunnel.",
            "And we're underway!",
            "Early pressure from the home side.",
            "Good passing movement in midfield.",
        ]
        
        # Update stats based on events
        self.stats.home_score = 2
        self.stats.away_score = 1
        self.stats.possession_home = 55
        self.stats.possession_away = 45
        self.stats.shots_home = 12
        self.stats.shots_away = 8
        self.stats.shots_on_target_home = 6
        self.stats.shots_on_target_away = 4
        self.stats.yellow_cards_home = 1
        self.stats.yellow_cards_away = 1
    
    def _setup_bindings(self):
        """Setup keyboard bindings for match navigation."""
        self.input_handler.bind('space', 'Pause/Resume match', self.toggle_pause)
        self.input_handler.bind('c', 'Read latest commentary', self.read_commentary)
        self.input_handler.bind('p', 'Read possession stats', self.read_possession)
        self.input_handler.bind('t', 'Read match stats', self.read_stats)
        self.input_handler.bind('g', 'Read last goal', self.read_last_goal)
        self.input_handler.bind('e', 'Read last event', self.read_last_event)
        self.input_handler.bind('f', 'Faster commentary', self.faster_commentary)
        self.input_handler.bind('s', 'Slower commentary', self.slower_commentary)
        self.input_handler.bind('left', 'Previous event', self.previous_event)
        self.input_handler.bind('right', 'Next event', self.next_event)
        self.input_handler.bind('escape', 'Back to menu', self.back)
        self.input_handler.bind('h', 'Help', self.show_help)
    
    def activate(self):
        """Activate the match day screen."""
        self.active = True
        self.input_handler.set_navigation_mode('match')
        
        welcome = f"Match Day. {self.stats.home_team} versus {self.stats.away_team}. Press space to pause or resume."
        self.narrator.speak(welcome)
    
    def deactivate(self):
        """Deactivate the match day screen."""
        self.active = False
    
    def toggle_pause(self):
        """Toggle match pause state."""
        if self.active:
            self.paused = not self.paused
            status = "paused" if self.paused else "resumed"
            self.narrator.speak(f"Match {status}")
    
    def read_commentary(self):
        """Read the latest commentary."""
        if self.active and self.commentary:
            latest = self.commentary[-1] if self.commentary else "No commentary available"
            self.narrator.speak(latest)
    
    def read_possession(self):
        """Read possession statistics."""
        if self.active:
            text = f"Possession: {self.stats.home_team} {self.stats.possession_home}%, {self.stats.away_team} {self.stats.possession_away}%"
            self.narrator.speak(text)
    
    def read_stats(self):
        """Read full match statistics."""
        if self.active:
            self.narrator.speak(self.stats.get_summary())
    
    def read_last_goal(self):
        """Read details of the last goal."""
        if self.active:
            goals = [e for e in self.events if e.event_type == "goal"]
            if goals:
                last_goal = goals[-1]
                text = f"Minute {last_goal.minute}: {last_goal.description}"
                self.narrator.speak(text)
            else:
                self.narrator.speak("No goals scored yet")
    
    def read_last_event(self):
        """Read the last event."""
        if self.active and self.events:
            last_event = self.events[-1]
            text = f"Minute {last_event.minute}: {last_event.description}"
            self.narrator.speak(text)
    
    def previous_event(self):
        """Navigate to previous event."""
        if self.active and self.events:
            self.current_event_index = max(0, self.current_event_index - 1)
            event = self.events[self.current_event_index]
            text = f"Event {self.current_event_index + 1} of {len(self.events)}, Minute {event.minute}: {event.description}"
            self.narrator.speak(text)
    
    def next_event(self):
        """Navigate to next event."""
        if self.active and self.events:
            self.current_event_index = min(len(self.events) - 1, self.current_event_index + 1)
            event = self.events[self.current_event_index]
            text = f"Event {self.current_event_index + 1} of {len(self.events)}, Minute {event.minute}: {event.description}"
            self.narrator.speak(text)
    
    def faster_commentary(self):
        """Increase commentary speed."""
        if self.active:
            speeds = ['slow', 'normal', 'fast']
            current_idx = speeds.index(self.commentary_speed)
            if current_idx < len(speeds) - 1:
                self.commentary_speed = speeds[current_idx + 1]
                # Increase narration rate
                rate = {'slow': 120, 'normal': 150, 'fast': 200}[self.commentary_speed]
                self.narrator.set_rate(rate)
                self.narrator.speak(f"Commentary speed: {self.commentary_speed}")
    
    def slower_commentary(self):
        """Decrease commentary speed."""
        if self.active:
            speeds = ['slow', 'normal', 'fast']
            current_idx = speeds.index(self.commentary_speed)
            if current_idx > 0:
                self.commentary_speed = speeds[current_idx - 1]
                # Decrease narration rate
                rate = {'slow': 120, 'normal': 150, 'fast': 200}[self.commentary_speed]
                self.narrator.set_rate(rate)
                self.narrator.speak(f"Commentary speed: {self.commentary_speed}")
    
    def show_help(self):
        """Show help information."""
        if self.active:
            help_text = (
                "Match Day Help. "
                "Press Space to pause or resume. "
                "Press C for latest commentary. "
                "Press P for possession stats. "
                "Press T for all match stats. "
                "Press G for last goal. "
                "Press E for last event. "
                "Press F for faster commentary, S for slower. "
                "Use left and right arrows to navigate events. "
                "Press Escape to return to menu."
            )
            self.narrator.speak(help_text)
    
    def back(self):
        """Return to main menu."""
        self.narrator.speak("Returning to main menu")
        self.deactivate()
        print("[MatchDay] Back to main menu")


def main():
    """Demo function to test match day screen."""
    print("=== Match Day Screen Demo ===\n")
    
    # Create instances
    narrator = NarrationEngine({'enabled': True})
    input_handler = InputHandler()
    match = MatchDayScreen(narrator, input_handler)
    
    # Activate match screen
    match.activate()
    
    # Simulate interactions
    print("\n--- Reading possession (P key) ---")
    match.read_possession()
    
    print("\n--- Reading stats (T key) ---")
    match.read_stats()
    
    print("\n--- Reading last goal (G key) ---")
    match.read_last_goal()
    
    print("\n--- Next event (Right arrow) ---")
    match.next_event()
    
    print("\n--- Help (H key) ---")
    match.show_help()


if __name__ == "__main__":
    main()
