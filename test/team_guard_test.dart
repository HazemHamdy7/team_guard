import 'dart:io';
import 'package:team_guard/src/cli_service.dart';
import 'package:team_guard/src/config_loader.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

void main() {
  group('Bug A — Lowercase text and non-widget identifier detection', () {
    late TestProject project;

    setUp(() {
      project = TestProject.create();
    });

    tearDown(() {
      project.dispose();
    });

    test('Flutter Text("Hello") is flagged when appropriate', () async {
      project.writeSource('lib/screen.dart', '''
import 'package:flutter/widgets.dart';

Widget buildUI() {
  return Text('Hello');
}
''');

      final errors = await project.runRuleOn('lib/screen.dart');
      expect(errors, hasLength(1));
      expect(
        errors.first.message,
        'The widget "Text" is restricted by team policy. Use "CustomText" instead. (Quick Fix available)',
      );
      expect(errors.first.severity.name.toUpperCase(), 'ERROR');
    });

    test('final String text = "Hello"; is not flagged', () async {
      project.writeSource('lib/variables.dart', '''
void test() {
  final String text = 'Hello';
  print(text);
}
''');

      final errors = await project.runRuleOn('lib/variables.dart');
      expect(errors, isEmpty);
    });

    test('void render(String text) {} is not flagged', () async {
      project.writeSource('lib/methods.dart', '''
void render(String text) {
  print(text);
}
''');

      final errors = await project.runRuleOn('lib/methods.dart');
      expect(errors, isEmpty);
    });

    test(
        'text.toUpperCase() and property accesses like text.length are not flagged',
        () async {
      project.writeSource('lib/members.dart', '''
void test() {
  final String text = 'hello';
  final upper = text.toUpperCase();
  final len = text.length;
  final empty = text.isEmpty;
  final runes = text.runes;
}
''');

      final errors = await project.runRuleOn('lib/members.dart');
      expect(errors, isEmpty);
    });

    test('Comments and strings containing Text are not flagged', () async {
      project.writeSource('lib/literals.dart', '''
// This comment mentions Text widget and text variable.
const myDescription = 'This is plain Text inside a string literal';
''');

      final errors = await project.runRuleOn('lib/literals.dart');
      expect(errors, isEmpty);
    });

    test('extractText() method invocation is not flagged', () async {
      project.writeSource('lib/extraction.dart', '''
import 'package:other/other.dart';

void test() {
  final doc = Unrelated();
  final result = doc.extractText();
}
''');

      final errors = await project.runRuleOn('lib/extraction.dart');
      expect(errors, isEmpty);
    });

    test(
        'Similarly named Text symbol from another non-Flutter package is not flagged',
        () async {
      project.writeSource('lib/other_pkg.dart', '''
import 'package:other/other.dart' as ot;

void test() {
  final t = ot.Text('Unrelated text content');
}
''');

      final errors = await project.runRuleOn('lib/other_pkg.dart');
      expect(errors, isEmpty);
    });
  });

  group('Bug B — Compatibility with PDF-generation packages', () {
    late TestProject project;

    setUp(() {
      project = TestProject.create();
    });

    tearDown(() {
      project.dispose();
    });

    test(
        'PDF pw.Text and pw.Paragraph APIs are not flagged by Flutter widget rule',
        () async {
      project.writeSource('lib/pdf_report.dart', '''
import 'package:pdf/widgets.dart' as pw;

pw.Document createPdf() {
  final pdf = pw.Document();
  final text = pw.Text('PDF document content');
  final paragraph = pw.Paragraph(text: 'Paragraph body');
  final color = pw.PdfColors.red;
  return pdf;
}
''');

      final errors = await project.runRuleOn('lib/pdf_report.dart');
      expect(errors, isEmpty);
    });

    test('Unprefixed PDF Text is not flagged', () async {
      project.writeSource('lib/unprefixed_pdf.dart', '''
import 'package:pdf/widgets.dart';

void buildDoc() {
  final t = Text('Direct PDF text');
}
''');

      final errors = await project.runRuleOn('lib/unprefixed_pdf.dart');
      expect(errors, isEmpty);
    });

    test(
        'Project with both Flutter UI screens and PDF generator works correctly',
        () async {
      project.writeSource('lib/ui/login_screen.dart', '''
import 'package:flutter/widgets.dart';

Widget buildUI() {
  return Text('Login Screen');
}
''');

      project.writeSource('lib/services/invoice_service.dart', '''
import 'package:pdf/widgets.dart' as pw;

pw.Document createInvoice() {
  final pdf = pw.Document();
  final label = pw.Text('Invoice total');
  return pdf;
}
''');

      final uiErrors = await project.runRuleOn('lib/ui/login_screen.dart');
      expect(uiErrors, hasLength(1));
      expect(
          uiErrors.first.message, contains('The widget "Text" is restricted'));

      final pdfErrors =
          await project.runRuleOn('lib/services/invoice_service.dart');
      expect(pdfErrors, isEmpty);
    });
  });

  group('Quick Fix improvements', () {
    late TestProject project;

    setUp(() {
      project = TestProject.create();
    });

    tearDown(() {
      project.dispose();
    });

    test('Replaces Flutter Text with CustomText and inserts import when absent',
        () async {
      project.writeSource('lib/ui_view.dart', '''
import 'package:flutter/widgets.dart';

Widget buildUI() {
  return Text('Hello World');
}
''');

      final errors = await project.runRuleOn('lib/ui_view.dart');
      expect(errors, hasLength(1));

      final fixes = await project.runFixOn('lib/ui_view.dart', errors.first);
      expect(fixes, isNotEmpty);

      final change = fixes.first.change;
      expect(change.message, 'Use CustomText');
      expect(change.edits, hasLength(1));

      final fileEdit = change.edits.first;
      // Should replace Text with CustomText
      final replacementEdits = fileEdit.edits;
      expect(
          replacementEdits.any((e) => e.replacement == 'CustomText'), isTrue);
      // Should add import for CustomText
      expect(
        replacementEdits.any(
          (e) => e.replacement
              .contains('package:sample_app/core/custom_text.dart'),
        ),
        isTrue,
      );
    });

    test(
        'Does not add duplicate import when approved replacement is already imported',
        () async {
      project.writeSource('lib/ui_view.dart', '''
import 'package:flutter/widgets.dart';
import 'package:sample_app/core/custom_text.dart';

Widget buildUI() {
  return Text('Hello World');
}
''');

      final errors = await project.runRuleOn('lib/ui_view.dart');
      expect(errors, hasLength(1));

      final fixes = await project.runFixOn('lib/ui_view.dart', errors.first);
      expect(fixes, isNotEmpty);

      final fileEdit = fixes.first.change.edits.first;
      // Should only have the replacement edit, no new import statement insertion
      expect(fileEdit.edits, hasLength(1));
      expect(fileEdit.edits.first.replacement, 'CustomText');
    });

    test('Preserves multiline arguments and children in nested widgets',
        () async {
      project.writeSource('lib/nested.dart', '''
import 'package:flutter/widgets.dart';

Widget buildUI() {
  return Text(
    'Long label text',
    key: null,
    style: null,
  );
}
''');

      final errors = await project.runRuleOn('lib/nested.dart');
      expect(errors, hasLength(1));

      final fixes = await project.runFixOn('lib/nested.dart', errors.first);
      expect(fixes, isNotEmpty);

      final fileEdit = fixes.first.change.edits.first;
      final textEdit =
          fileEdit.edits.firstWhere((e) => e.replacement == 'CustomText');
      expect(textEdit.length, 'Text'.length);
    });

    test('Replaces aliased import fl.Text without breaking code syntax',
        () async {
      project.writeSource('lib/aliased.dart', '''
import 'package:flutter/widgets.dart' as fl;

fl.Widget buildUI() {
  return fl.Text('Welcome');
}
''');

      final errors = await project.runRuleOn('lib/aliased.dart');
      expect(errors, hasLength(1));

      final fixes = await project.runFixOn('lib/aliased.dart', errors.first);
      expect(fixes, isNotEmpty);

      final fileEdit = fixes.first.change.edits.first;
      // Should replace fl.Text with CustomText
      expect(fileEdit.edits.any((e) => e.replacement == 'CustomText'), isTrue);
    });

    test(
        'Does not flag replacement class internally when it uses the original widget',
        () async {
      project.writeSource('lib/core/custom_text.dart', '''
import 'package:flutter/widgets.dart';

class CustomText extends StatelessWidget {
  final String text;
  const CustomText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text);
  }
}
''');

      final errors = await project.runRuleOn('lib/core/custom_text.dart');
      expect(errors, isEmpty);
    });

    test(
        'Auto-detects import path from lib/ when import is omitted in team_guard.yaml',
        () async {
      final customProject = TestProject.create(
        teamGuardYaml: '''
widgets:
  ElevatedButton:
    replacement: AppElevatedButton
    severity: error
''',
      );

      // Create the replacement file in lib/ui/buttons/app_elevated_button.dart
      customProject.writeSource('lib/ui/buttons/app_elevated_button.dart', '''
import 'package:flutter/widgets.dart';

class AppElevatedButton extends StatelessWidget {
  const AppElevatedButton({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
''');

      customProject.writeSource('lib/view.dart', '''
import 'package:flutter/material.dart';

Widget buildUI() {
  return ElevatedButton(onPressed: () {}, child: null);
}
''');

      final errors = await customProject.runRuleOn('lib/view.dart');
      expect(errors, hasLength(1));

      final fixes = await customProject.runFixOn('lib/view.dart', errors.first);
      expect(fixes, isNotEmpty);

      final fileEdit = fixes.first.change.edits.first;
      expect(
        fileEdit.edits.any(
          (e) => e.replacement.contains(
              'package:sample_app/ui/buttons/app_elevated_button.dart'),
        ),
        isTrue,
      );
      expect(
        fileEdit.edits.any((e) => e.replacement == 'AppElevatedButton'),
        isTrue,
      );

      customProject.dispose();
    });

    test(
        'Does not guess import path when replacement class cannot be found in lib/',
        () async {
      final customProject = TestProject.create(
        teamGuardYaml: '''
widgets:
  GestureDetector:
    replacement: UnknownTapWidget
    severity: error
''',
      );

      customProject.writeSource('lib/view.dart', '''
import 'package:flutter/widgets.dart';

Widget buildUI() {
  return GestureDetector(onTap: () {});
}
''');

      final errors = await customProject.runRuleOn('lib/view.dart');
      expect(errors, hasLength(1));

      final fixes = await customProject.runFixOn('lib/view.dart', errors.first);
      expect(fixes, isNotEmpty);

      final fileEdit = fixes.first.change.edits.first;
      // Replaces widget name without inserting unknown import
      expect(fileEdit.edits, hasLength(1));
      expect(fileEdit.edits.first.replacement, 'UnknownTapWidget');

      customProject.dispose();
    });
  });

  group('Class restrictions & Aliases', () {
    late TestProject project;

    setUp(() {
      project = TestProject.create();
    });

    tearDown(() {
      project.dispose();
    });

    test('Colors.red static access is flagged and offers AppColors fix',
        () async {
      project.writeSource('lib/colors_test.dart', '''
import 'package:flutter/material.dart';

void test() {
  final c = Colors.red;
}
''');

      final errors = await project.runRuleOn('lib/colors_test.dart');
      expect(errors, hasLength(1));
      expect(
        errors.first.message,
        'The class "Colors" is restricted by team policy. Use "AppColors" instead. (Quick Fix available)',
      );

      final fixes =
          await project.runFixOn('lib/colors_test.dart', errors.first);
      expect(fixes, isNotEmpty);
      expect(fixes.first.change.message, 'Use AppColors');
    });

    test('Aliased fl.Colors.red is flagged as a class restriction', () async {
      project.writeSource('lib/aliased_colors.dart', '''
import 'package:flutter/material.dart' as fl;

void test() {
  final c = fl.Colors.red;
}
''');

      final errors = await project.runRuleOn('lib/aliased_colors.dart');
      expect(errors, hasLength(1));
      expect(
          errors.first.message, contains('The class "Colors" is restricted'));
    });
  });

  group('Config validation & loading', () {
    late TestProject project;

    setUp(() {
      project = TestProject.create();
    });

    tearDown(() {
      project.dispose();
    });

    test('Handles missing team_guard.yaml gracefully', () {
      final emptyDir = Directory.systemTemp.createTempSync('team_guard_empty_');
      final config = WidgetGuardConfig.load(emptyDir.path);
      expect(config.widgets, isEmpty);
      expect(config.classes, isEmpty);
      expect(config.validationErrors, isEmpty);
      emptyDir.deleteSync(recursive: true);
    });

    test('Detects malformed YAML syntax in team_guard.yaml', () {
      final invalidDir =
          Directory.systemTemp.createTempSync('team_guard_invalid_');
      File('${invalidDir.path}/team_guard.yaml').writeAsStringSync('''
widgets:
  Text: [invalid yaml: {unclosed
''');

      final config = WidgetGuardConfig.load(invalidDir.path);
      expect(config.validationErrors, isNotEmpty);
      expect(config.validationErrors.first,
          contains('Failed to parse team_guard.yaml'));
      invalidDir.deleteSync(recursive: true);
    });

    test('Detects missing replacement field in team_guard.yaml', () {
      final badDir = Directory.systemTemp.createTempSync('team_guard_bad_');
      File('${badDir.path}/team_guard.yaml').writeAsStringSync('''
widgets:
  Text:
    severity: error
''');

      final config = WidgetGuardConfig.load(badDir.path);
      expect(config.validationErrors, isNotEmpty);
      expect(
        config.validationErrors.first,
        'Entry "Text" in widgets must define a non-empty "replacement".',
      );
      badDir.deleteSync(recursive: true);
    });

    test('Detects invalid severity in team_guard.yaml and falls back to error',
        () {
      final badDir = Directory.systemTemp.createTempSync('team_guard_sev_');
      File('${badDir.path}/team_guard.yaml').writeAsStringSync('''
widgets:
  Text:
    replacement: CustomText
    severity: critical
''');

      final config = WidgetGuardConfig.load(badDir.path);
      expect(config.validationErrors, isNotEmpty);
      expect(config.validationErrors.first,
          contains('Severity for "Text" in widgets must be "error"'));
      expect(config.widgets['Text']?.severity, 'error');
      badDir.deleteSync(recursive: true);
    });

    test(
        'Files nested deeply in subdirectories find team_guard.yaml at project root',
        () async {
      project.writeSource('lib/features/dashboard/presentation/view.dart', '''
import 'package:flutter/widgets.dart';

Widget buildUI() {
  return Text('Deeply nested');
}
''');

      final errors = await project.runRuleOn(
        'lib/features/dashboard/presentation/view.dart',
      );
      expect(errors, hasLength(1));
    });
  });

  group('Generated file handling', () {
    late TestProject project;

    setUp(() {
      project = TestProject.create();
    });

    tearDown(() {
      project.dispose();
    });

    test('Ignores .g.dart files', () async {
      project.writeSource('lib/model.g.dart', '''
import 'package:flutter/widgets.dart';

Widget buildGen() {
  return Text('Generated code');
}
''');

      final errors = await project.runRuleOn('lib/model.g.dart');
      expect(errors, isEmpty);
    });

    test('Ignores .freezed.dart files', () async {
      project.writeSource('lib/state.freezed.dart', '''
import 'package:flutter/widgets.dart';

Widget buildGen() {
  return Text('Freezed generated code');
}
''');

      final errors = await project.runRuleOn('lib/state.freezed.dart');
      expect(errors, isEmpty);
    });
  });

  group('Custom reason messages', () {
    late TestProject project;

    setUp(() {
      project = TestProject.create(
        teamGuardYaml: '''
widgets:
  Text:
    replacement: CustomText
    import: package:sample_app/core/custom_text.dart
    severity: error
    reason: Always use CustomText to enforce dynamic theming and localization.
''',
      );
    });

    tearDown(() {
      project.dispose();
    });

    test('Includes custom reason in problem message when configured', () async {
      project.writeSource('lib/view.dart', '''
import 'package:flutter/widgets.dart';

Widget buildUI() {
  return Text('Hello');
}
''');

      final errors = await project.runRuleOn('lib/view.dart');
      expect(errors, hasLength(1));
      expect(
        errors.first.message,
        'The widget "Text" is restricted by team policy: Always use CustomText to enforce dynamic theming and localization. Use "CustomText" instead. (Quick Fix available)',
      );
    });
  });

  group('Function restrictions (print -> debugPrint)', () {
    late TestProject project;

    setUp(() {
      project = TestProject.create(
        teamGuardYaml: '''
functions:
  print:
    replacement: debugPrint
    import: package:flutter/foundation.dart
    severity: warning
    reason: Avoid leaking logs to production stdout.
''',
      );
    });

    tearDown(() {
      project.dispose();
    });

    test('Flags top-level print call as a warning', () async {
      project.writeSource('lib/log_service.dart', '''
void logData(String msg) {
  print(msg);
}
''');

      final errors = await project.runRuleOn('lib/log_service.dart');
      expect(errors, hasLength(1));
      expect(errors.first.severity.name.toUpperCase(), 'WARNING');
      expect(
        errors.first.message,
        'The function "print" is restricted by team policy: Avoid leaking logs to production stdout. Use "debugPrint" instead. (Quick Fix available)',
      );
    });

    test('Quick Fix replaces print with debugPrint and adds foundation import',
        () async {
      project.writeSource('lib/log_service.dart', '''
void logData(String msg) {
  print(msg);
}
''');

      final errors = await project.runRuleOn('lib/log_service.dart');
      expect(errors, hasLength(1));

      final fixes =
          await project.runFixOn('lib/log_service.dart', errors.first);
      expect(fixes, isNotEmpty);

      final change = fixes.first.change;
      expect(change.message, 'Use debugPrint');

      final fileEdit = change.edits.first;
      expect(
        fileEdit.edits.any((e) => e.replacement == 'debugPrint'),
        isTrue,
      );
      expect(
        fileEdit.edits.any(
            (e) => e.replacement.contains('package:flutter/foundation.dart')),
        isTrue,
      );
    });
  });

  group('Batch Quick Fix (Fix all in file)', () {
    late TestProject project;

    setUp(() {
      project = TestProject.create();
    });

    tearDown(() {
      project.dispose();
    });

    test(
        'Offers "Fix all forbidden widgets in this file" when multiple violations exist',
        () async {
      project.writeSource('lib/multi_view.dart', '''
import 'package:flutter/widgets.dart';

Widget buildUI() {
  final a = Text('First');
  final b = Text('Second');
  return a;
}
''');

      final errors = await project.runRuleOn('lib/multi_view.dart');
      expect(errors, hasLength(2));

      final fixes = await project.runFixOn(
        'lib/multi_view.dart',
        errors.first,
        errors,
      );

      // Should offer both single fix and batch fix
      expect(fixes.any((f) => f.change.message == 'Use CustomText'), isTrue);
      expect(
        fixes.any((f) =>
            f.change.message == 'Fix all forbidden widgets in this file'),
        isTrue,
      );

      final batchFix = fixes.firstWhere(
        (f) => f.change.message == 'Fix all forbidden widgets in this file',
      );
      final fileEdit = batchFix.change.edits.first;

      // Both Text occurrences should be replaced
      final textReplacements =
          fileEdit.edits.where((e) => e.replacement == 'CustomText').toList();
      expect(textReplacements, hasLength(2));

      // Import should be added
      expect(
        fileEdit.edits.any((e) =>
            e.replacement.contains('package:sample_app/core/custom_text.dart')),
        isTrue,
      );
    });
  });

  group('CLI Services (check, migrate, doctor)', () {
    late TestProject project;

    setUp(() {
      project = TestProject.create();
    });

    tearDown(() {
      project.dispose();
    });

    test('TeamGuardCliService.scanFiles detects violations across files',
        () async {
      project.writeSource('lib/view_a.dart', '''
import 'package:flutter/widgets.dart';

Widget buildA() => Text('Hello A');
''');
      project.writeSource('lib/view_b.dart', '''
import 'package:flutter/material.dart';

Widget buildB() => ElevatedButton(onPressed: () {}, child: Text('Click'));
''');

      final service = TeamGuardCliService.fromDirectory(project.rootDir.path)!;
      final violations = await service.scanFiles();

      expect(violations, hasLength(3));
      expect(violations.any((v) => v.element == 'Text'), isTrue);
      expect(violations.any((v) => v.element == 'ElevatedButton'), isTrue);
      expect(violations.every((v) => v.severity == 'ERROR'), isTrue);

      final table = TeamGuardCliService.formatTable(violations);
      expect(table, contains('Text'));
      expect(table, contains('CustomText'));
      expect(table, contains('ElevatedButton'));
    });

    test(
        'TeamGuardCliService.migrateFiles with dryRun=true previews changes without writing',
        () async {
      final file = project.writeSource('lib/dry_view.dart', '''
import 'package:flutter/widgets.dart';

Widget buildUI() => Text('Hello');
''');

      final service = TeamGuardCliService.fromDirectory(project.rootDir.path)!;
      final result = await service.migrateFiles(dryRun: true);

      expect(result.filesChanged, 1);
      expect(result.totalEdits, greaterThanOrEqualTo(1));
      // Content on disk should remain unchanged
      expect(file.readAsStringSync(), contains("Text('Hello')"));
    });

    test('TeamGuardCliService.migrateFiles writes updated content to disk',
        () async {
      final file = project.writeSource('lib/real_view.dart', '''
import 'package:flutter/widgets.dart';

Widget buildUI() => Text('Hello');
''');

      final service = TeamGuardCliService.fromDirectory(project.rootDir.path)!;
      final result = await service.migrateFiles(dryRun: false);

      expect(result.filesChanged, 1);
      final updatedContent = file.readAsStringSync();
      expect(updatedContent, contains("CustomText('Hello')"));
      expect(
          updatedContent, contains('package:sample_app/core/custom_text.dart'));
      expect(RegExp(r'\bText\(').hasMatch(updatedContent), isFalse);
    });

    test('TeamGuardCliService.runDoctor returns accurate health status', () {
      // Create analysis_options.yaml with custom_lint
      File('${project.rootDir.path}/analysis_options.yaml')
          .writeAsStringSync('''
analyzer:
  plugins:
    - custom_lint
''');

      // Add custom_lint and team_guard to pubspec.yaml
      File('${project.rootDir.path}/pubspec.yaml').writeAsStringSync('''
name: sample_app
environment:
  sdk: ">=3.0.0 <4.0.0"
dev_dependencies:
  custom_lint: ^0.8.1
  team_guard: ^1.0.19
''');

      // Create replacement classes in lib/core
      project.writeSource('lib/core/custom_text.dart', 'class CustomText {}');
      project.writeSource(
          'lib/core/app_elevated_button.dart', 'class AppElevatedButton {}');
      project.writeSource('lib/core/app_colors.dart', 'class AppColors {}');
      project.writeSource('lib/core/app_dio.dart', 'class AppDio {}');

      final service = TeamGuardCliService.fromDirectory(project.rootDir.path)!;
      final report = service.runDoctor();

      expect(report.allPassed, isTrue);
      expect(report.items, hasLength(4));
    });
  });
}
