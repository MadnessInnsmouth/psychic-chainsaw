"""
Input Handler for Project Touchline
Manages keyboard input and navigation
"""

import sys
import json
from typing import Dict, Callable, Optional, List


class InputHandler:
    """
    Handles keyboard input and navigation for accessible interface.
    Supports custom hotkey mappings and event-driven callbacks.
    """
    
    def __init__(self, hotkeys_file: Optional[str] = None):
        """
        Initialize the input handler.
        
        Args:
            hotkeys_file: Path to hotkeys configuration JSON file
        """
        self.hotkeys: Dict[str, Callable] = {}
        self.key_bindings: Dict[str, str] = {}
        self.hotkeys_file = hotkeys_file
        self.navigation_mode = 'menu'  # 'menu', 'list', 'form', 'match'
        
        if hotkeys_file:
            self.load_hotkeys(hotkeys_file)
    
    def load_hotkeys(self, filepath: str):
        """
        Load hotkey mappings from JSON configuration file.
        
        Args:
            filepath: Path to hotkeys JSON file
        """
        try:
            with open(filepath, 'r') as f:
                self.key_bindings = json.load(f)
            print(f"[InputHandler] Loaded hotkeys from {filepath}")
        except FileNotFoundError:
            print(f"[InputHandler] Hotkeys file not found: {filepath}")
        except json.JSONDecodeError as e:
            print(f"[InputHandler] Error parsing hotkeys file: {e}")
    
    def bind(self, key: str, action: str, callback: Callable):
        """
        Bind a key to an action with a callback function.
        
        Args:
            key: Key identifier (e.g., 'r', 'up', 'ctrl+s')
            action: Action name/description
            callback: Function to call when key is pressed
        """
        self.hotkeys[key.lower()] = callback
        print(f"[InputHandler] Bound '{key}' to action: {action}")
    
    def unbind(self, key: str):
        """
        Remove a key binding.
        
        Args:
            key: Key identifier to unbind
        """
        if key.lower() in self.hotkeys:
            del self.hotkeys[key.lower()]
            print(f"[InputHandler] Unbound key: {key}")
    
    def handle_key(self, key: str) -> bool:
        """
        Handle a key press event.
        
        Args:
            key: Key that was pressed
            
        Returns:
            True if key was handled, False otherwise
        """
        key = key.lower()
        if key in self.hotkeys:
            try:
                self.hotkeys[key]()
                return True
            except Exception as e:
                print(f"[InputHandler] Error handling key '{key}': {e}")
                return False
        return False
    
    def set_navigation_mode(self, mode: str):
        """
        Set the current navigation mode.
        
        Args:
            mode: Navigation mode ('menu', 'list', 'form', 'match')
        """
        valid_modes = ['menu', 'list', 'form', 'match']
        if mode in valid_modes:
            self.navigation_mode = mode
            print(f"[InputHandler] Navigation mode set to: {mode}")
        else:
            print(f"[InputHandler] Invalid navigation mode: {mode}")
    
    def get_navigation_mode(self) -> str:
        """Get the current navigation mode."""
        return self.navigation_mode
    
    def clear_bindings(self):
        """Clear all key bindings."""
        self.hotkeys.clear()
        print("[InputHandler] Cleared all key bindings")
    
    def list_bindings(self) -> List[str]:
        """
        List all active key bindings.
        
        Returns:
            List of bound keys
        """
        return list(self.hotkeys.keys())
    
    def parse_key_combo(self, key_string: str) -> tuple:
        """
        Parse key combination string (e.g., 'ctrl+s', 'alt+f4').
        
        Args:
            key_string: Key combination string
            
        Returns:
            Tuple of (modifiers, key)
        """
        parts = key_string.lower().split('+')
        if len(parts) == 1:
            return ([], parts[0])
        else:
            modifiers = parts[:-1]
            key = parts[-1]
            return (modifiers, key)


class NavigationHelper:
    """Helper class for common navigation patterns."""
    
    def __init__(self, items: List[str]):
        """
        Initialize navigation helper.
        
        Args:
            items: List of items to navigate through
        """
        self.items = items
        self.current_index = 0
    
    def next(self) -> str:
        """Move to next item and return it."""
        if self.items:
            self.current_index = (self.current_index + 1) % len(self.items)
            return self.get_current()
        return ""
    
    def previous(self) -> str:
        """Move to previous item and return it."""
        if self.items:
            self.current_index = (self.current_index - 1) % len(self.items)
            return self.get_current()
        return ""
    
    def first(self) -> str:
        """Jump to first item and return it."""
        self.current_index = 0
        return self.get_current()
    
    def last(self) -> str:
        """Jump to last item and return it."""
        if self.items:
            self.current_index = len(self.items) - 1
            return self.get_current()
        return ""
    
    def get_current(self) -> str:
        """Get current item."""
        if self.items and 0 <= self.current_index < len(self.items):
            return self.items[self.current_index]
        return ""
    
    def get_current_index(self) -> int:
        """Get current index."""
        return self.current_index
    
    def set_index(self, index: int) -> str:
        """
        Set current index.
        
        Args:
            index: Index to set
            
        Returns:
            Item at the index
        """
        if self.items and 0 <= index < len(self.items):
            self.current_index = index
            return self.get_current()
        return ""
    
    def update_items(self, items: List[str]):
        """
        Update the items list.
        
        Args:
            items: New list of items
        """
        self.items = items
        self.current_index = 0
