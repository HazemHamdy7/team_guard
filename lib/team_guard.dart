// ignore_for_file: unnecessary_library_name

/// Team Guard custom_lint plugin entrypoint.
library team_guard;

import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'src/forbidden_widget_rule.dart';

/// Creates the Team Guard lint plugin instance for `custom_lint`.
PluginBase createPlugin() => _WidgetGuardPlugin();

class _WidgetGuardPlugin extends PluginBase {
  @override
  List<DartLintRule> getLintRules(CustomLintConfigs configs) => [
        ForbiddenWidgetRule(),
      ];
}
