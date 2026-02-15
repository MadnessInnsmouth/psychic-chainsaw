using HarmonyLib;
using System;
using System.Collections.Generic;
using TouchlineMod.Core;
using TouchlineMod.Config;
using UnityEngine;

namespace TouchlineMod.Patches
{
    /// <summary>
    /// Polling logic for live match day events in FM26.
    /// Scans the active UI for match-related text (score, commentary) and
    /// narrates changes for screen reader users.
    /// </summary>
    public class MatchPatches : MonoBehaviour
    {
        public static MatchPatches Instance { get; private set; }

        private string _lastCommentary = string.Empty;
        private string _lastScore = string.Empty;
        private float _pollTimer;

        private const float PollInterval = 0.5f;
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

        private void Update()
        {
            if (!TouchlineConfig.SpeechEnabled.Value) return;

            _pollTimer -= Time.deltaTime;
            if (_pollTimer > 0f) return;
            _pollTimer = PollInterval;

            try
            {
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
        /// Scan the current UI hierarchy for match-related panels and read their text.
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
        /// Recursively look for match-related UI panels (score, commentary).
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

            // Scan children (limit depth)
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
            // Match event types are discovered at runtime via reflection.
            // If the game types aren't available, we fall back to UI polling above.
            try
            {
                var matchEventType = Type.GetType("FM.Match.MatchEventDispatcher, FM.Match")
                    ?? Type.GetType("FM.UI.MatchEventHandler, FM.UI");

                if (matchEventType == null)
                {
                    Plugin.Log.LogInfo("Match event types not found — using UI polling for match commentary");
                    return;
                }

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

        private static void OnMatchEvent_Postfix(object __instance)
        {
            try
            {
                if (!TouchlineConfig.SpeechEnabled.Value) return;

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
    }
}
