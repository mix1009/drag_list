import 'package:flutter/material.dart';

import 'axis_dimen.dart';
import 'drag_list_state.dart';

typedef Widget DragItemBuilder<T>(
    BuildContext context, DragItem<T> item, Widget handle);
typedef Widget DragHandleBuilder(BuildContext context);

typedef Widget FeedbackDragItemBuilder<T>(BuildContext context,
    DragItem<T> item, Widget handle, Animation<double> transition);
typedef Widget FeedbackDragHandleBuilder(
    BuildContext context, Animation<double> transition);

typedef Widget BareDragItemBuilder<T>(BuildContext context, DragItem<T> item);
typedef Widget BareFeedbackDragItemBuilder<T>(
    BuildContext context, DragItem<T> item, Animation<double> transition);

typedef void ItemReorderCallback(int from, int to);

class DragItem<T> {
  final T value;
  final int itemIndex;
  final int dispIndex;

  DragItem(this.value, this.itemIndex, this.dispIndex);

  @override
  String toString() =>
      "DragItem<$T>(value: $value, itemIndex: $itemIndex, dispIndex: $dispIndex)";
}

class DragList<T> extends StatefulWidget with AxisDimen {
  /// List of items displayed in the list.
  final List<T> items;

  /// Extent of each item widget in the list. Corresponds to
  /// width/height in case of horizontal/vertical axis orientation.
  final double itemExtent;

  /// Relative position within item widget that corresponds to the center of
  /// handle, where -1.0 stands for beginning and 1.0 for end of the item.
  final double handleAlignment;

  /// Duration of raise and drop animation of dragged item.
  final Duration animDuration;

  /// Duration between list item touch and drag start.
  final Duration dragDelay;

  /// Builder function that creates handle widget for each element of the list.
  final DragHandleBuilder handleBuilder;

  /// Builder function that creates widget for each element of the list.
  final DragItemBuilder<T> itemBuilder;

  /// Builder function that creates handle widget of currently dragged item.
  /// If null, [handleBuilder] function will be used instead.
  final FeedbackDragHandleBuilder feedbackHandleBuilder;

  /// Builder function that creates widget of currently dragged item.
  /// If null, [builder] function will be used instead.
  final FeedbackDragItemBuilder<T> feedbackItemBuilder;

  /// Callback function that invokes if dragged item changed
  /// its index and drag action is ended. By default this
  /// will swap start and end position in [items] list.
  final ItemReorderCallback onItemReorder;

  /// Axis orientation of the list widget.
  final Axis scrollDirection;

  /// Whether the extent of the scroll view in the scrollDirection
  /// should be determined by the contents being viewed.
  final bool shrinkWrap;

  /// An object that can be used to control the position to which this scroll
  /// view is scrolled.
  final ScrollController controller;

  /// The amount of space by which to inset the children.
  final EdgeInsetsGeometry padding;

  /// How the scroll view should respond to user input.
  final ScrollPhysics physics;

  DragList({
    @required this.items,
    @required this.itemExtent,
    @required this.itemBuilder,
    Key key,
    Duration animDuration,
    Duration dragDelay,
    double handleAlignment,
    Axis scrollDirection,
    bool shrinkWrap,
    FeedbackDragItemBuilder<T> feedbackItemBuilder,
    FeedbackDragHandleBuilder feedbackHandleBuilder,
    DragHandleBuilder handleBuilder,
    this.onItemReorder,
    this.controller,
    this.padding,
    this.physics,
  })  : this.animDuration = animDuration ?? Duration(milliseconds: 300),
        this.dragDelay = dragDelay ?? Duration.zero,
        this.handleAlignment = handleAlignment ?? 0.0,
        this.scrollDirection = scrollDirection ?? Axis.vertical,
        this.shrinkWrap = shrinkWrap ?? false,
        this.handleBuilder = handleBuilder ??=
            ((_) => Center(child: Icon(Icons.drag_handle, size: 24.0))),
        this.feedbackItemBuilder = feedbackItemBuilder ??=
            ((context, item, handle, _) => itemBuilder(context, item, handle)),
        this.feedbackHandleBuilder =
            feedbackHandleBuilder ??= ((context, _) => handleBuilder(context)),
        super(key: key) {
    assert(this.handleAlignment >= -1.0 && this.handleAlignment <= 1.0,
        'Handle alignment has to be in bounds (-1, 1) inclusive. Passed value was: $handleAlignment.');
  }

  DragList.handleless({
    @required List<T> items,
    @required double itemExtent,
    @required BareDragItemBuilder<T> itemBuilder,
    Key key,
    BareFeedbackDragItemBuilder<T> feedbackItemBuilder,
    Duration animDuration,
    Duration dragDelay,
    double handleAlignment,
    Axis scrollDirection,
    ScrollPhysics physics,
    bool shrinkWrap,
    ItemReorderCallback onItemReorder,
  }) : this(
          items: items,
          itemExtent: itemExtent,
          key: key,
          scrollDirection: scrollDirection,
          physics: physics,
          shrinkWrap: shrinkWrap,
          animDuration: animDuration,
          dragDelay: dragDelay ?? Duration(milliseconds: 300),
          onItemReorder: onItemReorder,
          handleBuilder: (_) => Container(),
          itemBuilder: (context, item, handle) => Stack(children: [
            itemBuilder(context, item),
            Positioned.fill(child: handle),
          ]),
          feedbackItemBuilder: (context, item, _, transition) =>
              feedbackItemBuilder(context, item, transition),
        );

  @override
  DragListState<T> createState() => DragListState<T>();

  @override
  Axis get axis => scrollDirection;
}
