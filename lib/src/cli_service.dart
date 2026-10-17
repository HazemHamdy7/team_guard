// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' show SourceEdit;
import 'config_loader.dart';
import 'forbidden_widget_fix.dart';
import 'forbidden_widget_rule.dart';

class GuardViolation {
  final String filePath;
  final int line;
  final int column;
  final String element;
  final String replacement;
  final String severity;
  final String? reason;
  final String message;

  GuardViolation({
    required this.filePath,
    required this.line,
    required this.column,
    required this.element,
    required this.replacement,
    required this.severity,
    this.reason,
    required this.message,
  });
}

class MigrationResult {
  final int filesChanged;
  final int totalEdits;
  final List<String> modifiedFiles;

  MigrationResult({
    required this.filesChanged,
    required this.totalEdits,
    required this.modifiedFiles,
  });
}

class DoctorCheckItem {
  final String title;
  final bool isSuccess;
  final String message;
  final String? suggestion;

  DoctorCheckItem({
    required this.title,
    required this.isSuccess,
    required this.message,
    this.suggestion,
  });
}

class DoctorReport {
  final List<DoctorCheckItem> items;
  bool get allPassed => items.every((i) => i.isSuccess);

  DoctorReport(this.items);
}

class TeamGuardCliService {
  final String projectRoot;
  final WidgetGuardConfig config;

  TeamGuardCliService({
    required this.projectRoot,
    required this.config,
  });

  static TeamGuardCliService? fromDirectory(String startPath) {
    final rootDir = WidgetGuardConfig.findProjectRoot(startPath);
    if (rootDir == null) return null;

    final config = WidgetGuardConfig.load(rootDir.path);
    return TeamGuardCliService(
      projectRoot: rootDir.path,
      config: config,
    );
  }

  List<File> findDartFiles([List<String>? subdirs]) {
    final targets = subdirs != null && subdirs.isNotEmpty ? subdirs : ['lib'];

    final dartFiles = <File>[];

    for (final target in targets) {
      final dir = Directory('$projectRoot${Platform.pathSeparator}$target');
      if (!dir.existsSync()) continue;

      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final path = entity.path;
        if (!path.endsWith('.dart')) continue;
        if (path.endsWith('.g.dart') ||
            path.endsWith('.freezed.dart') ||
            path.endsWith('.mocks.dart') ||
            path.endsWith('.gen.dart')) {
          continue;
        }
        final normalized = path.replaceAll('\\', '/');
        if (normalized.contains('/.dart_tool/')) continue;

        dartFiles.add(entity);
      }
    }

