module util.input;

import std.algorithm : max, min, any;
import allegro;
import geometry.vector;

enum MouseKeymap {
  lmb = 1,
  rmb = 2
}

enum Keymap {
  left  = [ALLEGRO_KEY_A],
  right = [ALLEGRO_KEY_D],
  up    = [ALLEGRO_KEY_W],
  down  = [ALLEGRO_KEY_S],

  confirm = [ALLEGRO_KEY_J],
  cancel  = [ALLEGRO_KEY_K],
  end     = [ALLEGRO_KEY_SPACE],
  faster  = [ALLEGRO_KEY_LSHIFT, ALLEGRO_KEY_RSHIFT],
}

private enum {
  scrollSpeed = 14
}

class InputManager {
  void update(float time) {
    _prevKeyboardState = _curKeyboardState;
    _prevMouseState = _curMouseState;
    al_get_keyboard_state(&_curKeyboardState);
    al_get_mouse_state(&_curMouseState);

    /*
    if (keyHeld(ALLEGRO_KEY_W)) {
      if (_scrollAccumulator.y < -1) { _scrollAccumulator.y = 0; }
      _scrollAccumulator.y -= scrollSpeed * time;
    }
    else if (keyHeld(ALLEGRO_KEY_S)) {
      if (_scrollAccumulator.y > 1) { _scrollAccumulator.y = 0; }
      _scrollAccumulator.y += scrollSpeed * time;
    }
    if (keyHeld(ALLEGRO_KEY_A)) {
      if (_scrollAccumulator.x < -1) { _scrollAccumulator.x = 0; }
      _scrollAccumulator.x -= scrollSpeed * time;
    }
    else if (keyHeld(ALLEGRO_KEY_D)) {
      if (_scrollAccumulator.x > 1) { _scrollAccumulator.x = 0; }
      _scrollAccumulator.x += scrollSpeed * time;
    }

    if (keyReleased(ALLEGRO_KEY_W) || keyReleased(ALLEGRO_KEY_S)) {
      _scrollAccumulator.y = 0;
    }
    if (keyReleased(ALLEGRO_KEY_A) || keyReleased(ALLEGRO_KEY_D)) {
      _scrollAccumulator.x = 0;
    }
    */
  }

  @property {
    Vector2i scrollDirection() {
      Vector2i scroll;
      if (keyHeld(Keymap.up)) {
        scroll.y = -1;
      }
      else if (keyHeld(Keymap.down)) {
        scroll.y = 1;
      }
      if (keyHeld(Keymap.left)) {
        scroll.x = -1;
      }
      else if (keyHeld(Keymap.right)) {
        scroll.x = 1;
      }
      return scroll;
    }
    /*
    Vector2i scrollDirection() {
      Vector2i scroll;
      if ( _scrollAccumulator.y <= -1) {
        scroll.y = -1;
      }
      else if ( _scrollAccumulator.y >= 1) {
        scroll.y = 1;
      }
      if ( _scrollAccumulator.x <= -1) {
        scroll.x = -1;
      }
      else if ( _scrollAccumulator.x >= 1) {
        scroll.x = 1;
      }
      return scroll;
    }
    */
    bool selectUp()    { return keyPressed(Keymap.up); }
    bool selectDown()  { return keyPressed(Keymap.down); }
    bool selectLeft()  { return keyPressed(Keymap.left); }
    bool selectRight() { return keyPressed(Keymap.right); }

    bool confirm() { return keyPressed(Keymap.confirm); }
    bool cancel()  { return keyPressed(Keymap.cancel); }
    bool endTurn() { return keyPressed(Keymap.end); }

    bool speedScroll() { return keyHeld(Keymap.faster); }
  }

  Vector2i mousePos() {
    return Vector2i(_curMouseState.x, _curMouseState.y);
  }

  private:
  bool keyHeld(Keymap buttons) {
    return buttons.any!(key => al_key_down(&_curKeyboardState, key));
  }

  bool keyPressed(Keymap buttons) {
    return buttons.any!(key => !al_key_down(&_prevKeyboardState, key) && al_key_down(&_curKeyboardState, key));
  }

  bool keyReleased(int keycode) {
    return al_key_down(&_prevKeyboardState, keycode) && !al_key_down(&_curKeyboardState, keycode);
  }

  bool mouseClicked(MouseKeymap button) {
    int b = cast(int) button;
    return !al_mouse_button_down(&_prevMouseState, b) && al_mouse_button_down(&_curMouseState, b);
  }

  Vector2f _scrollAccumulator = Vector2f.Zero;

  ALLEGRO_KEYBOARD_STATE _curKeyboardState, _prevKeyboardState;
  ALLEGRO_MOUSE_STATE _curMouseState, _prevMouseState;
}

