import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart' show ClassDeclaration;
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
    final root = Directory(resolver.source.fullName).parent.parent.path;

    final config = WidgetGuardConfig.load(root);

    context.registry.addInstanceCreationExpression((node) {
      final typeNode = node.constructorName.type;
      final widgetName = typeNode.name.lexeme;

      final restriction = config.widgets[widgetName];
      if (restriction == null) return;

      final replacement = restriction.replacement;
      final enclosingClassName =
          node.thisOrAncestorOfType<ClassDeclaration>()?.name.lexeme;

      // Allow the replacement widget to use the original widget internally.
      if (enclosingClassName == replacement) {
        return;
      }

      final message =
          '$widgetName is restricted. A custom class is available: $replacement. Use it instead.';
      final nameToken = typeNode.name;
      final lintCode = _codeForSeverity(restriction.severity);

      reporter.atToken(
        nameToken,
        lintCode,
        arguments: [message],
      );
    });

    context.registry.addPrefixedIdentifier((node) {
      final className = node.prefix.name;
      final restriction =
          config.classes[className] ?? config.widgets[className];
      if (restriction == null) return;

      final replacement = restriction.replacement;
      final enclosingClassName =
          node.thisOrAncestorOfType<ClassDeclaration>()?.name.lexeme;
      if (enclosingClassName == replacement) return;

      final message =
          '$className is restricted. A custom class is available: $replacement. Use it instead.';

      reporter.atToken(
        node.prefix.token,
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
}
