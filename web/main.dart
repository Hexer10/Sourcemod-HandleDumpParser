import 'dart:html';
import 'dart:js';
import 'dart:js_util';

import 'package:HandleDumpParser/handle_dump_parser.dart';
import 'package:HandleDumpParser/web/elements.dart';
import 'package:HandleDumpParser/web/indexdb.dart';
import 'package:HandleDumpParser/web/sorter.dart';
import 'package:HandleDumpParser/web/theme_loader.dart';
import 'package:HandleDumpParser/web/wrapper.dart';

Future<void> main() async {
//  loadTheme();
  await initDB();
  initSort();
  dumpForm.onSubmit.listen(onFormSubmit);
  fileInput.onChange.listen(onFileSubmit);
  csvButton.onClick.listen((event) {
    if (currentResult == null) {
      Snackbar.show(SnackbarParams(
          text: 'No dump is selected.',
          pos: 'top-right',
          backgroundColor: '#cc3300'));
      return;
    }
    var csv = currentResult.toCsv();
    var result = copyToClipboard(csv);
    if (result) {
      Snackbar.show(SnackbarParams(
          text: 'Text copied to the clipboard.',
          pos: 'top-right',
          backgroundColor: '#5cb85c'));
    } else {
      window.console.log(csv);
      Snackbar.show(SnackbarParams(
          text:
              'Failed to copy the text, check the dev console for the output.',
          pos: 'top-right',
          backgroundColor: '#cc3300'));
    }
  });
  compareButton.onClick.listen((event) {
    if (currentResult == null || oldResult == null) {
      Snackbar.show(SnackbarParams(
          text: 'Compare failed',
          pos: 'top-right',
          backgroundColor: '#cc3300'));
      return;
    }
    window.location.hash = '#$currentResultId-$oldResultId';
  });
  textArea.onFocus.listen((event) {
    textArea.setAttribute('style', themesCSS[currentTheme]);
  });
  clearButton.onClick.listen((event) => clearHistory());
  leftArrow.onClick.listen((event) => updateHistoryPage(previous: true));
  rightArrow.onClick.listen((event) => updateHistoryPage());
  setProperty(window, 'loadTheme', allowInterop(loadTheme));

}

void onFormSubmit(Event event) {
  event.preventDefault();
  var dumpArea = querySelector('#dumpArea') as TextAreaElement;
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
  var fileInput = (querySelector('#files') as InputElement).files;

  if (fileInput.isEmpty) {
    return;
  }

  var reader = FileReader();

  reader.onLoad.listen((fileEvent) {
    var dump = reader.result as String;
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
