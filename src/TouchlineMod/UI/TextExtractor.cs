using UnityEngine;
using UnityEngine.UI;
using System;
using System.Collections.Generic;
using System.Text;
using TouchlineMod.Core;

namespace TouchlineMod.UI
{
    /// <summary>
    /// Extracts readable text from Unity UI elements and game-specific components.
    /// Handles various text sources: Unity Text, TextMeshPro, FM26 custom labels, and tooltips.
    /// </summary>
    public static class TextExtractor
    {
        /// <summary>
        /// Extract all readable text from a GameObject and its immediate children.
        /// </summary>
        public static string ExtractAll(GameObject obj)
        {
            if (obj == null) return string.Empty;

            var texts = new List<string>();

            // Direct text components
            string directText = ExtractDirect(obj);
            if (!string.IsNullOrEmpty(directText))
                texts.Add(directText);

            // Check immediate children for additional text
            foreach (Transform child in obj.transform)
            {
                string childText = ExtractDirect(child.gameObject);
                if (!string.IsNullOrEmpty(childText) && !texts.Contains(childText))
                    texts.Add(childText);
            }

            return string.Join(", ", texts);
        }

        /// <summary>
        /// Extract text directly from a single GameObject's components.
        /// </summary>
        public static string ExtractDirect(GameObject obj)
        {
            if (obj == null) return string.Empty;

            // Try Unity UI Text
            var text = obj.GetComponent<Text>();
            if (text != null && !string.IsNullOrWhiteSpace(text.text))
                return TextCleaner.Clean(text.text);

            // Try TextMeshPro via reflection
            string tmpText = ExtractTMPText(obj);
            if (!string.IsNullOrEmpty(tmpText))
                return TextCleaner.Clean(tmpText);

            // Try FM26/SI custom text components via reflection
            string fmText = ExtractFMText(obj);
            if (!string.IsNullOrEmpty(fmText))
                return TextCleaner.Clean(fmText);

            return string.Empty;
        }

        /// <summary>
        /// Extract a full table row as a readable string.
        /// Combines cell values with column headers when available.
        /// </summary>
        public static string ExtractTableRow(GameObject rowObj, List<string> columnHeaders = null)
        {
            if (rowObj == null) return string.Empty;

            var cells = new List<string>();
            foreach (Transform cell in rowObj.transform)
            {
                string cellText = ExtractAll(cell.gameObject);
                if (!string.IsNullOrEmpty(cellText))
                    cells.Add(cellText);
            }

            if (cells.Count == 0) return string.Empty;

            // If we have column headers, pair them with values
            if (columnHeaders != null && columnHeaders.Count > 0)
            {
                var sb = new StringBuilder();
                for (int i = 0; i < cells.Count; i++)
                {
                    if (i > 0) sb.Append(", ");
                    if (i < columnHeaders.Count)
                        sb.Append($"{columnHeaders[i]}: {cells[i]}");
                    else
                        sb.Append(cells[i]);
                }
                return sb.ToString();
            }

            return string.Join(", ", cells);
        }

        /// <summary>
        /// Extract column headers from a table header row.
        /// </summary>
        public static List<string> ExtractTableHeaders(GameObject tableObj)
        {
            var headers = new List<string>();
            if (tableObj == null) return headers;

            // Common header container names in FM26
            string[] headerNames = { "Header", "Headers", "ColumnHeaders", "HeaderRow", "header" };

            Transform headerTransform = null;
            foreach (string name in headerNames)
            {
                headerTransform = tableObj.transform.Find(name);
                if (headerTransform != null) break;
            }

            if (headerTransform != null)
            {
                foreach (Transform child in headerTransform)
                {
                    string headerText = ExtractAll(child.gameObject);
                    headers.Add(!string.IsNullOrEmpty(headerText) ? headerText : child.name);
                }
            }

            return headers;
        }

        /// <summary>
        /// Try to extract TextMeshPro text from a component without a compile-time dependency.
        /// </summary>
        private static string ExtractTMPText(GameObject obj)
        {
            try
            {
                var components = obj.GetComponents<Component>();
                foreach (var comp in components)
                {
                    if (comp == null) continue;
                    var typeName = comp.GetType().Name;
                    if (typeName.Contains("TextMeshPro") || typeName == "TMP_Text")
                    {
                        var textProp = comp.GetType().GetProperty("text");
                        if (textProp != null)
                            return textProp.GetValue(comp) as string;
                    }
                }
            }
            catch { }
            return null;
        }

        /// <summary>
        /// Try to extract text from FM26 or SI custom label components.
        /// </summary>
        private static string ExtractFMText(GameObject obj)
        {
            try
            {
                var components = obj.GetComponents<Component>();
                foreach (var comp in components)
                {
                    if (comp == null) continue;
                    var type = comp.GetType();
                    var typeName = type.Name;

                    // Check for common FM/SI text component patterns
                    if (typeName.Contains("Label") || typeName.Contains("Text") ||
                        typeName.StartsWith("SI") || typeName.StartsWith("FM"))
                    {
                        // Try common text property names
                        foreach (string propName in new[] { "text", "Text", "Label", "label", "Value", "value", "DisplayText" })
                        {
                            var prop = type.GetProperty(propName);
                            if (prop != null && prop.PropertyType == typeof(string))
                            {
                                string val = prop.GetValue(comp) as string;
                                if (!string.IsNullOrWhiteSpace(val))
                                    return val;
                            }
                        }
                    }
                }
            }
            catch { }
            return null;
        }
    }
}
