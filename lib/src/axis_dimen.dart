import 'package:flutter/material.dart';

mixin AxisDimen {
  Axis get axis;
  double axisOffset(Offset offset) =>
      axis == Axis.vertical ? offset.dy : offset.dx;
  double axisSize(Size size) =>
      axis == Axis.vertical ? size.height : size.width;
}
