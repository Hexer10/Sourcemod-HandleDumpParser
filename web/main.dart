import 'dart:collection';
import 'dart:html';
import 'dart:indexed_db';

import 'package:HandleDumpParser/handle_dump_parser.dart';
import 'package:HandleDumpParser/web/wrapper.dart';
//import 'package:pwa/client.dart' as pwa;

final TableElement dumpTable = querySelector('#dumpTable');
final UListElement historyList = querySelector('#history');
final ButtonElement compareButton = querySelector('#compareButton');
final TableSectionElement tBody = dumpTable.tBodies[0];

int nextIndex = 1;
Database db;
List<DumpResults> comparable = [];

Future<void> main() async {
  compareButton.onClick.listen((event) {
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
  });
  querySelector('#dumpForm').onSubmit.listen(onFormSubmit);
  document.querySelector('#files').onChange.listen(onFileSubmit);

  var idb = window.indexedDB;
  db = await idb.open('dumps', version: 1, onUpgradeNeeded: (event) {
    var db = event.target.result as Database;
    var version = db.version;
    print('Changed version to $version from(${event.oldVersion})!');

    var obj = db.createObjectStore('dumps', autoIncrement: true);
    obj.createIndex('data', 'data', unique: false);
    obj.createIndex('time', 'time', unique: false);
    obj.createIndex('memory', 'memory', unique: false);
    obj.createIndex('handles', 'handles', unique: false);
  });
  var transaction = db.transaction('dumps', 'readonly');
  var obj = transaction.objectStore('dumps');
  var request = obj.getAll(null);

  request.onSuccess.listen((event) {
    var result = request.result as List<dynamic>;
    nextIndex = result.length + 1;
    for (var i = result.length - 1; i >= 0; i--) {
      var e = result[i];
      historyList.appendHtml(
          '<li><small><a href="#${i + 1}">Dump #${i + 1} <br>Memory: ${e['memory']} <br>Handles: ${e['handles']}</a></small></li>');
    }

    Future<void> updateTable([_]) async {
      var hash = window.location.hash;
      if (hash.trim().isEmpty) {
        return;
      }
      var id = int.tryParse(window.location.hash.substring(1));
      if (id == null || id < 0 || id > nextIndex - 1) {
        return;
      }
      var transaction = db.transaction('dumps', 'readonly');
      var obj = transaction.objectStore('dumps');
      print('Id: $id');
      var result = await obj.getObject(id);
      var dumpResults = HandleDumpParser.parse(result['data']);

      if (dumpResults == null) {
        Snackbar.show(SnackbarParams(
            text: 'Invalid string!',
            pos: 'top-right',
            backgroundColor: '#cc3300'));
        return;
      }

      final htmlValidator = NodeValidatorBuilder.common()
        ..allowElement('span', attributes: [
          'data-toggle',
          'data-html',
          'data-placement',
          'data-container'
        ]);

      comparable.add(dumpResults);
      var results = dumpResults.sort();
      tBody.innerHtml = '';
      for (var result in results) {
        var types = result.types;
        var sortedKeys = types.keys.toList(growable:false)
          ..sort((k1, k2) => types[k2].compareTo(types[k1]));
        var sortedMap = LinkedHashMap
            .fromIterable(sortedKeys, key: (k) => k, value: (k) => types[k]);
        var type = sortedMap.keys.first;

        tBody.appendHtml(
            '<tr class="col-sm-12"><th>${result.owner}</th><th>${result.count}</th><th><span data-container="table" data-placement="top" data-toggle="tooltip" data-html="true" title="${getTooltip(result)}">$type</span></th><th>${result.memory}</th></tr>',
            validator: htmlValidator);
      }
      (jQuery('[data-toggle="tooltip"]') as TooltipElement).tooltip();
    }

    updateTable();
    window.onHashChange.listen(updateTable);
  });
}

String getTooltip(Owner result) {
  var buffer = StringBuffer('<small>');
  var types = result.types;
  var sortedKeys = types.keys.toList(growable:false)
    ..sort((k1, k2) => types[k2].compareTo(types[k1]));
  var sortedMap = LinkedHashMap
      .fromIterable(sortedKeys, key: (k) => k, value: (k) => types[k]);

  sortedMap.forEach((k, v) {
    buffer.write('$k - $v<br>');
  });
  buffer.write('</small>');
  return buffer.toString();
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
  addData(dump, dumpResults);
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
    addData(dump, dumpResults);
  });

  reader.readAsText(fileInput[0], 'UTF-8');
}

Future<void> addData(String text, DumpResults dump) async {
  var transaction = db.transaction('dumps', 'readwrite');
  await transaction.objectStore('dumps').add({
    'data': text,
    'time': DateTime.now().millisecondsSinceEpoch.toString(),
    'memory': dump.totalMemory,
    'handles': dump.handleCount
  });
  historyList.innerHtml =
      '<li><small><a href="#$nextIndex">Dump #$nextIndex <br>Memory: ${dump.totalMemory} <br>Handles: ${dump.handleCount}</a></small></li>'
      '${historyList.innerHtml}';
  window.location.href = '#$nextIndex';
  nextIndex += 1;
}
