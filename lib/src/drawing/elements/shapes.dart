import 'dart:math';
import 'dart:ui';

import 'package:lottie_flutter/src/animations.dart';
import 'package:lottie_flutter/src/drawing/drawing.dart';
import 'package:lottie_flutter/src/drawing/elements/paths.dart';
import 'package:lottie_flutter/src/utils.dart';
import 'package:lottie_flutter/src/values.dart';
import 'package:lottie_flutter/src/drawing/drawing_layers.dart';

import 'package:vector_math/vector_math_64.dart';

abstract class _PolygonDrawable extends AnimationDrawable
    implements PathContent {
  bool _isPathValid = false;
  TrimPathDrawable _trimPathDrawable;
  Path _path = new Path();

  _PolygonDrawable(String name, Repaint repaint, BaseLayer layer)
      : super(name, repaint, layer);

  @override
  Path get path {
    if (_isPathValid) {
      return _path;
    }

    _createPath();

    if (_trimPathDrawable != null) {
      _path = applyScaledTrimPathIfNeeded(_path, _trimPathDrawable.start,
          _trimPathDrawable.end, _trimPathDrawable.offset);
    }

    _isPathValid = true;
    return _path;
  }

  @override
  void invalidate() {
    _isPathValid = false;
    super.invalidate();
  }

  @override
  void setContents(List<Content> contentsBefore, List<Content> contentsAfter) {
    for (Content content in contentsBefore) {
      if (content is TrimPathDrawable &&
          content.type == ShapeTrimPathType.Simultaneously) {
        _trimPathDrawable = content;
        _trimPathDrawable.addListener(onValueChanged);
      }
    }
  }

  void _createPath();
}

///
/// CircleDrawable
///
class EllipseDrawable extends _PolygonDrawable {
  static const double CONTROL_POINT_PERCENTAGE = 0.55228;

  final BaseKeyframeAnimation<dynamic, Offset> _sizeAnimation;
  final BaseKeyframeAnimation<dynamic, Offset> _positionAnimation;

  final bool _isReversed;

  EllipseDrawable(String name, Repaint repaint, this._sizeAnimation,
      this._positionAnimation, this._isReversed, BaseLayer layer)
      : super(name, repaint, layer) {
    addAnimation(_sizeAnimation);
    addAnimation(_positionAnimation);
  }

  @override
  void _createPath() {
    final Offset size = _sizeAnimation.value;
    final double halfWidth = size.dx / 2.0;
    final double halfHeight = size.dy / 2.0;
    //TODO: handle bounds

    final double cpW = halfWidth * CONTROL_POINT_PERCENTAGE;
    final double cpH = halfHeight * CONTROL_POINT_PERCENTAGE;

    _path.reset();
    if (_isReversed) {
      _path.moveTo(0.0, -halfHeight);
      _path.cubicTo(0 - cpW, -halfHeight, -halfWidth, 0 - cpH, -halfWidth, 0.0);
      _path.cubicTo(-halfWidth, 0 + cpH, 0 - cpW, halfHeight, 0.0, halfHeight);
      _path.cubicTo(0 + cpW, halfHeight, halfWidth, 0 + cpH, halfWidth, 0.0);
      _path.cubicTo(halfWidth, 0 - cpH, 0 + cpW, -halfHeight, 0.0, -halfHeight);
    } else {
      _path.moveTo(0.0, -halfHeight);
      _path.cubicTo(0 + cpW, -halfHeight, halfWidth, 0 - cpH, halfWidth, 0.0);
      _path.cubicTo(halfWidth, 0 + cpH, 0 + cpW, halfHeight, 0.0, halfHeight);
      _path.cubicTo(0 - cpW, halfHeight, -halfWidth, 0 + cpH, -halfWidth, 0.0);
      _path.cubicTo(
          -halfWidth, 0 - cpH, 0 - cpW, -halfHeight, 0.0, -halfHeight);
    }

    _path = _path.shift(_positionAnimation.value);
    _path.close();
  }
}

///
/// RectangleContent
///
class RectangleDrawable extends _PolygonDrawable {
  final BaseKeyframeAnimation<dynamic, Offset> _positionAnimation;
  final BaseKeyframeAnimation<dynamic, Offset> _sizeAnimation;
  final BaseKeyframeAnimation<dynamic, double> _cornerRadiusAnimation;

  RectangleDrawable(
    String name,
    Repaint repaint,
    this._positionAnimation,
    this._sizeAnimation,
    this._cornerRadiusAnimation,
    BaseLayer layer,
  ) : super(name, repaint, layer) {
    addAnimation(_sizeAnimation);
    addAnimation(_positionAnimation);
    addAnimation(_cornerRadiusAnimation);
  }

  @override
  void _createPath() {
    final Offset size = _sizeAnimation.value;
    final Offset position = _positionAnimation.value;
    final double halfWidth = size.dx / 2.0;
    final double halfHeight = size.dy / 2.0;
    final double radius =
        min(_cornerRadiusAnimation?.value ?? 0.0, min(halfWidth, halfHeight));
    _path.reset();

    final RRect rect = new RRect.fromLTRBR(
      position.dx - halfHeight,
      position.dy - halfWidth,
      size.dx - halfHeight,
      size.dy - halfWidth,
      new Radius.circular(radius),
    );
    _path.addRRect(rect);
  }
}

///
/// ShapeDrawable
///
class ShapeDrawable extends _PolygonDrawable {
  final BaseKeyframeAnimation<dynamic, Path> _animation;

  ShapeDrawable(
    String name,
    Repaint repaint,
    this._animation,
    BaseLayer layer,
  ) : super(name, repaint, layer) {
    addAnimation(_animation);
  }

  @override
  void _createPath() {
    _path = _animation.value;
    _path.fillType = PathFillType.evenOdd;
  }
}
