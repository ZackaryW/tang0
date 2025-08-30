import 'package:flutter/material.dart';
import 'package:tang0/src/templates/synced_widget.dart';
import 'package:web/web.dart' as web;

/// Helper methods and widgets to make creating SyncedWidgets easier

/// Factory class for creating common SyncedVar types with simplified syntax.
///
/// This class provides convenient static methods to create commonly used
/// synchronized variable types without needing to specify generic parameters.
///
/// Example:
/// ```dart
/// final counter = SyncedVars.counter("myCounter", 10);
/// final message = SyncedVars.text("userMessage");
/// final isEnabled = SyncedVars.toggle("featureFlag", true);
/// ```
class SyncedVars {
  /// Creates a synchronized integer variable, typically used for counters.
  ///
  /// [name] - Unique identifier for the variable across tabs.
  /// [initialValue] - Starting value (defaults to 0).
  ///
  /// Returns a [SyncedVar<int>] ready for use in increment/decrement operations.
  static SyncedVar<int> counter(String name, [int initialValue = 0]) {
    return SyncedVar<int>(name: name, value: initialValue);
  }

  /// Creates a synchronized string variable, typically used for text input.
  ///
  /// [name] - Unique identifier for the variable across tabs.
  /// [initialValue] - Starting text value (defaults to empty string).
  ///
  /// Returns a [SyncedVar<String>] ready for use with text fields.
  static SyncedVar<String> text(String name, [String initialValue = '']) {
    return SyncedVar<String>(name: name, value: initialValue);
  }

  /// Creates a synchronized boolean variable, typically used for toggles.
  ///
  /// [name] - Unique identifier for the variable across tabs.
  /// [initialValue] - Starting boolean value (defaults to false).
  ///
  /// Returns a [SyncedVar<bool>] ready for use with switches and checkboxes.
  static SyncedVar<bool> toggle(String name, [bool initialValue = false]) {
    return SyncedVar<bool>(name: name, value: initialValue);
  }

  /// Creates a synchronized double variable, typically used for numeric input.
  ///
  /// [name] - Unique identifier for the variable across tabs.
  /// [initialValue] - Starting numeric value (defaults to 0.0).
  ///
  /// Returns a [SyncedVar<double>] ready for use with sliders and numeric fields.
  static SyncedVar<double> number(String name, [double initialValue = 0.0]) {
    return SyncedVar<double>(name: name, value: initialValue);
  }
}

/// Extension methods for all SyncedVar types to simplify common UI operations.
///
/// These extensions provide convenient methods to create UI widgets directly
/// from synchronized variables without additional boilerplate.
extension SyncedVarHelpers<T> on SyncedVar<T> {
  /// Creates a Text widget displaying the current value.
  ///
  /// [style] - Optional TextStyle to customize the appearance.
  ///
  /// Returns a [Text] widget showing the string representation of the value.
  ///
  /// Example:
  /// ```dart
  /// final counter = SyncedVars.counter("count", 5);
  /// Widget display = counter.toText(TextStyle(fontSize: 20));
  /// ```
  Text toText([TextStyle? style]) => Text('$value', style: style);

  /// Creates a labeled Text widget showing both label and current value.
  ///
  /// [label] - The text label to display before the value.
  /// [style] - Optional TextStyle to customize the appearance.
  ///
  /// Returns a [Text] widget in the format "label: value".
  ///
  /// Example:
  /// ```dart
  /// final score = SyncedVars.counter("score", 100);
  /// Widget display = score.toLabelText("Score");
  /// // Displays: "Score: 100"
  /// ```
  Text toLabelText(String label, [TextStyle? style]) =>
      Text('$label: $value', style: style);
}

/// Extension methods specifically for integer SyncedVars (counters).
///
/// Provides convenient methods for common counter operations and UI components.
extension SyncedIntHelpers on SyncedVar<int> {
  /// Increments the counter value by the specified amount.
  ///
  /// [by] - Amount to increment by (defaults to 1).
  ///
  /// Triggers synchronization to other tabs automatically.
  void increment([int by = 1]) => value += by;

  /// Decrements the counter value by the specified amount.
  ///
  /// [by] - Amount to decrement by (defaults to 1).
  ///
  /// Triggers synchronization to other tabs automatically.
  void decrement([int by = 1]) => value -= by;

  /// Resets the counter to zero.
  ///
  /// Triggers synchronization to other tabs automatically.
  void reset() => value = 0;

  /// Creates a button that increments the counter when pressed.
  ///
  /// [label] - Button text (defaults to '+').
  /// [onPressed] - Optional custom callback (defaults to increment()).
  ///
  /// Returns an [ElevatedButton] that increases the counter value.
  Widget incrementButton({String label = '+', VoidCallback? onPressed}) {
    return ElevatedButton(
      onPressed: onPressed ?? (() => increment()),
      child: Text(label),
    );
  }

  /// Creates a button that decrements the counter when pressed.
  ///
  /// [label] - Button text (defaults to '-').
  /// [onPressed] - Optional custom callback (defaults to decrement()).
  ///
  /// Returns an [ElevatedButton] that decreases the counter value.
  Widget decrementButton({String label = '-', VoidCallback? onPressed}) {
    return ElevatedButton(
      onPressed: onPressed ?? (() => decrement()),
      child: Text(label),
    );
  }

