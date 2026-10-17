// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:team_guard/src/forbidden_widget_fix.dart';
import 'package:team_guard/src/forbidden_widget_rule.dart';

class TestProject {
  final Directory rootDir;

  TestProject(this.rootDir);

  static TestProject create({
    String? teamGuardYaml,
    String? pubspecYaml,
  }) {
    final tempDir = Directory.systemTemp.createTempSync('team_guard_test_');

    final pubspec = pubspecYaml ??
        '''
name: sample_app
environment:
  sdk: ">=3.0.0 <4.0.0"
''';
    File('${tempDir.path}/pubspec.yaml').writeAsStringSync(pubspec);

    final guardConfig = teamGuardYaml ??
        '''
widgets:
  Text:
    replacement: CustomText
    import: package:sample_app/core/custom_text.dart
    severity: error

  ElevatedButton:
    replacement: AppElevatedButton
    import: package:sample_app/core/app_elevated_button.dart
    severity: error

classes:
  Colors:
    replacement: AppColors
    import: package:sample_app/core/app_colors.dart
    severity: error

  Dio:
    replacement: AppDio
    import: package:sample_app/core/app_dio.dart
    severity: error
''';
    File('${tempDir.path}/team_guard.yaml').writeAsStringSync(guardConfig);

    // Create mock packages
    final flutterDir = Directory('${tempDir.path}/mock_packages/flutter/lib')
      ..createSync(recursive: true);
    final pdfDir = Directory('${tempDir.path}/mock_packages/pdf/lib')
      ..createSync(recursive: true);
    final otherDir = Directory('${tempDir.path}/mock_packages/other/lib')
      ..createSync(recursive: true);

    File('${flutterDir.path}/widgets.dart').writeAsStringSync('''
abstract class Widget {
  const Widget();
}

abstract class StatelessWidget extends Widget {
  const StatelessWidget({dynamic key});
}

abstract class StatefulWidget extends Widget {
  const StatefulWidget({dynamic key});
}

class Text extends StatelessWidget {
  const Text(String data, {dynamic key, dynamic style});
}

class GestureDetector extends StatelessWidget {
  const GestureDetector({dynamic key, dynamic child, dynamic onTap});
}
''');

    File('${flutterDir.path}/material.dart').writeAsStringSync('''
export 'widgets.dart';

class ButtonStyleButton extends StatelessWidget {
  const ButtonStyleButton({dynamic key, dynamic child, dynamic onPressed});
}

class ElevatedButton extends ButtonStyleButton {
  const ElevatedButton({dynamic key, dynamic child, dynamic onPressed});
}

class Color {
  final int value;
  const Color(this.value);
}

class Colors {
  const Colors._();
  static const Color red = Color(0xFFFF0000);
  static const Color blue = Color(0xFF0000FF);
}
''');

    File('${pdfDir.path}/widgets.dart').writeAsStringSync('''
abstract class PdfWidget {}

class Text extends PdfWidget {
  Text(String text, {dynamic style});
}

class Paragraph extends PdfWidget {
  Paragraph({String? text});
}

class Document {
  void addPage(dynamic page) {}
}

class PdfColor {
  final int value;
  const PdfColor(this.value);
}

class PdfColors {
  static const PdfColor red = PdfColor(0xFFFF0000);
}
''');

    File('${otherDir.path}/other.dart').writeAsStringSync('''
class Text {
  final String content;
  Text(this.content);
}

class Unrelated {
  String extractText() => 'extracted';
}
''');

    final dartTool = Directory('${tempDir.path}/.dart_tool')..createSync();
    File('${dartTool.path}/package_config.json').writeAsStringSync('''{
  "configVersion": 2,
  "packages": [
    {
      "name": "sample_app",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "3.0"
    },
    {
      "name": "flutter",
      "rootUri": "../mock_packages/flutter",
      "packageUri": "lib/",
      "languageVersion": "3.0"
    },
    {
      "name": "pdf",
      "rootUri": "../mock_packages/pdf",
      "packageUri": "lib/",
      "languageVersion": "3.0"
    },
    {
      "name": "other",
      "rootUri": "../mock_packages/other",
      "packageUri": "lib/",
      "languageVersion": "3.0"
    }
  ]
}''');

    return TestProject(tempDir);
  }

  File writeSource(String relativePath, String content) {
    final file = File('${rootDir.path}/$relativePath');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
    return file;
  }

  Future<List<AnalysisError>> runRuleOn(String relativePath) async {
    final file = File('${rootDir.path}/$relativePath');
    final result = await resolveFile(path: file.path);
    result as ResolvedUnitResult;
    final rule = ForbiddenWidgetRule();
    return rule.testRun(result);
  }

  Future<List<PrioritizedSourceChange>> runFixOn(
    String relativePath,
    AnalysisError error, [
    List<AnalysisError>? others,
  ]) async {
    final file = File('${rootDir.path}/$relativePath');
    final result = await resolveFile(path: file.path);
    result as ResolvedUnitResult;
    final fix = ForbiddenWidgetFix();
    return fix.testRun(result, error, others ?? [error]);
  }

  void dispose() {
    try {
      rootDir.deleteSync(recursive: true);
    } catch (_) {}
  }
}
