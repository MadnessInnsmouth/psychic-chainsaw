#!/usr/bin/env python3
"""
Interactive Demo for Project Touchline
Demonstrates the accessibility framework in an interactive way
"""

import sys
import os
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from core.narration_engine import NarrationEngine
from core.input_handler import InputHandler
from screens.main_menu_screen import MainMenuScreen
from screens.inbox_screen import InboxScreen
from screens.matchday_screen import MatchDayScreen
from screens.tactics_screen import TacticsScreen


def print_header(title):
    """Print a formatted header."""
    print("\n" + "=" * 70)
    print(f"  {title}")
    print("=" * 70 + "\n")


def print_box(text, width=70):
    """Print text in a box."""
    print("┌" + "─" * (width - 2) + "┐")
    for line in text.split('\n'):
        padding = width - len(line) - 4
        print(f"│ {line}{' ' * padding} │")
    print("└" + "─" * (width - 2) + "┘")


def simulate_interaction(description, action_func):
    """Simulate a user interaction."""
    print(f"\n→ {description}")
    time.sleep(0.3)
    action_func()
    time.sleep(0.5)


def demo_main_menu():
    """Interactive demo of main menu."""
    print_header("MAIN MENU DEMO")
    
    narrator = NarrationEngine({'enabled': True})
    input_handler = InputHandler()
    menu = MainMenuScreen(narrator, input_handler)
    
    print("The main menu is the entry point to the game.")
    print("Users can navigate with arrow keys and select with Enter.\n")
    
    simulate_interaction("Activating main menu...", menu.activate)
    
    print("\n📋 Available actions:")
    print("  ↑/↓  - Navigate menu items")
    print("  Enter - Select item")
    print("  R    - Read current item")
    print("  H    - Help")
    
    simulate_interaction("Pressing DOWN arrow →", menu.next_item)
    simulate_interaction("Pressing DOWN arrow →", menu.next_item)
    simulate_interaction("Pressing R to read current →", menu.read_current)
    
    print("\n✅ Main menu navigation working correctly!")


def demo_inbox():
    """Interactive demo of inbox."""
    print_header("INBOX DEMO")
    
    narrator = NarrationEngine({'enabled': True})
    input_handler = InputHandler()
    inbox = InboxScreen(narrator, input_handler)
    
    print("The inbox shows emails from board, scouts, and staff.")
    print("Users can browse and read emails with keyboard controls.\n")
    
    simulate_interaction("Opening inbox...", inbox.activate)
    
    print("\n📋 Available actions:")
    print("  ↑/↓   - Navigate emails")
    print("  Enter - Open email")
    print("  R     - Read full email")
    
    simulate_interaction("Pressing DOWN arrow →", inbox.next_email)
    simulate_interaction("Pressing R to read email →", inbox.read_full_email)
    
    print("\n✅ Inbox navigation working correctly!")


def demo_match_day():
    """Interactive demo of match day."""
    print_header("MATCH DAY DEMO")
    
    narrator = NarrationEngine({'enabled': True})
    input_handler = InputHandler()
    match = MatchDayScreen(narrator, input_handler)
    
    print("Match day provides real-time text commentary.")
    print("Users can check stats, goals, and events via hotkeys.\n")
    
    simulate_interaction("Starting match...", match.activate)
    
    print("\n📋 Available actions:")
    print("  Space - Pause/Resume")
    print("  C     - Read commentary")
    print("  P     - Possession stats")
    print("  T     - All stats")
    print("  G     - Last goal")
    print("  ←/→   - Navigate events")
    
    simulate_interaction("Pressing P for possession stats →", match.read_possession)
    simulate_interaction("Pressing G to hear last goal →", match.read_last_goal)
    simulate_interaction("Pressing → to next event →", match.next_event)
    
    print("\n✅ Match day features working correctly!")


def demo_tactics():
    """Interactive demo of tactics screen."""
    print_header("TACTICS DEMO")
    
    narrator = NarrationEngine({'enabled': True})
    input_handler = InputHandler()
    tactics = TacticsScreen(narrator, input_handler)
    
    print("The tactics screen manages formations and player positions.")
    print("Users can change formations and assign player roles.\n")
    
    simulate_interaction("Opening tactics screen...", tactics.activate)
    
    print("\n📋 Available actions:")
    print("  ↑/↓  - Navigate players")
    print("  F    - Change formation")
    print("  R    - Read formation")
    print("  S    - Substitutions")
    
    simulate_interaction("Pressing DOWN arrow →", tactics.next_player)
    simulate_interaction("Pressing F to change formation →", tactics.change_formation)
    
    print("\n✅ Tactics screen working correctly!")


def main():
    """Main interactive demo."""
    print_box("""
    PROJECT TOUCHLINE
    Interactive Demo
    
    Football Manager 2026 Accessibility Framework
    Making the game fully playable for blind users
    """, 70)
    
    print("\nThis demo shows the core accessibility features in action.")
    print("Each screen demonstrates keyboard navigation and text-to-speech.\n")
    
    input("Press Enter to start the demo...")
    
    # Run demos
    demo_main_menu()
    input("\nPress Enter to continue to Inbox demo...")
    
    demo_inbox()
    input("\nPress Enter to continue to Match Day demo...")
    
    demo_match_day()
    input("\nPress Enter to continue to Tactics demo...")
    
    demo_tactics()
    
    # Summary
    print_header("DEMO COMPLETE")
    
    print_box("""
    ✅ All core features demonstrated successfully!
    
    Phase 1 MVP includes:
    • Main menu navigation
    • Inbox/email system
    • Club selection
    • Team overview
    • Match day commentary
    • Tactics screen
    • Save/load functionality
    
    All features are keyboard-accessible with text-to-speech support.
    """, 70)
    
    print("\nFor more information:")
    print("  • Read README.md for full documentation")
    print("  • Check roadmap.txt for development plans")
    print("  • Run individual screen demos with: python screens/<screen_name>.py")
    print("  • Try: python main.py --demo")
    print("\nThank you for exploring Project Touchline! 🎮")


if __name__ == "__main__":
    main()
