using UnityEngine;
using UnityEngine.UI;
using System;
using System.Collections.Generic;
using TouchlineMod.Core;
using TouchlineMod.Config;

namespace TouchlineMod.Navigation
{
    /// <summary>
    /// Monitors the Unity UI for focus changes and emits events with accessible element data.
    /// Uses FM26's built-in navigation system to detect which element has keyboard focus.
    /// </summary>
    public class FocusTracker : MonoBehaviour
    {
        /// <summary>
        /// Fired when the focused UI element changes. Parameters: previous element, new element.
        /// </summary>
        public event Action<AccessibleElement, AccessibleElement> OnFocusChanged;

        /// <summary>
        /// The currently focused accessible element.
        /// </summary>
        public AccessibleElement CurrentElement { get; private set; }

        private GameObject _lastFocusedObject;
        private float _focusChangeTimer;
        private bool _pendingAnnouncement;

        // Table tracking
        private GameObject _currentTableContainer;
        private bool _tableHeadersAnnounced;

        private new void Update()
        {
            TrackFocus();

            // Delayed announcement to prevent rapid-fire speech
            if (_pendingAnnouncement)
            {
                _focusChangeTimer -= Time.deltaTime;
                if (_focusChangeTimer <= 0f)
                {
                    _pendingAnnouncement = false;
                    // The event was already fired; this just gates rapid changes
                }
            }
        }

        private void TrackFocus()
        {
            // Try FM26's native navigation manager first
            GameObject focusedObj = GetFMFocusedElement();

            // Fall back to Unity's EventSystem
            if (focusedObj == null)
            {
                focusedObj = GetUnitySelectedObject();
            }

            if (focusedObj == null || focusedObj == _lastFocusedObject)
                return;

            var previousElement = CurrentElement;
            _lastFocusedObject = focusedObj;

            // Build accessible element from the focused GameObject
            CurrentElement = BuildAccessibleElement(focusedObj);

            // Check for table context
            CheckTableContext(focusedObj);

            // Fire event with delay
            _focusChangeTimer = TouchlineConfig.FocusChangeDelay.Value;
            _pendingAnnouncement = true;

            OnFocusChanged?.Invoke(previousElement, CurrentElement);

            if (TouchlineConfig.DebugMode.Value)
            {
                Plugin.Log.LogInfo($"Focus: {CurrentElement}");
            }
        }

        /// <summary>
        /// Try to get the focused element from FM26's FMNavigationManager.
        /// This requires the game's FM.UI assembly; returns null if unavailable.
        /// </summary>
        private GameObject GetFMFocusedElement()
        {
            try
            {
                // FM26 uses FMNavigationManager.CurrentFocus for keyboard nav.
                // Access via reflection to avoid hard dependency on FM.UI at compile time.
                var navType = Type.GetType("FM.UI.FMNavigationManager, FM.UI");
                if (navType == null) return null;

                var focusProp = navType.GetProperty("CurrentFocus",
                    System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Static);
                if (focusProp == null) return null;

                var focusObj = focusProp.GetValue(null);
                if (focusObj == null) return null;

                // FMNavigationManager.CurrentFocus returns a Component; get its GameObject
                if (focusObj is Component comp)
                    return comp.gameObject;
                if (focusObj is GameObject go)
                    return go;
            }
            catch (Exception ex)
            {
                if (TouchlineConfig.DebugMode.Value)
                    Plugin.Log.LogWarning($"FM focus lookup failed: {ex.Message}");
            }
            return null;
        }

        /// <summary>
        /// Get the currently selected UI object via Unity's EventSystem.
        /// </summary>
        private GameObject GetUnitySelectedObject()
        {
            var eventSystem = UnityEngine.EventSystems.EventSystem.current;
            return eventSystem != null ? eventSystem.currentSelectedGameObject : null;
        }

