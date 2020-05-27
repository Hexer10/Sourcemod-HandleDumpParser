import 'dart:html';
import 'dart:indexed_db';

import '../handle_dump_parser.dart';
import '../sorting.dart';
import 'elements.dart';
import 'sorter.dart';
import 'wrapper.dart';

Database _database;
int _nextIndex = 1;
final _htmlValidator = NodeValidatorBuilder.common()
  ..allowElement('span', attributes: [
    'data-toggle',
    'data-html',
    'data-placement',
    'data-container'
  ]);

/// Initialize db.
Future<void> initDB() async {
  if (!IdbFactory.supported) {
    throw UnsupportedError('Indexed DB is not supported in this browser!');
  }
  var idb = window.indexedDB;

  // Open database
  _database = await idb.open('dumps',
      version: 1,
      onUpgradeNeeded: (event) =>
          _createObjectStore(event.target.result as Database));

  // Get the dumps in the history.
  var transaction = _database.transaction('dumps', 'readonly');
  var store = transaction.objectStore('dumps');
  var request = store.getAll(null);

  request.onSuccess.listen((event) {
    createHistory(request);
    updateTable();
    window.onHashChange.listen(updateTable);
  });
}

/// Create the object store and its indexes.
void _createObjectStore(Database database) {
  var store = database.createObjectStore('dumps', autoIncrement: true);
  store.createIndex('data', 'data', unique: false);
  store.createIndex('time', 'time', unique: false);
  store.createIndex('memory', 'memory', unique: false);
  store.createIndex('handles', 'handles', unique: false);
}

final _compareRegex = RegExp(r'^(\d*)-(\d*)$');

/// Update the table
Future<void> updateTable([_]) async {
  // Validate the hash.
  var hash = window.location.hash;
  if (hash.trim().isEmpty) {
    return;
  }
  hash = window.location.hash.substring(1);
  var id = int.tryParse(hash);
  int compareId;
  if (id == null) {
    var match = _compareRegex.firstMatch(hash);
    if (match == null) {
      window.location.hash = '#';
      return;
    }
    id = int.tryParse(match.group(1));
    compareId = int.tryParse(match.group(2));
    if (id == null ||
        compareId == null ||
        compareId < 0 ||
        compareId > _nextIndex - 1) {
      window.location.hash = '#';
      return;
    }
  }

  if (id < 0 || id > _nextIndex - 1) {
    window.location.hash = '#';
    return;
  }

  var transaction = _database.transaction('dumps', 'readonly');
  var store = transaction.objectStore('dumps');
  var result = await store.getObject(id);
  var dumpResults = HandleDumpParser.parse(result['data'] as String);

  if (dumpResults == null) {
    Snackbar.show(SnackbarParams(
        text: 'Invalid string!', pos: 'top-right', backgroundColor: '#cc3300'));
    return;
  }

  if (compareId != null) {
    transaction = _database.transaction('dumps', 'readonly');
    store = transaction.objectStore('dumps');
    result = await store.getObject(compareId);
    var dumpResults2 = HandleDumpParser.parse(result['data'] as String);

    if (dumpResults2 == null) {
      Snackbar.show(SnackbarParams(
          text: 'Invalid string!',
          pos: 'top-right',
          backgroundColor: '#cc3300'));
      return;
    }

    dumpResults = DumpResults.compare(dumpResults, dumpResults2);
  }

  oldResult = dumpResults;
  var results = dumpResults.sort();
  resetSort();
  tableBody.innerHtml = '';
  for (var result in results) {
    tableBody.appendHtml(
        '<tr class="col-sm-12${result.changed ? ' table-danger' : ''}"><th>${result.owner}</th><th>${result.count}</th><th><span data-container="table" data-placement="top" data-toggle="tooltip" data-html="true" title="${_getTooltip(result)}">${result.getMostUsedType()}</span></th><th>${result.memory} bytes</th></tr>',
        validator: _htmlValidator);
  }
  (jQuery('[data-toggle="tooltip"]') as TooltipElement).tooltip();
}

/// Sort a table from a previous dumpResult.
void sortTable(Sorter sorter) {
  final htmlValidator = NodeValidatorBuilder.common()
    ..allowElement('span', attributes: [
      'data-toggle',
      'data-html',
      'data-placement',
      'data-container'
    ]);

  var results = oldResult.sort(sorter);
  tableBody.innerHtml = '';
  for (var result in results) {
    var types = result.types;
    var sortedKeys = types.keys.toList(growable: false)
      ..sort((k1, k2) => types[k2].compareTo(types[k1]));
    var sortedMap = Map<String, int>.fromIterable(sortedKeys,
        key: (k) => k as String, value: (k) => types[k]);
    var type = sortedMap.keys.first;

    tableBody.appendHtml(
        '<tr class="col-sm-12${result.changed ? ' table-danger' : ''}"><th>${result.owner}</th><th>${result.count}</th><th><span data-container="table" data-placement="top" data-toggle="tooltip" data-html="true" title="${_getTooltip(result)}">$type</span></th><th>${result.memory}</th></tr>',
        validator: htmlValidator);
  }
  (jQuery('[data-toggle="tooltip"]') as TooltipElement).tooltip();
}

/// Creates the history list.
void createHistory(Request request) {
  var result = request.result as List<dynamic>;
  _nextIndex = result.length + 1;
  var min = result.length - 10;
  if (min < 0) {
    min = 0;
  }
  for (var i = result.length - 1; i >= min; i--) {
    var e = result[i];
    historyList.appendHtml(
        '<li><small><a href="#${i + 1}">Dump #${i + 1} <br>Memory: ${e['memory']} <br>Handles: ${e['handles']}</a></small></li>');
  }
}

/// Add a new dump into the database.
Future<void> addData(DumpResults dump) async {
  var transaction = _database.transaction('dumps', 'readwrite');
  await transaction.objectStore('dumps').add({
    'data': dump.raw,
    'time': DateTime.now().millisecondsSinceEpoch.toString(),
    'memory': dump.totalMemory,
    'handles': dump.handleCount
  });
  var children = historyList.children;
  if (children.length >= 10) {
    children.removeLast();
  }
  children.insert(
      0,
      Element.html(
          '<li><small><a href="#$_nextIndex">Dump #$_nextIndex <br>Memory: ${dump.totalMemory} <br>Handles: ${dump.handleCount}</a></small></li>'));
  window.location.hash = '#$_nextIndex';
  _nextIndex += 1;
}

/// Clears all the history data.
Future<void> clearHistory() async {
  var transaction = _database.transaction('dumps', 'readwrite');
  await transaction.objectStore('dumps').clear();
  historyList.children.clear();
  tableBody.innerHtml = '';
  window.location.hash = '#';
  _nextIndex = 1;
}

/// Returns the owners' tooltip string.
String _getTooltip(Owner owner) {
  var buffer = StringBuffer('<small>');
  var types = owner.types;
  var sortedKeys = types.keys.toList(growable: false)
    ..sort((k1, k2) => types[k2].compareTo(types[k1]));
  var sortedMap = Map<String, int>.fromIterable(sortedKeys,
      key: (k) => k as String, value: (k) => types[k]);

  sortedMap.forEach((k, v) {
    buffer.write('$k - $v (${owner.ownerMemory[k]} bytes)<br>');
  });
  buffer.write('</small>');
  return buffer.toString();
}
