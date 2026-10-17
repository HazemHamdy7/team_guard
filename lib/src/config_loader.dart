import 'dart:io';
import 'package:yaml/yaml.dart';

class WidgetRestriction {
  final String replacement;
  final String? import;
  final String severity;
  final String? reason;

  WidgetRestriction({
    required this.replacement,
    this.import,
    this.severity = 'info',
    this.reason,
  });
}

class WidgetGuardConfig {
  final Map<String, WidgetRestriction> widgets;
  final Map<String, WidgetRestriction> classes;
  final Map<String, WidgetRestriction> functions;
  final List<String> validationErrors;

  WidgetGuardConfig({
    required this.widgets,
    required this.classes,
    this.functions = const {},
    this.validationErrors = const [],
  });

  WidgetRestriction? restrictionForSymbol(String symbolName) {
    return restrictionForWidget(symbolName) ?? restrictionForClass(symbolName);
  }

  WidgetRestriction? restrictionForWidget(String symbolName) {
    if (_isLowerCamelCase(symbolName)) return null;
    return widgets[symbolName] ?? _findByNormalized(widgets, symbolName);
  }

  WidgetRestriction? restrictionForClass(String symbolName) {
    if (_isLowerCamelCase(symbolName)) return null;
    return classes[symbolName] ?? _findByNormalized(classes, symbolName);
  }

  WidgetRestriction? restrictionForFunction(String functionName) {
    return functions[functionName] ??
        _findByNormalized(functions, functionName);
  }

  bool isWidget(String symbolName) => restrictionForWidget(symbolName) != null;

  static bool _isLowerCamelCase(String value) {
    if (value.isEmpty) return false;
    final first = value.codeUnitAt(0);
    return first >= 97 && first <= 122; // 'a' through 'z'
  }

  static WidgetGuardConfig load(String startPath) {
    final file = _findConfigFile(startPath);

    if (file == null || !file.existsSync()) {
      return WidgetGuardConfig(widgets: {}, classes: {});
    }

    try {
      final content = file.readAsStringSync();
      final yaml = loadYaml(content);
      if (yaml is! YamlMap) {
        return WidgetGuardConfig(
          widgets: {},
          classes: {},
          validationErrors: [
            'team_guard.yaml at ${file.path} must be a YAML mapping.',
          ],
        );
      }

      final errors = <String>[];
      final widgets = _parseRestrictionsMap(yaml['widgets'], 'widgets', errors);
      final classes = _parseRestrictionsMap(yaml['classes'], 'classes', errors);
      final functions =
          _parseRestrictionsMap(yaml['functions'], 'functions', errors);

      return WidgetGuardConfig(
        widgets: widgets,
        classes: classes,
        functions: functions,
        validationErrors: errors,
      );
    } on YamlException catch (e) {
      return WidgetGuardConfig(
        widgets: {},
        classes: {},
        validationErrors: [
          'Failed to parse team_guard.yaml at ${file.path}: ${e.message}',
        ],
      );
    } catch (e) {
      return WidgetGuardConfig(
        widgets: {},
        classes: {},
        validationErrors: [
          'Error reading team_guard.yaml at ${file.path}: $e',
        ],
      );
    }
  }

  static File? ensureConfigFile(String startPath) {
    return _findConfigFile(startPath) ?? _createDefaultConfig(startPath);
  }

  static File? _createDefaultConfig(String startPath) {
    final projectRoot = findProjectRoot(startPath);
    if (projectRoot == null) return null;

    final file = File('${projectRoot.path}/team_guard.yaml');
    if (file.existsSync()) return file;

    try {
      file.writeAsStringSync(_defaultConfigTemplate);
      return file;
    } catch (_) {
      return null;
    }
  }

  static Directory? findProjectRoot(String startPath) {
    var entity = FileSystemEntity.isDirectorySync(startPath)
        ? Directory(startPath).absolute
        : File(startPath).parent.absolute;

    while (true) {
      final pubspec = File('${entity.path}/pubspec.yaml');
      if (pubspec.existsSync()) {
        return entity;
      }

      final parent = entity.parent;
      if (parent.path == entity.path) {
        return null;
      }
      entity = parent;
    }
  }

