import 'dart:math' as math;
import 'package:vector_math/vector_math.dart';

const OCTAVES = 6;

double fract(double x) {
  return x - x.floor();
}

double random(Vector2 st) {
  return fract(math.sin(dot2(st.xy, Vector2(12.9898, 78.233))) * 43758.5453123);
}

double noise(Vector2 st) {
  Vector2 i = Vector2(st.x.floor().toDouble(), st.y.floor().toDouble());
  Vector2 f = Vector2(fract(st.x), fract(st.y));

  double a = random(i + Vector2(0.0, 0.0));
  double b = random(i + Vector2(1.0, 0.0));
  double c = random(i + Vector2(0.0, 1.0));
  double d = random(i + Vector2(1.0, 1.0));

  Vector2 u = Vector2(
    smoothStep(0.0, 1.0, f.x),
    smoothStep(0.0, 1.0, f.y),
  );

  double result =
      mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;

  return result;
}

double fbm(Vector2 st) {
  double value = 0.0;
  double amplitude = .5;

  for (int i = 0; i < OCTAVES; i++) {
    value += amplitude * noise(st);
    st *= 2.0;
    amplitude *= 0.5;
  }
  return value;
}
