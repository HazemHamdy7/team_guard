import 'dart:io';
import 'package:team_guard/src/cli_service.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln('Usage: dart run team_guard:check [directories...]');
    stdout.writeln(
      'Scans Dart files and prints a table of forbidden widget/class violations.',
    );
    return;
  }

  final subdirs = args.where((a) => !a.startsWith('-')).toList();
  final service = TeamGuardCliService.fromDirectory(Directory.current.path);

  if (service == null) {
    stderr.writeln(
      'Error: Could not find project root (pubspec.yaml) from ${Directory.current.path}',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln('Scanning project for restricted widgets & elements...');
  final violations = await service.scanFiles(subdirs.isEmpty ? null : subdirs);

  if (violations.isEmpty) {
    stdout.writeln('\n✓ All clean! No forbidden widgets or elements found.');
    exitCode = 0;
    return;
  }

  stdout.writeln('\n${TeamGuardCliService.formatTable(violations)}');
  stdout.writeln(
    '\nFound ${violations.length} violation(s).'
    '\n💡 Tip: Run "dart run team_guard:migrate" to automatically fix these violations!\n',
  );
  exitCode = 1;
}
