class DragItemStatus {
  const DragItemStatus._(this.name);

  final String name;

  static const BEFORE = DragItemStatus._('BEFORE');
  static const AFTER = DragItemStatus._('AFTER');
  static const HOVER = DragItemStatus._('HOVER');
  static const SETTLED = DragItemStatus._('SETTLED');

  factory DragItemStatus(int currentIndex, int hoverIndex) {
    if (hoverIndex == null) return DragItemStatus.SETTLED;
    if (currentIndex == hoverIndex) return DragItemStatus.HOVER;
    if (currentIndex < hoverIndex) return DragItemStatus.BEFORE;
    if (currentIndex > hoverIndex) return DragItemStatus.AFTER;
    throw Exception('Cannot determine DragItemStatus. ' +
        'Indices were: $currentIndex (current), $hoverIndex (hover).');
  }

  @override
  String toString() => '$runtimeType.$name';
}
