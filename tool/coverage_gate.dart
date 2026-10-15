// Coverage gate for `flutter test --coverage`.
//
// Usage: `dart run tool/coverage_gate.dart <lcov.info> <min_percent>`
// Excludes `lib/main.dart` (a `runApp` one-liner CI cannot execute).
// Exits 0 when line coverage meets the threshold, 1 otherwise.
import 'dart:io';

const _excluded = {'lib/main.dart'};

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('usage: coverage_gate.dart <lcov.info> <min_percent>');
    exit(2);
  }
  final file = File(args[0]);
  if (!file.existsSync()) {
    stderr.writeln('coverage file not found: ${args[0]}');
    exit(2);
  }
  final min = double.parse(args[1]);
  var current = '';
  var found = 0;
  var hit = 0;
  final perFile = <String, List<int>>{};
  var fileFound = 0;
  var fileHit = 0;

  void flush() {
    if (current.isEmpty) return;
    if (!_excluded.contains(current)) {
      found += fileFound;
      hit += fileHit;
      perFile[current] = [fileFound, fileHit];
    }
    fileFound = 0;
    fileHit = 0;
  }

  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      flush();
      current = line.substring(3);
    } else if (line.startsWith('LF:')) {
      fileFound = int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      fileHit = int.parse(line.substring(3));
    } else if (line == 'end_of_record') {
      flush();
      current = '';
    }
  }
  flush();

  final pct = found == 0 ? 0.0 : hit / found * 100;
  stdout.writeln(
    'lines: $hit/$found (${pct.toStringAsFixed(2)}%), '
    'threshold: ${min.toStringAsFixed(0)}%',
  );
  final weak = perFile.entries
      .where((e) => e.value[0] > 0 && e.value[1] / e.value[0] * 100 < min)
      .toList()
    ..sort(
      (a, b) => (a.value[1] / a.value[0]).compareTo(b.value[1] / b.value[0]),
    );
  for (final e in weak) {
    final p = e.value[1] / e.value[0] * 100;
    stdout.writeln(
      '  below gate: ${e.key} '
      '(${e.value[1]}/${e.value[0]}, ${p.toStringAsFixed(1)}%)',
    );
  }
  if (pct < min) {
    stderr.writeln(
      'coverage gate failed: ${pct.toStringAsFixed(2)}% < '
      '${min.toStringAsFixed(0)}%',
    );
    exit(1);
  }
}
