## 1.0.18

- **Fast Inspection CLI (`dart run team_guard:check`)**: Instantly audit the entire codebase and print a formatted ASCII table of forbidden elements, lines, approved replacements, and severity levels.
- **Bulk Automated Migration CLI (`dart run team_guard:migrate`)**: Automatically replace forbidden widgets with approved replacements across all files with automatic import addition and `--dry-run` preview support.
- **Setup Diagnostics CLI (`dart run team_guard:doctor`)**: Health check tool that validates `team_guard.yaml` syntax, `analysis_options.yaml` plugins, dependencies, and verifies that replacement classes exist.
- **Batch Quick Fix in IDE ("Fix all in file")**: One-click quick fix option in IDE to fix all forbidden widgets in the current file simultaneously.
- **Custom Policy Reasons**: Support `reason` property in `team_guard.yaml` to explain why a widget, class, or function is restricted directly in IDE problem messages.
- **Function Restrictions (`print` -> `debugPrint`)**: Support restricting top-level functions such as `print` with `warning` severity and automated Quick Fix to `debugPrint`.
- **Fix Bug A (False-positive `text` detection)**: Prevent false-positive detections on lowercase variables, parameters, fields, methods, comments, and strings named `text` by enforcing AST element resolution and case-sensitive identifier checks.
- **Fix Bug B (PDF package compatibility)**: Full compatibility with PDF-generation packages (e.g. `package:pdf/widgets.dart`) by verifying that guarded UI widgets resolve to genuine Flutter framework widgets (`package:flutter`).
- **Enhanced Quick Fix**: Reliably replace restricted widgets and add approved replacement imports in a single action, prevent duplicate imports when the import already exists, and preserve all widget arguments and children.
- **Prefix & Aliased Access**: Accurately detect prefixed accesses such as `fl.Colors.red` and replace aliased widgets cleanly.
- **Safe Generated File Handling**: Automatically skip analysis on generated files (`.g.dart`, `.freezed.dart`, `.mocks.dart`, `.gen.dart`, and `.dart_tool`).
- **Guard Configuration Validation**: Gracefully handle missing or malformed `team_guard.yaml` files and report clear, actionable diagnostics for invalid entries or severity settings.
- **Unified CLI Router (`dart run team_guard <command>`)**: Run `check`, `migrate`, `doctor`, `init`, and `setup` through standard subcommands.
- **Comprehensive Test Suite**: 34 automated regression, unit, and integration tests ensuring 100% test pass rate.

## 1.0.17

- Simplify README setup instructions to use `dart run team_guard:setup` as the primary command instead of documenting separate init/lint commands.

## 1.0.16

- Update `team_guard:init` scaffolding to skip generating replacement files when a file with the same name already exists anywhere under `lib/`.
- Avoid creating `lib/core` unless at least one new replacement file actually needs to be generated.
- Refresh README to document the new duplicate-skip behavior and latest install version.

## 1.0.15

- Change generated Flutter color-class templates to use `static const Color ... = Color(...)` fields directly.
- Update README examples to match the generated `AppColors` shape and latest install version.

## 1.0.14

- Update default generated `team_guard.yaml` template to include:
  - `widgets`: `Text`, `ElevatedButton`
  - `classes`: `Colors`, `Dio`, `GetIt`, `Cubit`
- Improve generated color helper template to keep internal tokens flexible (`int` or `Color`) while exposing `Color` getters for direct Flutter widget usage.
- Refresh README to document the updated color pattern and latest install version.

## 1.0.13

- Publish follow-up release with the latest lint/fix and scaffolding updates from `1.0.12`.

## 1.0.12

- Enforce class restrictions in type references (`NamedType`) such as:
  - `extends Cubit<MyState>`
  - `implements Cubit<MyState>`
  - type annotations and generic arguments using restricted classes
- Keep constructor checks/fixes and avoid duplicate diagnostics for `InstanceCreationExpression`.
- Add tolerant class-name matching in config (`GetIt`, `get_it`, `getit` are treated equivalently).
- Update README with examples for restricting classes like `Dio`, `GetIt`, and `Cubit`.
- Add a minimal policy example (`Text`, `ElevatedButton`, `Colors`, `Dio`) and clarify mixed `int`/`Color` usage in color templates.

## 1.0.11

- Enforce class restrictions in constructor usage as well as prefixed access.
- Apply the same symbol lookup in quick-fix for both `widgets` and `classes`.
- Improve `team_guard:init` scaffolding in Flutter projects:
  - generate richer starter templates for text-like replacement widgets
  - generate color palette starter templates for color-like helper classes
- Update README with regeneration behavior (existing files are not overwritten) and starter template examples.

## 1.0.10

- Add `dart run team_guard:setup` command to run `team_guard:init` then `custom_lint` in one step.
- Update README setup flow to prefer single-command setup while keeping manual steps documented.

## 1.0.9

- Add `custom_lint` to runtime dependencies so `dart run custom_lint` is available after installing `team_guard`.
- Improve quick-fix import behavior:
  - accept `import` values in both package-path form and full Dart import statement form
  - auto-detect replacement imports from `lib/` when a replacement class is found in exactly one file
- Enhance `dart run team_guard:init`:
  - scaffold missing replacement files in `lib/core` from `team_guard.yaml`
  - keep init idempotent by skipping files that already exist
- Refresh README for setup, auto-import, and init scaffolding flow.

## 1.0.8

- Lower minimum Dart SDK constraint to `>=3.0.0 <4.0.0`.
- Update README:
  - document that `team_guard.yaml` is generated automatically by `dart run team_guard:init`
  - remove `info` from supported severity values (`warning`, `error` only)
  - refresh install snippet to `team_guard: ^1.0.8`

## 1.0.7

- Add uninstall command to README:
  - `flutter pub remove team_guard custom_lint`

## 1.0.6

- Update docs and examples to use `severity: error` by default.
- Update generated default `team_guard.yaml` template to use `severity: error`.

## 1.0.5

- Improve pub score compliance:
  - Add Dartdoc for public API entrypoints.
  - Shorten package description in `pubspec.yaml`.
  - Replace deprecated analyzer API usage in lint/fix implementation.
- Broaden analyzer compatibility constraint to `>=8.4.0 <12.0.0`.

## 1.0.4

- Add `dart run team_guard:init` command to generate `team_guard.yaml` directly.
- Auto-configure `analysis_options.yaml` to include `analyzer.plugins: [custom_lint]` when missing.
- Refresh README setup flow and add an updated full example in `example/team_guard_example.dart`.

## 1.0.3

- Clarify `import` field format in docs/config template: use package path only (not a Dart `import '...';` statement).

## 1.0.2

- Rewrite README with complete setup steps, correct team_guard.yaml configuration, and troubleshooting for IDE visibility/generation.

## 1.0.1

- Update README with explicit custom lint run command (dart run custom_lint).

## 1.0.0

- Initial version.