    return dartFiles;
  }

  Future<List<GuardViolation>> scanFiles([List<String>? subdirs]) async {
    final files = findDartFiles(subdirs);
    final violations = <GuardViolation>[];
    final rule = ForbiddenWidgetRule();

    for (final file in files) {
      final resolved = await resolveFile(path: file.path);
      if (resolved is! ResolvedUnitResult) continue;

      final errors = await rule.testRun(resolved);
      final relPath = _relativePath(file.path);

      for (final error in errors) {
        final loc = resolved.lineInfo.getLocation(error.offset);
        final parsed = _parseMessage(error.message);

        violations.add(
          GuardViolation(
            filePath: relPath,
            line: loc.lineNumber,
            column: loc.columnNumber,
            element: parsed.element,
            replacement: parsed.replacement,
            severity: error.severity.name.toUpperCase(),
            reason: parsed.reason,
            message: error.message,
          ),
        );
      }
    }

    return violations;
  }

  Future<MigrationResult> migrateFiles({
    bool dryRun = false,
    List<String>? subdirs,
  }) async {
    final files = findDartFiles(subdirs);
    final rule = ForbiddenWidgetRule();
    final fix = ForbiddenWidgetFix();

    var filesChanged = 0;
    var totalEdits = 0;
    final modifiedFiles = <String>[];

    for (final file in files) {
      final resolved = await resolveFile(path: file.path);
      if (resolved is! ResolvedUnitResult) continue;

      final errors = await rule.testRun(resolved);
      if (errors.isEmpty) continue;

      final fixes = await fix.testRun(resolved, errors.first, errors);
      if (fixes.isEmpty) continue;

      final fixToApply = fixes.firstWhere(
        (f) => f.change.message == 'Fix all forbidden widgets in this file',
        orElse: () => fixes.first,
      );

      if (fixToApply.change.edits.isEmpty) continue;
      final fileEdit = fixToApply.change.edits.first;
      if (fileEdit.edits.isEmpty) continue;

      final originalContent = file.readAsStringSync();
      final updatedContent = applySourceEdits(originalContent, fileEdit.edits);

      if (originalContent != updatedContent) {
        if (!dryRun) {
          file.writeAsStringSync(updatedContent);
        }
        filesChanged++;
        totalEdits += fileEdit.edits.length;
        modifiedFiles.add(_relativePath(file.path));
      }
    }

    return MigrationResult(
      filesChanged: filesChanged,
      totalEdits: totalEdits,
      modifiedFiles: modifiedFiles,
    );
  }

  DoctorReport runDoctor() {
    final items = <DoctorCheckItem>[];

    // 1. Check team_guard.yaml
    final configFile =
        File('$projectRoot${Platform.pathSeparator}team_guard.yaml');
    if (!configFile.existsSync()) {
      items.add(
        DoctorCheckItem(
          title: 'Configuration file (team_guard.yaml)',
          isSuccess: false,
          message: 'File not found at $projectRoot/team_guard.yaml',
          suggestion:
              'Run "dart run team_guard:init" to create a default configuration.',
        ),
      );
    } else if (config.validationErrors.isNotEmpty) {
      items.add(
        DoctorCheckItem(
          title: 'Configuration file (team_guard.yaml)',
          isSuccess: false,
          message:
              'Syntax/validation errors detected:\n  ${config.validationErrors.join('\n  ')}',
          suggestion: 'Fix the syntax in team_guard.yaml.',
        ),
      );
    } else {
      final totalRules = config.widgets.length +
          config.classes.length +
          config.functions.length;
      items.add(
        DoctorCheckItem(
          title: 'Configuration file (team_guard.yaml)',
          isSuccess: true,
          message:
              'Valid configuration with $totalRules rule(s) (${config.widgets.length} widgets, ${config.classes.length} classes, ${config.functions.length} functions).',
        ),
      );
    }

    // 2. Check analysis_options.yaml
    final analysisFile =
        File('$projectRoot${Platform.pathSeparator}analysis_options.yaml');
    if (!analysisFile.existsSync()) {
      items.add(
        DoctorCheckItem(
          title: 'Analysis options (analysis_options.yaml)',
          isSuccess: false,
          message: 'analysis_options.yaml not found.',
          suggestion:
              'Run "dart run team_guard:init" to scaffold analysis_options.yaml.',
        ),
      );
    } else {
      final content = analysisFile.readAsStringSync();
      if (content.contains('custom_lint')) {
        items.add(
          DoctorCheckItem(
            title: 'Analysis options (analysis_options.yaml)',
            isSuccess: true,
            message: 'custom_lint plugin is enabled in analysis_options.yaml.',
          ),
        );
      } else {
        items.add(
          DoctorCheckItem(
            title: 'Analysis options (analysis_options.yaml)',
            isSuccess: false,
            message:
                'custom_lint plugin is not declared in analysis_options.yaml.',
            suggestion:
                'Add custom_lint under analyzer: plugins: in analysis_options.yaml.',
          ),
        );
      }
    }

    // 3. Check pubspec.yaml dependencies
    final pubspecFile =
        File('$projectRoot${Platform.pathSeparator}pubspec.yaml');
    if (pubspecFile.existsSync()) {
      final content = pubspecFile.readAsStringSync();
      final hasCustomLint = content.contains('custom_lint');
      final hasTeamGuard = content.contains('team_guard');

      if (hasCustomLint && hasTeamGuard) {
        items.add(
          DoctorCheckItem(
            title: 'Project dependencies (pubspec.yaml)',
            isSuccess: true,
            message: 'team_guard and custom_lint dependencies found.',
          ),
        );
      } else {
        items.add(
          DoctorCheckItem(
            title: 'Project dependencies (pubspec.yaml)',
            isSuccess: false,
            message:
                'Missing required dependencies: ${!hasTeamGuard ? "team_guard " : ""}${!hasCustomLint ? "custom_lint" : ""}'
                    .trim(),
            suggestion: 'Run "dart pub add dev:team_guard dev:custom_lint".',
          ),
        );
      }
    }

    // 4. Check replacement symbols
    final libDir = Directory('$projectRoot${Platform.pathSeparator}lib');
    final missingReplacements = <String>[];

    for (final entry in [
      ...config.widgets.entries,
      ...config.classes.entries
    ]) {
      final rep = entry.value.replacement;
      if (entry.value.import != null && entry.value.import!.isNotEmpty) {
        // Explicit import specified
        continue;
      }
      if (libDir.existsSync()) {
        final pattern = RegExp('class\\s+${RegExp.escape(rep)}\\b');
        var found = false;
        for (final file in libDir.listSync(recursive: true)) {
          if (file is File && file.path.endsWith('.dart')) {
            try {
              if (pattern.hasMatch(file.readAsStringSync())) {
                found = true;
                break;
              }
            } catch (_) {}
          }
        }
        if (!found) {
          missingReplacements.add(rep);
        }
      }
    }

    if (missingReplacements.isEmpty) {
      items.add(
        DoctorCheckItem(
          title: 'Approved replacements verification',
          isSuccess: true,
          message:
              'All configured replacement classes exist in lib/ or specify explicit imports.',
        ),
      );
    } else {
      items.add(
        DoctorCheckItem(
          title: 'Approved replacements verification',
          isSuccess: false,
          message:
              'Replacement class(es) not found in lib/: ${missingReplacements.join(', ')}',
          suggestion:
              'Run "dart run team_guard:init" to scaffold missing replacement classes in lib/core/.',
        ),
      );
    }

    return DoctorReport(items);
  }

  static String applySourceEdits(String original, List<SourceEdit> edits) {
    final sortedEdits = List<SourceEdit>.from(edits)
      ..sort((a, b) => b.offset.compareTo(a.offset));

    var content = original;
    final seenOffsets = <int>{};

    for (final edit in sortedEdits) {
      if (!seenOffsets.add(edit.offset)) continue;
      content = content.replaceRange(
        edit.offset,
        edit.offset + edit.length,
        edit.replacement,
      );
    }

    return content;
  }

  String _relativePath(String fullPath) {
    if (fullPath.startsWith(projectRoot)) {
      var rel = fullPath.substring(projectRoot.length);
      if (rel.startsWith(Platform.pathSeparator) || rel.startsWith('/')) {
        rel = rel.substring(1);
      }
      return rel.replaceAll('\\', '/');
    }
    return fullPath.replaceAll('\\', '/');
  }

  static ({String element, String replacement, String? reason}) _parseMessage(
    String message,
  ) {
    // Regex matching:
    // The <kind> "<name>" is restricted by team policy: <reason>. Use "<replacement>" instead.
    // The <kind> "<name>" is restricted by team policy. Use "<replacement>" instead.
    final match = RegExp(
      r'The (?:widget|class|function) "([^"]+)" is restricted by team policy(?:: (.+?))?\. Use "([^"]+)" instead',
    ).firstMatch(message);

    if (match != null) {
      return (
        element: match.group(1) ?? 'Unknown',
        reason: match.group(2),
        replacement: match.group(3) ?? 'ApprovedWidget',
      );
    }

    return (
      element: 'Unknown',
      replacement: 'ApprovedWidget',
      reason: null,
    );
  }

  static String formatTable(List<GuardViolation> violations) {
    if (violations.isEmpty) {
      return 'No violations found.';
    }

    final headers = ['File', 'Line', 'Restricted', 'Replacement', 'Severity'];

    final rows = violations.map((v) {
      return [
        v.filePath,
        v.line.toString(),
        v.element,
        v.replacement,
        v.severity,
      ];
    }).toList();

    final colWidths = List<int>.generate(headers.length, (i) {
      var maxLen = headers[i].length;
      for (final row in rows) {
        if (row[i].length > maxLen) {
          maxLen = row[i].length;
        }
      }
      return maxLen;
    });

    final buffer = StringBuffer();

    // Top border
    buffer.write('┌');
    for (var i = 0; i < colWidths.length; i++) {
      buffer.write('─' * (colWidths[i] + 2));
      buffer.write(i == colWidths.length - 1 ? '┐\n' : '┬');
    }

    // Header row
    buffer.write('│');
    for (var i = 0; i < headers.length; i++) {
      buffer.write(' ${headers[i].padRight(colWidths[i])} │');
    }
    buffer.writeln();

    // Separator
    buffer.write('├');
    for (var i = 0; i < colWidths.length; i++) {
      buffer.write('─' * (colWidths[i] + 2));
      buffer.write(i == colWidths.length - 1 ? '┤\n' : '┼');
    }

    // Data rows
    for (final row in rows) {
      buffer.write('│');
      for (var i = 0; i < row.length; i++) {
        buffer.write(' ${row[i].padRight(colWidths[i])} │');
      }
      buffer.writeln();
    }

    // Bottom border
    buffer.write('└');
    for (var i = 0; i < colWidths.length; i++) {
      buffer.write('─' * (colWidths[i] + 2));
      buffer.write(i == colWidths.length - 1 ? '┘' : '┴');
    }

    return buffer.toString();
  }
}
