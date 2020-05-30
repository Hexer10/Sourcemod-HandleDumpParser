import 'dart:html';

import '../handle_dump_parser.dart';

/// Dump table element.
final TableElement _dumpTable = querySelector('#dumpTable') as TableElement;

/// Table body(tr) element.
final TableSectionElement tableBody = _dumpTable.tBodies.first;

/// The input form element.
final FormElement dumpForm = querySelector('#dumpForm') as FormElement;

/// The input file element.
final InputElement fileInput = querySelector('#files') as InputElement;

/// History list element.
final UListElement historyListElement =
    querySelector('#history') as UListElement;

/// Convert to CSV button element.
final ButtonElement csvButton = querySelector('#csvButton') as ButtonElement;

/// Compare button element.
final ButtonElement compareButton =
    querySelector('#compareButton') as ButtonElement;

/// Clear history button element.
final ButtonElement clearButton =
    querySelector('#clearButton') as ButtonElement;

/// Button to go the the previous history page.
final ButtonElement leftArrow =
    querySelector('#leftArrowButton') as ButtonElement;

/// Button to go the the next history page.
final ButtonElement rightArrow =
    querySelector('#rightArrowButton') as ButtonElement;

/// Owner body column.
final TableCellElement ownerCol =
    querySelector('#ownerCol') as TableCellElement;

/// Handle count column.
final TableCellElement handleCol =
    querySelector('#handleCol') as TableCellElement;

/// Most used handle type column.
final TableCellElement typeCol = querySelector('#typeCol') as TableCellElement;

/// Memory used column.
final TableCellElement memoryCol =
    querySelector('#memoryCol') as TableCellElement;

/// Sorting indicators.
final List<SpanElement> spanSort =
    querySelectorAll('[id\$=\'Sort\']').toList().cast<SpanElement>();

/// The latest displayed result.
DumpResults currentResult;

/// Result displayed before [currentResult].
DumpResults oldResult;

/// The latest displayed result id.
int currentResultId;

/// Result id set before [currentResultId].
int oldResultId;
