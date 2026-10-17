/// Team Guard example demonstrating:
/// 1. Enforcing approved custom widget replacements.
/// 2. Safe coexistence with PDF-generation packages (e.g. `package:pdf/widgets.dart`).
/// 3. Normal identifier usage (`final String text = ...; text.toUpperCase();`) without false positives.
///
/// Example `team_guard.yaml`:
/// ```yaml
/// widgets:
///   Text:
///     replacement: CustomText
///     import: package:your_app/core/ui/custom_text.dart
///     severity: error
///
///   ElevatedButton:
///     replacement: AppElevatedButton
///     import: package:your_app/core/ui/buttons/app_elevated_button.dart
///     severity: error
///
/// classes:
///   Colors:
///     replacement: AppColors
///     import: package:your_app/core/theme/app_colors.dart
///     severity: error
/// ```
library;

// Example 1: Approved custom widgets created by team
class CustomText {
  final String text;
  const CustomText(this.text);
}

class AppColors {
  const AppColors._();
  static const int primary = 0xFF6200EE;
}

// Example 2: Normal variables and methods named 'text' - NOT flagged
void processText(String text) {
  final String trimmed = text.trim();
  final String upper = trimmed.toUpperCase();
  final int length = text.length;
  if (text.isEmpty) {
    print('Empty text with length $length: $upper');
  }
}

// Example 3: Flutter UI code
// In real code:
// import 'package:flutter/widgets.dart';
//
// Widget buildScreen() {
//   // Text('Hello') is flagged -> Quick Fix replaces with CustomText('Hello')
//   // and adds: import 'package:your_app/core/ui/custom_text.dart';
//   return const CustomText('Hello');
// }

// Example 4: PDF generation code
// In real PDF code:
// import 'package:pdf/widgets.dart' as pw;
//
// pw.Document generatePdfReport() {
//   final doc = pw.Document();
//   // pw.Text('Invoice') is a PDF API, NOT a Flutter widget.
//   // Team Guard will NOT flag it and will NOT insert Flutter UI imports.
//   return doc;
// }

void main() {
  processText('Team Guard is active');
}
