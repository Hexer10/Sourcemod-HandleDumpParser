import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:quiver/core.dart';

/// Handle Dump Parser.
class HandleDumpParser {
  HandleDumpParser._();

  /// Parse an Handle Dump.
  static DumpResults parse(String file) {
    var count = 0;
    var owners = <String, Owner>{};
    var totalMemory = 0;
    var handleCount = 0;

    var lines = file.trim().split('\n');
    for (var line in lines) {
      if (line.length < 53) {
        return null;
      }

      if (++count < 2 || line.startsWith('-')) {
        continue;
      }

      final ownerName = line.substring(11, 32).trim();

      final type = line.substring(32, 53);

      var memory = int.parse(line.substring(53).trim());
      if (memory <= 0) {
        memory = 0;
      } else {
        handleCount++;
      }

      totalMemory += memory;

      var owner = Owner(ownerName, type, memory);
      if (owners[ownerName] == null) {
        owners[ownerName] = owner;
      } else {
        owners[ownerName]
          ..memory += memory
          ..count += 1;

        owners[ownerName].types[type] == null
            ? owners[ownerName].types[type] = 1
            : owners[ownerName].types[type]++;
      }
    }
    return DumpResults._(owners, totalMemory, handleCount);
  }
}

/// Dump results
class DumpResults {
  final Map<String, Owner> _owners;

  /// Total memory used.
  final int totalMemory;

  /// Total handle count.
  final int handleCount;

  DumpResults._(this._owners, [this.totalMemory, this.handleCount]);

  /// Sort the handles by their memory.
  List<Owner> sort() {
    var sortedOwners = <Owner>[];
    _owners.values.toList()
      ..sort((a, b) => b.memory.compareTo(a.memory))
      ..forEach((owner) {
        sortedOwners.add(owner);
      });

    return sortedOwners;
  }

  /// A Map containing all the owners names linked to the [Owner] objects.
  Map<String, Owner> get owners => _owners;

  /// Compare two DumpResults
  factory DumpResults.compare(DumpResults dump1, DumpResults dump2) {
    var owners1 = dump1.owners;
    var owners2 = dump2.owners;
    owners1.forEach((k, v) => v._changed = !owners2.containsValue(v));
    return DumpResults._(owners1, dump1.totalMemory, dump1.handleCount);
  }
}

/// Owner
class Owner {
  /// Owner's name,
  final String owner;

  /// Map containing all the handles names and their count.
  Map<String, int> types = <String, int>{};

  /// The total handle count.
  int count = 1;

  /// Memory used.
  int memory;

  bool _changed = false;

  /// True if the owner was changed.
  /// See [DumpResults.compare]
  bool get changed => _changed;

  /// Initialize Owner.
  Owner(this.owner, String type, this.memory) {
    types[type] = 1;
  }

  static const _mapEquality = MapEquality();

  @override
  // ignore: type_annotate_public_apis, avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(other) =>
      other is Owner &&
      _mapEquality.equals(types, other.types) &&
      count == other.count &&
      memory == other.memory;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => hash3(types, count, memory);

  @override
  String toString() {
    var sortedKeys = types.keys.toList(growable:false)
      ..sort((k1, k2) => types[k1].compareTo(types[k2]));
    var sortedMap = LinkedHashMap
        .fromIterable(sortedKeys, key: (k) => k, value: (k) => types[k]);
    var type = sortedMap.keys.first;

    print(sortedMap);
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
