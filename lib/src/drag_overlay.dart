import 'package:flutter/material.dart';

class DragOverlay extends StatelessWidget {
  DragOverlay({
    @required this.child,
    @required this.elevation,
    @required this.translation,
    @required this.itemStart,
    @required this.itemExtent,
    @required RenderBox listBox,
    @required Axis scrollDirection,
  })  : this.axisBuilder = AxisOverlayBuilder(scrollDirection),
        this.listPos = listBox.localToGlobal(Offset.zero),
        this.listSize = listBox.size;

  final Widget child;
  final Offset listPos;
  final Size listSize;
  final double elevation;
  final double translation;
  final double itemStart;
  final double itemExtent;
  final AxisOverlayBuilder axisBuilder;

  @override
  Widget build(BuildContext context) {
    return axisBuilder.builGlobalPos(
      overlay: this,
      child: ClipRect(
        child: Stack(children: [
          axisBuilder.buildLocalPos(
              overlay: this,
              child: Transform.translate(
                offset: axisBuilder.buildTransOffset(translation),
                child: Material(
                  elevation: elevation,
                  child: child,
                ),
              ))
        ]),
      ),
    );
  }
}

abstract class AxisOverlayBuilder {
  AxisOverlayBuilder._();

  Positioned builGlobalPos({DragOverlay overlay, Widget child});
  Positioned buildLocalPos({DragOverlay overlay, Widget child});
  Offset buildTransOffset(double translation);

  factory AxisOverlayBuilder(Axis scrollDirection) =>
      scrollDirection == Axis.vertical
          ? _VerticalBuilder()
          : _HorizontalBuilder();
}

class _VerticalBuilder extends AxisOverlayBuilder {
  _VerticalBuilder() : super._();

  @override
  Positioned builGlobalPos({DragOverlay overlay, Widget child}) {
    return Positioned(
      top: overlay.listPos.dy,
      height: overlay.listSize.height,
      left: 0.0,
      right: 0.0,
      child: child,
    );
  }

  @override
  Positioned buildLocalPos({DragOverlay overlay, Widget child}) {
    return Positioned(
      top: overlay.itemStart,
      height: overlay.itemExtent,
      left: overlay.listPos.dx,
      width: overlay.listSize.width,
      child: child,
    );
  }

  @override
  Offset buildTransOffset(double translation) => Offset(0.0, translation);
}

class _HorizontalBuilder extends AxisOverlayBuilder {
  _HorizontalBuilder() : super._();

  @override
  Positioned builGlobalPos({DragOverlay overlay, Widget child}) {
    return Positioned(
      top: 0.0,
      bottom: 0.0,
      left: overlay.listPos.dx,
      width: overlay.listSize.width,
      child: child,
    );
  }

  @override
  Positioned buildLocalPos({DragOverlay overlay, Widget child}) {
    return Positioned(
      left: overlay.itemStart,
      width: overlay.itemExtent,
      top: overlay.listPos.dy,
      height: overlay.listSize.height,
      child: child,
    );
  }

  @override
  Offset buildTransOffset(double translation) => Offset(translation, 0.0);
}
