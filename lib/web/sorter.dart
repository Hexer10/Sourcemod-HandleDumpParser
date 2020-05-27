import 'dart:html';

import '../sorting.dart';
import 'elements.dart';
import 'indexdb.dart';

SortOrder _order = SortOrder.ascending;
SortKey _key = SortKey.memory;

/// Initialize sorting.
void initSort() {
  ownerCol.onClick.listen(_handleEvent);
  handleCol.onClick.listen(_handleEvent);
  typeCol.onClick.listen(_handleEvent);
  memoryCol.onClick.listen(_handleEvent);
}

/// Reset the sorting settings.
void resetSort() {
  _order = SortOrder.ascending;
  _key = SortKey.memory;
  for (var e in spanSort) {
    e.innerText = '';
  }
  spanSort[3].innerText = '▼';
}

void _handleEvent(MouseEvent event) {
  if (oldResult == null) {
    return;
  }

  var target = event.currentTarget as TableCellElement;
  var newKey = _stringToKey(target.id);
  assert(newKey != null);

  var span = target.children.first as SpanElement;
  if (newKey == _key) {
    if (_order == SortOrder.ascending) {
      _order = SortOrder.descending;
      span.innerText = '▲';
    } else {
      _order = SortOrder.ascending;
      span.innerText = '▼';
    }
  } else {
    for (var e in spanSort) {
      e.innerText = '';
    }
    _order = SortOrder.ascending;
    _key = newKey;
    span.innerText = '▼';
  }
  sortTable(Sorter(order: _order, key: _key));
}

SortKey _stringToKey(String key) {
  switch (key) {
    case 'ownerCol':
      return SortKey.owner;
    case 'handleCol':
      return SortKey.handles;
    case 'typeCol':
      return SortKey.type;
    case 'memoryCol':
      return SortKey.memory;
    default:
      return null;
  }
}
/*
/// Owner body column.
TableRowElement get ownerCol => _ownerCol;

/// Handle count column.
TableRowElement get handleCol => _handleCol;

/// Most used handle type column.
TableRowElement get typeCol => _typeCol;

/// Memory used column.
TableRowElement get memoryCol => _memoryCol;
 */
