# Team Guard

[![Pub Version](https://img.shields.io/pub/v/team_guard.svg?logo=dart&logoColor=white)](https://pub.dev/packages/team_guard)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Pub Points](https://img.shields.io/pub/points/team_guard)](https://pub.dev/packages/team_guard/score)
[![Popularity](https://img.shields.io/pub/popularity/team_guard)](https://pub.dev/packages/team_guard)

A modern, developer-friendly architecture and UI enforcement plugin for Dart & Flutter. **Team Guard** keeps codebases consistent by restricting forbidden widgets, classes, and functions (e.g. raw `Text`, `Colors`, or `print`), guiding developers toward approved design system replacements with one-click IDE Quick Fixes and automated project-wide migrations.

---

## 🛠️ 1. Setup (One-Step Quickstart)

After installing the package, initialize Team Guard in your project with a single command:

```bash
dart run team_guard:setup
```

### What this command does automatically:
1. **Creates `team_guard.yaml`** at your project root with recommended starter rules (if missing).
2. **Configures `analysis_options.yaml`** to enable the `custom_lint` analyzer plugin.
3. **Scaffolds approved starter templates** in `lib/core` (e.g., `CustomText`, `AppColors`) without overwriting any existing files.
4. **Starts live analysis** in your IDE.

---

### Verify Your Setup Anytime (Team Guard Doctor 🩺)

Run the doctor command to ensure your configuration, dependencies, and replacement symbols are healthy:

```bash
dart run team_guard:doctor
```

**Doctor Output:**
```text
Team Guard Doctor 🩺

[✓] Configuration file (team_guard.yaml)
    Valid configuration with 7 rule(s) (2 widgets, 4 classes, 1 function).

[✓] Analysis options (analysis_options.yaml)
    custom_lint plugin is enabled in analysis_options.yaml.

[✓] Project dependencies (pubspec.yaml)
    team_guard and custom_lint dependencies found.

[✓] Approved replacements verification
    All configured replacement classes exist in lib/ or specify explicit imports.

✓ Everything looks great! Team Guard is ready to protect your project.
```

*(Optional Manual Setup: If you prefer manual configuration, simply add `custom_lint` to `analysis_options.yaml` under `analyzer: plugins: [custom_lint]` and create your `team_guard.yaml` file in the project root).*

---

## 📦 2. Installation

Add `team_guard` to the `dev_dependencies` of your project:

```bash
# In Flutter projects:
flutter pub add dev:team_guard

# In standalone Dart CLI projects:
dart pub add dev:team_guard
```

Or manually add it to your `pubspec.yaml`:

```yaml
dev_dependencies:
  team_guard: ^1.0.19
```

Then fetch your packages:

```bash
flutter pub get
```

> **Note:** Required IDE extensions for live highlights:
> - **VS Code:** Install the [`Custom Lint`](https://marketplace.visualstudio.com/items?itemName=invertase.custom-lint) extension.
> - **Android Studio / IntelliJ:** Install the `Custom Lint` plugin.

---

## 🚀 3. Features

### 📊 Feature 1: Instant Codebase Audit (`dart run team_guard:check`)
Scan your entire codebase from the terminal to see a clean, formatted ASCII table of all restricted elements, exact file locations, and suggested replacements:

```bash
dart run team_guard:check
# or shorthand: dart run team_guard check
```

**Audit Table Output:**
```text
Scanning project for restricted widgets & elements...

┌──────────────────────────────────────┬──────┬──────────────┬──────────────────┬──────────┐
│ File                                 │ Line │ Restricted   │ Replacement      │ Severity │
├──────────────────────────────────────┼──────┼──────────────┼──────────────────┼──────────┤
│ lib/features/home/presentation.dart  │ 24   │ Text         │ CustomText       │ ERROR    │
│ lib/features/home/presentation.dart  │ 48   │ Colors       │ AppColors        │ ERROR    │
│ lib/core/network/api_client.dart     │ 15   │ print        │ debugPrint       │ WARNING  │
└──────────────────────────────────────┴──────┴──────────────┴──────────────────┴──────────┘

Found 3 violation(s).
💡 Tip: Run "dart run team_guard:migrate" to automatically fix these violations!
```
*(Exits with code `0` if clean, or `1` if violations are found — perfect for CI/CD pipelines).*

---

### 🔄 Feature 2: Bulk Codebase Migration (`dart run team_guard:migrate`)
Have a large existing codebase with hundreds of legacy widgets? Migrate them all automatically across all files with a single command:

```bash
# 1. Preview changes first without modifying files:
dart run team_guard:migrate --dry-run

# 2. Apply all replacements across your codebase:
dart run team_guard:migrate
```

**Migration Output:**
```text
Running Team Guard automated migration...

  [Migrated] Updated: lib/features/home/presentation.dart
  [Migrated] Updated: lib/features/profile/view.dart
  [Migrated] Updated: lib/core/network/api_client.dart

✓ Migration complete! 3 file(s) updated with 12 edits.
Tip: Run "dart format ." to format updated files.
```

---

### 💡 Feature 3: One-Click Quick Fix & Batch "Fix all in file"
When writing code in your IDE (VS Code, Android Studio, IntelliJ):
- **Single Fix**: Press `Cmd + .` (macOS) or `Alt + Enter` (Windows/Linux) and select **`Use CustomText`**.
- **Batch Fix ("Fix all in file")**: Select **`Fix all forbidden widgets in this file`** to replace every forbidden widget in the open file at once!
- **Zero Syntax Errors**: Automatically adds missing imports, prevents duplicate imports, and preserves all arguments, formatting, and child trees.

---

### 💬 Feature 4: Custom Policy Explanations (`reason`)
Add an optional `reason` to any rule in `team_guard.yaml`. The explanation appears directly in the IDE problem tooltip so every developer understands **why** a restriction exists:

> *The widget "Text" is restricted by team policy: Always use CustomText to enforce typography scale and localization. Use "CustomText" instead. (Quick Fix available)*

---

### 🚫 Feature 5: Function Restrictions (`print` ➔ `debugPrint`)
Restrict top-level functions such as `print` to prevent accidental data leaks in production:
- Flags `print(...)` with configurable severity (`warning` or `error`).
- Offers an automated Quick Fix replacing `print` with `debugPrint` (or your custom logging utility) and automatically imports `package:flutter/foundation.dart`.

---

### 🎯 Feature 6: 100% PDF & Third-Party Library Compatibility
Unlike naive text linters, Team Guard performs **semantic Dart analyzer resolution**:
- **PDF Compatibility**: Libraries like `package:pdf/widgets.dart` (`pw.Text`, `pw.Paragraph`, etc.) are recognized as non-Flutter canvas types and are **never** flagged.
- **No False Positives**: Variables (`final String text = '...'`), parameters (`void format(String text)`), properties (`text.length`), methods (`doc.extractText()`), and comments containing the word "text" are safely ignored.

---

### ⚡ Feature 7: Class Prefixes, Aliases & Static Access
Guards classes across constructor calls, type annotations, and static member accesses:
- Flags both `Colors.red` and aliased imports like `fl.Colors.red`.
- Enforces approved network clients (`Dio` ➔ `AppDio`), dependency injection (`GetIt` ➔ `AppLocator`), and state managers (`Cubit` ➔ `AppCubit`).

---

### 🛡️ Feature 8: Automated Generated File Exclusion
Files generated by tools like build_runner (`.g.dart`, `.freezed.dart`, `.mocks.dart`, `.gen.dart`, and `.dart_tool`) are skipped automatically to eliminate unnecessary noise.

---

## ⚙️ 4. Configuration Guide (`team_guard.yaml`)

Edit the generated `team_guard.yaml` file in your project root to customize your team's rules:

```yaml
# 1. Flutter Widgets
widgets:
  Text:
    replacement: CustomText
    # Optional explicit import path. If omitted, auto-detected from lib/
    # import: package:my_app/core/ui/custom_text.dart
    severity: error
    reason: Always use CustomText to enforce typography scale and localization.

  ElevatedButton:
    replacement: AppElevatedButton
    severity: error
    reason: Use AppElevatedButton for consistent design system interaction states.

# 2. Classes & Utilities
classes:
  Colors:
    replacement: AppColors
    severity: error
    reason: Use AppColors to support dark mode and dynamic theme tokens.

  Dio:
    replacement: AppDio
    severity: error
    reason: Use AppDio to ensure authentication interceptors and retry policies.

  GetIt:
    replacement: AppLocator
    severity: error

  Cubit:
    replacement: AppCubit
    severity: error

# 3. Top-Level Functions
functions:
  print:
    replacement: debugPrint
    # import: package:flutter/foundation.dart
    severity: warning
    reason: Avoid leaking sensitive logs to production stdout.
```

### Rule Properties Reference

| Property | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `replacement` | `String` | **(Required)** | The approved replacement symbol (e.g. `CustomText`, `AppColors`). |
| `import` | `String` | *(Optional)* | Package URI path (e.g. `package:my_app/core/custom_text.dart`). Auto-detected from `lib/` if omitted. |
| `severity` | `String` | `error` | Diagnostic level: `error` (blocks builds / red squiggles) or `warning` (yellow squiggles). |
| `reason` | `String` | *(Optional)* | Custom message displayed in the IDE diagnostic to explain why the item is restricted. |

---

## 💻 5. CLI Commands Reference

All commands can be invoked using the namespace (`team_guard:<cmd>`) or the unified router (`team_guard <cmd>`):

| Command | Shorthand | Description |
| :--- | :--- | :--- |
| `dart run team_guard:setup` | `dart run team_guard setup` | One-step project setup (generates config, enables plugin, scaffolds starter files). |
| `dart run team_guard:doctor` | `dart run team_guard doctor` | Diagnoses and checks setup health, YAML syntax, and replacement symbols. |
| `dart run team_guard:check` | `dart run team_guard check` | Scans project files and outputs a formatted ASCII violation table. |
| `dart run team_guard:migrate` | `dart run team_guard migrate` | Automatically migrates all files across the project to approved replacements. |
| `dart run team_guard:migrate --dry-run` | `dart run team_guard migrate -n` | Previews files that would be modified without writing changes to disk. |
| `dart run team_guard:init` | `dart run team_guard init` | Generates default `team_guard.yaml` and configures `analysis_options.yaml`. |

---

## 🔍 6. Troubleshooting

### Lints do not appear in the IDE?
1. **Check `analysis_options.yaml`**: Confirm it contains:
   ```yaml
   analyzer:
     plugins:
       - custom_lint
   ```
2. **Ensure IDE plugin is installed**:
   - VS Code: Search and install `Custom Lint`.
   - Android Studio / IntelliJ: Search and install `Custom Lint`.
3. **Restart the Analysis Server**:
   - **VS Code**: Press `Cmd + Shift + P` (or `Ctrl + Shift + P`) ➔ type `Dart: Restart Analysis Server`.
   - **Android Studio / IntelliJ**: Go to `File` ➔ `Repair IDE` or restart the editor.
4. **Run Doctor**:
   ```bash
   dart run team_guard:doctor
   ```
   Follow any suggestions printed by the doctor.

---

## 📄 License & Links

- **Package on Pub:** [pub.dev/packages/team_guard](https://pub.dev/packages/team_guard)
- **Source Code & Issues:** [github.com/HazemHamdy7/team_guard](https://github.com/HazemHamdy7/team_guard)
- **Engine:** Built with [custom_lint](https://pub.dev/packages/custom_lint)
