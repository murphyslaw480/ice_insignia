module graphics.character_sprite;

import std.conv;
import allegro;
import geometry.all;
import graphics.texture;
import graphics.sprite;
import graphics.color;
import util.config;
import model.character;
import model.battler;

/// displays a single frame of a texture
class CharacterSprite : Sprite {
  this(string model, BattleTeam team = BattleTeam.ally) {
    auto spriteSheet = (team == BattleTeam.ally) ? _blueSpriteSheet : _redSpriteSheet;
    assert(model in _spriteData.entries["rows"], "cannot find character sprite model " ~ model);
    int row = to!int(_spriteData.entries["rows"][model]);
    int col = 1; // TODO: set based on talents
    super(spriteSheet, row, col);
  }

  override void draw(Vector2i pos) {
    super.draw(pos);
    // TODO: overlay weapon sprite
  }
}

// used to palette swap the spritesheet
Color blueToRed(Color color) {
  if (isBluish(color)) {
    auto r = color.r;
    color.r = color.b;
    color.b = r;
  }
  return color;
}

bool isBluish(ALLEGRO_COLOR c) {
  return c.b > 0.5 && c.r < 0.5 && c.g < 0.5;
}

private:
ConfigData _spriteData;
Texture _redSpriteSheet;
Texture _blueSpriteSheet;

static this() {
  _spriteData = loadConfigFile(Paths.characterSpriteData);
  _blueSpriteSheet = getTexture(_spriteData.globals["blue_texture"]);
  _redSpriteSheet = getTexture(_spriteData.globals["red_texture"]);
}