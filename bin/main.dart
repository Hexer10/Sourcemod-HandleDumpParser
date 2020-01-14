import 'dart:io';

import 'package:HandleDumpParser/handle_dump_parser.dart';
import 'package:args/args.dart';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption('path', abbr: 'p', help: 'Path to the dump file')
    ..addFlag('help', abbr: 'h', help: 'Display this text', negatable: false);

  final argResults = parser.parse(arguments);

  String path = argResults['path'];

  if (argResults['help']) {
    print(parser.usage);
  } else if (path == null) {
    handleError('Missing required argument: path');
  }

  if (!FileSystemEntity.isFileSync(path)) {
    handleError('$path is not a file!');
  }

  File('$path-parsed.txt').writeAsStringSync(
      'Owner                       Type                            Memory\n',
      mode: FileMode.write);

  var dump = File('dump_parsed.txt').openWrite(mode: FileMode.writeOnlyAppend);

  var dumpResults = HandleDumpParser.parse(File(path).readAsStringSync());

  dumpResults.sort().forEach(dump.writeln);
  dump.close();
}

void handleError(String msg) {
  stderr.writeln(msg);
  exitCode = 2;
}
