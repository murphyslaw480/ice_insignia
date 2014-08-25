module graphics.sprite;

import std.string;
import std.array;
import std.conv;
import std.algorithm : min;
import allegro;
import geometry.vector;
import graphics.texture;
import graphics.color;
import util.config;
import util.math;

/// displays a single frame of a texture
class Sprite {
  this(string spriteName, Color tint = Color.white) {
    assert(spriteName in _spriteData.entries, spriteName ~ " is not defined in " ~ Paths.spriteData);
    auto data = _spriteData.entries[spriteName];
    _name = spriteName;
    _texture = getTexture(data["texture"]);
    _row = to!int(data["row"]);
    _col = to!int(data["col"]);
    _tint = tint;
    assert(_row >= 0 && _col >= 0 && _row < _texture.numRows && _col < _texture.numCols,
        format("sprite coord %d, %d is out of bounds", _row, _col));
    _baseScale = to!int(data.get("baseScale", "1"));
  }

  this(Texture spriteSheet, int spriteIdx, float baseScale = 1) {
    _texture = spriteSheet;
    _row = spriteIdx / _texture.numCols;
    _col = spriteIdx % _texture.numCols;
    assert(_row >= 0 && _col >= 0 && _row < _texture.numRows && _col < _texture.numCols,
        format("sprite coord %d, %d is out of bounds", _row, _col));
    _baseScale = baseScale;
  }

  void flash(float time, Color flashColor) {
    _flashTimer = 0;
    _totalFlashTime = time;
    _colorSpectrum = [_tint, flashColor, _tint];
  }

  void fade(float time, Color color) {
    _flashTimer = 0;
    _totalFlashTime = time;
    _colorSpectrum = [_tint, color];
  }

  void shift(Vector2i offset, float speed) {
    _jiggleEffect = JiggleEffect(Vector2i.Zero, offset, speed, 1);
  }

  void update(float time) {
    if (_totalFlashTime > 0) {
      _flashTimer += time;
      if (_flashTimer > _totalFlashTime) {
        _totalFlashTime = 0;
        _flashTimer = 0;
        _tint = _colorSpectrum[$ - 1];
      }
      else {
        _tint = lerp(_colorSpectrum, _flashTimer / _totalFlashTime);
      }
    }
    _jiggleEffect.update(time);
  }

  void draw(Vector2i pos) {
    auto adjustedPos = pos + _jiggleEffect.offset;
    debug {
      import std.stdio;
      if (_jiggleEffect.active) {
      writeln(_jiggleEffect.offset, adjustedPos);
      }
    }
    _texture.draw(_row, _col, adjustedPos, totalScale, _tint, _angle);
  }

  @property {
    /// unique name used to look up sprite data
    string name() { return _name; }
    /// width of the sprite after scaling (px)
    int width() { return cast(int) (_texture.frameWidth * totalScale); }
    /// height of the sprite after scaling (px)
    int height() { return cast(int) (_texture.frameHeight * totalScale); }
    /// width and height of sprite after scaling
    auto size() { return Vector2i(width, height); }
    /// tint color of the sprite
    auto tint()                    { return _tint; }
    auto tint(Color color) {
      _totalFlashTime = 0;
      return _tint = color;
    }
    /// get the rotation angle of the sprite (radians)
    auto angle()            { return _angle; }
    auto angle(float angle) { return _angle = angle; }
    /// the scale factor of the sprite
    auto scale()            { return _scaleFactor; }
    auto scale(float scale) { return _scaleFactor = scale; }
    /// the total scale factor from the original image
    auto totalScale() { return _scaleFactor * _baseScale; }

    bool isJiggling() { return _jiggleEffect.active; }
  }

  protected:
  int _row, _col;

  private:
  string _name;
  Texture _texture;
  const float _baseScale;
  float _scaleFactor  = 1;
  float _angle        = 0;
  Color _tint = Color.white;

  float _flashTimer, _totalFlashTime;
  Color[] _colorSpectrum;

  JiggleEffect _jiggleEffect;
}
private:
struct JiggleEffect {
  this(Vector2i start, Vector2i end, float frequency, int repetitions) {
    assert(frequency > 0, "cannot jiggle sprite with frequency <= 0");
    _start = start;
    _end = end;
    _period = 1 / frequency;
    _repetitions = repetitions;
  }

  void update(float time) {
    _lerpFactor += time / _period;
    if (_lerpFactor > 2) {
      _lerpFactor = 0;
      --_repetitions;
    }
  }

  @property {
    bool active() { return _repetitions > 0; }

    Vector2i offset() {
      if (!active) {
        return Vector2i.Zero;
      }
      else if (_lerpFactor <= 1) {
        return lerp(_start, _end, _lerpFactor);
      }
      else if (_lerpFactor <= 2) {
        return lerp(_end, _start, _lerpFactor - 1);
      }
      else {
        assert(0, "internal failure : _lerpFactor > 2");
      }
    }
  }

  private:
  Vector2i _start, _end;
  float _period;
  float _lerpFactor = 0;
  int _repetitions = 0;
}

ConfigData _spriteData;

static this() {
  _spriteData = loadConfigFile(Paths.spriteData);
}
