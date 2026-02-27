/// Team Guard setup example.
///
/// 1) Add dependencies:
///
/// ```yaml
/// dev_dependencies:
///   team_guard: ^1.0.3
///   custom_lint: ^0.8.1
/// ```
///
/// 2) Install packages:
///
/// ```bash
/// flutter pub get
/// # or
/// dart pub get
/// ```
///
/// 3) Initialize Team Guard:
///
/// ```bash
/// dart run team_guard:init
/// ```
///
/// 4) Example `team_guard.yaml`:
///
/// ```yaml
/// widgets:
///   Text:
///     replacement: CustomText
///     import: package:your_app/widgets/custom_text.dart
///     severity: error
///
///   GestureDetector:
///     replacement: AppGestureDetector
///     severity: error
///
/// classes:
///   Colors:
///     replacement: AppColors
///     import: package:your_app/theme/app_colors.dart
///     severity: error
/// ```
///
/// 5) Run lint:
///
/// ```bash
/// dart run custom_lint
/// ```
///
/// Notes:
/// - In `team_guard.yaml`, `import` value is a package path only.
/// - Do not write: `import 'package:...';`
void main() {}
