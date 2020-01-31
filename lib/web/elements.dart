import 'dart:html';

import '../handle_dump_parser.dart';

final TableElement _dumpTable = querySelector('#dumpTable');
final TableSectionElement _tableBody = _dumpTable.tBodies.first;
final UListElement _historyList = querySelector('#history');
final ButtonElement _csvButton = querySelector('#csvButton');

final TableCellElement _ownerCol = querySelector('#ownerCol');
final TableCellElement _handleCol = querySelector('#handleCol');
final TableCellElement _typeCol = querySelector('#typeCol');
final TableCellElement _memoryCol = querySelector('#memoryCol');
final List<SpanElement> _spanSort = querySelectorAll('[id\$=\'Sort\']');

/// The latest displayed result.
DumpResults oldResult;

/// Dump table element.
TableElement get dumpTable => _dumpTable;

/// Table body(tr) element.
TableSectionElement get tableBody => _tableBody;

/// History list element.
UListElement get historyList => _historyList;

/// Convert to CSV button element.
ButtonElement get csvButton => _csvButton;

/// Owner body column.
TableCellElement get ownerCol => _ownerCol;

/// Handle count column.
TableCellElement get handleCol => _handleCol;

/// Most used handle type column.
TableCellElement get typeCol => _typeCol;

/// Memory used column.
TableCellElement get memoryCol => _memoryCol;

/// Sorting indicators.
List<SpanElement> get spanSort => _spanSort;
