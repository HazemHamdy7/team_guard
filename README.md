# Team Guard

A custom lint plugin for Dart and Flutter that helps teams enforce UI rules by blocking specific widgets/classes and suggesting approved replacements.

## Features

- Integrates with `custom_lint` for live IDE feedback.
- Supports configurable restrictions for both widgets and classes.
- Supports `info`, `warning`, and `error` severities per rule.
- Provides quick-fix suggestions with replacement names/imports.

## Prerequisites

- Dart SDK `>=3.3.0 <4.0.0`
- `custom_lint` installed in the target project
- IDE plugin:
  - VS Code: `Custom Lint`
  - Android Studio / IntelliJ: `Custom Lint`

## Installation

Add dependencies to your app's `pubspec.yaml`:

```yaml
dev_dependencies:
  team_guard: ^1.0.6
  custom_lint: ^0.8.1
```

Then run:

```bash
# Flutter project
flutter pub get

# Dart project
dart pub get
```

## Setup (Required)

1. Initialize Team Guard in your project root:

```bash
dart run team_guard:init
```

This command:
- creates `team_guard.yaml` if missing
- creates `analysis_options.yaml` if missing
- adds `custom_lint` plugin under `analyzer.plugins` if missing

2. Run the linter:

```bash
dart run custom_lint
```

3. If your IDE still does not show lints, restart analysis server/IDE.

## Configuration

Create `team_guard.yaml` in your project root:

```yaml
widgets:
  Text:
    replacement: CustomText
    # import: package:your_app/widgets/custom_text.dart
    severity: error

  GestureDetector:
    replacement: AppGestureDetector
    severity: error

classes:
  Colors:
    replacement: AppColors
    # import: package:your_app/theme/app_colors.dart
    severity: error
```

Full setup example: [`example/team_guard_example.dart`](example/team_guard_example.dart)

### Import Field Format

`import` in `team_guard.yaml` must be a package path only.

Correct:

```yaml
import: package:your_app/widgets/custom_text.dart
```

or

```yaml
import: "package:your_app/widgets/custom_text.dart"
```

Wrong:

```yaml
import: "import 'package:your_app/widgets/custom_text.dart';"
```

### Severity Values

- `info`
- `warning`
- `error`

Use `error` if you want violations to appear as red errors in IDE problems.

## Example Violation

If `Text` is restricted:

```dart
Text('Hello');
```

You will get a lint message suggesting `CustomText` instead.

## Troubleshooting

### Lints appear in terminal but not in IDE

1. Confirm `analysis_options.yaml` contains:

```yaml
analyzer:
  plugins:
    - custom_lint
```

2. Install IDE plugin `Custom Lint`.
3. Restart analysis:
   - VS Code: `Dart: Restart Analysis Server`
   - Android Studio/IntelliJ: restart IDE
4. Check Problems filter is not set to errors-only if your rules are `warning`.

### `team_guard.yaml` was not generated

- Run `dart run custom_lint` from the project root.
- If still missing, create `team_guard.yaml` manually using the example above.

## Additional Information

- Package: https://pub.dev/packages/team_guard
- custom_lint docs: https://pub.dev/packages/custom_lint
- Issues and contributions: https://github.com/HazemHamdy7/team_guard
