import 'dart:html';

import '../handle_dump_parser.dart';

final _dumpTable = querySelector('#dumpTable') as TableElement;
final _tableBody = _dumpTable.tBodies.first;
final _dumpForm = querySelector('#dumpForm') as FormElement;
final _fileInput = querySelector('#files') as InputElement;
final _historyList = querySelector('#history') as UListElement;
final _csvButton = querySelector('#csvButton') as ButtonElement;
final _clearButton = querySelector('#clearButton') as ButtonElement;

final _ownerCol = querySelector('#ownerCol') as TableCellElement;

final _handleCol = querySelector('#handleCol') as TableCellElement;
final _typeCol = querySelector('#typeCol') as TableCellElement;
final _memoryCol = querySelector('#memoryCol') as TableCellElement;
final _spanSort = querySelectorAll('[id\$=\'Sort\']') as List<SpanElement>;

/// The latest displayed result.
DumpResults oldResult;

/// Dump table element.
TableElement get dumpTable => _dumpTable;

/// Table body(tr) element.
TableSectionElement get tableBody => _tableBody;

/// The input form element.
FormElement get dumpForm => _dumpForm;

/// The input file element.
InputElement get fileInput => _fileInput;

/// History list element.
UListElement get historyList => _historyList;

/// Convert to CSV button element.
ButtonElement get csvButton => _csvButton;

/// Clear history button element.
ButtonElement get clearButton => _clearButton;

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
