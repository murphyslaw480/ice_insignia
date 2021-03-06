module gui.inventory_menu;

import std.string : format;
import std.array : array;
import std.algorithm : filter, max;
import graphics.all;
import geometry.all;
import gui.selection_menu;
import gui.input_icon;
import model.item;

private enum {
  normColor = Color.black,
  dropColor = Color(0, 0.8, 0.2)
}

class InventoryMenu : SelectionMenu!Item {
  enum ShowPrice { no, full, resale }
  this(Vector2i pos, Item[] items, Action onChoose, HoverAction onHover = null, 
      InputString inputString = null, ShowPrice showPrice = ShowPrice.no, bool focus = true, 
      bool drawBackButton = false)
  {
    _showPrice = showPrice;
    super(pos, items, onChoose, onHover, inputString, focus, drawBackButton);
  }

  this(Vector2i pos, Item[5] items, Action onChoose, HoverAction onHover = null,
      InputString inputString = null, ShowPrice showPrice = ShowPrice.no, bool focus = true, 
      bool drawBackButton = false)
  {
    _showPrice = showPrice;
    super(pos, items.dup, onChoose, onHover, inputString, focus, drawBackButton);
  }

  protected override {
    void drawEntry(Item item, Rect2i rect, bool isSelected) {
      if (item) {
        auto color = (item.drop) ? dropColor : normColor;
        Vector2i size = item.sprite.size;
        item.sprite.draw(rect.topLeft + size / 2);
        _font.draw(itemText(item), rect.topLeft + Vector2i(size.x, 0), color);
      }
    }

    int entryWidth(Item entry) {
      entry = (entry is null) ? Item.none : entry;
      return entry.sprite.width + _font.widthOf(itemText(entry));
    }

    int entryHeight(Item entry) {
      entry = (entry is null) ? Item.none : entry;
      return max(entry.sprite.height, _font.heightOf(itemText(entry)));
    }
  }

  string itemText(Item item) {
    if (item is null) { return ""; }
    final switch (_showPrice) { // choose how to display item text
      case ShowPrice.no:
        return format("%12s (%d)", item.name, item.uses);
      case ShowPrice.full:
        return format("%12s (%d)  %4dG", item.name, item.uses, item.price);
      case ShowPrice.resale:
        return format("%12s (%d)  %4dG", item.name, item.uses, item.resalePrice);
    }
  }

  private:
  ShowPrice _showPrice;
}
