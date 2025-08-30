import 'package:flutter/material.dart';
import 'package:tang0/src/templates/synced_widget.dart';
import 'package:web/web.dart' as web;

/// Helper methods and widgets to make creating SyncedWidgets easier

/// Quick creator for common SyncedVar types with simplified syntax
class SyncedVars {
  /// Create a synced counter with built-in increment/decrement
  static SyncedVar<int> counter(String name, [int initialValue = 0]) {
    return SyncedVar<int>(name: name, value: initialValue);
  }

  /// Create a synced text field value
  static SyncedVar<String> text(String name, [String initialValue = '']) {
    return SyncedVar<String>(name: name, value: initialValue);
  }

  /// Create a synced boolean toggle
  static SyncedVar<bool> toggle(String name, [bool initialValue = false]) {
    return SyncedVar<bool>(name: name, value: initialValue);
  }

  /// Create a synced double/number value
  static SyncedVar<double> number(String name, [double initialValue = 0.0]) {
    return SyncedVar<double>(name: name, value: initialValue);
  }
}

/// Extension methods on SyncedVar to make common operations easier
extension SyncedVarHelpers<T> on SyncedVar<T> {
  /// Quick way to create a Text widget showing the current value
  Text toText([TextStyle? style]) => Text('$value', style: style);

  /// Create a Text widget with a label
  Text toLabelText(String label, [TextStyle? style]) =>
      Text('$label: $value', style: style);
}

/// Extension specifically for int SyncedVars (counters)
extension SyncedIntHelpers on SyncedVar<int> {
  /// Increment the counter
  void increment([int by = 1]) => value += by;

  /// Decrement the counter
  void decrement([int by = 1]) => value -= by;

  /// Reset to zero
  void reset() => value = 0;

  /// Quick increment button
  Widget incrementButton({String label = '+', VoidCallback? onPressed}) {
    return ElevatedButton(
      onPressed: onPressed ?? (() => increment()),
      child: Text(label),
    );
  }

  /// Quick decrement button
  Widget decrementButton({String label = '-', VoidCallback? onPressed}) {
    return ElevatedButton(
      onPressed: onPressed ?? (() => decrement()),
      child: Text(label),
    );
  }

  /// Counter controls (+ and - buttons in a Row)
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

/// Extension for String SyncedVars (text fields)
extension SyncedStringHelpers on SyncedVar<String> {
  /// Quick TextField that automatically updates the synced value
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

/// Extension for bool SyncedVars (toggles/switches)
extension SyncedBoolHelpers on SyncedVar<bool> {
  /// Quick Switch widget
  Widget switch_({String? title}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (title != null) Text(title),
        Switch(value: value, onChanged: (newValue) => value = newValue),
      ],
    );
  }

  /// Quick Checkbox widget
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

  /// Toggle the boolean value
  void toggle() => value = !value;

  /// Quick toggle button
  Widget toggleButton({String? trueLabel, String? falseLabel}) {
    return ElevatedButton(
      onPressed: toggle,
      child: Text(value ? (trueLabel ?? 'On') : (falseLabel ?? 'Off')),
    );
  }
}

/// Helper widgets for common UI patterns
class SyncedUI {
  /// Card wrapper for synced variable controls
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

  /// Quick "Open New Tab" button for testing sync functionality
  static Widget openTabButton({String label = 'Open New Tab'}) {
    return ElevatedButton.icon(
      onPressed: () {
        web.window.open(web.window.location.href, '_blank');
      },
      icon: const Icon(Icons.open_in_new),
      label: Text(label),
    );
  }

  /// Instructions text for sync testing
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

  /// Debug info showing which variables are syncing
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

/// Quick builder for common SyncedWidget patterns
class SyncedWidgetBuilder {
  final List<SyncedVar> _vars = [];

  /// Add a counter variable
  SyncedWidgetBuilder addCounter(String name, [int initialValue = 0]) {
    _vars.add(SyncedVars.counter(name, initialValue));
    return this;
  }

  /// Add a text variable
  SyncedWidgetBuilder addText(String name, [String initialValue = '']) {
    _vars.add(SyncedVars.text(name, initialValue));
    return this;
  }

  /// Add a boolean toggle variable
  SyncedWidgetBuilder addToggle(String name, [bool initialValue = false]) {
    _vars.add(SyncedVars.toggle(name, initialValue));
    return this;
  }

  /// Add any custom SyncedVar
  SyncedWidgetBuilder add<T>(SyncedVar<T> variable) {
    _vars.add(variable);
    return this;
  }

  /// Build the final SyncedWidget
  Widget build(
    Widget Function(BuildContext context, List<SyncedVar> vars) builder,
  ) {
    return SyncedWidget(
      syncedVars: _vars,
      builder: (context) => builder(context, _vars),
    );
  }
}
