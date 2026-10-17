import 'dart:io';
import 'package:team_guard/src/cli_service.dart';

void main(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln('Usage: dart run team_guard:doctor');
    stdout.writeln(
      'Verifies Team Guard configuration, dependencies, and replacement files.',
    );
    return;
  }

  final service = TeamGuardCliService.fromDirectory(Directory.current.path);
  if (service == null) {
    stderr.writeln(
      'Error: Could not find project root (pubspec.yaml) from ${Directory.current.path}',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln('Team Guard Doctor 🩺\n');
  final report = service.runDoctor();

  for (final item in report.items) {
    final symbol = item.isSuccess ? '✓' : '✗';
    stdout.writeln('[$symbol] ${item.title}');
    stdout.writeln('    ${item.message}');
    if (!item.isSuccess && item.suggestion != null) {
      stdout.writeln('    👉 ${item.suggestion}');
    }
    stdout.writeln();
  }

  if (report.allPassed) {
    stdout.writeln(
      '✓ Everything looks great! Team Guard is ready to protect your project.',
    );
    exitCode = 0;
  } else {
    stdout.writeln('! Some checks need attention. See suggestions above.');
    exitCode = 1;
  }
}
