import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'src/forbidden_widget_rule.dart';

PluginBase createPlugin() => _WidgetGuardPlugin();

class _WidgetGuardPlugin extends PluginBase {
  @override
  List<DartLintRule> getLintRules(CustomLintConfigs configs) => [
        ForbiddenWidgetRule(),
      ];
}
