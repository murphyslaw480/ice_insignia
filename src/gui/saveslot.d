module gui.saveslot;

import std.string;
import gui.element;
import gui.container;
import gui.saveslot;
import graphics.all;
import geometry.all;
import util.savegame;

private enum {
  namePos = Vector2i(40, 0),
  infoPos  = Vector2i(248, 0),
}

class SaveSlot : GUIElement {
  this(Vector2i topLeft, SaveData data, void delegate(SaveData) onSelect) {
    super(topLeft, Anchor.topLeft);
    _onSelect = onSelect;
    _data = data;
    _name = "Save %d".format(data.idx);
    _info = [
      "Mission: %d".format(_data.mission),
      "Gold: %d".format(_data.gold),
      "Roster: %d/%d".format(_data.roster.length, rosterSize),
    ];
  }

  override {
    void handleSelect() {
      _onSelect(_data);
    }

    void draw() {
      _texture.draw(center);
      _nameFont.draw(_name, topLeft + namePos);
      _infoFont.draw(_info, topLeft + infoPos);
    }

    @property {
      int width() { return _texture.width; }
      int height() { return _texture.height; }
    }
  }

  private:
  SaveData _data;
  void delegate(SaveData) _onSelect;
  string _name;
  string[] _info;
}

private:
Texture _texture;
Font _nameFont, _infoFont;
static this() {
  _texture = getTexture("saveslot");
  _nameFont = getFont("saveName");
  _infoFont = getFont("saveInfo");
}
