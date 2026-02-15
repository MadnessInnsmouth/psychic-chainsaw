using HarmonyLib;
using System;
using TouchlineMod.Core;

namespace TouchlineMod.Patches
{
    /// <summary>
    /// Harmony patches that hook into FM26's focus/navigation events.
    /// These patches are applied at runtime by BepInEx's Harmony instance.
    ///
    /// Note: The target types and methods reference FM26's internal UI framework.
    /// If the game's API changes between versions, these patches may need updating.
    /// The patches use TryPatch pattern - they fail gracefully if the target methods
    /// don't exist (e.g., when building against stubs rather than the real game).
    /// </summary>
    public static class FocusPatches
    {
        /// <summary>
        /// Attempts to manually apply patches that require runtime type resolution.
        /// Called from Plugin.Load() after Harmony is initialized.
        /// </summary>
        public static void ApplyManualPatches(Harmony harmony)
        {
            TryPatchFMNavigation(harmony);
            TryPatchSceneLoad(harmony);
        }

        /// <summary>
        /// Patch FMNavigationManager to intercept focus changes at the source.
        /// This gives us immediate notification when the game's navigation system moves focus.
        /// </summary>
        private static void TryPatchFMNavigation(Harmony harmony)
        {
            try
            {
                var navType = Type.GetType("FM.UI.FMNavigationManager, FM.UI");
                if (navType == null)
                {
                    Plugin.Log.LogInfo("FM.UI.FMNavigationManager not found - navigation patch skipped");
                    return;
                }

                // Look for the method that sets CurrentFocus
                var setFocusMethod = AccessTools.Method(navType, "SetFocus");
                if (setFocusMethod == null)
                    setFocusMethod = AccessTools.PropertySetter(navType, "CurrentFocus");

                if (setFocusMethod != null)
                {
                    var postfix = new HarmonyMethod(typeof(FocusPatches), nameof(OnFocusSet_Postfix));
                    harmony.Patch(setFocusMethod, postfix: postfix);
                    Plugin.Log.LogInfo("Patched FMNavigationManager focus setter");
                }
                else
                {
                    Plugin.Log.LogInfo("FMNavigationManager.SetFocus/CurrentFocus setter not found");
                }
            }
            catch (Exception ex)
            {
                Plugin.Log.LogWarning($"Failed to patch FMNavigationManager: {ex.Message}");
            }
        }

        /// <summary>
        /// Patch scene loading to announce screen transitions.
        /// </summary>
        private static void TryPatchSceneLoad(Harmony harmony)
        {
            try
            {
                // Hook into Unity's SceneManager.sceneLoaded via a MonoBehaviour callback
                // instead of Harmony, since it's an event rather than a patchable method.
                UnityEngine.SceneManagement.SceneManager.sceneLoaded += OnSceneLoaded;
                Plugin.Log.LogInfo("Registered scene load listener");
            }
            catch (Exception ex)
            {
                Plugin.Log.LogWarning($"Failed to register scene listener: {ex.Message}");
            }
        }

        /// <summary>
        /// Postfix patch: Called after FM26 sets focus on a new element.
        /// </summary>
        private static void OnFocusSet_Postfix()
        {
            try
            {
                // The FocusTracker MonoBehaviour will pick up the change on its next Update.
                // This patch serves as an immediate notification path for debug logging.
                if (Config.TouchlineConfig.DebugMode.Value)
                {
                    Plugin.Log.LogInfo("FM navigation focus changed (patch triggered)");
                }
            }
            catch { }
        }

        /// <summary>
        /// Called when a new scene is loaded. Announces the transition to the user.
        /// </summary>
        private static void OnSceneLoaded(UnityEngine.SceneManagement.Scene scene,
            UnityEngine.SceneManagement.LoadSceneMode mode)
        {
            try
            {
                string sceneName = scene.name;
                if (!string.IsNullOrEmpty(sceneName))
                {
                    // Clean up technical scene names for announcement
                    string cleanName = sceneName
                        .Replace("_", " ")
                        .Replace("Screen", "")
                        .Replace("Panel", "")
                        .Trim();

                    if (!string.IsNullOrEmpty(cleanName))
                    {
                        SpeechOutput.Speak($"Screen: {cleanName}");
                    }
                }

                if (Config.TouchlineConfig.DebugMode.Value)
                {
                    Plugin.Log.LogInfo($"Scene loaded: {sceneName} (mode: {mode})");
                }
            }
            catch { }
        }
    }
}
