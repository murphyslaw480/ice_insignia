module gui.character_sheet;

import std.conv;
import std.traits;
import allegro;
import gui.all;
import model.character;
import model.battler;
import model.item;
import geometry.all;
import graphics.all;
import util.input;
import state.combat_calc;

protected enum {
  textureName        = "character_view",
  spritePos          = Vector2i(51, 51),
  namePos            = Vector2i(81, 40),
  lvlPos             = Vector2i(260, 40),
  hpBarPos           = Vector2i(71, 106),
  hpBarWidth         = 96,
  hpBarHeight        = 16,
  hpBarFg            = Color(0.0, 0.8, 0),
  hpBarBg            = Color.white,
  hpTextColor        = Color.black,
  xpBarPos           = Vector2i(71, 138),
  xpBarWidth         = 96,
  xpBarHeight        = 16,
  xpBarFg            = Color(0.8, 0.8, 0),
  xpBarBg            = Color.white,
  xpTextColor        = Color.black,
  attributesPos      = Vector2i(83, 200),
  attributesSep      = 32,
  attributeBarWidth  = 96,
  attributeBarHeight = 12,
  potentialBarHeight = 4,
  attributeBarFg     = Color(0.0, 0.8, 0),
  attributeBarBg     = Color.white,
  potentialBarFg     = Color(0.3, 0.4, 0.8),
  potentialBarBg     = Color.black,
  attributeTextColor = Color.black,
  equipmentPos       = Vector2i(271, 306),
  equipmentSep       = 32,
  talentPos         = Vector2i(350, 100),
  talentsSep         = 32,
  combatStatsPos     = Vector2i(271, 120),
  combatStatsSep     = 32
}

/// displays info about a character's stats
class CharacterSheet {
  alias InventoryAction = InventoryMenu.Action;
  alias TalentAction = TalentMenu.Action;
  enum Mode { idle, editInventory, editTalents }
  this(Vector2i topLeft, Battler battler, bool showPotential = false,
      InventoryAction inventoryAction = null, TalentAction talentAction = null)
  {
    _topLeft = topLeft;
    _bgTexture = getTexture(textureName);
    _character = battler.character;
    _sprite = battler.sprite;
    populate(battler.hp, showPotential, inventoryAction, talentAction);
  }

  this(Vector2i topLeft, Character character, bool showPotential = false,
      InventoryAction inventoryAction = null, TalentAction talentAction = null)
  {
    _topLeft = topLeft;
    _character = character;
    _sprite = new CharacterSprite(character);
    populate(character.maxHp, showPotential, inventoryAction, talentAction);
  }

  @property {
    auto mode() { return _mode; }
    auto mode(Mode val) {
      final switch(val) with(Mode) {
        case editInventory:
          _inventoryMenu.hasFocus = true;
          _talentMenu.hasFocus = false;
          break;
        case editTalents:
          _inventoryMenu.hasFocus = false;
          _talentMenu.hasFocus = true;
          break;
        case idle:
          _inventoryMenu.hasFocus = false;
          _talentMenu.hasFocus = false;
          break;
      }
      _mode = val;
    }
  }

  void regenerateInventoryMenu(InventoryAction inventoryAction,
      InventoryMenu.HoverAction onHover = null)
  {
    _inventoryMenu = new InventoryMenu(_topLeft + equipmentPos, _character.items,
        inventoryAction, onHover, x => "take", InventoryMenu.ShowPrice.no, false);
    _sprite = new CharacterSprite(_character);
  }

  void handleInput(InputManager input) {
    final switch(_mode) {
      case Mode.idle:
      case Mode.editTalents:
        break;
      case Mode.editInventory:
        _inventoryMenu.handleInput(input);
        break;
    }
  }

  void update(float time) {
    foreach(bar ; _progressBars) {
      bar.update(time);
    }
  }

  void draw() {
    _bgTexture.drawTopLeft(_topLeft);
    foreach(bar ; _progressBars) {
      bar.draw();
    }
    drawCombatStats;
    _inventoryMenu.draw;
    _talentMenu.draw;
    _sprite.draw(_topLeft + spritePos);
    _nameFont.draw(_character.name, _topLeft + namePos);
    _levelFont.draw(to!string(_character.level), _topLeft + lvlPos);
  }

