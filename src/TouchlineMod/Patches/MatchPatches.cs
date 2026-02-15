using HarmonyLib;
using System;
using System.Collections.Generic;
using System.Reflection;
using TouchlineMod.Core;
using TouchlineMod.Config;
using UnityEngine;

namespace TouchlineMod.Patches
{
    /// <summary>
    /// Harmony patches and polling logic for live match day events in FM26.
    /// Hooks into match engine components to narrate goals, score updates,
    /// commentary text, and match status changes for screen reader users.
    /// </summary>
    public class MatchPatches : MonoBehaviour
    {
        public static MatchPatches Instance { get; private set; }

        private string _lastCommentary = string.Empty;
        private string _lastScore = string.Empty;
        private string _lastMatchStatus = string.Empty;
        private int _lastMinute = -1;
        private float _pollTimer;

        // Reflection-cached types and members (resolved once at startup)
        private Type _matchViewModelType;
        private Type _commentaryType;
        private bool _typesResolved;
        private bool _matchTypesAvailable;

        private const float PollInterval = 0.5f;
        private const int HalfTime = 45;
        private const int FullTime = 90;
        private const int ExtraTimeHalf = 105;
        private const int ExtraTimeFull = 120;
        private const int MaxChildScanDepth = 50;

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
            ResolveMatchTypes();
        }

        /// <summary>
        /// Try to locate FM26 match engine types via reflection.
        /// This runs once and caches the results.
        /// </summary>
        private void ResolveMatchTypes()
        {
            if (_typesResolved) return;
            _typesResolved = true;

            try
            {
                // FM26 match view models — these types hold live match state
                _matchViewModelType = Type.GetType("FM.UI.MatchViewModel, FM.UI")
                    ?? Type.GetType("FM.Match.MatchViewModel, FM.Match");

                _commentaryType = Type.GetType("FM.UI.MatchCommentaryViewModel, FM.UI")
                    ?? Type.GetType("FM.Match.CommentaryEntry, FM.Match");

                _matchTypesAvailable = _matchViewModelType != null;

                if (_matchTypesAvailable)
                {
                    Plugin.Log.LogInfo("Match engine types resolved — live commentary available");
                }
                else
                {
                    Plugin.Log.LogInfo("Match engine types not found — will use UI text polling for match events");
                }
            }
            catch (Exception ex)
            {
                Plugin.Log.LogWarning($"Failed to resolve match types: {ex.Message}");
            }
        }

        private void Update()
        {
            if (!TouchlineConfig.SpeechEnabled.Value) return;

            _pollTimer -= Time.deltaTime;
            if (_pollTimer > 0f) return;
            _pollTimer = PollInterval;

            PollMatchState();
        }

        /// <summary>
        /// Poll for match state changes by scanning the active UI for match-related text.
        /// Uses both reflection-based game API access and UI text scanning as fallback.
        /// </summary>
        private void PollMatchState()
        {
            try
            {
                // Strategy 1: Try FM26 match API via reflection
                if (_matchTypesAvailable)
                {
                    PollViaMatchAPI();
                }

                // Strategy 2: Scan active UI for match-related panels (works even without API)
                PollViaUIScanning();
            }
            catch (Exception ex)
            {
                if (TouchlineConfig.DebugMode.Value)
                {
                    Plugin.Log.LogWarning($"Match poll error: {ex.Message}");
                }
            }
        }

        /// <summary>
        /// Attempt to read match state via FM26's match view model API.
        /// </summary>
        private void PollViaMatchAPI()
        {
            try
            {
                // Look for singleton or active instance of match view model
                var instanceProp = _matchViewModelType.GetProperty("Instance",
                    BindingFlags.Public | BindingFlags.Static);
                var currentProp = _matchViewModelType.GetProperty("Current",
                    BindingFlags.Public | BindingFlags.Static);

                object matchVM = instanceProp?.GetValue(null) ?? currentProp?.GetValue(null);
                if (matchVM == null) return;

                // Read score
                ReadMatchProperty(matchVM, new[] { "Score", "ScoreText", "ScoreLine" },
                    ref _lastScore, "Score update");

                // Read match minute
                ReadMatchMinute(matchVM);

                // Read commentary
                ReadCommentary(matchVM);

                // Read match status
                ReadMatchProperty(matchVM, new[] { "MatchStatus", "Status", "StatusText" },
                    ref _lastMatchStatus, null);
            }
            catch { }
        }

