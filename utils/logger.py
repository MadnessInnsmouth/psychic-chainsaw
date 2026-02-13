"""
Logger utility for Project Touchline
Provides logging functionality for debugging and tracking
"""

import logging
import os
from datetime import datetime
from typing import Optional


class AccessibilityLogger:
    """
    Custom logger for Project Touchline accessibility framework.
    Provides structured logging with different levels and file output.
    """
    
    def __init__(self, name: str = "ProjectTouchline", log_file: Optional[str] = None, 
                 level: int = logging.INFO):
        """
        Initialize the logger.
        
        Args:
            name: Logger name
            log_file: Path to log file (optional)
            level: Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
        """
        self.logger = logging.getLogger(name)
        self.logger.setLevel(level)
        
        # Clear existing handlers
        self.logger.handlers.clear()
        
        # Create formatters
        detailed_formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        
        simple_formatter = logging.Formatter(
            '%(levelname)s: %(message)s'
        )
        
        # Console handler
        console_handler = logging.StreamHandler()
        console_handler.setLevel(level)
        console_handler.setFormatter(simple_formatter)
        self.logger.addHandler(console_handler)
        
        # File handler (if log file specified)
        if log_file:
            try:
                # Create log directory if it doesn't exist
                log_dir = os.path.dirname(log_file)
                if log_dir and not os.path.exists(log_dir):
                    os.makedirs(log_dir)
                
                file_handler = logging.FileHandler(log_file)
                file_handler.setLevel(level)
                file_handler.setFormatter(detailed_formatter)
                self.logger.addHandler(file_handler)
            except Exception as e:
                self.logger.error(f"Failed to create log file: {e}")
    
    def debug(self, message: str):
        """Log a debug message."""
        self.logger.debug(message)
    
    def info(self, message: str):
        """Log an info message."""
        self.logger.info(message)
    
    def warning(self, message: str):
        """Log a warning message."""
        self.logger.warning(message)
    
    def error(self, message: str):
        """Log an error message."""
        self.logger.error(message)
    
    def critical(self, message: str):
        """Log a critical message."""
        self.logger.critical(message)
    
    def log_user_action(self, action: str, details: str = ""):
        """
        Log a user action for analytics.
        
        Args:
            action: Action performed
            details: Additional details
        """
        message = f"USER_ACTION: {action}"
        if details:
            message += f" - {details}"
        self.logger.info(message)
    
    def log_navigation(self, from_screen: str, to_screen: str):
        """
        Log screen navigation.
        
        Args:
            from_screen: Source screen
            to_screen: Destination screen
        """
        self.logger.info(f"NAVIGATION: {from_screen} -> {to_screen}")
    
    def log_accessibility_event(self, event_type: str, details: str = ""):
        """
        Log an accessibility-related event.
        
        Args:
            event_type: Type of event (narration, hotkey, etc.)
            details: Additional details
        """
        message = f"ACCESSIBILITY: {event_type}"
        if details:
            message += f" - {details}"
        self.logger.info(message)
    
    def set_level(self, level: int):
        """
        Set the logging level.
        
        Args:
            level: New logging level
        """
        self.logger.setLevel(level)
        for handler in self.logger.handlers:
            handler.setLevel(level)


# Create a default logger instance
default_logger = AccessibilityLogger(
    name="ProjectTouchline",
    log_file="logs/touchline.log",
    level=logging.INFO
)


def get_logger(name: Optional[str] = None) -> AccessibilityLogger:
    """
    Get a logger instance.
    
    Args:
        name: Logger name (uses default if None)
        
    Returns:
        Logger instance
    """
    if name:
        return AccessibilityLogger(name=name)
    return default_logger
