import 'dart:async';
import 'dart:math';

import 'package:async/async.dart';
import 'package:flutter/material.dart';

import 'drag_item_status.dart';
import 'drag_list.dart';
import 'drag_list_item.dart';
import 'drag_overlay.dart';

class DragListState<T> extends State<DragList<T>>
    with SingleTickerProviderStateMixin {
  int _dragIndex;
  int _hoverIndex;
  bool _isDropping;
  bool _isDragging;
  double _overdragDelta;
  double _totalDragDelta;
  double _boundedDragDelta;
  double _touchStartOffset;
  double _dragStartOffset;
  double _lastFrameAnimDelta;
  double _lastTouchOffset;
  double _touchScrollOffset;
  Offset _touchStartPoint;
  Offset _dragStartPoint;
  CancelableOperation _startDragJob;
  StreamSubscription _overdragSub;
  OverlayEntry _dragOverlay;
  ScrollController _scrollController;
  ScrollController _innerController;
  Map<int, GlobalKey> _itemKeys;

  AnimationController _animator;
  Animation<double> _baseAnim;
  Animation<double> _deltaAnim;
  Animation<double> _elevAnim;
  Animation<double> _transAnim;

  RenderBox get _listBox => context.findRenderObject();
  bool get _isDragSettled => _dragIndex == null;
  bool get _dragsForwards => _boundedDragDelta > 0;
  double get _scrollOffset => _scrollController.offset;
  double get _listSize => widget.axisSize(_listBox.size);
  double get _handleCenterOffset =>
      widget.itemExtent * (1 + widget.handleAlignment) / 2;

  @override
  void didUpdateWidget(DragList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateScrollController();
  }

  @override
  void initState() {
    super.initState();
    _innerController = ScrollController();
    _updateScrollController();
    _clearState();
    _itemKeys = {};
    _animator = AnimationController(vsync: this, duration: widget.animDuration)
      ..addListener(_onAnimUpdate)
      ..addStatusListener(_onAnimStatus);
    _baseAnim = _animator.drive(CurveTween(curve: Curves.easeInOut));
    _elevAnim = _baseAnim.drive(Tween(begin: 0.0, end: 2.0));
    _dragOverlay = OverlayEntry(builder: _buildOverlay);
  }

  void _updateScrollController() {
    _scrollController = widget.controller ?? _innerController;
  }

  void _onAnimUpdate() {
    final toAdd = _deltaAnim.value - _lastFrameAnimDelta;
    _lastFrameAnimDelta = _deltaAnim.value;
    _onDeltaChanged(toAdd);
  }

  void _onAnimStatus(AnimationStatus status) {
    if (!_animator.isAnimating) {
      _lastFrameAnimDelta = 0.0;
      if (_animator.isDismissed) {
        _onDragSettled();
      }
    }
  }

  void _onDragSettled() {
    if (_dragIndex != _hoverIndex) {
      (widget.onItemReorder ?? _defaultOnItemReorder)
          .call(_dragIndex, _hoverIndex);
      _swapItemKeys(_dragIndex, _hoverIndex);
    }
    _dragOverlay.remove();
    setState(_clearState);
    // Jump to current offset to make sure _drag in ScrollableState has been disposed.
    // Happened every time when list view was touched after an item had been dragged.
    _scrollController.jumpTo(_scrollOffset);
  }

  void _swapItemKeys(int from, int to) {
    final sign = from < to ? 1 : -1;
    final temp = _itemKeys[from];
    List.generate((to - from).abs(), (it) => from + it * sign)
        .forEach((it) => _itemKeys[it] = _itemKeys[it + sign]);
    _itemKeys[to] = temp;
  }

  void _defaultOnItemReorder(int from, int to) =>
      widget.items.insert(to, widget.items.removeAt(from));

  void _clearState() {
    _overdragDelta = 0.0;
    _lastFrameAnimDelta = 0.0;
    _totalDragDelta = 0.0;
    _boundedDragDelta = 0.0;
    _touchScrollOffset = 0.0;
    _isDropping = false;
    _isDragging = false;
    _lastTouchOffset = null;
    _touchStartOffset = null;
    _dragStartOffset = null;
    _dragIndex = null;
    _hoverIndex = null;
    _startDragJob = null;
    _dragStartPoint = null;
    _touchStartPoint = null;
  }

  Widget _buildOverlay(BuildContext context) {
    return DragOverlay(
      scrollDirection: widget.scrollDirection,
      itemStart: _touchStartOffset - _dragStartOffset + _boundedDragDelta,
      listBox: _listBox,
      itemExtent: widget.itemExtent,
      translation: _transAnim.value,
      elevation: _elevAnim.value,
      child: widget.feedbackItemBuilder(
        context,
        DragItem(widget.items[_dragIndex], _dragIndex, _hoverIndex),
        widget.feedbackHandleBuilder(context, _animator),
        _animator,
      ),
    );
  }

  @override
  void dispose() {
    _innerController.dispose();
    _animator.dispose();
    _clearDragJob();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: _isDragSettled ? widget.physics : NeverScrollableScrollPhysics(),
      padding: widget.padding,
      scrollDirection: widget.scrollDirection,
      shrinkWrap: widget.shrinkWrap,
      itemExtent: widget.itemExtent,
      controller: _scrollController,
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final itemIndex = _calcItemIndex(index);
        return _buildDragItem(context, itemIndex, index);
      },
    );
  }

  int _calcItemIndex(int index) {
    if (_dragIndex == _hoverIndex) {
      return index;
    }
    if (index == _hoverIndex) {
      return _dragIndex;
    }
    if (index > _hoverIndex && index <= _dragIndex) {
      return index - 1;
    }
    if (index < _hoverIndex && index >= _dragIndex) {
      return index + 1;
    }
    return index;
  }

  Widget _buildDragItem(BuildContext context, int itemIndex, int dispIndex) {
    return DragListItem(
      key: _itemKeys.putIfAbsent(itemIndex, () => GlobalKey()),
      handle: widget.handleBuilder(context),
      builder: (context, handle) => widget.itemBuilder(context,
          DragItem(widget.items[itemIndex], itemIndex, dispIndex), handle),
      onDragTouch: (position) => _onItemDragTouch(itemIndex, position),
      onDragStop: (position) => _onItemDragStop(itemIndex, position),
      onDragUpdate: (delta) => _onItemDragUpdate(itemIndex, delta),
      extent: widget.itemExtent,
      animDuration: widget.animDuration,
      scrollDirection: widget.scrollDirection,
      status: DragItemStatus(dispIndex, _hoverIndex),
    );
  }

  void _onItemDragTouch(int index, Offset position) {
    if (_isDragSettled) {
      _lastTouchOffset = widget.axisOffset(_listBox.globalToLocal(position));
      _touchStartPoint = position;
      _dragStartPoint = position;
      _touchScrollOffset = _scrollOffset;
      _scheduleDragStart(index);
    }
  }

  void _scheduleDragStart(int index) {
    _clearDragJob();
    _startDragJob = CancelableOperation.fromFuture(Future.delayed(
      widget.dragDelay,
      () => _onItemDragStart(index),
    ));
  }

  void _onItemDragStart(int index) {
    _isDragging = true;
    _clearDragJob();
    _registerStartPoint(_touchStartPoint);
    Overlay.of(context).insert(_dragOverlay);
    setState(() {
      _dragIndex = index;
      _hoverIndex = index;
    });
    _runRaiseAnim();
  }

  void _registerStartPoint(Offset position) {
    final localPos = _listBox.globalToLocal(position);
    _touchStartOffset =
        widget.axisOffset(localPos) + _touchScrollOffset - _scrollOffset;
    _dragStartOffset = (_touchStartOffset + _scrollOffset) % widget.itemExtent;
  }

  void _runRaiseAnim() {
    _transAnim = _baseAnim.drive(Tween(begin: _calcTranslation(), end: 0.0));
    _deltaAnim = _baseAnim.drive(Tween(begin: 0.0, end: _calcRaiseDelta()));
    _animator.forward();
  }

  double _calcRaiseDelta() {
    final touchToStartDelta =
        widget.axisOffset(_dragStartPoint - _touchStartPoint) +
            _scrollOffset -
            _touchScrollOffset;
    return _dragStartOffset - _handleCenterOffset + touchToStartDelta;
  }

  void _onItemDragStop(int index, Offset position) {
    _isDragging = false;
    _clearDragJob();
    _stopOverdrag();
    if (!_isDragSettled && !_isDropping) {
      _totalDragDelta = _calcBoundedDelta(_totalDragDelta);
      final localPos = _listBox.globalToLocal(position);
      _runDropAnim(localPos);
    }
  }

  void _runDropAnim(Offset stopOffset) {
    _isDropping = true;
    final delta = _calcDropDelta(stopOffset);
    _lastFrameAnimDelta += delta * (1 - _baseAnim.value);
    _deltaAnim = _baseAnim.drive(Tween(begin: delta, end: 0.0));
    final trans = _calcTranslation();
    _transAnim = _baseAnim.drive(Tween(
      begin: trans,
      end: trans * (1 - 1 / _baseAnim.value),
    ));
    _animator.reverse();
  }

  double _calcDropDelta(Offset stopOffset) {
    final rawPos = widget.axisOffset(stopOffset);
    final halfItemStart = widget.itemExtent * widget.handleAlignment / 2;
    final stopPos = rawPos.clamp(halfItemStart, _listSize + halfItemStart);
    final hoverStartPos = _hoverIndex * widget.itemExtent - _scrollOffset;
    return -(stopPos - hoverStartPos - _handleCenterOffset);
  }

  double _calcTranslation() {
    final rawClip = _dragsForwards
        ? 1 - ((_scrollOffset + _listSize) / widget.itemExtent - _hoverIndex)
        : _scrollOffset / widget.itemExtent - _hoverIndex;
    final clip = max(rawClip - 0.5, 0.0) * (_dragsForwards ? 1 : -1);
    return clip * widget.itemExtent;
  }

  void _onItemDragUpdate(int index, Offset delta) {
    _lastTouchOffset += widget.axisOffset(delta);
    if (_startDragJob != null) {
      _updateStartPoint(delta);
    }
    if (!_isDragSettled && !_isDropping) {
      _onDeltaChanged(widget.axisOffset(delta));
    }
  }

  void _updateStartPoint(Offset delta) {
    _dragStartPoint += delta;
    final dragSinceTouch =
        widget.axisOffset(_dragStartPoint - _touchStartPoint).abs();
    if (dragSinceTouch > widget.itemExtent / 2) {
      _clearDragJob();
    }
  }

  void _clearDragJob() {
    if (_startDragJob != null) {
      _startDragJob.cancel();
      _startDragJob = null;
    }
  }

  void _onDeltaChanged(double delta) {
    _updateDelta(delta);
    _updateOverdragScroll();
    if (_overdragSub == null) {
      _updateHoverIndex();
    }
  }

  void _updateDelta(double delta) {
    _totalDragDelta += delta;
    _boundedDragDelta = _calcBoundedDelta(_totalDragDelta);
    Overlay.of(context).setState(() {});
  }

  double _calcBoundedDelta(double delta) {
    final minDelta =
        -_touchStartOffset + _dragStartOffset - widget.itemExtent / 2;
    final maxDelta = minDelta + _listSize;
    return delta.clamp(minDelta, maxDelta);
  }

  void _updateOverdragScroll() {
    final isDraggedBeyond = _dragsForwards
        ? _lastTouchOffset > _listSize - widget.itemExtent / 2
        : _lastTouchOffset < widget.itemExtent / 2;
    if (_overdragSub == null && _isDragging && isDraggedBeyond) {
      _overdragSub = Stream.periodic(Duration(milliseconds: 16))
          .listen((_) => _onOverdragUpdate());
    } else if (_overdragSub != null && !isDraggedBeyond) {
      _stopOverdrag();
    }
  }

  void _onOverdragUpdate() {
    final canScrollMore = _dragsForwards
        ? _scrollOffset < widget.items.length * widget.itemExtent - _listSize
        : _scrollOffset > 0;
    if (canScrollMore) {
      _updateOverdragOffset();
      _updateHoverIndex();
    } else {
      _stopOverdrag();
    }
  }

  void _updateOverdragOffset() {
    final overdragScale = _dragsForwards
        ? 1 - (_listSize - _lastTouchOffset) / (widget.itemExtent / 2)
        : -1 + _lastTouchOffset / (widget.itemExtent / 2);
    final offsetDelta = 6.0 * overdragScale.clamp(-1.0, 1.0);
    _scrollController.jumpTo(_scrollOffset + offsetDelta);
    _overdragDelta += offsetDelta;
  }

  void _updateHoverIndex() {
    final halfExtent = widget.itemExtent / 2 * (_dragsForwards ? 1 : -1);
    final rawIndex = _dragIndex +
        (_boundedDragDelta + halfExtent + _overdragDelta) ~/ widget.itemExtent;
    final index = rawIndex.clamp(0, widget.items.length - 1);
    if (_hoverIndex != index) {
      setState(() => _hoverIndex = index);
    }
  }

  void _stopOverdrag() {
    _overdragSub?.cancel();
    _overdragSub = null;
  }
}
