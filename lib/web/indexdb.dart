import 'dart:html';
import 'dart:indexed_db';

import '../handle_dump_parser.dart';
import '../sorting.dart';
import 'dump_entry.dart';
import 'elements.dart';
import 'sorter.dart';
import 'wrapper.dart';

Database _database;

final _htmlValidator = NodeValidatorBuilder.common()
  ..allowElement('span', attributes: [
    'data-toggle',
    'data-html',
    'data-placement',
    'data-container'
  ]);

final _historyList = <HistoryEntry>[];

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
    _historyList.addAll((request.result as List).toHistoryList());
    createHistory();
    updateTable();
    window.onHashChange.listen(updateTable);
  });

  request.onError.listen((event) {
    window.console.error('Failed to retrieve history\n$event');
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

  // Try match compare
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
        compareId <= 0 ||
        compareId > _historyList.length) {
      window.location.hash = '#';
      return;
    }
    if (id == compareId) {
      window.location.hash = '#$id';
      return;
    }
  }

  if (id <= 0 || id > _historyList.length) {
    window.location.hash = '#';
    return;
  }

  var result = _historyList[id - 1];

  assert(result != null, 'Null result with id: $id');
  var dumpResults = HandleDumpParser.parse(result.data);

  if (dumpResults == null) {
    Snackbar.show(SnackbarParams(
        text: 'Invalid string!', pos: 'top-right', backgroundColor: '#cc3300'));
    return;
  }

  if (compareId != null) {
    result = _historyList[compareId - 1];

    assert(result != null, 'Null result with id: $id (compare)');
    var dumpResults2 = HandleDumpParser.parse(result.data);

    if (dumpResults2 == null) {
      Snackbar.show(SnackbarParams(
          text: 'Invalid string!',
          pos: 'top-right',
          backgroundColor: '#cc3300'));
      return;
    }

    dumpResults = DumpResults.compare(dumpResults, dumpResults2);
  }

  oldResult = currentResult;
  currentResult = dumpResults;

  oldResultId = currentResultId;
  currentResultId = id;

  csvButton.disabled = false;
  compareButton.disabled = oldResult == null;

  var results = dumpResults.sort();
  resetSort();
  tableBody.innerHtml = '';
  results.forEach(appendRows);
  (jQuery('[data-toggle="tooltip"]') as TooltipElement).tooltip();
}

/// Append the rows to the datatable
void appendRows(Owner result) {
  if (result.changed) {
    tableBody.appendHtml(
        '<tr class="col-sm-12 table-warning">'
        '<th>${result.owner}</th><th>${result.count} (${result.otherOwner.count})</th>'
        '<th>'
        '<span data-container="table" data-placement="top" data-toggle="tooltip" data-html="true" title="${_getTooltip(result)}">${result.getMostUsedType()}</span>'
        '<span data-container="table" data-placement="top" data-toggle="tooltip" data-html="true" title="${_getTooltip(result.otherOwner)}"> (${result.otherOwner.getMostUsedType()})</span>'
        '</th>'
        '<th>${result.memory} (${result.otherOwner.memory}) bytes</th>'
        '</tr>',
        validator: _htmlValidator);
  } else if (result.added) {
    tableBody.appendHtml(
        '<tr class="col-sm-12 table-success"><th>${result.owner}</th><th>${result.count}</th><th><span data-container="table" data-placement="top" data-toggle="tooltip" data-html="true" title="${_getTooltip(result)}">${result.getMostUsedType()}</span></th><th>${result.memory} bytes</th></tr>',
        validator: _htmlValidator);
  } else if (result.removed) {
    tableBody.appendHtml(
        '<tr class="col-sm-12 table-danger"><th>${result.owner}</th><th>${result.count}</th><th><span data-container="table" data-placement="top" data-toggle="tooltip" data-html="true" title="${_getTooltip(result)}">${result.getMostUsedType()}</span></th><th>${result.memory} bytes</th></tr>',
        validator: _htmlValidator);
  } else {
    tableBody.appendHtml(
        '<tr class="col-sm-12"><th>${result.owner}</th><th>${result.count}</th><th><span data-container="table" data-placement="top" data-toggle="tooltip" data-html="true" title="${_getTooltip(result)}">${result.getMostUsedType()}</span></th><th>${result.memory} bytes</th></tr>',
        validator: _htmlValidator);
  }
}

/// Sort a table from a previous dumpResult.
void sortTable(Sorter sorter) {
  var results = currentResult.sort(sorter);
  tableBody.innerHtml = '';
  results.forEach(appendRows);

  (jQuery('[data-toggle="tooltip"]') as TooltipElement).tooltip();
}

var _currentPage = 1;

/// Creates the history list.
void createHistory() {
  clearButton.disabled = _historyList.isEmpty;
  for (var e in _historyList
      .sublist((_historyList.length - 10).clamp(0, double.maxFinite).toInt())) {
    historyListElement.prependHtml(
        '<li><small><a href="#${e.index + 1}">Dump #${e.index + 1} <br>Memory: ${e.memory} <br>Handles: ${e.handles}</a></small></li>');
  }
  rightArrow.disabled = _historyList.length < 10;
}

/// Updates the history list, if [previous] is true it goes back otherwise to
/// the next page. If [page] is not null the current page is set to that.
void updateHistoryPage({final bool previous = false, final int page}) {
  historyListElement.text = '';
  _currentPage += previous ? -1 : 1;
  if (page != null) {
    _currentPage = page;
  }
  for (var e in _historyList
      .sublist((_historyList.length - (10 * _currentPage))
          .clamp(0, double.maxFinite)
          .toInt())
      .take(10)) {
    historyListElement.prependHtml(
        '<li><small><a href="#${e.index + 1}">Dump #${e.index + 1} <br>Memory: ${e.memory} <br>Handles: ${e.handles}</a></small></li>');
  }
  leftArrow.disabled = _currentPage == 1;
  rightArrow.disabled = _historyList.length < (10 * _currentPage);
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
  updateHistoryPage(page: 1);
  _historyList.add(HistoryEntry(
      _historyList.length, dump.totalMemory, dump.handleCount, dump.raw));
  clearButton.disabled = false;
  var children = historyListElement.children;
  if (children.length >= 10) {
    children.removeLast();
  }
  historyListElement.prependHtml(
      '<li><small><a href="#${_historyList.length}">Dump #${_historyList.length} <br>Memory: ${dump.totalMemory} <br>Handles: ${dump.handleCount}</a></small></li>');
  window.location.hash = '#${_historyList.length}';
}

/// Clears all the history data.
Future<void> clearHistory() async {
  var transaction = _database.transaction('dumps', 'readwrite');
  await transaction.objectStore('dumps').clear();
  historyListElement.children.clear();
  tableBody.innerHtml = '';
  window.location.hash = '#';
  _historyList.clear();
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

extension on Element {
  void prependHtml(String text,
      {NodeValidator validator, NodeTreeSanitizer treeSanitizer}) {
    insertAdjacentHtml('afterbegin', text,
        validator: validator, treeSanitizer: treeSanitizer);
  }
}

extension on List {
  List<HistoryEntry> toHistoryList() {
    var index = 0;
    return <HistoryEntry>[
      for (var e in this)
        HistoryEntry(index++, e['memory'] as int, e['handles'] as int,
            e['data'] as String)
    ];
  }
}
