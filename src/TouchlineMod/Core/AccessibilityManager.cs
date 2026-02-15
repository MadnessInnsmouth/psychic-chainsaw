using UnityEngine;
using System;
using System.Collections.Generic;
using TouchlineMod.Config;
using TouchlineMod.Navigation;
using TouchlineMod.Patches;
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
        private MatchPatches _matchPatches;
        private bool _debugMode;

        // Periodic content change detection
        private string _lastScreenContent = string.Empty;
        private float _contentPollTimer;
        private const float ContentPollInterval = 2.0f;
        private const int MaxScreenTextItems = 50;
        private const int MaxTextCollectionDepth = 15;

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
            _matchPatches = gameObject.AddComponent<MatchPatches>();

            _focusTracker.OnFocusChanged += HandleFocusChanged;

            Plugin.Log.LogInfo("AccessibilityManager ready");
        }

        private void Update()
        {
            HandleHotkeys();
            PollForContentChanges();
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

            // Ctrl+Shift+M - Match state
            if (IsKeyCombo(KeyCode.M, ctrl: true, shift: true))
            {
                _matchPatches?.AnnounceMatchState();
            }

            // Ctrl+Shift+R - Read entire visible screen
            if (IsKeyCombo(KeyCode.R, ctrl: true, shift: true))
            {
                ReadScreen();
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
        /// Periodically check for dynamic content changes on the current screen
        /// (e.g., pop-up dialogs, status messages, notifications).
        /// </summary>
        private void PollForContentChanges()
        {
            _contentPollTimer -= Time.deltaTime;
            if (_contentPollTimer > 0f) return;
            _contentPollTimer = ContentPollInterval;

            try
            {
                // Look for popup/dialog/notification panels that may appear dynamically
                var rootObjects = new List<GameObject>();
                var scene = UnityEngine.SceneManagement.SceneManager.GetActiveScene();
                scene.GetRootGameObjects(rootObjects);

                foreach (var root in rootObjects)
                {
                    ScanForDynamicContent(root.transform);
                }
            }
            catch { }
        }

        /// <summary>
        /// Scan for popup dialogs, notifications, and other dynamic content.
        /// </summary>
        private void ScanForDynamicContent(Transform parent)
        {
            if (parent == null) return;
            string name = parent.name.ToLower();

            // Detect common popup/dialog/notification patterns
            if ((name.Contains("popup") || name.Contains("dialog") || name.Contains("modal")
                || name.Contains("notification") || name.Contains("alert") || name.Contains("toast"))
                && parent.gameObject.activeInHierarchy)
            {
                string text = TextExtractor.ExtractAll(parent.gameObject);
                if (!string.IsNullOrEmpty(text) && text != _lastScreenContent)
                {
                    _lastScreenContent = text;
                    SpeechOutput.Speak(TextCleaner.Clean(text), false);
                }
            }
        }

        /// <summary>
        /// Announce the currently focused element with full context.
        /// </summary>
        public void AnnounceCurrent()
        {
            var current = _focusTracker?.CurrentElement;
            if (current != null)
            {
                string announcement = current.GetAnnouncement();
                if (!string.IsNullOrEmpty(current.Context))
                {
                    announcement = current.Context + ". " + announcement;
                }
                SpeechOutput.Output(announcement);
            }
            else
            {
                SpeechOutput.Speak("No element focused");
            }
        }

        /// <summary>
        /// Read all visible text on the current screen.
        /// Provides a full overview of the active UI for orientation.
        /// </summary>
        public void ReadScreen()
        {
            try
            {
                var rootObjects = new List<GameObject>();
                var scene = UnityEngine.SceneManagement.SceneManager.GetActiveScene();
                scene.GetRootGameObjects(rootObjects);

                var screenTexts = new List<string>();

                foreach (var root in rootObjects)
                {
                    CollectVisibleText(root.transform, screenTexts, 0);
                }

                if (screenTexts.Count > 0)
                {
                    string fullText = string.Join(". ", screenTexts);
                    SpeechOutput.Speak(fullText);
                }
                else
                {
                    SpeechOutput.Speak("No readable text found on screen");
                }
            }
            catch (Exception ex)
            {
                Plugin.Log.LogWarning($"ReadScreen failed: {ex.Message}");
                SpeechOutput.Speak("Could not read screen");
            }
        }

        /// <summary>
        /// Collect visible text from the UI hierarchy for screen reading.
        /// </summary>
        private void CollectVisibleText(Transform parent, List<string> texts, int depth)
        {
            if (parent == null || depth > MaxTextCollectionDepth) return;
            if (!parent.gameObject.activeInHierarchy) return;

            string text = TextExtractor.ExtractDirect(parent.gameObject);
            if (!string.IsNullOrEmpty(text))
            {
                string cleaned = TextCleaner.Clean(text);
                if (!string.IsNullOrEmpty(cleaned) && cleaned.Length > 1 && !texts.Contains(cleaned))
                {
                    texts.Add(cleaned);
                }
            }

            // Limit total text to prevent extremely long announcements
            if (texts.Count >= MaxScreenTextItems) return;

            for (int i = 0; i < parent.childCount; i++)
            {
                CollectVisibleText(parent.GetChild(i), texts, depth + 1);
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
                          "Ctrl Shift M, match score and commentary. " +
                          "Ctrl Shift R, read entire screen. " +
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
