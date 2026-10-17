import 'dart:io';

import 'check.dart' as check_cmd;
import 'doctor.dart' as doctor_cmd;
import 'init.dart' as init_cmd;
import 'migrate.dart' as migrate_cmd;
import 'setup.dart' as setup_cmd;

Future<void> main(List<String> args) async {
  if (args.isEmpty ||
      args.first == 'help' ||
      args.first == '--help' ||
      args.first == '-h') {
    _printUsage();
    return;
  }

  final command = args.first;
  final subArgs = args.sublist(1);

  switch (command) {
    case 'check':
      await check_cmd.main(subArgs);
      break;
    case 'migrate':
      await migrate_cmd.main(subArgs);
      break;
    case 'doctor':
      doctor_cmd.main(subArgs);
      break;
    case 'init':
      init_cmd.main(subArgs);
      break;
    case 'setup':
      await setup_cmd.main(subArgs);
      break;
    default:
      stderr.writeln('Unknown command: "$command"\n');
      _printUsage();
      exitCode = 1;
  }
}

void _printUsage() {
  stdout.writeln('''
Team Guard - Guard your Flutter codebase against forbidden widgets.

Usage: dart run team_guard <command> [arguments]

Commands:
  check      Scan project for restricted widgets/classes and print violation table
  migrate    Automatically replace forbidden widgets with approved replacements across project
  doctor     Diagnose and verify configuration, dependencies, and replacements
  init       Initialize team_guard.yaml and configure custom_lint
  setup      Run init and start custom_lint

For command-specific help:
  dart run team_guard <command> --help
''');
}
