import 'dart:io';
import 'package:yaml/yaml.dart';

class WidgetRestriction {
  final String replacement;
  final String? import;
  final String severity;

  WidgetRestriction({
    required this.replacement,
    this.import,
    this.severity = 'info',
  });
}

class WidgetGuardConfig {
  final Map<String, WidgetRestriction> widgets;
  final Map<String, WidgetRestriction> classes;

  WidgetGuardConfig({
    required this.widgets,
    required this.classes,
  });

  static WidgetGuardConfig load(String startPath) {
    final file = _findConfigFile(startPath) ?? _createDefaultConfig(startPath);

    if (file == null || !file.existsSync()) {
      return WidgetGuardConfig(widgets: {}, classes: {});
    }

    final yaml = loadYaml(file.readAsStringSync());
    if (yaml is! YamlMap) {
      return WidgetGuardConfig(widgets: {}, classes: {});
    }

    final widgets = _parseRestrictionsMap(yaml['widgets']);
    final classes = _parseRestrictionsMap(yaml['classes']);

    return WidgetGuardConfig(
      widgets: widgets,
      classes: classes,
    );
  }

  static File? _createDefaultConfig(String startPath) {
    final projectRoot = _findProjectRoot(startPath);
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

  static Directory? _findProjectRoot(String startPath) {
    var current = Directory(startPath).absolute;

    while (true) {
      final pubspec = File('${current.path}/pubspec.yaml');
      if (pubspec.existsSync()) {
        return current;
      }

      final parent = current.parent;
      if (parent.path == current.path) {
        return null;
      }
      current = parent;
    }
  }

  static File? _findConfigFile(String startPath) {
    var current = Directory(startPath).absolute;

    while (true) {
      final candidate = File('${current.path}/team_guard.yaml');
      if (candidate.existsSync()) {
        return candidate;
      }

      final parent = current.parent;
      if (parent.path == current.path) {
        return null;
      }
      current = parent;
    }
  }

  static WidgetRestriction? _parseRestriction(Object? value) {
    if (value is YamlMap) {
      final replacement = value['replacement']?.toString();
      if (replacement == null || replacement.isEmpty) {
        return null;
      }

      return WidgetRestriction(
        replacement: replacement,
        import: value['import']?.toString(),
        severity: value['severity']?.toString().toLowerCase() ?? 'info',
      );
    }

    if (value is String && value.isNotEmpty) {
      // Backward compatibility for simple shape:
      // widgets:
      //   Text: CustomText
      return WidgetRestriction(replacement: value);
    }

    return null;
  }

  static Map<String, WidgetRestriction> _parseRestrictionsMap(Object? source) {
    if (source is! YamlMap) {
      return {};
    }

    final restrictions = <String, WidgetRestriction>{};
    for (final entry in source.entries) {
      final key = entry.key.toString();
      final restriction = _parseRestriction(entry.value);
      if (restriction == null) continue;
      restrictions[key] = restriction;
    }
    return restrictions;
  }

  static const _defaultConfigTemplate = '''
widgets:
  Text:
    replacement: CustomText
    # import must be a package path only (no Dart import statement).
    # import: package:your_app/custom_text.dart
    severity: warning

classes:
  Colors:
    replacement: AppColors
    # import must be a package path only (no Dart import statement).
    # import: package:your_app/app_colors.dart
    severity: warning
''';
}
