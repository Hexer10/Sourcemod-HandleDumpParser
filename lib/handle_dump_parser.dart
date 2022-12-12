import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:quiver/core.dart';

import 'sorting.dart';

const _csvHead = ['Owner', 'HandleCount', 'MostUsedHandle', 'Memory'];

const _listEquality = ListEquality();
const _mapEquality = MapEquality<String, int>();

/// Handle Dump Parser.
class HandleDumpParser {
  HandleDumpParser._();

  /// Parse a Handle Dump.
  static DumpResults parse(String file) {
    var count = 0;
    var owners = <String, Owner>{};
    var totalMemory = 0;
    var handleCount = 0;

    var lines = file.trim().split('\n');
    for (var line in lines) {
      if (line.length < 53) {
        return _tryCSV(file);
      }

      if (++count < 2 || line.startsWith('-')) {
        continue;
      }

      final ownerName = line.substring(11, 32).trim();

      final type = line.substring(32, 53).trim();

      var memory = int.tryParse(line.substring(53).trim());
      if (memory == null) {
        // SM 1.11+ compat
        memory = int.tryParse(line.substring(53, 64).trim());
      }
      if (memory == null) {
        return null;
      }
      if (memory <= 0) {
        memory = 0;
      }
      handleCount++;

      totalMemory += memory;

      var owner = Owner(ownerName, type, memory);
      if (owners[ownerName] == null) {
        owners[ownerName] = owner;
      } else {
        owners[ownerName]
          ..memory += memory
          ..count += 1;

        owners[ownerName]
            .types
            .update(type, (value) => value + 1, ifAbsent: () => 1);

        owners[ownerName]
            .ownerMemory
            .update(type, (value) => value + memory, ifAbsent: () => memory);
      }
    }
    return DumpResults._(owners, totalMemory, handleCount, file);
  }

  static DumpResults _tryCSV(String file) {
    var list = CsvToListConverter(eol: '\n').convert(file);
    var head = list.first;
    if (!_listEquality.equals(_csvHead, head)) {
      return null;
    }
    var totalMemory = 0;
    var totalHandles = 0;
    var owners = <Owner>[];
    for (var row in list.skip(1)) {
      var count = row[1];
      var memory = row[3];
      if (count is int && memory is int) {
        totalMemory += memory;
        totalHandles += count;
        owners.add(
            Owner(row[0] as String, row[2] as String, memory)..count = count);
      }
      return null;
    }
    return DumpResults._(
        Map<String, Owner>.fromIterable(owners,
            key: (k) => k.owner as String, value: (v) => v as Owner),
        totalMemory,
        totalHandles,
        file);
  }
}

/// Dump results
class DumpResults {
  final Map<String, Owner> _owners;

  /// Total memory used.
  final int totalMemory;

  /// Total handle count.
  final int handleCount;

  /// Raw unparsed dump.
  final String raw;

  /// A Map containing all the owners names linked to the [Owner] objects.
  Map<String, Owner> get owners => _owners;

  const DumpResults._(
      this._owners, this.totalMemory, this.handleCount, this.raw);

  /// Sort the handles by [Sorter].
  List<Owner> sort([Sorter sorter]) {
    sorter ??= Sorter();
    var values = _owners.values.toList();
    if (sorter.order == SortOrder.ascending) {
      switch (sorter.key) {
        case SortKey.owner:
          return values
            ..sort((a, b) =>
                a.owner.toLowerCase().compareTo(b.owner.toLowerCase()));
        case SortKey.handles:
          return values..sort((a, b) => b.count.compareTo(a.count));
        case SortKey.type:
          return values
            ..sort((a, b) => a
                .getMostUsedType()
                .toLowerCase()
                .compareTo(b.getMostUsedType().toLowerCase()));
        case SortKey.memory:
          return values..sort((a, b) => b.memory.compareTo(a.memory));
        default:
          return null;
      }
    } else {
      switch (sorter.key) {
        case SortKey.owner:
          return values
            ..sort((a, b) =>
                b.owner.toLowerCase().compareTo(a.owner.toLowerCase()));
        case SortKey.handles:
          return values..sort((a, b) => a.count.compareTo(b.count));
        case SortKey.type:
          return values
            ..sort((a, b) => b
                .getMostUsedType()
                .toLowerCase()
                .compareTo(a.getMostUsedType().toLowerCase()));
        case SortKey.memory:
          return values..sort((a, b) => a.memory.compareTo(b.memory));
        default:
          return null;
      }
    }
  }

