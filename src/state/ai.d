module state.ai;

import model.battler;
import tilemap.all;

abstract class Behavior {
  this(Battler self, TileMap map, Battler[] enemies, Battler[] allies) {
    _self = self;
    _map = map;
    _enemies = enemies;
    _allies = allies;
    _pathFinder = new PathFinder(map, _map.tileAt(self.row, self.col), self.move);
  }

  @property {
    Tile[] moveRequest();
    Battler attackRequest();
  }

  protected:
  Battler _self;
  TileMap _map;
  Battler[] _enemies, _allies;
  PathFinder _pathFinder;
}
