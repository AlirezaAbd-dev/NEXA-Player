import 'dart:io';

/// Automated Version Bump & Release Utility for NEXA Player.
void main(List<String> args) {
  if (args.isEmpty) {
    _printUsage();
    exit(0);
  }

  final command = args[0].toLowerCase();
  switch (command) {
    case 'status':
      _showStatus();
      break;
    case 'bump':
      final type = args.length > 1 ? args[1].toLowerCase() : 'patch';
      _bumpVersion(type);
      break;
    case 'changelog':
      _generateChangelog();
      break;
    default:
      stdout.writeln('Unknown command: $command');
      _printUsage();
      exit(1);
  }
}

void _printUsage() {
  stdout.writeln('''
NEXA Player Release Manager
Usage: dart run tool/release_manager.dart <command>

Commands:
  status               Show current version, build number, and staged artifacts
  bump [major|minor|patch]   Increment semantic version in pubspec.yaml and bump build number
  changelog            Generate and prepend recent commits to CHANGELOG.md
''');
}

void _showStatus() {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    stderr.writeln('Error: pubspec.yaml not found in current directory.');
    exit(1);
  }

  final lines = pubspecFile.readAsLinesSync();
  final versionLine = lines.firstWhere(
    (l) => l.startsWith('version:'),
    orElse: () => '',
  );

  stdout.writeln('=== NEXA Player Release Status ===');
  stdout.writeln(versionLine);

  final distDir = Directory('dist');
  if (distDir.existsSync()) {
    stdout.writeln('\nStaged Distribution Artifacts:');
    for (final entity in distDir.listSync(recursive: true)) {
      if (entity is File) {
        final bytes = entity.lengthSync();
        final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
        stdout.writeln(' - ${entity.path} ($mb MB)');
      }
    }
  } else {
    stdout.writeln('\nNo staged artifacts in dist/ yet.');
  }
}

void _bumpVersion(String type) {
  final pubspecFile = File('pubspec.yaml');
  final content = pubspecFile.readAsStringSync();
  final regExp = RegExp(r'version:\s*([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)');
  final match = regExp.firstMatch(content);

  if (match == null) {
    stderr.writeln('Error: Could not parse version line in pubspec.yaml');
    exit(1);
  }

  var major = int.parse(match.group(1)!);
  var minor = int.parse(match.group(2)!);
  var patch = int.parse(match.group(3)!);
  var build = int.parse(match.group(4)!) + 1;

  switch (type) {
    case 'major':
      major++;
      minor = 0;
      patch = 0;
      break;
    case 'minor':
      minor++;
      patch = 0;
      break;
    case 'patch':
    default:
      patch++;
      break;
  }

  final newVersion = '$major.$minor.$patch+$build';
  final updated = content.replaceFirst(
    regExp,
    'version: $newVersion',
  );

  pubspecFile.writeAsStringSync(updated);
  stdout.writeln('Successfully bumped version: ${match.group(0)} -> version: $newVersion');
}

void _generateChangelog() {
  final changelogFile = File('CHANGELOG.md');
  final existing = changelogFile.existsSync() ? changelogFile.readAsStringSync() : '';

  final pubspecFile = File('pubspec.yaml');
  final content = pubspecFile.readAsStringSync();
  final versionMatch = RegExp(r'version:\s*([^\s]+)').firstMatch(content);
  final currentVersion = versionMatch?.group(1) ?? '1.0.0+1';

  final gitResult = Process.runSync('git', ['log', '-n', '15', '--oneline']);
  final commits = gitResult.stdout.toString().trim();

  final entry = StringBuffer()
    ..writeln('## [v${currentVersion.split('+').first}] - ${DateTime.now().toIso8601String().split('T').first}')
    ..writeln('### Notable Updates & Commits')
    ..writeln(commits.split('\n').map((c) => '- $c').join('\n'))
    ..writeln('\n');

  changelogFile.writeAsStringSync('${entry.toString()}$existing');
  stdout.writeln('Updated CHANGELOG.md with recent commits for v$currentVersion.');
}
