import 'dart:html';

import 'package:HandleDumpParser/handle_dump_parser.dart';
import 'package:HandleDumpParser/web/indexdb.dart';
import 'package:HandleDumpParser/web/sorter.dart';
import 'package:HandleDumpParser/web/wrapper.dart';

Future<void> main() async {
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