  /// Creates a complete counter control UI with increment and decrement buttons.
  ///
  /// [title] - Optional title to display above the controls.
  ///
  /// Returns a [Column] containing the title (if provided) and a [Row]
  /// of decrement and increment buttons.
  ///
  /// Example:
  /// ```dart
  /// final counter = SyncedVars.counter("items");
  /// Widget ui = counter.controls(title: "Item Count");
  /// ```
  Widget controls({String? title}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) toLabelText(title),
        if (title != null) const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            decrementButton(),
            const SizedBox(width: 10),
            incrementButton(),
          ],
        ),
      ],
    );
  }
}

/// Extension methods specifically for String SyncedVars (text fields).
///
/// Provides convenient methods for creating text input UI components.
extension SyncedStringHelpers on SyncedVar<String> {
  /// Creates a TextField that automatically updates the synced value.
  ///
  /// [label] - Optional label text for the field.
  /// [hint] - Optional hint text shown when field is empty.
  /// [maxLines] - Maximum number of lines (defaults to 1).
  /// [keyboardType] - Type of keyboard to show (defaults to system default).
  ///
  /// Returns a [TextField] that synchronizes changes across tabs in real-time.
  /// Updates occur both on submission (Enter key) and on each character change.
  ///
  /// Example:
  /// ```dart
  /// final message = SyncedVars.text("userMessage");
  /// Widget input = message.textField(
  ///   label: "Your Message",
  ///   hint: "Type something...",
  ///   maxLines: 3,
  /// );
  /// ```
  Widget textField({
    String? label,
    String? hint,
    int? maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      controller: TextEditingController(text: value),
      onSubmitted: (newValue) => value = newValue,
      onChanged: (newValue) => value = newValue,
    );
  }
}

/// Extension methods specifically for boolean SyncedVars (toggles/switches).
///
/// Provides convenient methods for creating toggle UI components.
extension SyncedBoolHelpers on SyncedVar<bool> {
  /// Creates a Switch widget with optional title.
  ///
  /// [title] - Optional title text displayed next to the switch.
  ///
  /// Returns a [Row] containing the title (if provided) and a [Switch]
  /// that automatically syncs state changes across tabs.
  ///
  /// Example:
  /// ```dart
  /// final darkMode = SyncedVars.toggle("darkMode");
  /// Widget toggle = darkMode.switch_(title: "Dark Mode");
  /// ```
  Widget switch_({String? title}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (title != null) Text(title),
        Switch(value: value, onChanged: (newValue) => value = newValue),
      ],
    );
  }

  /// Creates a Checkbox widget with optional title.
  ///
  /// [title] - Optional title text displayed next to the checkbox.
  ///
  /// Returns a [Row] containing the [Checkbox] and title (if provided)
  /// that automatically syncs state changes across tabs.
  ///
  /// Example:
  /// ```dart
  /// final agreed = SyncedVars.toggle("termsAgreed");
  /// Widget check = agreed.checkbox(title: "I agree to terms");
  /// ```
  Widget checkbox({String? title}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: (newValue) => value = newValue ?? false,
        ),
        if (title != null) Text(title),
      ],
    );
  }

  /// Toggles the boolean value from true to false or false to true.
  ///
  /// Triggers synchronization to other tabs automatically.
  void toggle() => value = !value;

  /// Creates a button that toggles the boolean value when pressed.
  ///
  /// [trueLabel] - Text shown when value is true (defaults to 'On').
  /// [falseLabel] - Text shown when value is false (defaults to 'Off').
  ///
  /// Returns an [ElevatedButton] that shows the current state and
  /// toggles the value when pressed.
  ///
  /// Example:
  /// ```dart
  /// final sound = SyncedVars.toggle("soundEnabled", true);
  /// Widget button = sound.toggleButton(
  ///   trueLabel: "Sound On",
  ///   falseLabel: "Sound Off"
  /// );
  /// ```
  Widget toggleButton({String? trueLabel, String? falseLabel}) {
    return ElevatedButton(
      onPressed: toggle,
      child: Text(value ? (trueLabel ?? 'On') : (falseLabel ?? 'Off')),
    );
  }
}

