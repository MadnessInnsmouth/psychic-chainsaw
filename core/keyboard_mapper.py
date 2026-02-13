"""
Keyboard Mapper for Project Touchline
Provides customizable keyboard mapping system
"""

import json
from typing import Dict, Optional, List


class KeyboardMapper:
    """
    Manages keyboard mappings and allows customization.
    Supports remapping keys and saving/loading configurations.
    """
    
    def __init__(self, config_file: Optional[str] = None):
        """
        Initialize the keyboard mapper.
        
        Args:
            config_file: Path to configuration file
        """
        self.mappings: Dict[str, Dict[str, str]] = {}
        self.config_file = config_file
        self.current_preset = 'default'
        
        # Initialize default mappings
        self._init_default_mappings()
        
        if config_file:
            self.load_config(config_file)
    
    def _init_default_mappings(self):
        """Initialize default keyboard mappings for different contexts."""
        
        # Default preset for general navigation
        self.mappings['default'] = {
            'up': 'navigate_up',
            'down': 'navigate_down',
            'left': 'navigate_left',
            'right': 'navigate_right',
            'enter': 'select',
            'escape': 'back',
            'tab': 'next_section',
            'shift+tab': 'previous_section',
            'space': 'toggle',
            'r': 'read_current',
            's': 'save',
            'l': 'load',
            'h': 'help',
            'q': 'quit',
            'm': 'main_menu',
            'n': 'toggle_narration',
            'f1': 'help',
            'ctrl+s': 'save',
            'ctrl+l': 'load',
        }
        
        # Screen reader optimized preset
        self.mappings['screen_reader'] = {
            'up': 'navigate_up',
            'down': 'navigate_down',
            'left': 'navigate_left',
            'right': 'navigate_right',
            'enter': 'select',
            'escape': 'back',
            'insert+r': 'read_current',
            'insert+s': 'stop_speech',
            'insert+h': 'read_heading',
            'insert+t': 'read_title',
            'ctrl+home': 'first_item',
            'ctrl+end': 'last_item',
        }
        
        # Match day specific mappings
        self.mappings['match'] = {
            'space': 'pause_match',
            'c': 'read_commentary',
            'p': 'read_possession',
            't': 'read_stats',
            'g': 'read_last_goal',
            'e': 'read_last_event',
            'f': 'faster_commentary',
            'slower': 'slower_commentary',
            'left': 'previous_event',
            'right': 'next_event',
            'escape': 'back_to_menu',
        }
        
        # Tactics screen mappings
        self.mappings['tactics'] = {
            'up': 'previous_player',
            'down': 'next_player',
            'left': 'previous_position',
            'right': 'next_position',
            'enter': 'select_player',
            'f': 'change_formation',
            'r': 'read_formation',
            's': 'substitute_menu',
            'i': 'player_instructions',
            'escape': 'back',
        }
        
        # Inbox/email mappings
        self.mappings['inbox'] = {
            'up': 'previous_email',
            'down': 'next_email',
            'enter': 'open_email',
            'r': 'read_email',
            'd': 'delete_email',
            'a': 'archive_email',
            'escape': 'back',
        }
    
    def load_config(self, filepath: str):
        """
        Load keyboard mappings from a configuration file.
        
        Args:
            filepath: Path to JSON configuration file
        """
        try:
            with open(filepath, 'r') as f:
                loaded_mappings = json.load(f)
                # Merge loaded mappings with defaults
                for preset, mappings in loaded_mappings.items():
                    if preset in self.mappings:
                        self.mappings[preset].update(mappings)
                    else:
                        self.mappings[preset] = mappings
            print(f"[KeyboardMapper] Loaded configuration from {filepath}")
        except FileNotFoundError:
            print(f"[KeyboardMapper] Config file not found: {filepath}")
        except json.JSONDecodeError as e:
            print(f"[KeyboardMapper] Error parsing config file: {e}")
    
    def save_config(self, filepath: str):
        """
        Save current keyboard mappings to a file.
        
        Args:
            filepath: Path to save configuration
        """
        try:
            with open(filepath, 'w') as f:
                json.dump(self.mappings, f, indent=2)
            print(f"[KeyboardMapper] Saved configuration to {filepath}")
        except Exception as e:
            print(f"[KeyboardMapper] Error saving config: {e}")
    
    def set_preset(self, preset_name: str):
        """
        Set the active keyboard preset.
        
        Args:
            preset_name: Name of preset to activate
        """
        if preset_name in self.mappings:
            self.current_preset = preset_name
            print(f"[KeyboardMapper] Activated preset: {preset_name}")
            return True
        else:
            print(f"[KeyboardMapper] Preset not found: {preset_name}")
            return False
    
    def get_action(self, key: str, preset: Optional[str] = None) -> Optional[str]:
        """
        Get the action mapped to a key.
        
        Args:
            key: Key to look up
            preset: Preset to use (uses current preset if None)
            
        Returns:
            Action name or None if not mapped
        """
        preset = preset or self.current_preset
        if preset in self.mappings:
            return self.mappings[preset].get(key.lower())
        return None
    
    def map_key(self, key: str, action: str, preset: Optional[str] = None):
        """
        Map a key to an action.
        
        Args:
            key: Key to map
            action: Action to map to
            preset: Preset to modify (uses current preset if None)
        """
        preset = preset or self.current_preset
        if preset not in self.mappings:
            self.mappings[preset] = {}
        self.mappings[preset][key.lower()] = action
        print(f"[KeyboardMapper] Mapped '{key}' to '{action}' in preset '{preset}'")
    
    def unmap_key(self, key: str, preset: Optional[str] = None):
        """
        Remove a key mapping.
        
        Args:
            key: Key to unmap
            preset: Preset to modify (uses current preset if None)
        """
        preset = preset or self.current_preset
        if preset in self.mappings and key.lower() in self.mappings[preset]:
            del self.mappings[preset][key.lower()]
            print(f"[KeyboardMapper] Unmapped '{key}' from preset '{preset}'")
    
    def get_mappings(self, preset: Optional[str] = None) -> Dict[str, str]:
        """
        Get all mappings for a preset.
        
        Args:
            preset: Preset to get (uses current preset if None)
            
        Returns:
            Dictionary of key->action mappings
        """
        preset = preset or self.current_preset
        return self.mappings.get(preset, {}).copy()
    
    def list_presets(self) -> List[str]:
        """
        Get list of available presets.
        
        Returns:
            List of preset names
        """
        return list(self.mappings.keys())
    
    def create_preset(self, name: str, base_preset: Optional[str] = None):
        """
        Create a new preset, optionally based on an existing one.
        
        Args:
            name: Name for the new preset
            base_preset: Preset to copy from (optional)
        """
        if base_preset and base_preset in self.mappings:
            self.mappings[name] = self.mappings[base_preset].copy()
            print(f"[KeyboardMapper] Created preset '{name}' based on '{base_preset}'")
        else:
            self.mappings[name] = {}
            print(f"[KeyboardMapper] Created empty preset '{name}'")
