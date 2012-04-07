/**
PerceptVala character renderer widget
Written by Leszek Godlewski <github@inequation.org>
*/

using Gtk;

public class CharacterRenderer : Gtk.Image {
	public CharacterRenderer() {
		expand = true;
		set_from_stock(Gtk.Stock.MISSING_IMAGE, IconSize.LARGE_TOOLBAR);
	}
}
