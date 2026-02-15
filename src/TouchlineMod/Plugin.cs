using BepInEx;
using BepInEx.Logging;
using HarmonyLib;
using System;
using TouchlineMod.Core;
using TouchlineMod.Config;

namespace TouchlineMod
{
    [BepInPlugin(PluginInfo.PLUGIN_GUID, PluginInfo.PLUGIN_NAME, PluginInfo.PLUGIN_VERSION)]
    public class Plugin : BaseUnityPlugin
    {
        public static Plugin Instance { get; private set; }
        internal static ManualLogSource Log { get; private set; }

        private Harmony _harmony;
        private AccessibilityManager _manager;

        private void Awake()
        {
            Instance = this;
            Log = base.Logger;

            Log.LogInfo($"Touchline v{PluginInfo.PLUGIN_VERSION} loading...");

            try
            {
                TouchlineConfig.Init(Config);

                if (SpeechOutput.Initialize())
                {
                    Log.LogInfo("Speech output initialized");
                    SpeechOutput.Speak("Touchline accessibility mod loaded");
                }
                else
                {
                    Log.LogWarning("No screen reader detected - using log fallback");
                }

                _manager = gameObject.AddComponent<AccessibilityManager>();

                _harmony = new Harmony(PluginInfo.PLUGIN_GUID);
                _harmony.PatchAll();
                Log.LogInfo("Harmony patches applied");

                Log.LogInfo("Touchline loaded successfully");
            }
            catch (Exception ex)
            {
                Log.LogError($"Failed to initialize Touchline: {ex}");
            }
        }

        private void OnDestroy()
        {
            _harmony?.UnpatchSelf();
            SpeechOutput.Shutdown();
            Log.LogInfo("Touchline unloaded");
        }
    }

    public static class PluginInfo
    {
        public const string PLUGIN_GUID = "com.touchline.fm26accessibility";
        public const string PLUGIN_NAME = "Touchline";
        public const string PLUGIN_VERSION = "0.2.0";
    }
}
