import 'dart:io';
import 'package:analyzer/dart/ast/ast.dart'
    show ClassDeclaration, ConstructorName, NamedType, PrefixedIdentifier;
import 'package:analyzer/dart/element/element.dart' show InterfaceElement;
import 'package:analyzer/source/source_range.dart' show SourceRange;
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'config_loader.dart';

class _FileReplacement {
  final SourceRange sourceRange;
  final String replacement;
  final String? importPath;

  _FileReplacement({
    required this.sourceRange,
    required this.replacement,
    this.importPath,
  });
}

class ForbiddenWidgetFix extends DartFix {
  static final Map<String, String?> _autoImportCache = {};

  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Object analysisError,
    List<Object> others,
  ) {
    final projectRoot =
        _findProjectRoot(resolver.path) ?? File(resolver.path).parent.path;
    final config = WidgetGuardConfig.load(projectRoot);
    final packageName = _readPackageName(projectRoot);
    final diagnostic = analysisError as dynamic;

    final allReplacements = <_FileReplacement>[];
    final seenOffsets = <int>{};

    void recordReplacement({
      required SourceRange range,
      required String replacement,
      required String? importPath,
    }) {
      if (seenOffsets.add(range.offset)) {
        allReplacements.add(
          _FileReplacement(
            sourceRange: range,
            replacement: replacement,
            importPath: importPath,
          ),
        );
      }
    }

    context.registry.addInstanceCreationExpression((node) {
      final typeNode = node.constructorName.type;
      final nameToken = typeNode.name;
      final symbolName = nameToken.lexeme;

      final widgetRestriction = config.restrictionForWidget(symbolName);
      final classRestriction = config.restrictionForClass(symbolName);
      final restriction = widgetRestriction ?? classRestriction;
      if (restriction == null) return;

      final constructorElem = node.constructorName.element;
      final interfaceElem = (constructorElem?.enclosingElement ??
          typeNode.element) as InterfaceElement?;
      if (widgetRestriction != null &&
          interfaceElem != null &&
          !_isFlutterWidget(interfaceElem)) {
        return;
      }

      final replacement = restriction.replacement;
      final enclosingClassName =
          node.thisOrAncestorOfType<ClassDeclaration>()?.name.lexeme;

      if (enclosingClassName == replacement) {
        return;
      }

      final importPath = _resolveImportPath(
        explicitImport: restriction.import,
        replacement: replacement,
        projectRoot: projectRoot,
        packageName: packageName,
      );

      recordReplacement(
        range: typeNode.sourceRange,
        replacement: replacement,
        importPath: importPath,
      );

      final matchesCurrentError = diagnostic.offset == nameToken.offset &&
          diagnostic.length == nameToken.length;
      if (!matchesCurrentError) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Use $replacement',
        priority: 1,
      );

      changeBuilder.addDartFileEdit((builder) {
        if (importPath != null && importPath.isNotEmpty) {
          builder.importLibrary(Uri.parse(importPath));
        }

        builder.addSimpleReplacement(
          typeNode.sourceRange,
          replacement,
        );
      });
    });

    context.registry.addPrefixedIdentifier((node) {
      final prefixElement = node.prefix.element;
      if (prefixElement is! InterfaceElement) return;

      final className = prefixElement.name;
      if (className == null) return;

      final restriction = config.restrictionForClass(className) ??
          config.restrictionForWidget(className);
      if (restriction == null) return;

      if (config.isWidget(className) && !_isFlutterWidget(prefixElement)) {
        return;
      }

      final replacement = restriction.replacement;
      final enclosingClassName =
          node.thisOrAncestorOfType<ClassDeclaration>()?.name.lexeme;
      if (enclosingClassName == replacement) return;

      final importPath = _resolveImportPath(
        explicitImport: restriction.import,
        replacement: replacement,
        projectRoot: projectRoot,
        packageName: packageName,
      );

      recordReplacement(
        range: node.prefix.sourceRange,
        replacement: replacement,
        importPath: importPath,
      );

      final nameToken = node.prefix.token;
      final matchesCurrentError = diagnostic.offset == nameToken.offset &&
          diagnostic.length == nameToken.length;
      if (!matchesCurrentError) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Use $replacement',
        priority: 1,
      );

      changeBuilder.addDartFileEdit((builder) {
        if (importPath != null && importPath.isNotEmpty) {
          builder.importLibrary(Uri.parse(importPath));
        }

        builder.addSimpleReplacement(
          node.prefix.sourceRange,
          replacement,
        );
      });
    });

    context.registry.addPropertyAccess((node) {
      final target = node.target;
      if (target is! PrefixedIdentifier) return;

      final targetElem = target.identifier.element;
      if (targetElem is! InterfaceElement) return;

      final className = targetElem.name;
      if (className == null) return;

      final restriction = config.restrictionForClass(className) ??
          config.restrictionForWidget(className);
      if (restriction == null) return;

      if (config.isWidget(className) && !_isFlutterWidget(targetElem)) {
        return;
      }

      final replacement = restriction.replacement;
      final enclosingClassName =
          node.thisOrAncestorOfType<ClassDeclaration>()?.name.lexeme;
      if (enclosingClassName == replacement) return;

      final importPath = _resolveImportPath(
        explicitImport: restriction.import,
        replacement: replacement,
        projectRoot: projectRoot,
        packageName: packageName,
      );

      recordReplacement(
        range: target.sourceRange,
        replacement: replacement,
        importPath: importPath,
      );

      final nameToken = target.identifier.token;
      final matchesCurrentError = diagnostic.offset == nameToken.offset &&
          diagnostic.length == nameToken.length;
      if (!matchesCurrentError) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Use $replacement',
        priority: 1,
      );

      changeBuilder.addDartFileEdit((builder) {
        if (importPath != null && importPath.isNotEmpty) {
          builder.importLibrary(Uri.parse(importPath));
        }

        builder.addSimpleReplacement(
          target.sourceRange,
          replacement,
        );
      });
    });

    context.registry.addNamedType((node) {
      if (_isConstructorType(node)) {
        // Already handled by instance creation fix.
        return;
      }

      final nameToken = node.name;
      final symbolName = nameToken.lexeme;
      final widgetRestriction = config.restrictionForWidget(symbolName);
      final classRestriction = config.restrictionForClass(symbolName);
      final restriction = widgetRestriction ?? classRestriction;
      if (restriction == null) return;

      final elem = node.element;
      if (elem is InterfaceElement &&
          widgetRestriction != null &&
          !_isFlutterWidget(elem)) {
        return;
      }

      final replacement = restriction.replacement;
      final enclosingClassName =
          node.thisOrAncestorOfType<ClassDeclaration>()?.name.lexeme;
      if (enclosingClassName == replacement) return;

      final importPath = _resolveImportPath(
        explicitImport: restriction.import,
        replacement: replacement,
        projectRoot: projectRoot,
        packageName: packageName,
      );

      recordReplacement(
        range: node.name.sourceRange,
        replacement: replacement,
        importPath: importPath,
      );

      final matchesCurrentError = diagnostic.offset == nameToken.offset &&
          diagnostic.length == nameToken.length;
      if (!matchesCurrentError) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Use $replacement',
        priority: 1,
      );

      changeBuilder.addDartFileEdit((builder) {
        if (importPath != null && importPath.isNotEmpty) {
          builder.importLibrary(Uri.parse(importPath));
        }

        builder.addSimpleReplacement(
          node.name.sourceRange,
          replacement,
        );
      });
    });

    context.registry.addMethodInvocation((node) {
      // Top-level function invocations (e.g. print(...)) have no target.
      if (node.target != null) return;

      final functionName = node.methodName.name;
      final restriction = config.restrictionForFunction(functionName);
      if (restriction == null) return;

      final replacement = restriction.replacement;
      final importPath = _resolveImportPath(
        explicitImport: restriction.import,
        replacement: replacement,
        projectRoot: projectRoot,
        packageName: packageName,
      );

      recordReplacement(
        range: node.methodName.sourceRange,
        replacement: replacement,
        importPath: importPath,
      );

      final nameToken = node.methodName.token;
      final matchesCurrentError = diagnostic.offset == nameToken.offset &&
          diagnostic.length == nameToken.length;
      if (!matchesCurrentError) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Use $replacement',
        priority: 1,
      );

      changeBuilder.addDartFileEdit((builder) {
        if (importPath != null && importPath.isNotEmpty) {
          builder.importLibrary(Uri.parse(importPath));
        }

        builder.addSimpleReplacement(
          node.methodName.sourceRange,
          replacement,
        );
      });
    });

    context.addPostRunCallback(() {
      if (allReplacements.length > 1) {
        final changeBuilder = reporter.createChangeBuilder(
          message: 'Fix all forbidden widgets in this file',
          priority: 0,
        );

        changeBuilder.addDartFileEdit((builder) {
          final sortedReplacements = List<_FileReplacement>.from(
              allReplacements)
            ..sort(
                (a, b) => b.sourceRange.offset.compareTo(a.sourceRange.offset));

          for (final rep in sortedReplacements) {
            if (rep.importPath != null && rep.importPath!.isNotEmpty) {
              builder.importLibrary(Uri.parse(rep.importPath!));
            }
            builder.addSimpleReplacement(rep.sourceRange, rep.replacement);
          }
        });
      }
    });
  }

  String? _resolveImportPath({
    required String? explicitImport,
    required String replacement,
    required String projectRoot,
    required String? packageName,
  }) {
    final normalizedExplicit = _normalizeImportPath(explicitImport);
    if (normalizedExplicit != null) {
      return normalizedExplicit;
    }

    if (replacement == 'debugPrint') {
      return 'package:flutter/foundation.dart';
    }

    if (packageName == null || packageName.isEmpty) {
      return null;
    }

    final cacheKey = '$projectRoot|$replacement|$packageName';
    final cached = _autoImportCache[cacheKey];
    if (cached != null || _autoImportCache.containsKey(cacheKey)) {
      return cached;
    }

    final detectedImport = _detectImportFromLib(
      replacement: replacement,
      projectRoot: projectRoot,
      packageName: packageName,
    );
    _autoImportCache[cacheKey] = detectedImport;
    return detectedImport;
  }

  bool _isConstructorType(NamedType node) {
    final parent = node.parent;
    return parent is ConstructorName && identical(parent.type, node);
  }

  String? _normalizeImportPath(String? value) {
    if (value == null) return null;

    var normalized = value.trim();
    if (normalized.isEmpty) return null;

    final fullImportMatch = RegExp(
      r'''^import\s+['"]([^'"]+)['"]\s*;?$''',
    ).firstMatch(normalized);
    if (fullImportMatch != null) {
      normalized = fullImportMatch.group(1)!;
    }

    if ((normalized.startsWith("'") && normalized.endsWith("'")) ||
        (normalized.startsWith('"') && normalized.endsWith('"'))) {
      normalized = normalized.substring(1, normalized.length - 1);
    }

    if (normalized.endsWith(';')) {
      normalized = normalized.substring(0, normalized.length - 1).trim();
    }

    if (normalized.isEmpty) return null;
    return normalized;
  }

  String? _detectImportFromLib({
    required String replacement,
    required String projectRoot,
    required String packageName,
  }) {
    final libDir = Directory('$projectRoot${Platform.pathSeparator}lib');
    if (!libDir.existsSync()) {
      return null;
    }

    final classPattern = RegExp('class\\s+${RegExp.escape(replacement)}\\b');
    final matchedImports = <String>[];

    for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File ||
          !entity.path.endsWith('.dart') ||
          entity.path.endsWith('.g.dart') ||
          entity.path.endsWith('.freezed.dart') ||
          entity.path.endsWith('.mocks.dart') ||
          entity.path.endsWith('.gen.dart')) {
        continue;
      }

      String content;
      try {
        content = entity.readAsStringSync();
      } catch (_) {
        continue;
      }

      if (!classPattern.hasMatch(content)) {
        continue;
      }

      final relativePath =
          entity.path.substring(libDir.path.length + 1).replaceAll('\\', '/');
      matchedImports.add('package:$packageName/$relativePath');

      // Keep this deterministic: auto-import only when a single match exists.
      if (matchedImports.length > 1) {
        return null;
      }
    }

    return matchedImports.isEmpty ? null : matchedImports.first;
  }

  String? _findProjectRoot(String sourcePath) {
    var entity = FileSystemEntity.isDirectorySync(sourcePath)
        ? Directory(sourcePath).absolute
        : File(sourcePath).parent.absolute;

    while (true) {
      final pubspec = File(
        '${entity.path}${Platform.pathSeparator}pubspec.yaml',
      );
      if (pubspec.existsSync()) {
        return entity.path;
      }

      final parent = entity.parent;
      if (parent.path == entity.path) {
        return null;
      }
      entity = parent;
    }
  }

  String? _readPackageName(String projectRoot) {
    final pubspecFile = File(
      '$projectRoot${Platform.pathSeparator}pubspec.yaml',
    );
    if (!pubspecFile.existsSync()) {
      return null;
    }

    try {
      for (final line in pubspecFile.readAsLinesSync()) {
        final match = RegExp(r'^\s*name\s*:\s*([^\s#]+)').firstMatch(line);
        if (match != null) {
          return match.group(1);
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static bool _isFlutterWidget(InterfaceElement element) {
    if (_isFromFlutter(element.library.uri)) {
      return true;
    }
    return element.allSupertypes.any((supertype) {
      final name = supertype.element.name;
      return (name == 'Widget' ||
              name == 'StatelessWidget' ||
              name == 'StatefulWidget' ||
              name == 'InheritedWidget' ||
              name == 'RenderObjectWidget') &&
          _isFromFlutter(supertype.element.library.uri);
    });
  }

  static bool _isFromFlutter(Uri uri) {
    return uri.scheme == 'package' &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first == 'flutter';
  }
}
