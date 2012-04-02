/**
PerceptVala main window class
Written by Leszek Godlewski <github@inequation.org>
*/

using Gtk;

public class MainWindow : Gtk.Window {
	private Gtk.Notebook m_notebook;
	public MainWindow() {
		title = "PerceptVala";
		border_width = 5;
		window_position = WindowPosition.CENTER;
		set_default_size (640, 480);
		destroy.connect (Gtk.main_quit);

		m_notebook = new Notebook();

		// create the network setup tab
		var net_setup_label = new Label("Network setup");
		var net_setup_page = new Grid();
		m_notebook.append_page(net_setup_page, net_setup_label);

		// create the learning tab
		var learning_label = new Label("Learning");
		var learning_page = new Grid();
		m_notebook.append_page(learning_page, learning_label);

		// create the testing tab
		var testing_label = new Label("Testing");
		var testing_page = new Grid();
		m_notebook.append_page(testing_page, testing_label);

		add(m_notebook);
	}
}
