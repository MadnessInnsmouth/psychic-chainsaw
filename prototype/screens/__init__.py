"""
Screens module for Project Touchline accessibility framework
"""

from .main_menu_screen import MainMenuScreen
from .inbox_screen import InboxScreen
from .matchday_screen import MatchDayScreen
from .tactics_screen import TacticsScreen
from .club_selection_screen import ClubSelectionScreen
from .team_overview_screen import TeamOverviewScreen
from .save_load_screen import SaveLoadScreen

__all__ = [
    'MainMenuScreen',
    'InboxScreen',
    'MatchDayScreen',
    'TacticsScreen',
    'ClubSelectionScreen',
    'TeamOverviewScreen',
    'SaveLoadScreen',
]
