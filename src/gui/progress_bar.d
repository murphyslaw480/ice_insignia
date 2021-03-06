module gui.progress_bar;

import std.math : abs;
import std.string : format;
import util.math : lerp;
import graphics.all;
import geometry.all;

class ProgressBar(T : real) {
  enum DrawText { fraction, value, none }
  this(Rect2i area, T currentVal, T maxVal, Color fgColor, Color bgColor = Color.clear,
      Color textColor = Color.black, DrawText drawText = DrawText.fraction, Font font = defaultFont)
  {
    _area = area;
    _filledArea = _area;
    _maxVal = maxVal;
    _font = font;
    _fgColor = fgColor;
    _bgColor = bgColor;
    _textColor = textColor;
    _drawText = drawText;
    val = currentVal;
  }

  @property {
    auto bounds() { return _area; }
    T val() { return _val; }
    void val(T val) {
      _val = val;
      resetBarSize();
    }
    T maxVal() { return _maxVal; }
    void maxVal(T newMax) {
      _maxVal = newMax;
      resetBarSize();
    }
    bool isTransitioning() { return _totalTransitionTime != 0; }
  }

  void update(float time) {
    if (_totalTransitionTime != 0) {
      _transitionTimer += time;
      val = _transitionStart.lerp(_transitionTarget, _transitionTimer / _totalTransitionTime);
      if (_transitionTimer > _totalTransitionTime) {
        _totalTransitionTime = 0;
      }
    }
  }

  void transition(T start, T end, float speed) {
    _transitionStart = start;
    _transitionTarget = end;
    _transitionTimer = 0;
    _totalTransitionTime = abs(end - start) / speed;
  }

  void transition(T end, float speed) {
    transition(val, end, speed);
  }

  void draw() {
    _area.drawFilled(_bgColor);
    _filledArea.drawFilled(_fgColor);
    _font.draw(_text, _area.topLeft - Vector2i.UnitY, _textColor);
  }

  private:
  Rect2i _area; /// total bar
  T _maxVal, _val;
  DrawText _drawText;
  Font _font;
  Color _bgColor, _fgColor, _textColor;

  Rect2i _filledArea; /// area filled in
  string _text;

  // for transition effect
  T _transitionStart, _transitionTarget;
  float _transitionTimer, _totalTransitionTime = 0;

  static Font defaultFont() {
    return getFont("default_progress_bar_font");
  }

  void resetBarSize() {
    _filledArea.width = cast(int) (_area.width * cast(float)val / maxVal);
    final switch(_drawText) {
      case DrawText.fraction:
        _text = format("%d/%d", val, maxVal);
        break;
      case DrawText.value:
        _text = format("%d", val);
        break;
      case DrawText.none:
        _text = "";
        break;
    }
  }
}
