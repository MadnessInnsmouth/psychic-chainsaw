using System.Text.RegularExpressions;

namespace TouchlineMod.Core
{
    /// <summary>
    /// Cleans Unity rich text markup and other formatting for screen reader output.
    /// Unity UI elements often contain HTML-like tags that should not be read aloud.
    /// </summary>
    public static class TextCleaner
    {
        // Matches Unity rich text tags like <color=#FF0000>, <b>, <size=14>, <sprite=...>, etc.
        private static readonly Regex RichTextPattern = new Regex(
            @"<\/?(?:color|b|i|u|s|size|material|quad|sprite|font|style|mark|align|indent|line-height|margin|nobr|page|pos|space|voffset|width|allcaps|smallcaps|lowercase|uppercase|mspace|noparse|cspace|rotate)(?:=[^>]*)?>",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

        // Matches any remaining HTML-like tags
        private static readonly Regex HtmlTagPattern = new Regex(
            @"<[^>]+>",
            RegexOptions.Compiled);

        // Matches multiple whitespace characters
        private static readonly Regex MultiSpacePattern = new Regex(
            @"\s{2,}",
            RegexOptions.Compiled);

        // Matches common Unicode symbols that screen readers may not handle well
        private static readonly Regex SymbolPattern = new Regex(
            @"[\u2022\u2023\u25E6\u2043\u2219]",
            RegexOptions.Compiled);

        /// <summary>
        /// Clean a string for screen reader output by removing rich text tags and normalizing whitespace.
        /// </summary>
        public static string Clean(string text)
        {
            if (string.IsNullOrEmpty(text))
                return string.Empty;

            // Remove Unity rich text tags
            string cleaned = RichTextPattern.Replace(text, "");

            // Remove any remaining HTML-like tags
            cleaned = HtmlTagPattern.Replace(cleaned, "");

            // Replace bullet-like Unicode symbols with a dash
            cleaned = SymbolPattern.Replace(cleaned, "-");

            // Normalize whitespace
            cleaned = MultiSpacePattern.Replace(cleaned, " ");

            return cleaned.Trim();
        }

        /// <summary>
        /// Clean text and add contextual separators for multi-part announcements.
        /// </summary>
        public static string CleanWithSeparator(string text, string separator = ", ")
        {
            string cleaned = Clean(text);
            // Replace pipe characters commonly used as visual separators in FM
            cleaned = cleaned.Replace("|", separator);
            cleaned = cleaned.Replace(" - ", separator);
            return cleaned;
        }

        /// <summary>
        /// Format a label-value pair for announcement.
        /// Example: FormatPair("Age", "24") => "Age: 24"
        /// </summary>
        public static string FormatPair(string label, string value)
        {
            string cleanLabel = Clean(label);
            string cleanValue = Clean(value);

            if (string.IsNullOrEmpty(cleanLabel))
                return cleanValue;
            if (string.IsNullOrEmpty(cleanValue))
                return cleanLabel;

            return $"{cleanLabel}: {cleanValue}";
        }
    }
}
