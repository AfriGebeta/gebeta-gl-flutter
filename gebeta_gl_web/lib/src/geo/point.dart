import 'package:gebeta_gl_web/src/interop/interop.dart';

class Point extends JsObjectWrapper<PointJsImpl> {
  num get x => jsObject.x;

  num get y => jsObject.y;

  factory Point(
    num x,
    num y,
  ) =>
      Point.fromJsObject(PointJsImpl(
        x: x,
        y: y,
      ));

  /// Creates a new LngLat from a [jsObject].
  Point.fromJsObject(super.jsObject) : super.fromJsObject();
}
