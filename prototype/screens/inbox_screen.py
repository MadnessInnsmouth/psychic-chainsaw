"""
Inbox Screen for Project Touchline
Handles email/message navigation and reading
"""

from typing import Optional, List, Dict
import sys
import os
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.narration_engine import NarrationEngine
from core.input_handler import InputHandler, NavigationHelper


class Email:
    """Represents an email/message in the inbox."""
    
    def __init__(self, sender: str, subject: str, content: str, date: str, read: bool = False):
        """
        Initialize an email.
        
        Args:
            sender: Email sender
            subject: Email subject
            content: Email body content
            date: Date string
            read: Whether email has been read
        """
        self.sender = sender
        self.subject = subject
        self.content = content
        self.date = date
        self.read = read
    
    def get_summary(self) -> str:
        """Get a summary of the email for list view."""
        read_status = "read" if self.read else "unread"
        return f"{read_status}, From {self.sender}, {self.subject}, {self.date}"
    
    def mark_read(self):
        """Mark email as read."""
        self.read = True


class InboxScreen:
    """
    Inbox screen for reading emails and messages.
    Supports navigation, reading, and managing emails.
    """
    
    def __init__(self, narrator: NarrationEngine, input_handler: InputHandler):
        """
        Initialize the inbox screen.
        
        Args:
            narrator: Narration engine instance
            input_handler: Input handler instance
        """
        self.narrator = narrator
        self.input_handler = input_handler
        self.emails: List[Email] = []
        self.navigator: Optional[NavigationHelper] = None
        self.active = False
        self.current_email: Optional[Email] = None
        
        # Load sample emails
        self._load_sample_emails()
        
        # Setup navigation
        self._update_navigator()
        
        # Setup key bindings
        self._setup_bindings()
    
    def _load_sample_emails(self):
        """Load sample emails for demonstration."""
        self.emails = [
            Email(
                "Board of Directors",
                "Welcome to the Club",
                "Welcome to your new role as manager. We have high expectations for this season. "
                "Please review the squad and make any necessary signings. Good luck!",
                "1 Jan 2026"
            ),
            Email(
                "Assistant Manager",
                "Squad Training Report",
                "The team is looking sharp in training. Fitness levels are good overall, "
                "but we need to work on set pieces. Player morale is high.",
                "3 Jan 2026"
            ),
            Email(
                "Chief Scout",
                "New Talent Identified",
                "We've identified a promising young striker from the academy. "
                "Age 18, good potential. Recommend adding to first team squad for development.",
                "5 Jan 2026"
            ),
            Email(
                "Director of Football",
                "Transfer Budget Update",
                "Your transfer budget for this window is £10 million. "
                "The board expects us to strengthen the midfield area. "
                "Several targets have been shortlisted.",
                "7 Jan 2026"
            ),
        ]
    
    def _update_navigator(self):
        """Update the navigator with current email summaries."""
        summaries = [email.get_summary() for email in self.emails]
        self.navigator = NavigationHelper(summaries)
    
    def _setup_bindings(self):
        """Setup keyboard bindings for inbox navigation."""
        self.input_handler.bind('up', 'Previous email', self.previous_email)
        self.input_handler.bind('down', 'Next email', self.next_email)
        self.input_handler.bind('enter', 'Open email', self.open_email)
        self.input_handler.bind('r', 'Read full email', self.read_full_email)
        self.input_handler.bind('escape', 'Back to menu', self.back)
        self.input_handler.bind('h', 'Help', self.show_help)
    
    def activate(self):
        """Activate the inbox screen."""
        self.active = True
        self.input_handler.set_navigation_mode('inbox')
        
        unread_count = sum(1 for e in self.emails if not e.read)
        welcome = f"Inbox. {len(self.emails)} total messages, {unread_count} unread."
        self.narrator.speak(welcome)
        self.read_current_summary()
    
    def deactivate(self):
        """Deactivate the inbox screen."""
        self.active = False
        self.current_email = None
    
    def next_email(self):
        """Navigate to next email."""
        if self.active and self.navigator:
            summary = self.navigator.next()
            self.narrator.speak(summary)
    
    def previous_email(self):
        """Navigate to previous email."""
        if self.active and self.navigator:
            summary = self.navigator.previous()
            self.narrator.speak(summary)
    
    def read_current_summary(self):
        """Read summary of current email."""
        if self.active and self.navigator:
            index = self.navigator.get_current_index()
            summary = self.navigator.get_current()
            text = f"Email {index + 1} of {len(self.emails)}: {summary}"
            self.narrator.speak(text)
    
    def open_email(self):
        """Open and mark the current email as read."""
        if self.active and self.navigator:
            index = self.navigator.get_current_index()
            self.current_email = self.emails[index]
            self.current_email.mark_read()
            
            # Update navigator to reflect read status
            self._update_navigator()
            self.navigator.set_index(index)
            
            self.read_full_email()
    
    def read_full_email(self):
        """Read the full content of current email."""
        if self.active and self.navigator:
            index = self.navigator.get_current_index()
            email = self.emails[index]
            
            full_text = (
                f"Email from {email.sender}, dated {email.date}. "
                f"Subject: {email.subject}. "
                f"Message: {email.content}"
            )
            self.narrator.speak(full_text)
    
    def show_help(self):
        """Show help information."""
        if self.active:
            help_text = (
                "Inbox Help. "
                "Use up and down arrows to navigate emails. "
                "Press Enter or R to read full email. "
                "Press Escape to return to main menu. "
                "Press H for help."
            )
            self.narrator.speak(help_text)
    
    def back(self):
        """Return to main menu."""
        self.narrator.speak("Returning to main menu")
        self.deactivate()
        print("[Inbox] Back to main menu")


def main():
    """Demo function to test inbox screen."""
    print("=== Inbox Screen Demo ===\n")
    
    # Create instances
    narrator = NarrationEngine({'enabled': True})
    input_handler = InputHandler()
    inbox = InboxScreen(narrator, input_handler)
    
    # Activate inbox
    inbox.activate()
    
    # Simulate navigation
    print("\n--- Simulating down arrow ---")
    inbox.next_email()
    
    print("\n--- Simulating read email (R key) ---")
    inbox.read_full_email()
    
    print("\n--- Simulating down arrow ---")
    inbox.next_email()
    
    print("\n--- Simulating open email (Enter) ---")
    inbox.open_email()
    
    print("\n--- Simulating help (H key) ---")
    inbox.show_help()


if __name__ == "__main__":
    main()
