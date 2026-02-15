using UnityEngine;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using TouchlineMod.Core;
using TouchlineMod.Config;

namespace TouchlineMod.UI
{
    /// <summary>
    /// Scans the Unity UI hierarchy to discover and catalog accessible elements.
    /// Provides deep-scan functionality for debugging and UI discovery.
    /// </summary>
    public class UIScanner : MonoBehaviour
    {
        private float _scanCooldown;

        /// <summary>
        /// Perform a deep scan of all active UI elements and write results to a file.
        /// Useful for discovering the game's UI structure and finding accessible elements.
        /// </summary>
        public void PerformDeepScan()
        {
            if (_scanCooldown > 0f)
            {
                SpeechOutput.Speak("Scan in progress, please wait");
                return;
            }
            _scanCooldown = 5f; // Prevent spamming

            try
            {
                var sb = new StringBuilder();
                sb.AppendLine($"Touchline UI Deep Scan - {DateTime.Now:yyyy-MM-dd HH:mm:ss}");
                sb.AppendLine(new string('=', 80));
                sb.AppendLine();

                // Find all root GameObjects in the scene
                var rootObjects = GetRootGameObjects();
                sb.AppendLine($"Found {rootObjects.Count} root objects");
                sb.AppendLine();

                int totalElements = 0;
                int interactableCount = 0;

                foreach (var root in rootObjects)
                {
                    ScanHierarchy(root.transform, sb, 0, ref totalElements, ref interactableCount);
                }

                sb.AppendLine();
                sb.AppendLine(new string('=', 80));
                sb.AppendLine($"Total elements: {totalElements}");
                sb.AppendLine($"Interactable elements: {interactableCount}");

                // Write to file in the BepInEx directory
                string outputPath = Path.Combine(Application.dataPath, "..", "BepInEx", "TouchlineUIScan.txt");
                File.WriteAllText(outputPath, sb.ToString());

                SpeechOutput.Speak($"Scan complete. Found {totalElements} elements, {interactableCount} interactable. Results saved to TouchlineUIScan.txt");
                Plugin.Log.LogInfo($"UI scan saved to {outputPath}");
            }
            catch (Exception ex)
            {
                Plugin.Log.LogError($"UI scan failed: {ex}");
                SpeechOutput.Speak("UI scan failed. Check log for details.");
            }
        }

        private new void Update()
        {
            if (_scanCooldown > 0f)
                _scanCooldown -= Time.deltaTime;
        }

        /// <summary>
        /// Recursively scan a transform hierarchy and catalog UI elements.
        /// </summary>
        private void ScanHierarchy(Transform parent, StringBuilder sb, int depth,
            ref int totalElements, ref int interactableCount)
        {
            if (parent == null) return;
            if (depth > 30) return; // Prevent infinite recursion

            string indent = new string(' ', depth * 2);
            var obj = parent.gameObject;

            if (!obj.activeInHierarchy && depth > 0)
                return;

            totalElements++;

            // Gather component info
            var info = new List<string>();
            info.Add(obj.name);

            var text = obj.GetComponent<UnityEngine.UI.Text>();
            if (text != null)
                info.Add($"Text=\"{TextCleaner.Clean(text.text)}\"");

            var button = obj.GetComponent<UnityEngine.UI.Button>();
            if (button != null)
            {
                info.Add("Button");
                interactableCount++;
            }

            var toggle = obj.GetComponent<UnityEngine.UI.Toggle>();
            if (toggle != null)
            {
                info.Add($"Toggle({(toggle.isOn ? "ON" : "OFF")})");
                interactableCount++;
            }

            var dropdown = obj.GetComponent<UnityEngine.UI.Dropdown>();
            if (dropdown != null)
            {
                info.Add($"Dropdown(value={dropdown.value})");
                interactableCount++;
            }

            var inputField = obj.GetComponent<UnityEngine.UI.InputField>();
            if (inputField != null)
            {
                info.Add("InputField");
                interactableCount++;
            }

            // Check for FM26-specific components via reflection
            ScanFMComponents(obj, info);

            if (TouchlineConfig.LogUIHierarchy.Value || info.Count > 1)
            {
                sb.AppendLine($"{indent}{string.Join(" | ", info)}");
            }

            // Recurse into children
            for (int i = 0; i < parent.childCount; i++)
            {
                ScanHierarchy(parent.GetChild(i), sb, depth + 1, ref totalElements, ref interactableCount);
            }
        }

        /// <summary>
        /// Check for FM26-specific UI components using reflection.
        /// </summary>
        private void ScanFMComponents(GameObject obj, List<string> info)
        {
            try
            {
                var components = obj.GetComponents<Component>();
                foreach (var comp in components)
                {
                    if (comp == null) continue;
                    string typeName = comp.GetType().Name;

                    // Log interesting FM/SI component types
                    if (typeName.StartsWith("FM") || typeName.StartsWith("SI") ||
                        typeName.Contains("Navigation") || typeName.Contains("Selectable"))
                    {
                        info.Add(typeName);
                    }
                }
            }
            catch { }
        }

        /// <summary>
        /// Get all root GameObjects in the active scene.
        /// </summary>
        private List<GameObject> GetRootGameObjects()
        {
            var roots = new List<GameObject>();
            try
            {
                var scene = UnityEngine.SceneManagement.SceneManager.GetActiveScene();
                scene.GetRootGameObjects(roots);
            }
            catch (Exception ex)
            {
                Plugin.Log.LogWarning($"Failed to get root objects: {ex.Message}");
            }
            return roots;
        }
    }
}
