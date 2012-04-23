/**
PerceptVala main file
Written by Leszek Godlewski <github@inequation.org>
*/

using Gee;
using Gtk;

int main(string[] args) {
	Gtk.init(ref args);

    var window = new MainWindow();

    window.show_all();

    Gtk.main();

	return 0;
}