  void drawCombatStats() {
    Vector2i pos = _topLeft + combatStatsPos;
    // damage
    auto str = _character.isArmed ? to!string(_character.attackDamage) : "-";
    _statsFont.draw(str, pos);
    pos.y += combatStatsSep;
    // hit
    str = _character.isArmed ? to!string(_character.attackHit) : "-";
    _statsFont.draw(str, pos);
    pos.y += combatStatsSep;
    // crit
    str = _character.isArmed ? to!string(_character.attackCrit) : "-";
    _statsFont.draw(str, pos);
    pos.y += combatStatsSep;
    // avoid
    str = _character.isArmed ? to!string(_character.avoid) : "-";
    _statsFont.draw(str, pos);
    pos.y += combatStatsSep;
  }

  protected:
  ProgressBar!int statBarFor(ulong i) {
    auto a = to!Attribute(i);
    if (a == Attribute.maxHp) {
      return _progressBars[0];
    }
    return _progressBars[2 * a + 1];
  }

  ProgressBar!int potentialBarFor(ulong i) {
    auto a = to!Attribute(i);
    if (a == Attribute.maxHp) {
      return _progressBars[1];
    }
    return _progressBars[2 * a + 2];
  }

  private:
  Mode _mode;
  Texture _bgTexture;
  Sprite _sprite;
  Character _character;
  InventoryMenu _inventoryMenu;
  TalentMenu _talentMenu;
  Vector2i _topLeft;
  ProgressBar!int[] _progressBars;

  void populate(int hp, bool showPotential, InventoryAction inventoryAction, TalentAction
      talentAction)
  {
    _bgTexture = getTexture(textureName);
    makeXpAndHpBars(hp);
    makeAttributeBars(showPotential);
    _inventoryMenu = new InventoryMenu(_topLeft + equipmentPos, _character.items,
        inventoryAction, null, x => "take", InventoryMenu.ShowPrice.no, false);
    _talentMenu = new TalentMenu(_topLeft + talentPos, _character.talents, talentAction, false);
  }

  void makeAttributeBars(bool showPotential) {
    Rect2i area = Rect2i(_topLeft + attributesPos, attributeBarWidth, attributeBarHeight);
    foreach(attribute ; EnumMembers!Attribute[1 .. $]) { // skip over maxHp
      // make bar for attribute
      auto val = _character.attributes[attribute];
      auto maxVal = AttributeCaps[attribute];
      _progressBars ~= new ProgressBar!int(area, val, maxVal, attributeBarFg, attributeBarBg,
          attributeTextColor, ProgressBar!int.DrawText.value);
      if (showPotential) {
        // now make bar for potential right below attribute
        val = _character.potential[attribute];
        auto area2 = Rect2i(area.x, area.y + attributeBarHeight, attributeBarWidth, potentialBarHeight);
        _progressBars ~= new ProgressBar!int(area2, val, 100, potentialBarFg, potentialBarBg, attributeTextColor,
            ProgressBar!int.DrawText.none);
      }
      area.y += attributesSep;
    }
  }

  void makeXpAndHpBars(int currentHp) {
    auto area = Rect2i(_topLeft + hpBarPos, hpBarWidth, hpBarHeight);
    _progressBars ~= new ProgressBar!int(area, currentHp, _character.maxHp, hpBarFg, hpBarBg, hpTextColor);
    auto area2 = Rect2i(area.x, area.y + hpBarHeight, hpBarWidth, potentialBarHeight);
    _progressBars ~= new ProgressBar!int(area2, _character.potential.maxHp, 100, potentialBarFg,
        potentialBarBg, attributeTextColor, ProgressBar!int.DrawText.none);
    area = Rect2i(_topLeft + xpBarPos, xpBarWidth, xpBarHeight);
    _progressBars ~= new ProgressBar!int(area, _character.xp, _character.xpLimit, xpBarFg, xpBarBg, xpTextColor);
  }

  static Font _nameFont, _levelFont, _statsFont;
  static this() {
    _nameFont  = getFont("characterSheetName");
    _levelFont = getFont("characterSheetLevel");
    _statsFont = getFont("combatStats");
  }
}