        /// <summary>
        /// Build an AccessibleElement from a Unity GameObject by inspecting its components.
        /// </summary>
        private AccessibleElement BuildAccessibleElement(GameObject obj)
        {
            var element = new AccessibleElement
            {
                HierarchyPath = GetHierarchyPath(obj)
            };

            // Check for common UI component types
            var text = obj.GetComponentInChildren<Text>();
            var tmpText = GetTMPText(obj);
            var button = obj.GetComponent<Button>();
            var toggle = obj.GetComponent<Toggle>();
            var dropdown = obj.GetComponent<Dropdown>();
            var inputField = obj.GetComponent<InputField>();
            var selectable = obj.GetComponent<Selectable>();

            // Determine element type and extract info
            if (button != null)
            {
                element.ElementType = "Button";
                element.Name = ExtractText(obj);
                element.IsInteractable = button.interactable;
            }
            else if (toggle != null)
            {
                element.ElementType = "Checkbox";
                element.Name = ExtractText(obj);
                element.State = toggle.isOn ? "checked" : "unchecked";
                element.IsInteractable = toggle.interactable;
            }
            else if (dropdown != null)
            {
                element.ElementType = "Dropdown";
                element.Name = ExtractText(obj);
                if (dropdown.options != null && dropdown.value >= 0 && dropdown.value < dropdown.options.Count)
                {
                    element.Value = TextCleaner.Clean(dropdown.options[dropdown.value].text);
                }
                element.IsInteractable = dropdown.interactable;
            }
            else if (inputField != null)
            {
                element.ElementType = "Text field";
                element.Name = !string.IsNullOrEmpty(inputField.text)
                    ? inputField.text
                    : (inputField.placeholder is Text ph ? ph.text : "");
                element.Value = inputField.text;
                element.IsInteractable = inputField.interactable;
            }
            else if (selectable != null)
            {
                element.ElementType = "Element";
                element.Name = ExtractText(obj);
                element.IsInteractable = selectable.interactable;
            }
            else
            {
                element.ElementType = "Text";
                element.Name = ExtractText(obj);
            }

            return element;
        }

        /// <summary>
        /// Extract readable text from a GameObject, checking Text, TMP_Text, and child elements.
        /// </summary>
        private string ExtractText(GameObject obj)
        {
            // Check Unity Text component
            var text = obj.GetComponentInChildren<Text>();
            if (text != null && !string.IsNullOrEmpty(text.text))
                return TextCleaner.Clean(text.text);

            // Check TextMeshPro (via reflection to avoid hard dependency)
            string tmpText = GetTMPText(obj);
            if (!string.IsNullOrEmpty(tmpText))
                return TextCleaner.Clean(tmpText);

            // Use GameObject name as fallback
            return TextCleaner.Clean(obj.name);
        }

        /// <summary>
        /// Try to get TextMeshPro text via reflection (avoids compile-time dependency).
        /// </summary>
        private string GetTMPText(GameObject obj)
        {
            try
            {
                // Look for TMP_Text component in children
                var components = obj.GetComponentsInChildren<Component>();
                foreach (var comp in components)
                {
                    if (comp == null) continue;
                    var type = comp.GetType();
                    if (type.Name == "TMP_Text" || type.Name == "TextMeshProUGUI" || type.Name == "TextMeshPro")
                    {
                        var textProp = type.GetProperty("text");
                        if (textProp != null)
                        {
                            return textProp.GetValue(comp) as string;
                        }
                    }
                }
            }
            catch { }
            return null;
        }

        /// <summary>
        /// Check if the focused element is inside a table and announce headers if needed.
        /// </summary>
        private void CheckTableContext(GameObject obj)
        {
            // Look for table-like parent containers
            var parent = obj.transform.parent;
            while (parent != null)
            {
                string name = parent.name.ToLower();
                if (name.Contains("table") || name.Contains("grid") || name.Contains("list"))
                {
                    if (parent.gameObject != _currentTableContainer)
                    {
                        _currentTableContainer = parent.gameObject;
                        _tableHeadersAnnounced = false;
                    }

                    if (!_tableHeadersAnnounced && TouchlineConfig.AnnounceTableHeaders.Value)
                    {
                        AnnounceTableHeaders(parent.gameObject);
                        _tableHeadersAnnounced = true;
                    }
                    return;
                }
                parent = parent.parent;
            }

            // Not in a table anymore
            _currentTableContainer = null;
            _tableHeadersAnnounced = false;
        }

        private void AnnounceTableHeaders(GameObject tableObj)
        {
            // Look for a header row (common patterns in FM26 UI)
            var headers = new List<string>();
            var headerTransform = tableObj.transform.Find("Header");
            if (headerTransform == null)
                headerTransform = tableObj.transform.Find("Headers");
            if (headerTransform == null)
                headerTransform = tableObj.transform.Find("ColumnHeaders");

            if (headerTransform != null)
            {
                foreach (Transform child in headerTransform)
                {
                    string headerText = ExtractText(child.gameObject);
                    if (!string.IsNullOrEmpty(headerText))
                        headers.Add(headerText);
                }

                if (headers.Count > 0)
                {
                    SpeechOutput.Speak("Table columns: " + string.Join(", ", headers), false);
                }
            }
        }

        /// <summary>
        /// Get the full hierarchy path of a GameObject for debugging.
        /// </summary>
        private static string GetHierarchyPath(GameObject obj)
        {
            string path = obj.name;
            Transform current = obj.transform.parent;
            while (current != null)
            {
                path = current.name + "/" + path;
                current = current.parent;
            }
            return path;
        }
    }
}
