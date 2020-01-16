import 'dart:html';

import 'package:HandleDumpParser/handle_dump_parser.dart';
import 'package:HandleDumpParser/web/indexdb.dart';
import 'package:HandleDumpParser/web/sorter.dart';
import 'package:HandleDumpParser/web/wrapper.dart';
//import 'package:pwa/client.dart' as pwa;

Future<void> main() async {
  /*compareButton.onClick.listen((event) {
    print('Comparing!');
    var dump = DumpResults.compare(comparable[0], comparable[1]);
    var results = dump.sort();

    tBody.innerHtml = '';
    for (var result in results) {
      var reverse = result.types.map((k, v) => MapEntry(v, k));
      var sortedKeys = reverse.keys.toList()..sort((a, b) => a > b ? a : b);
      var type = reverse[sortedKeys[0]].toString().trim();

      tBody.appendHtml(
          '<tr class="col-sm-12${result.changed ? ' table-danger' : ''}"><th>${result.owner}</th><th>${result.count}</th><th>$type</th><th>${result.memory}</th></tr>');
    }
  });*/

  await initDB();
  initSort();
  querySelector('#dumpForm').onSubmit.listen(onFormSubmit);
  document.querySelector('#files').onChange.listen(onFileSubmit);
}

void onFormSubmit(Event event) {
  event.preventDefault();
  TextAreaElement dumpArea = querySelector('#dumpArea');
  var dump = dumpArea.value;

  var dumpResults = HandleDumpParser.parse(dump);

  if (dumpResults == null) {
    Snackbar.show(SnackbarParams(
        text: 'Invalid string!', pos: 'top-right', backgroundColor: '#cc3300'));
    return;
  }
  addData(dumpResults);
  dumpArea.value = '';
}

void onFileSubmit(_) {
  List fileInput = (querySelector('#files') as InputElement).files;

  if (fileInput.isEmpty) {
    return;
  }

  var reader = FileReader();

  reader.onLoad.listen((fileEvent) {
    String dump = reader.result;
    var dumpResults = HandleDumpParser.parse(dump);

    if (dumpResults == null) {
      Snackbar.show(SnackbarParams(
          text: 'Invalid string!',
          pos: 'top-right',
          backgroundColor: '#cc3300'));
      return;
    }
    addData(dumpResults);
  });

  reader.readAsText(fileInput[0], 'UTF-8');
}