/// Utility class providing pre-built UI components for synchronized widgets.
///
/// Contains static methods that create common UI patterns used when
/// demonstrating or testing cross-tab synchronization functionality.
class SyncedUI {
  /// Creates a Card wrapper for grouped synchronized variable controls.
  ///
  /// [title] - Header text for the card.
  /// [children] - List of widgets to display inside the card.
  /// [padding] - Optional custom padding (defaults to 16.0 on all sides).
  ///
  /// Returns a [Card] with consistent styling for organizing sync controls.
  ///
  /// Example:
  /// ```dart
  /// Widget controls = SyncedUI.card(
  ///   title: "Settings",
  ///   children: [
  ///     darkMode.switch_(title: "Dark Mode"),
  ///     notifications.checkbox(title: "Enable Notifications"),
  ///   ],
  /// );
  /// ```
  static Widget card({
    required String title,
    required List<Widget> children,
    EdgeInsets? padding,
  }) {
    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  /// Creates a button that opens a new browser tab for testing synchronization.
  ///
  /// [label] - Button text (defaults to 'Open New Tab').
  ///
  /// Returns an [ElevatedButton] with an icon that opens the current page
  /// in a new tab when pressed. Useful for demonstrating cross-tab sync.
  ///
  /// Example:
  /// ```dart
  /// Widget testButton = SyncedUI.openTabButton(label: "Test Sync");
  /// ```
  static Widget openTabButton({String label = 'Open New Tab'}) {
    return ElevatedButton.icon(
      onPressed: () {
        web.window.open(web.window.location.href, '_blank');
      },
      icon: const Icon(Icons.open_in_new),
      label: Text(label),
    );
  }

  /// Creates instructional text for users testing synchronization features.
  ///
  /// [customText] - Optional custom instructions (uses default if not provided).
  ///
  /// Returns a [Text] widget with step-by-step instructions for testing
  /// cross-tab synchronization. Useful in example applications.
  static Widget syncInstructions([String? customText]) {
    return Text(
      customText ??
          'Instructions:\n'
              '1. Open this page in multiple tabs\n'
              '2. Change any value in one tab\n'
              '3. Watch it automatically sync to other tabs\n'
              '4. Only tabs with the same variable structure will sync',
      style: const TextStyle(fontSize: 12, color: Colors.grey),
    );
  }

  /// Creates a debug information panel showing current synchronized variables.
  ///
  /// [vars] - List of SyncedVar instances to display information for.
  ///
  /// Returns a [Card] containing debug information about each variable
  /// including name, type, and current value. Useful for development
  /// and troubleshooting synchronization issues.
  ///
  /// Example:
  /// ```dart
  /// Widget debug = SyncedUI.debugInfo([counter, message, isEnabled]);
  /// ```
  static Widget debugInfo(List<SyncedVar> vars) {
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sync Debug Info:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...vars.map((v) => Text('${v.name} (${v.typeName}): ${v.value}')),
          ],
        ),
      ),
    );
  }
}

/// Builder class for programmatically constructing SyncedWidget instances.
///
/// Provides a fluent interface for adding multiple synchronized variables
/// and building the final widget. Useful when creating dynamic UIs or
/// when the set of variables is determined at runtime.
///
/// Example:
/// ```dart
/// Widget myApp = SyncedWidgetBuilder()
///   .addCounter("clicks", 0)
///   .addText("message", "Hello")
///   .addToggle("enabled", true)
///   .build((context, vars) {
///     return Column(
///       children: [
///         vars[0].controls(title: "Click Count"),
///         vars[1].textField(label: "Message"),
///         vars[2].switch_(title: "Enabled"),
///       ],
///     );
///   });
/// ```
class SyncedWidgetBuilder {
  /// Internal list of synchronized variables being built.
  final List<SyncedVar> _vars = [];

  /// Adds a counter (integer) variable to the builder.
  ///
  /// [name] - Unique identifier for the variable.
  /// [initialValue] - Starting value (defaults to 0).
  ///
  /// Returns this builder instance for method chaining.
  SyncedWidgetBuilder addCounter(String name, [int initialValue = 0]) {
    _vars.add(SyncedVars.counter(name, initialValue));
    return this;
  }

  /// Adds a text (string) variable to the builder.
  ///
  /// [name] - Unique identifier for the variable.
  /// [initialValue] - Starting text value (defaults to empty string).
  ///
  /// Returns this builder instance for method chaining.
  SyncedWidgetBuilder addText(String name, [String initialValue = '']) {
    _vars.add(SyncedVars.text(name, initialValue));
    return this;
  }

  /// Adds a toggle (boolean) variable to the builder.
  ///
  /// [name] - Unique identifier for the variable.
  /// [initialValue] - Starting boolean value (defaults to false).
  ///
  /// Returns this builder instance for method chaining.
  SyncedWidgetBuilder addToggle(String name, [bool initialValue = false]) {
    _vars.add(SyncedVars.toggle(name, initialValue));
    return this;
  }

  /// Adds any custom SyncedVar to the builder.
  ///
  /// [variable] - A pre-configured SyncedVar instance.
  ///
  /// Returns this builder instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// final customVar = SyncedVar<double>(name: "rating", value: 4.5);
  /// builder.add(customVar);
  /// ```
  SyncedWidgetBuilder add<T>(SyncedVar<T> variable) {
    _vars.add(variable);
    return this;
  }

  /// Builds the final SyncedWidget with all added variables.
  ///
  /// [builder] - Function that takes the BuildContext and list of variables
  ///            and returns the UI widget tree.
  ///
  /// Returns a [SyncedWidget] configured with all added variables that
  /// will automatically synchronize across browser tabs.
  Widget build(
    Widget Function(BuildContext context, List<SyncedVar> vars) builder,
  ) {
    return SyncedWidget(
      syncedVars: _vars,
      builder: (context) => builder(context, _vars),
    );
  }
}
