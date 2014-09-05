module model.character;

import std.conv;
import std.string : format;
import std.random : uniform;
import std.range : empty;
import std.array : array;
import std.algorithm;
import allegro;
import util.jsonizer;
import model.item;
import model.valueset;
import model.talent;
import model.character_spec;
import graphics.sprite;
public import model.attribute;

alias AttributeSet = ValueSet!Attribute;

private enum talentAwardLevels = [1, 3, 6, 10, 15, 20];

class Character {
  mixin JsonizeMe;

  enum {
    itemCapacity = 5,
    xpLimit = 100,
    maxPotential = 100,
  }

  /// load saved character
  @jsonize this(string name, string model, AttributeSet attributes, AttributeSet potential,
      int level, int xp, Item[itemCapacity] items, string[] talentKeys = [])
  {
    _name = name;
    _model = model;
    _attributes = attributes;
    _potential = potential;
    _level = level;
    _xp = xp;
    _items = items;
    _talents = array(talentKeys.map!(a => loadTalent(a)));
  }

  this(CharacterSpec spec) {
    _name       = spec.name;
    _model      = spec.model;
    _attributes = spec.attributes;
    _potential  = spec.potential;
  }

  @property {
    @jsonize {
      string name() { return _name; }
      string model() { return _model; }
      int level() { return _level; }
      int xp() { return _xp; }

      AttributeSet potential() { return _potential; }
      AttributeSet attributes() { return _attributes; }

      auto items() { return _items; }
      auto talentKeys() { return array(_talents.map!"a.key"); }
    }

    auto talents() { return _talents; }

    Item equippedWeapon() {
      return (_items[0] && _items[0].isWeapon) ? _items[0] : Item.none;
    }

    /// set equipped weapon
    void equippedWeapon(Item item) {
      if (item) {
        auto idx = _items[].countUntil(item);
        assert(idx >= 0);
        _items[idx] = _items[0];
        _items[0] = item;
      }
    }

    bool canAwardTalent() {
      return talentAwardLevels.canFind(level);
    }
  }

  /// if results in level-up, returns true and assigns bonuses
  bool awardXp(int val, out AttributeSet bonuses) {
    if (_xp + val >= xpLimit) {
      bonuses = levelUp();
      _xp = (_xp + val) % xpLimit;
      return true;
    }
    _xp = (_xp + val) % xpLimit;
    return false;
  }

  bool canWield(Item item) {
    return _talents.canFind!(x => x.weaponSkill == item.type && x.weaponTier == item.tier);
  }

  ref Item itemAt(ulong slot) {
    assert(slot >= 0 && slot < itemCapacity, format("item #%d/%d out of range", slot, itemCapacity));
    return _items[slot];
  }

  bool addItem(Item newItem) {
    foreach(ref item ; _items) { // look for empty slot to place item in
      if (item is null) {
        item = newItem;
        return true;
      }
    }
    return false;
  }

  /// access an attribute by name
  int opDispatch(string m)() const if (hasMember!(Attribute, m)) {
    return _attributes.opDispatch!m;
  }

  /// level up and return attribute increase values
  AttributeSet levelUp() {
    ++_level;
    auto bonuses = _potential.map!(p => uniform!"[]"(0, 100) > p ? 0 : 1);
    _attributes = attributes + bonuses;
    return bonuses;
  }

  void addTalent(Talent talent) {
    _talents ~= talent;
    _attributes = _attributes + talent.bonus;
    _potential = _potential + talent.potential;
  }

  private:
  string _name;
  string _model;
  int _xp;
  int _level = 1;
  AttributeSet _attributes, _potential;
  Item[itemCapacity] _items;
  Talent[] _talents;
}

Character generateCharacter(string name, int level = 1, string[] itemNames = []) {
  auto spec =  loadCharacterSpec(name);
  auto character = new Character(spec);
  foreach(key ; spec.talentKeys) {
    character.addTalent(loadTalent(key));
  }
  foreach(item ; itemNames) {
    assert(character.addItem(loadItem(item)));
  }
  for(int i = 1 ; i < level ; i++) {
    character.levelUp();
  }
  return character;
}

unittest {
  import std.json : parseJSON;

  auto json = parseJSON(`{
      "name" : "Myron",
      "attributes" : {
      "valueSet" : {
      "maxHp"        : 20,
      "strength"     : 5,
      "skill"        : 4,
      "speed"        : 5,
      "defense"      : 5,
      "resist"       : 3,
      "luck"         : 2,
      "move"         : 4,
      "constitution" : 5
      }
      },
      "potential" : {
      "valueSet" : {
      "maxHp"        : 10,
      "strength"     : 2,
      "skill"        : 8,
      "speed"        : 5,
      "defense"      : 4,
      "resist"       : 5,
      "luck"         : 2,
      "move"         : 0,
      "constitution" : 1
      }
      }
  }`);

  auto myron = json.extract!Character;
  assert(myron.maxHp == 20 && myron.move == 4 && myron.defense == 5);
  assert(myron.potential.strength == 2 && myron.potential.constitution == 1);
}
