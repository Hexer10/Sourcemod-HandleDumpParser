/// Sorting order.
enum SortOrder {
  /// Ascending, Highest to lowest.
  ascending,

  /// Descending, Lowest to Highest.
  descending,
}

/// Sorting key.
enum SortKey {
  /// Owner name.
  owner,

  /// Handle total count.
  handles,

  /// Handle type name.
  type,

  /// Memory used.
  memory,
}

/// Sorter.
class Sorter {
  /// Sorting order
  final SortOrder order;

  /// Sorting key
  final SortKey key;

  /// Initialize sorter.
  const Sorter({this.order = SortOrder.ascending, this.key = SortKey.memory});
}
