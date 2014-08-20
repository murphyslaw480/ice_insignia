module graphics.color;

import allegro;

/// common colors
enum Color {
  white = ALLEGRO_COLOR(1, 1, 1, 1),
  black = ALLEGRO_COLOR(0, 0, 0, 1),
  red   = ALLEGRO_COLOR(1, 0, 0, 1),
  green = ALLEGRO_COLOR(0, 1, 0, 1),
  blue  = ALLEGRO_COLOR(0, 0, 1, 1),
}

/// shortcut to create colors from float values
ALLEGRO_COLOR color(float r, float g, float b, float a = 1.0f) {
  return al_map_rgba_f(r, g, b, a);
}

/// shortcut to create colors from unsigned byte values
ALLEGRO_COLOR ucolor(ubyte r, ubyte g, ubyte b, ubyte a = 255u) {
  return al_map_rgba(r, g, b, a);
}

unittest {
  import std.math : approxEqual;
  // float color with implied alpha
  auto c1 = color(0.5, 1, 0.3);
  assert(c1.r.approxEqual(0.5f));
  assert(c1.g.approxEqual(1.0f));
  assert(c1.b.approxEqual(0.3f));
  assert(c1.a.approxEqual(1.0f));

  // float color with specified alpha
  auto c2 = color(0, 0, 0, 0.5);
  assert(c2.r.approxEqual(0));
  assert(c2.g.approxEqual(0));
  assert(c2.b.approxEqual(0));
  assert(c2.a.approxEqual(0.5f));

  // unsigned color with implied alpha
  auto c3 = ucolor(100, 255, 0);
  assert(c3.r.approxEqual(100 / 255f));
  assert(c3.g.approxEqual(255 / 255f));
  assert(c3.b.approxEqual(  0 / 255f));
  assert(c3.a.approxEqual(255 / 255f));

  // unsigned color with specified alpha
  auto c4 = ucolor(0, 0, 255, 127);
  assert(c4.r.approxEqual(  0 / 255f));
  assert(c4.g.approxEqual(  0 / 255f));
  assert(c4.b.approxEqual(255 / 255f));
  assert(c4.a.approxEqual(127 / 255f));
}