  /// Compare two DumpResults
  DumpResults.compare(DumpResults dump1, DumpResults dump2)
      : _owners = dump1.owners,
        totalMemory = dump1.totalMemory,
        handleCount = dump1.handleCount,
        raw = dump1.raw {
    var owners1 = dump1.owners;
    var owners2 = dump2.owners;
    owners1.forEach((name, owner) {
      if (owners2[name] == null) {
        owner._added = true;
        return;
      }
      owner._changed = owners2[name] != owner;
      if (owner._changed) {
        owner._otherOwner = owners2[name];
        assert(owner._otherOwner != null, 'Other Owner must be not null');
        return;
      }
    });
    owners2.forEach((name, owner) {
      if (owners1[name] == null) {
        owner._removed = true;
        owners1[name] = owner;
      }
    });
  }

  /// Convert this object to a csv format string.
  String toCsv() {
    var csv = <List<dynamic>>[_csvHead];

    owners.forEach((k, v) {
      csv.add([v.owner, v.count, v.getMostUsedType(), v.memory]);
    });
    return ListToCsvConverter().convert(csv);
  }
}

/// Owner
class Owner {
  /// Owner's name,
  final String owner;

  /// Map containing all the handles names and their count.
  Map<String, int> types = <String, int>{};

  /// Map containing all the handles names the memory used.
  /// The keys have the same order and have the same names as [types].
  Map<String, int> ownerMemory = <String, int>{};

  /// The total handle count.
  int count = 1;

  /// Total memory used.
  int memory;

  bool _changed = false;

  bool _added = false;

  bool _removed = false;

  Owner _otherOwner;

  /// True if the results are changed.
  /// See [DumpResults.compare]
  bool get changed => _changed;

  /// True if this item was added in the current result.
  /// See [DumpResults.compare]
  bool get added => _added;

  /// True if this item was removed in the current result.
  /// See [DumpResults.compare]
  bool get removed => _removed;

  /// Returns the owner this was compared to.
  /// Throws if [changed] is false
  Owner get otherOwner => changed
      ? _otherOwner
      : throw UnsupportedError('This Owner did not change!');

  /// Initialize Owner.
  Owner(this.owner, String type, this.memory) {
    types[type] = 1;
    ownerMemory[type] = memory;
  }

  @override
  // ignore: type_annotate_public_apis, avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      other is Owner &&
      _mapEquality.equals(types, other.types) &&
      count == other.count &&
      memory == other.memory;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => hash3(types, count, memory);

  /// Returns the most appearing handle type.
  String getMostUsedType() {
    var sortedKeys = types.keys.toList(growable: false)
      ..sort((k1, k2) => types[k2].compareTo(types[k1]));
    var sortedMap = Map<String, int>.fromIterable(sortedKeys,
        key: (k) => k as String, value: (k) => types[k]);
    return sortedMap.keys.first;
  }

  @override
  String toString() {
    var sortedKeys = types.keys.toList(growable: false)
      ..sort((k1, k2) => types[k1].compareTo(types[k2]));
    var sortedMap = Map<String, int>.fromIterable(sortedKeys,
        key: (k) => k as String, value: (k) => types[k]);
    var type = sortedMap.keys.first;

    var ownerBuffer = StringBuffer(owner);
    for (var i = owner.length; i < 28; i++) {
      ownerBuffer.write(' ');
    }
    var typeBuffer = StringBuffer(type);
    for (var i = type.length; i < 32; i++) {
      typeBuffer.write(' ');
    }

    return ownerBuffer.toString() + typeBuffer.toString() + memory.toString();
  }
}