        /// <summary>
        /// Read a string property from the match view model and announce if changed.
        /// </summary>
        private void ReadMatchProperty(object viewModel, string[] propertyNames,
            ref string lastValue, string prefix)
        {
            foreach (string propName in propertyNames)
            {
                var prop = viewModel.GetType().GetProperty(propName);
                if (prop != null && prop.PropertyType == typeof(string))
                {
                    string value = prop.GetValue(viewModel) as string;
                    if (!string.IsNullOrEmpty(value) && value != lastValue)
                    {
                        lastValue = value;
                        string cleaned = TextCleaner.Clean(value);
                        string announcement = string.IsNullOrEmpty(prefix)
                            ? cleaned
                            : $"{prefix}: {cleaned}";
                        SpeechOutput.Speak(announcement, false);
                    }
                    return;
                }
            }
        }

        /// <summary>
        /// Track match minute and announce significant time milestones.
        /// </summary>
        private void ReadMatchMinute(object viewModel)
        {
            foreach (string propName in new[] { "MatchMinute", "Minute", "CurrentMinute", "Time" })
            {
                var prop = viewModel.GetType().GetProperty(propName);
                if (prop != null)
                {
                    try
                    {
                        int minute = Convert.ToInt32(prop.GetValue(viewModel));
                        if (minute != _lastMinute && minute > 0)
                        {
                            // Announce key time milestones
                            if (minute == HalfTime || minute == FullTime
                                || minute == ExtraTimeHalf || minute == ExtraTimeFull
                                || _lastMinute == -1)
                            {
                                SpeechOutput.Speak($"Minute {minute}", false);
                            }
                            _lastMinute = minute;
                        }
                        return;
                    }
                    catch { }
                }
            }
        }

        /// <summary>
        /// Read latest commentary entry from the match view model.
        /// </summary>
        private void ReadCommentary(object viewModel)
        {
            // Try to access commentary list/collection
            foreach (string propName in new[] { "Commentary", "CommentaryEntries", "LatestCommentary",
                "CommentaryText", "LastCommentary" })
            {
                var prop = viewModel.GetType().GetProperty(propName);
                if (prop == null) continue;

                object commentaryObj = prop.GetValue(viewModel);
                if (commentaryObj == null) continue;

                string text = ExtractCommentaryText(commentaryObj);
                if (!string.IsNullOrEmpty(text) && text != _lastCommentary)
                {
                    _lastCommentary = text;
                    SpeechOutput.Speak(TextCleaner.Clean(text), false);
                }
                return;
            }
        }

        /// <summary>
        /// Extract text from a commentary object (could be string, list, or custom type).
        /// </summary>
        private string ExtractCommentaryText(object commentary)
        {
            // Direct string
            if (commentary is string str) return str;

            // Try as IList — get last entry
            if (commentary is System.Collections.IList list && list.Count > 0)
            {
                object lastEntry = list[list.Count - 1];
                if (lastEntry is string s) return s;

                // Try Text/Description/Message property on the entry
                foreach (string propName in new[] { "Text", "Description", "Message", "Commentary" })
                {
                    var prop = lastEntry.GetType().GetProperty(propName);
                    if (prop != null && prop.PropertyType == typeof(string))
                    {
                        return prop.GetValue(lastEntry) as string;
                    }
                }
                return lastEntry.ToString();
            }

            // Try as object with text properties
            foreach (string propName in new[] { "Text", "Description", "Message" })
            {
                var prop = commentary.GetType().GetProperty(propName);
                if (prop != null && prop.PropertyType == typeof(string))
                {
                    return prop.GetValue(commentary) as string;
                }
            }

            return null;
        }

        /// <summary>
        /// Scan the current UI hierarchy for match-related panels and read their text.
        /// This is a fallback approach that works without knowing FM26's internal API.
        /// </summary>
        private void PollViaUIScanning()
        {
            var rootObjects = new List<GameObject>();
            try
            {
                var scene = UnityEngine.SceneManagement.SceneManager.GetActiveScene();
                scene.GetRootGameObjects(rootObjects);
            }
            catch { return; }

            foreach (var root in rootObjects)
            {
                ScanForMatchPanels(root.transform);
            }
        }

