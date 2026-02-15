namespace TouchlineMod.Navigation
{
    /// <summary>
    /// Represents an accessible UI element extracted from the Unity UI hierarchy.
    /// Provides structured information for screen reader announcements.
    /// </summary>
    public class AccessibleElement
    {
        /// <summary>
        /// Display name or label text of the element.
        /// </summary>
        public string Name { get; set; } = string.Empty;

        /// <summary>
        /// Type of UI element (Button, Label, Toggle, Dropdown, InputField, Table, TableRow, etc.)
        /// </summary>
        public string ElementType { get; set; } = "Unknown";

        /// <summary>
        /// Current value or content of the element (e.g., input field text, dropdown selection).
        /// </summary>
        public string Value { get; set; } = string.Empty;

        /// <summary>
        /// Current state description (e.g., "checked", "unchecked", "selected", "disabled").
        /// </summary>
        public string State { get; set; } = string.Empty;

        /// <summary>
        /// Position hint for lists/tables (e.g., "3 of 15").
        /// </summary>
        public string PositionHint { get; set; } = string.Empty;

        /// <summary>
        /// Additional context (e.g., parent container name, table column headers).
        /// </summary>
        public string Context { get; set; } = string.Empty;

        /// <summary>
        /// Full path in the UI hierarchy for debugging.
        /// </summary>
        public string HierarchyPath { get; set; } = string.Empty;

        /// <summary>
        /// Whether this element is currently interactable.
        /// </summary>
        public bool IsInteractable { get; set; } = true;

        /// <summary>
        /// Build an announcement string for screen reader output.
        /// Follows a consistent order: Name, Value, Type, State, Position.
        /// </summary>
        public string GetAnnouncement()
        {
            var parts = new System.Collections.Generic.List<string>();

            if (!string.IsNullOrEmpty(Name))
                parts.Add(Core.TextCleaner.Clean(Name));

            if (!string.IsNullOrEmpty(Value))
                parts.Add(Core.TextCleaner.Clean(Value));

            if (!string.IsNullOrEmpty(ElementType) && Config.TouchlineConfig.AnnounceElementType.Value)
                parts.Add(ElementType);

            if (!string.IsNullOrEmpty(State) && Config.TouchlineConfig.AnnounceElementState.Value)
                parts.Add(State);

            if (!string.IsNullOrEmpty(PositionHint))
                parts.Add(PositionHint);

            if (!IsInteractable)
                parts.Add("disabled");

            return string.Join(", ", parts);
        }

        public override string ToString()
        {
            return $"[{ElementType}] {Name}" +
                   (string.IsNullOrEmpty(Value) ? "" : $" = {Value}") +
                   (string.IsNullOrEmpty(State) ? "" : $" ({State})");
        }
    }
}
