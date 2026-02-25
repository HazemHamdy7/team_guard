// Example configuration for Team Guard
// 
// This example shows how to configure Widget Guard in your project's pubspec.yaml
// to prevent the use of certain widgets.

// In your pubspec.yaml, add the following configuration:
//
// dev_dependencies:
//   team_guard: ^1.0.0
//   custom_lint: ^0.8.1
//
// custom_lint:
//   rules:
//     - forbidden_widget:
//         forbidden_widgets:
//           - name: GestureDetector
//             replacement: MyCustomGestureDetector
//             severity: error
//           - name: Padding
//             replacement: MyCustomPadding
//             severity: warning

// Example: If you forbidden GestureDetector, this code will trigger an error:
// 
// ❌ FORBIDDEN:
// Widget buildButton() {
//   return GestureDetector(
//     onTap: () => print('Tapped'),
//     child: Text('Click me'),
//   );
// }
//
// ✅ ALLOWED (Using replacement):
// Widget buildButton() {
//   return MyCustomGestureDetector(
//     onTap: () => print('Tapped'),
//     child: Text('Click me'),
//   );
// }

// For more information, see: https://pub.dev/packages/team_guard
