import 'package:analyzer/dart/ast/ast.dart'
    show ClassDeclaration, ConstructorName, NamedType, PrefixedIdentifier;
import 'package:analyzer/dart/element/element.dart' show InterfaceElement;
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'config_loader.dart';
import 'forbidden_widget_fix.dart';

class ForbiddenWidgetRule extends DartLintRule {
  ForbiddenWidgetRule() : super(code: _errorCode);

  static const _errorCode = LintCode(
    name: 'team_guard.forbidden_widget',
    problemMessage: '{0}',
    errorSeverity: DiagnosticSeverity.ERROR,
    uniqueName: 'team_guard.forbidden_widget.error',
  );

  static const _warningCode = LintCode(
    name: 'team_guard.forbidden_widget',
    problemMessage: '{0}',
    errorSeverity: DiagnosticSeverity.WARNING,
    uniqueName: 'team_guard.forbidden_widget.warning',
  );

  static const _infoCode = LintCode(
    name: 'team_guard.forbidden_widget',
    problemMessage: '{0}',
    errorSeverity: DiagnosticSeverity.INFO,
    uniqueName: 'team_guard.forbidden_widget.info',
  );

  @override
  List<Fix> getFixes() => [ForbiddenWidgetFix()];

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (_shouldIgnore(resolver.path)) {
      return;
    }

    final config = WidgetGuardConfig.load(resolver.path);

    context.registry.addInstanceCreationExpression((node) {
      final typeNode = node.constructorName.type;
      final symbolName = typeNode.name.lexeme;

      if (_isLowerCamelCase(symbolName)) return;

      final widgetRestriction = config.restrictionForWidget(symbolName);
      final classRestriction = config.restrictionForClass(symbolName);
      final restriction = widgetRestriction ?? classRestriction;
      if (restriction == null) return;

      final constructorElem = node.constructorName.element;
      final interfaceElem = (constructorElem?.enclosingElement ??
          typeNode.element) as InterfaceElement?;

      if (widgetRestriction != null) {
        if (interfaceElem != null && !_isFlutterWidget(interfaceElem)) {
          return;
        }
      }

      final replacement = restriction.replacement;
      final enclosingClassName =
          node.thisOrAncestorOfType<ClassDeclaration>()?.name.lexeme;

      // Allow the replacement widget to use the original widget internally.
      if (enclosingClassName == replacement) {
        return;
      }

      final kind = widgetRestriction != null ? 'widget' : 'class';
      final message = _formatMessage(
        kind: kind,
        name: symbolName,
        replacement: replacement,
        reason: restriction.reason,
      );
      final nameToken = typeNode.name;
      final lintCode = _codeForSeverity(restriction.severity);

      reporter.atToken(
        nameToken,
        lintCode,
        arguments: [message],
      );
    });

    context.registry.addPrefixedIdentifier((node) {
      final prefixElement = node.prefix.element;
      // Only inspect if prefix is an actual class/interface element (not a variable, parameter, or field).
      if (prefixElement is! InterfaceElement) {
        return;
      }

      final className = prefixElement.name;
      if (className == null || _isLowerCamelCase(className)) return;

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

      final message = _formatMessage(
        kind: 'class',
        name: className,
        replacement: replacement,
        reason: restriction.reason,
      );

      reporter.atToken(
        node.prefix.token,
        _codeForSeverity(restriction.severity),
        arguments: [message],
      );
    });

    context.registry.addPropertyAccess((node) {
      final target = node.target;
      if (target is! PrefixedIdentifier) return;

      final targetElem = target.identifier.element;
      if (targetElem is! InterfaceElement) return;

      final className = targetElem.name;
      if (className == null || _isLowerCamelCase(className)) return;

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

      final message = _formatMessage(
        kind: 'class',
        name: className,
        replacement: replacement,
        reason: restriction.reason,
      );

      reporter.atToken(
        target.identifier.token,
        _codeForSeverity(restriction.severity),
        arguments: [message],
      );
    });

    context.registry.addNamedType((node) {
      if (_isConstructorType(node)) {
        // Already covered by instance creation checks.
        return;
      }

      final symbolName = node.name.lexeme;
      if (_isLowerCamelCase(symbolName)) return;

      final widgetRestriction = config.restrictionForWidget(symbolName);
      final classRestriction = config.restrictionForClass(symbolName);
      final restriction = widgetRestriction ?? classRestriction;
      if (restriction == null) return;

      final elem = node.element;
      if (elem is InterfaceElement) {
        if (widgetRestriction != null && !_isFlutterWidget(elem)) {
          return;
        }
      }

      final replacement = restriction.replacement;
      final enclosingClassName =
          node.thisOrAncestorOfType<ClassDeclaration>()?.name.lexeme;
      if (enclosingClassName == replacement) return;

      final kind = widgetRestriction != null ? 'widget' : 'class';
      final message = _formatMessage(
        kind: kind,
        name: symbolName,
        replacement: replacement,
        reason: restriction.reason,
      );

      reporter.atToken(
        node.name,
        _codeForSeverity(restriction.severity),
        arguments: [message],
      );
    });

    context.registry.addMethodInvocation((node) {
      // Top-level function invocation has no target (e.g. print('...'))
      if (node.target != null) return;
      final functionName = node.methodName.name;
      final restriction = config.restrictionForFunction(functionName);
      if (restriction == null) return;

      final message = _formatMessage(
        kind: 'function',
        name: functionName,
        replacement: restriction.replacement,
        reason: restriction.reason,
      );

      reporter.atToken(
        node.methodName.token,
        _codeForSeverity(restriction.severity),
        arguments: [message],
      );
    });
  }

  LintCode _codeForSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'error':
        return _errorCode;
      case 'warning':
        return _warningCode;
      case 'info':
      default:
        return _infoCode;
    }
  }

  bool _isConstructorType(NamedType node) {
    final parent = node.parent;
    return parent is ConstructorName && identical(parent.type, node);
  }

  static String _formatMessage({
    required String kind,
    required String name,
    required String replacement,
    String? reason,
  }) {
    if (reason != null && reason.trim().isNotEmpty) {
      var cleanReason = reason.trim();
      if (cleanReason.endsWith('.')) {
        cleanReason = cleanReason.substring(0, cleanReason.length - 1);
      }
      return 'The $kind "$name" is restricted by team policy: $cleanReason. Use "$replacement" instead. (Quick Fix available)';
    }
    return 'The $kind "$name" is restricted by team policy. Use "$replacement" instead. (Quick Fix available)';
  }

  static bool _isLowerCamelCase(String value) {
    if (value.isEmpty) return false;
    final first = value.codeUnitAt(0);
    return first >= 97 && first <= 122;
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

  static bool _shouldIgnore(String path) {
    if (path.endsWith('.g.dart') ||
        path.endsWith('.freezed.dart') ||
        path.endsWith('.mocks.dart') ||
        path.endsWith('.gen.dart')) {
      return true;
    }
    final normalized = path.replaceAll('\\', '/');
    if (normalized.contains('/.dart_tool/')) {
      return true;
    }
    return false;
  }
}
