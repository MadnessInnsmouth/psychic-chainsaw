"""
Narration Engine for Project Touchline
Provides text-to-speech functionality for accessibility
"""

import platform
import threading
from typing import Optional, Callable


class NarrationEngine:
    """
    Handles text-to-speech narration for blind/visually impaired users.
    Supports multiple TTS backends (pyttsx3, eSpeak, system TTS).
    """
    
    def __init__(self, config: Optional[dict] = None):
        """
        Initialize the narration engine.
        
        Args:
            config: Configuration dictionary with TTS settings
        """
        self.config = config or {}
        self.enabled = self.config.get('enabled', True)
        self.rate = self.config.get('rate', 150)  # Words per minute
        self.volume = self.config.get('volume', 1.0)  # 0.0 to 1.0
        self.voice = self.config.get('voice', None)
        self.engine = None
        self.speaking = False
        self._init_engine()
    
    def _init_engine(self):
        """Initialize the TTS engine based on platform and availability."""
        try:
            import pyttsx3
            self.engine = pyttsx3.init()
            self.engine.setProperty('rate', self.rate)
            self.engine.setProperty('volume', self.volume)
            
            if self.voice:
                self.engine.setProperty('voice', self.voice)
            
            print("[NarrationEngine] pyttsx3 initialized successfully")
        except ImportError:
            print("[NarrationEngine] pyttsx3 not available, using fallback")
            self.engine = None
        except Exception as e:
            print(f"[NarrationEngine] Error initializing TTS: {e}")
            self.engine = None
    
    def speak(self, text: str, interrupt: bool = True):
        """
        Speak the given text.
        
        Args:
            text: Text to speak
            interrupt: If True, interrupt current speech
        """
        if not self.enabled or not text:
            return
        
        if interrupt and self.speaking:
            self.stop()
        
        if self.engine:
            try:
                self.speaking = True
                self.engine.say(text)
                self.engine.runAndWait()
                self.speaking = False
            except Exception as e:
                print(f"[NarrationEngine] Error speaking: {e}")
                self.speaking = False
        else:
            # Fallback: print to console
            print(f"[SPEAK]: {text}")
    
    def speak_async(self, text: str, callback: Optional[Callable] = None):
        """
        Speak text asynchronously in a separate thread.
        
        Args:
            text: Text to speak
            callback: Optional callback to run after speaking
        """
        def _speak():
            self.speak(text, interrupt=False)
            if callback:
                callback()
        
        thread = threading.Thread(target=_speak, daemon=True)
        thread.start()
    
    def stop(self):
        """Stop current speech."""
        if self.engine and self.speaking:
            try:
                self.engine.stop()
                self.speaking = False
            except Exception as e:
                print(f"[NarrationEngine] Error stopping speech: {e}")
    
    def set_rate(self, rate: int):
        """
        Set speech rate.
        
        Args:
            rate: Words per minute (typically 100-300)
        """
        self.rate = rate
        if self.engine:
            self.engine.setProperty('rate', rate)
    
    def set_volume(self, volume: float):
        """
        Set speech volume.
        
        Args:
            volume: Volume level (0.0 to 1.0)
        """
        self.volume = max(0.0, min(1.0, volume))
        if self.engine:
            self.engine.setProperty('volume', self.volume)
    
    def toggle(self):
        """Toggle narration on/off."""
        self.enabled = not self.enabled
        status = "enabled" if self.enabled else "disabled"
        print(f"[NarrationEngine] Narration {status}")
        if self.enabled:
            self.speak(f"Narration {status}")
    
    def list_voices(self):
        """List available voices."""
        if self.engine:
            voices = self.engine.getProperty('voices')
            return [(v.id, v.name) for v in voices]
        return []
    
    def set_voice(self, voice_id: str):
        """
        Set the TTS voice.
        
        Args:
            voice_id: Voice identifier
        """
        self.voice = voice_id
        if self.engine:
            self.engine.setProperty('voice', voice_id)
