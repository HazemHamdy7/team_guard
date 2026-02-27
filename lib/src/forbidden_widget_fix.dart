import 'dart:io';
import 'package:analyzer/dart/ast/ast.dart' show ClassDeclaration;
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'config_loader.dart';

class ForbiddenWidgetFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Object analysisError,
    List<Object> others,
  ) {
    final root = Directory(resolver.source.fullName).parent.parent.path;

    final config = WidgetGuardConfig.load(root);
    final diagnostic = analysisError as dynamic;

    context.registry.addInstanceCreationExpression((node) {
      final typeNode = node.constructorName.type;
      final nameToken = typeNode.name;
      final widgetName = nameToken.lexeme;

      final restriction = config.widgets[widgetName];
      if (restriction == null) return;

      final matchesCurrentError = diagnostic.offset == nameToken.offset &&
          diagnostic.length == nameToken.length;
      if (!matchesCurrentError) return;

      final replacement = restriction.replacement;
      final importPath = restriction.import;
      final enclosingClassName =
          node.thisOrAncestorOfType<ClassDeclaration>()?.name.lexeme;

      if (enclosingClassName == replacement) {
        return;
      }

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
      final className = node.prefix.name;
      final restriction =
          config.classes[className] ?? config.widgets[className];
      if (restriction == null) return;

      final nameToken = node.prefix.token;
      final matchesCurrentError = diagnostic.offset == nameToken.offset &&
          diagnostic.length == nameToken.length;
      if (!matchesCurrentError) return;

      final replacement = restriction.replacement;
      final importPath = restriction.import;
      final enclosingClassName =
          node.thisOrAncestorOfType<ClassDeclaration>()?.name.lexeme;
      if (enclosingClassName == replacement) return;

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
  }
}