        /// <summary>
        /// Recursively look for match-related UI panels (score, commentary, status).
        /// </summary>
        private void ScanForMatchPanels(Transform parent)
        {
            if (parent == null) return;

            string objName = parent.name.ToLower();

            // Look for commentary panels
            if (objName.Contains("commentary") || objName.Contains("matchtext")
                || objName.Contains("narration"))
            {
                string text = UI.TextExtractor.ExtractAll(parent.gameObject);
                if (!string.IsNullOrEmpty(text) && text != _lastCommentary)
                {
                    _lastCommentary = text;
                    SpeechOutput.Speak(TextCleaner.Clean(text), false);
                }
            }

            // Look for score display
            if (objName.Contains("score") && !objName.Contains("scorer"))
            {
                string text = UI.TextExtractor.ExtractAll(parent.gameObject);
                if (!string.IsNullOrEmpty(text) && text != _lastScore)
                {
                    _lastScore = text;
                    SpeechOutput.Speak($"Score: {TextCleaner.Clean(text)}");
                }
            }

            // Scan children (limit depth to avoid performance issues)
            for (int i = 0; i < parent.childCount && i < MaxChildScanDepth; i++)
            {
                var child = parent.GetChild(i);
                if (child != null && child.gameObject.activeInHierarchy)
                {
                    ScanForMatchPanels(child);
                }
            }
        }

        /// <summary>
        /// Apply Harmony patches for match engine hooks.
        /// </summary>
        public static void ApplyMatchPatches(Harmony harmony)
        {
            TryPatchMatchEvents(harmony);
        }

        /// <summary>
        /// Attempt to hook into FM26 match event dispatchers via Harmony.
        /// </summary>
        private static void TryPatchMatchEvents(Harmony harmony)
        {
            try
            {
                // Try to patch the match event/goal handler
                var matchEventType = Type.GetType("FM.Match.MatchEventDispatcher, FM.Match")
                    ?? Type.GetType("FM.UI.MatchEventHandler, FM.UI");

                if (matchEventType == null)
                {
                    Plugin.Log.LogInfo("Match event types not found — using UI polling for match commentary");
                    return;
                }

                // Look for goal/event methods
                foreach (string methodName in new[] { "OnGoal", "OnMatchEvent", "RaiseEvent", "HandleEvent" })
                {
                    var method = AccessTools.Method(matchEventType, methodName);
                    if (method != null)
                    {
                        var postfix = new HarmonyMethod(typeof(MatchPatches), nameof(OnMatchEvent_Postfix));
                        harmony.Patch(method, postfix: postfix);
                        Plugin.Log.LogInfo($"Patched match event: {matchEventType.Name}.{methodName}");
                    }
                }
            }
            catch (Exception ex)
            {
                Plugin.Log.LogWarning($"Failed to patch match events: {ex.Message}");
            }
        }

        /// <summary>
        /// Postfix called when a match event fires (goal, card, substitution, etc.).
        /// </summary>
        private static void OnMatchEvent_Postfix(object __instance)
        {
            try
            {
                if (!TouchlineConfig.SpeechEnabled.Value) return;

                // Try to extract event description
                var type = __instance.GetType();
                foreach (string propName in new[] { "Description", "Text", "EventText", "Message" })
                {
                    var prop = type.GetProperty(propName);
                    if (prop != null && prop.PropertyType == typeof(string))
                    {
                        string text = prop.GetValue(__instance) as string;
                        if (!string.IsNullOrEmpty(text))
                        {
                            SpeechOutput.Speak(TextCleaner.Clean(text));
                            return;
                        }
                    }
                }

                if (TouchlineConfig.DebugMode.Value)
                {
                    Plugin.Log.LogInfo($"Match event triggered: {type.Name}");
                }
            }
            catch { }
        }

        /// <summary>
        /// Manually announce the current match state. Called by hotkey (Ctrl+Shift+M).
        /// </summary>
        public void AnnounceMatchState()
        {
            var parts = new List<string>();

            if (!string.IsNullOrEmpty(_lastScore))
                parts.Add($"Score: {TextCleaner.Clean(_lastScore)}");

            if (_lastMinute > 0)
                parts.Add($"Minute {_lastMinute}");

            if (!string.IsNullOrEmpty(_lastMatchStatus))
                parts.Add(TextCleaner.Clean(_lastMatchStatus));

            if (!string.IsNullOrEmpty(_lastCommentary))
                parts.Add(TextCleaner.Clean(_lastCommentary));

            if (parts.Count > 0)
            {
                SpeechOutput.Speak(string.Join(". ", parts));
            }
            else
            {
                SpeechOutput.Speak("No match in progress");
            }
        }

        /// <summary>
        /// Reset match state tracking (called when leaving match screen).
        /// </summary>
        public void ResetMatchState()
        {
            _lastCommentary = string.Empty;
            _lastScore = string.Empty;
            _lastMatchStatus = string.Empty;
            _lastMinute = -1;
        }
    }
}
