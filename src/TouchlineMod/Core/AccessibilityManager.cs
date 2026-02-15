using UnityEngine;
using System;
using TouchlineMod.Config;
using TouchlineMod.Navigation;
using TouchlineMod.UI;

namespace TouchlineMod.Core
{
    /// <summary>
    /// Central manager component coordinating all accessibility features.
    /// Attached to a persistent GameObject that survives scene changes.
    /// </summary>
    public class AccessibilityManager : MonoBehaviour
    {
        public static AccessibilityManager Instance { get; private set; }

        private FocusTracker _focusTracker;
        private UIScanner _uiScanner;
        private bool _debugMode;

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(this);
                return;
            }
            Instance = this;
        }

        private void Start()
        {
            Plugin.Log.LogInfo("AccessibilityManager starting...");

            _focusTracker = gameObject.AddComponent<FocusTracker>();
            _uiScanner = gameObject.AddComponent<UIScanner>();

            _focusTracker.OnFocusChanged += HandleFocusChanged;

            Plugin.Log.LogInfo("AccessibilityManager ready");
        }

        private void Update()
        {
            HandleHotkeys();
        }

        private void HandleHotkeys()
        {
            // Ctrl+Shift+D - Toggle debug mode
            if (IsKeyCombo(KeyCode.D, ctrl: true, shift: true))
            {
                _debugMode = !_debugMode;
                TouchlineConfig.DebugMode.Value = _debugMode;
                SpeechOutput.Speak(_debugMode ? "Debug mode on" : "Debug mode off");
            }

            // Ctrl+Shift+S - Deep scan UI
            if (IsKeyCombo(KeyCode.S, ctrl: true, shift: true))
            {
                SpeechOutput.Speak("Scanning UI...");
                _uiScanner.PerformDeepScan();
            }

            // Ctrl+Shift+W - Where am I?
            if (IsKeyCombo(KeyCode.W, ctrl: true, shift: true))
            {
                AnnounceCurrent();
            }

            // Ctrl+Shift+H - Help
            if (IsKeyCombo(KeyCode.H, ctrl: true, shift: true))
            {
                AnnounceHelp();
            }

            // Escape - Stop speech
            if (Input.GetKeyDown(KeyCode.Escape))
            {
                SpeechOutput.Silence();
            }
        }

        private void HandleFocusChanged(AccessibleElement previous, AccessibleElement current)
        {
            if (current == null) return;
            if (!TouchlineConfig.AutoReadOnFocus.Value) return;

            string announcement = current.GetAnnouncement();
            SpeechOutput.Output(announcement);

            if (_debugMode)
            {
                Plugin.Log.LogInfo($"[Focus] {announcement}");
            }
        }

        /// <summary>
        /// Announce the currently focused element.
        /// </summary>
        public void AnnounceCurrent()
        {
            var current = _focusTracker?.CurrentElement;
            if (current != null)
            {
                SpeechOutput.Output(current.GetAnnouncement());
            }
            else
            {
                SpeechOutput.Speak("No element focused");
            }
        }

        /// <summary>
        /// Announce available keyboard shortcuts.
        /// </summary>
        public void AnnounceHelp()
        {
            string help = "Touchline keyboard shortcuts: " +
                          "Ctrl Shift D, toggle debug mode. " +
                          "Ctrl Shift S, scan UI. " +
                          "Ctrl Shift W, where am I. " +
                          "Ctrl Shift H, this help. " +
                          "Escape, stop speech. " +
                          "Arrow keys, navigate. " +
                          "Enter or Space, activate.";
            SpeechOutput.Speak(help);
        }

        private static bool IsKeyCombo(KeyCode key, bool ctrl = false, bool shift = false, bool alt = false)
        {
            if (!Input.GetKeyDown(key)) return false;
            if (ctrl && !(Input.GetKey(KeyCode.LeftControl) || Input.GetKey(KeyCode.RightControl))) return false;
            if (shift && !(Input.GetKey(KeyCode.LeftShift) || Input.GetKey(KeyCode.RightShift))) return false;
            if (alt && !(Input.GetKey(KeyCode.LeftAlt) || Input.GetKey(KeyCode.RightAlt))) return false;
            return true;
        }

        private void OnDestroy()
        {
            if (_focusTracker != null)
                _focusTracker.OnFocusChanged -= HandleFocusChanged;
        }
    }
}
