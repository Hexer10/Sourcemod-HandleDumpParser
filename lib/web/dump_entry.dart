///
class HistoryEntry {
  ///
  final int index;

  ///
  final int memory;

  ///
  final int handles;

  ///
  final String data;

  ///
  const HistoryEntry(this.index, this.memory, this.handles, this.data)
      : assert(index != null),
        assert(memory != null),
        assert(handles != null),
        assert(data != null);
}