  static File? _findConfigFile(String startPath) {
    var entity = FileSystemEntity.isDirectorySync(startPath)
        ? Directory(startPath).absolute
        : File(startPath).parent.absolute;

    while (true) {
      final candidate = File('${entity.path}/team_guard.yaml');
      if (candidate.existsSync()) {
        return candidate;
      }

      final parent = entity.parent;
      if (parent.path == entity.path) {
        return null;
      }
      entity = parent;
    }
  }

  static WidgetRestriction? _parseRestriction(
    String key,
    Object? value,
    String section,
    List<String> errors,
  ) {
    if (value is YamlMap) {
      final replacement = value['replacement']?.toString().trim();
      if (replacement == null || replacement.isEmpty) {
        errors.add(
          'Entry "$key" in $section must define a non-empty "replacement".',
        );
        return null;
      }

      var severity = value['severity']?.toString().toLowerCase() ?? 'info';
      if (severity != 'error' && severity != 'warning' && severity != 'info') {
        errors.add(
          'Severity for "$key" in $section must be "error", "warning", or "info" (got "$severity").',
        );
        severity = 'error';
      }

      return WidgetRestriction(
        replacement: replacement,
        import: value['import']?.toString(),
        severity: severity,
        reason: value['reason']?.toString(),
      );
    }

    if (value is String && value.trim().isNotEmpty) {
      // Backward compatibility for simple shape:
      // widgets:
      //   Text: CustomText
      return WidgetRestriction(replacement: value.trim());
    }

    errors
        .add('Entry "$key" in $section must be a map or a replacement string.');
    return null;
  }

  static Map<String, WidgetRestriction> _parseRestrictionsMap(
    Object? source,
    String section,
    List<String> errors,
  ) {
    if (source == null) {
      return {};
    }

    if (source is! YamlMap) {
      errors
          .add('The "$section" section in team_guard.yaml must be a mapping.');
      return {};
    }

    final restrictions = <String, WidgetRestriction>{};
    for (final entry in source.entries) {
      final key = entry.key.toString();
      final restriction = _parseRestriction(key, entry.value, section, errors);
      if (restriction == null) continue;
      restrictions[key] = restriction;
    }
    return restrictions;
  }

  static WidgetRestriction? _findByNormalized(
    Map<String, WidgetRestriction> source,
    String normalizedSymbol,
  ) {
    for (final entry in source.entries) {
      if (_normalizeSymbol(entry.key) == normalizedSymbol) {
        return entry.value;
      }
    }
    return null;
  }

  static String _normalizeSymbol(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toLowerCase();
  }

  static const _defaultConfigTemplate = '''
widgets:
  Text:
    replacement: CustomText
    # import must be a package path only (no Dart import statement).
    # import: package:your_app/core/ui/custom_text.dart
    severity: error
    # reason: CustomText enforces brand typography and localization.

  ElevatedButton:
    replacement: AppElevatedButton
    # import must be a package path only (no Dart import statement).
    # import: package:your_app/core/ui/buttons/app_elevated_button.dart
    severity: error

classes:
  Colors:
    replacement: AppColors
    # import must be a package path only (no Dart import statement).
    # import: package:your_app/core/theme/app_colors.dart
    severity: error

  Dio:
    replacement: AppDio
    # import must be a package path only (no Dart import statement).
    # import: package:your_app/core/network/app_dio.dart
    severity: error

  GetIt:
    replacement: AppLocator
    # import must be a package path only (no Dart import statement).
    # import: package:your_app/core/di/app_locator.dart
    severity: error

  Cubit:
    replacement: AppCubit
    # import must be a package path only (no Dart import statement).
    # import: package:your_app/core/state/app_cubit.dart
    severity: error

functions:
  print:
    replacement: debugPrint
    # import must be a package path only (no Dart import statement).
    # import: package:flutter/foundation.dart
    severity: warning
    reason: Use debugPrint or a logging utility to avoid leaking production logs.
''';
}
