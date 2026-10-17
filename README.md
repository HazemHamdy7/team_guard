# Team Guard

A custom lint and architecture enforcement plugin for Dart & Flutter that protects codebases against forbidden widgets, classes, and functions — keeping codebases clean, consistent, and scalable.

---

## ⚡ First Step After Installation: Scan Your Codebase

Right after adding `team_guard`, audit your entire codebase with one command to instantly see where forbidden widgets are used and what approved replacements should be used:

```bash
dart run team_guard:check
# or: dart run team_guard check
```

**Output:**

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

---

## 🚀 Key Features

- **Instant Audit Table (`dart run team_guard:check`)**: Terminal inspection table listing file, line, restricted element, approved replacement, and severity.
- **Bulk Automated Migration (`dart run team_guard:migrate`)**: One command fixes all violations across your entire project, adds required imports, and preserves all arguments (with `--dry-run` preview support).
- **Setup Diagnostics (`dart run team_guard:doctor`)**: Diagnoses and verifies your `team_guard.yaml`, dependencies, `analysis_options.yaml`, and replacement symbols.
- **One-Click Quick Fix in IDE**: Replaces forbidden widgets, adds approved imports automatically, prevents duplicate imports, and preserves multiline arguments and child trees.
- **"Fix all in file" Batch Quick Fix**: Fix every forbidden widget in the open file in a single click from your IDE.
- **Custom Policy Reasons**: Define a custom `reason` for each restriction so team members immediately understand *why* a widget or function is restricted.
- **Function & Method Restrictions**: Restrict functions such as `print` in favor of `debugPrint` or your logger with `warning` or `error` severity.
- **Accurate Widget Detection**: Semantic analysis ensures genuine Flutter widgets are targeted — ordinary variables (e.g. `final String text`), properties (`text.length`), methods (`extractText()`), and comments are never falsely flagged.
- **PDF Generation Compatible**: Works seamlessly alongside PDF libraries (`package:pdf/widgets.dart`) without confusing PDF canvas text with Flutter UI widgets.
- **Prefix & Aliased Access**: Enforces policies even when classes are accessed via prefixes (e.g. `Colors.red` or `fl.Colors.red`).
- **Generated File Skipping**: Automatically ignores `.g.dart`, `.freezed.dart`, `.mocks.dart`, `.gen.dart`, and `.dart_tool`.

---

## 📦 Installation

Add `team_guard` to your `pubspec.yaml`:

```yaml
dev_dependencies:
  team_guard: ^1.0.18
```

Then fetch packages:

```bash
flutter pub get
# or: dart pub get
```

---

## 🛠️ Setup (One Command)

Initialize Team Guard in your project:

```bash
dart run team_guard:setup
```

This command automatically:
1. Generates `team_guard.yaml` in your project root (if missing).
2. Configures `analysis_options.yaml` with the `custom_lint` plugin.
3. Scaffolds approved starter replacement files in `lib/core` (never overwrites existing files).
4. Starts live analysis.

Verify your setup anytime with **Team Guard Doctor**:

```bash
dart run team_guard:doctor
```

```text
Team Guard Doctor 🩺

[✓] Configuration file (team_guard.yaml)
    Valid configuration with 7 rule(s) (2 widgets, 4 classes, 1 functions).

[✓] Analysis options (analysis_options.yaml)
    custom_lint plugin is enabled in analysis_options.yaml.

[✓] Project dependencies (pubspec.yaml)
    team_guard and custom_lint dependencies found.

[✓] Approved replacements verification
    All configured replacement classes exist in lib/ or specify explicit imports.

✓ Everything looks great! Team Guard is ready to protect your project.
```

---

## ⚙️ Configuration (`team_guard.yaml`)

Define your team's forbidden widgets, classes, and functions:

```yaml
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
    reason: Use AppElevatedButton for consistent design system states.

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

functions:
  print:
    replacement: debugPrint
    # import: package:flutter/foundation.dart
    severity: warning
    reason: Avoid leaking sensitive logs to production stdout.
```

### Configuration Options

| Key | Type | Description |
| :--- | :--- | :--- |
| `replacement` | `String` | **(Required)** Approved replacement symbol. |
| `import` | `String` | *(Optional)* Package import path (e.g. `package:my_app/core/custom_text.dart`). Auto-detected from `lib/` if omitted. |
| `severity` | `String` | `error` (default) or `warning`. |
| `reason` | `String` | *(Optional)* Explanation displayed in the diagnostic message. |

---

## 🔄 Automated Bulk Migration (`dart run team_guard:migrate`)

Got an existing codebase with hundreds of `Text` or `print` violations? Migrate them all automatically:

```bash
# Preview what would be updated without writing to disk:
dart run team_guard:migrate --dry-run

# Apply all replacements across your project:
dart run team_guard:migrate
```

**Output:**

```text
Running Team Guard automated migration...

  [Migrated] Updated: lib/features/home/presentation.dart
  [Migrated] Updated: lib/features/profile/view.dart
  [Migrated] Updated: lib/core/network/api_client.dart

✓ Migration complete! 3 file(s) updated with 12 edits.
Tip: Run "dart format ." to format updated files.
```

---

## 💡 IDE Experience & Quick Fixes

When writing code in VS Code or Android Studio / IntelliJ:

1. **Live Highlights**: Violations appear with clear problem messages including the policy reason:
   > *The widget "Text" is restricted by team policy: Always use CustomText to enforce typography scale and localization. Use "CustomText" instead. (Quick Fix available)*
2. **Single Quick Fix**: Press `Cmd + .` (macOS) or `Alt + Enter` (Windows/Linux) and select **Use CustomText**.
3. **Batch Quick Fix**: Select **Fix all forbidden widgets in this file** to update every forbidden widget in the current file in one click.

---

## 🧰 CLI Commands Reference

| Command | Description |
| :--- | :--- |
| `dart run team_guard:check` | Scan files and print formatted ASCII violation table (first post-install step). |
| `dart run team_guard:migrate` | Bulk migrate all violations to approved replacements across the codebase. |
| `dart run team_guard:migrate --dry-run` | Preview files that would be modified without touching disk. |
| `dart run team_guard:doctor` | Validate setup, configuration syntax, dependencies, and replacement files. |
| `dart run team_guard:init` | Create `team_guard.yaml` and configure `analysis_options.yaml`. |
| `dart run team_guard:setup` | Run init and launch `custom_lint`. |

*(Note: You can also use the shorthand router `dart run team_guard check`, `dart run team_guard migrate`, etc.)*

---

## 🔍 Troubleshooting

### Lints do not appear in IDE
1. Verify `analysis_options.yaml` contains:
   ```yaml
   analyzer:
     plugins:
       - custom_lint
   ```
2. Verify you have the **Custom Lint** extension installed in VS Code or IntelliJ / Android Studio.
3. Restart analysis server:
   - VS Code: `Command Palette` -> `Dart: Restart Analysis Server`.
   - Android Studio / IntelliJ: `File` -> `Repair IDE` or restart.
4. Run `dart run team_guard:doctor` to pinpoint the exact issue.

---

## 📄 License & Links

- Pub Package: [pub.dev/packages/team_guard](https://pub.dev/packages/team_guard)
- Repository: [github.com/HazemHamdy7/team_guard](https://github.com/HazemHamdy7/team_guard)
