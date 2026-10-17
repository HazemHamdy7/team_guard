import 'dart:io';
import 'package:team_guard/src/cli_service.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(
      'Usage: dart run team_guard:migrate [--dry-run] [directories...]',
    );
    stdout.writeln(
      'Automatically replaces forbidden widgets with approved widgets across the project.',
    );
    return;
  }

  final dryRun = args.contains('--dry-run') || args.contains('-n');
  final subdirs = args.where((a) => !a.startsWith('-')).toList();
  final service = TeamGuardCliService.fromDirectory(Directory.current.path);

  if (service == null) {
    stderr.writeln(
      'Error: Could not find project root (pubspec.yaml) from ${Directory.current.path}',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln(
    dryRun
        ? 'Running Team Guard migration preview (--dry-run)...'
        : 'Running Team Guard automated migration...',
  );

  final result = await service.migrateFiles(
    dryRun: dryRun,
    subdirs: subdirs.isEmpty ? null : subdirs,
  );

  if (result.filesChanged == 0) {
    stdout.writeln(
      'No forbidden widgets found. Everything is already up to date!',
    );
    exitCode = 0;
    return;
  }

  stdout.writeln();
  for (final file in result.modifiedFiles) {
    stdout.writeln(
      dryRun
          ? '  [Preview] Would update: $file'
          : '  [Migrated] Updated: $file',
    );
  }

  stdout.writeln();
  if (dryRun) {
    stdout.writeln(
      'Dry run complete: ${result.filesChanged} file(s) would be updated (${result.totalEdits} edits).'
      '\nRun without --dry-run to apply changes.',
    );
  } else {
    stdout.writeln(
      '✓ Migration complete! ${result.filesChanged} file(s) updated with ${result.totalEdits} edits.'
      '\nTip: Run "dart format ." to format updated files.',
    );
  }
  exitCode = 0;
}
