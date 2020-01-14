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
    var reverse = _owners.map((k, v) => MapEntry(v, k));

    var sortedOwners = <Owner>[];
    reverse.keys.toList()
      ..sort((a, b) => b.memory.compareTo(a.memory))
      ..forEach((owner) {
        sortedOwners.add(owner);
      });

    return sortedOwners;
  }

  /// A Map containing all the owners names linked to the [Owner] objects.
  Map<String, Owner> get owners => _owners;
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

  /// Initialize Owner.
  Owner(this.owner, String type, this.memory) {
    types[type] = 1;
  }

  @override
  String toString() {
    var reverse = types.map((k, v) => MapEntry(v, k));
    var sortedKeys = reverse.keys.toList()..sort((a, b) => a > b ? a : b);
    var type = reverse[sortedKeys[0]].toString().trim();

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
