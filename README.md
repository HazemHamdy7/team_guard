# Team Guard

A powerful custom lint plugin for Dart and Flutter that helps your team enforce coding standards by preventing the use of forbidden widgets in your projects.

## Features

- ✨ **Custom Lint Integration**: Seamlessly integrates with `custom_lint` to provide real-time feedback in your IDE
- 🚫 **Forbidden Widget Detection**: Easily configure and block the usage of specific widgets
- 🔧 **Flexible Configuration**: Control which widgets are forbidden through YAML configuration
- 📊 **Automatic Code Analysis**: Runs during static analysis and provides clear error messages
- 🎯 **Developer-Friendly**: Clear and actionable lint rule suggestions

## Getting started

### Prerequisites

- Dart SDK >= 3.3.0
- Custom Lint plugin installed

### Installation

Add `team_guard` to your `pubspec.yaml`:

```yaml
dev_dependencies:
  team_guard: ^1.0.0
  custom_lint: ^0.8.1
```

Then run:

```bash
dart pub get
# or for Flutter
flutter pub get
```

## Usage

1. Add `team_guard` to your dev dependencies
2. Configure forbidden widgets in your `pubspec.yaml`:

```yaml
custom_lint:
  rules:
    - forbidden_widget:
        forbidden_widgets:
          - 'GestureDetector'
          - 'Padding'
```

3. The linter will automatically check your code and highlight any usage of forbidden widgets

### Example

If you forbid `GestureDetector`, the following code:

```dart
GestureDetector(
  onTap: () {},
  child: Text('Click me'),
)
```

Will produce a lint error with a helpful message and suggestions for alternatives.

## How it works

Widget Guard uses Dart's analyzer to scan your code and detect instantiations of forbidden widgets. It provides:

- **Error Descriptions**: Clear explanation of why the widget is forbidden
- **Suggestions**: Recommendations for alternative widgets to use
- **Location Info**: Exact file and line number of the offending code

## Additional information

For more information about custom_lint, see the [custom_lint documentation](https://pub.dev/packages/custom_lint).

For issues, feature requests, or contributions, feel free to open an issue on the GitHub repository.

For more information, see: https://pub.dev/packages/team_guard
