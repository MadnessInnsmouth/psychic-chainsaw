using BepInEx.Configuration;

namespace TouchlineMod.Config
{
    /// <summary>
    /// BepInEx configuration entries for the Touchline accessibility mod.
    /// Settings are saved to BepInEx/config/com.touchline.fm26accessibility.cfg
    /// </summary>
    public static class TouchlineConfig
    {
        // Speech settings
        public static ConfigEntry<bool> SpeechEnabled { get; private set; }
        public static ConfigEntry<bool> InterruptOnNew { get; private set; }
        public static ConfigEntry<bool> AnnounceElementType { get; private set; }
        public static ConfigEntry<bool> AnnounceElementState { get; private set; }

        // Navigation settings
        public static ConfigEntry<bool> AutoReadOnFocus { get; private set; }
        public static ConfigEntry<bool> AnnounceTableHeaders { get; private set; }
        public static ConfigEntry<bool> ReadFullTableRow { get; private set; }
        public static ConfigEntry<float> FocusChangeDelay { get; private set; }

        // Debug settings
        public static ConfigEntry<bool> DebugMode { get; private set; }
        public static ConfigEntry<bool> LogUIHierarchy { get; private set; }

        public static void Init(ConfigFile config)
        {
            // Speech
            SpeechEnabled = config.Bind(
                "Speech", "Enabled", true,
                "Enable or disable all speech output");

            InterruptOnNew = config.Bind(
                "Speech", "InterruptOnNew", true,
                "Stop current speech when new text is queued");

            AnnounceElementType = config.Bind(
                "Speech", "AnnounceElementType", true,
                "Announce the type of UI element (button, checkbox, etc.)");

            AnnounceElementState = config.Bind(
                "Speech", "AnnounceElementState", true,
                "Announce element state (checked, selected, etc.)");

            // Navigation
            AutoReadOnFocus = config.Bind(
                "Navigation", "AutoReadOnFocus", true,
                "Automatically read element text when focus changes");

            AnnounceTableHeaders = config.Bind(
                "Navigation", "AnnounceTableHeaders", true,
                "Announce column headers when entering a table");

            ReadFullTableRow = config.Bind(
                "Navigation", "ReadFullTableRow", true,
                "Read all cells in a row when navigating tables");

            FocusChangeDelay = config.Bind(
                "Navigation", "FocusChangeDelay", 0.1f,
                new ConfigDescription(
                    "Delay in seconds before announcing a focus change (prevents rapid-fire speech)",
                    new AcceptableValueRange<float>(0f, 1f)));

            // Debug
            DebugMode = config.Bind(
                "Debug", "DebugMode", false,
                "Enable debug logging for accessibility events");

            LogUIHierarchy = config.Bind(
                "Debug", "LogUIHierarchy", false,
                "Log the full UI hierarchy when scanning (creates large log files)");
        }
    }
}
