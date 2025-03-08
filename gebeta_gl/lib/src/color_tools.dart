part of '../gebeta_gl.dart';

extension MapLibreColorConversion on Color {
  String toHexStringRGB() {
    final red = r.round().toRadixString(16).padLeft(2, '0');
    final green = g.round().toRadixString(16).padLeft(2, '0');
    final blue = b.round().toRadixString(16).padLeft(2, '0');
    return '#$red$green$blue';
  }
}
