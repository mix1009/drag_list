import 'package:flutter/material.dart';

import 'drag_item_status.dart';

typedef Widget DragListItemBuilder(BuildContext context, Widget handle);
typedef void OffsetChanged(Offset value);

class DragListItem extends StatefulWidget {
  DragListItem({
    @required Key key,
    @required this.builder,
    @required this.handle,
    @required this.onDragStop,
    @required this.onDragUpdate,
    @required this.onDragTouch,
    @required this.extent,
    @required this.status,
    @required this.animDuration,
    @required this.scrollDirection,
  }) : super(key: key);

  final DragListItemBuilder builder;
  final Widget handle;
  final OffsetChanged onDragStop;
  final OffsetChanged onDragUpdate;
  final OffsetChanged onDragTouch;
  final double extent;
  final DragItemStatus status;
  final Duration animDuration;
  final Axis scrollDirection;

  @override
  DragListItemState createState() => DragListItemState();
}

class DragListItemState extends State<DragListItem>
    with SingleTickerProviderStateMixin {
  AnimationController _animator;
  Animation<double> _transAnim;
  DragItemStatus _status;
  DragItemStatus _prevStatus;

  @override
  void initState() {
    super.initState();
    _status = DragItemStatus.SETTLED;
    _animator = AnimationController(
      vsync: this,
      value: 1.0,
      duration: widget.animDuration,
    );
    _transAnim = _animator.drive(Tween(begin: 0.0, end: 0.0));
  }

  @override
  void dispose() {
    _animator.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DragListItem old) {
    super.didUpdateWidget(old);
    if (widget.status != old.status) {
      _prevStatus = _status;
      _status = widget.status;
      if (_didChangeIndex) {
        _updateTransAnim();
      }
    }
  }

  bool get _didChangeIndex =>
      (_prevStatus == DragItemStatus.AFTER &&
          _status == DragItemStatus.BEFORE) ||
      (_prevStatus == DragItemStatus.BEFORE && _status == DragItemStatus.AFTER);

  void _updateTransAnim() {
    final trans = widget.extent * (_status == DragItemStatus.BEFORE ? 1 : -1);
    _transAnim = Tween(begin: trans, end: 0.0)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_animator);
    _animator.forward(from: 1 - _animator.value);
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _status == DragItemStatus.HOVER ? 0.0 : 1.0,
      child: AbsorbPointer(
        absorbing: _status == DragItemStatus.HOVER,
        child: AnimatedBuilder(
          animation: _transAnim,
          child: widget.builder(context, _wrapHandle()),
          builder: (_, child) => Transform.translate(
            offset: widget.scrollDirection == Axis.vertical
                ? Offset(0.0, _transAnim.value)
                : Offset(_transAnim.value, 0.0),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _wrapHandle() {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerCancel: (it) => widget.onDragStop(it.position),
      onPointerUp: (it) => widget.onDragStop(it.position),
      onPointerDown: (it) => widget.onDragTouch(it.position),
      onPointerMove: (it) => widget.onDragUpdate(it.delta),
      child: widget.handle,
    );
  }
}
