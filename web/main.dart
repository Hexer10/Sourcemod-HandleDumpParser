import 'dart:html';

import 'package:HandleDumpParser/handle_dump_parser.dart';
import 'package:HandleDumpParser/web/elements.dart';
import 'package:HandleDumpParser/web/indexdb.dart';
import 'package:HandleDumpParser/web/sorter.dart';
import 'package:HandleDumpParser/web/wrapper.dart';

Future<void> main() async {
  await initDB();
  initSort();
  querySelector('#dumpForm').onSubmit.listen(onFormSubmit);
  document.querySelector('#files').onChange.listen(onFileSubmit);
  csvButton.onClick.listen((data) {
    if (oldResult == null) {
      Snackbar.show(SnackbarParams(
          text:
          'No dump is selected.',
          pos: 'top-right',
          backgroundColor: '#cc3300'));
      return;
    }
    var csv = oldResult.toCsv();
    var result = copyToClipboard(csv);
    if (result) {
      Snackbar.show(SnackbarParams(
          text: 'Text copied to the clipboard.',
          pos: 'top-right',
          backgroundColor: '#5cb85c'));
    } else {
      Snackbar.show(SnackbarParams(
          text:
              'Failed to copy the text, check the dev console for the output.',
          pos: 'top-right',
          backgroundColor: '#cc3300'));
      print(result);
    }
  });
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

/*
const copyToClipboard = str => {
  const el = document.createElement('textarea');
  el.value = str;
  el.setAttribute('readonly', '');
  el.style.position = 'absolute';
  el.style.left = '-9999px';
  document.body.appendChild(el);
  el.select();
  document.execCommand('copy');
  document.body.removeChild(el);
};
 */
bool copyToClipboard(String text) {
  final textArea = TextAreaElement();
  textArea.value = text;
  textArea.setAttribute('readonly', '');
  textArea.style.position = 'absolute';
  textArea.style.left = '-9999px';
  document.body.append(textArea);
  textArea.select();
  var r = document.execCommand('copy');
  document.body.children.last.remove();
  return r;
}
