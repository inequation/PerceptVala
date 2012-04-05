/**
PerceptVala main window class
Written by Leszek Godlewski <github@inequation.org>
*/

using Gtk;

public class MainWindow : Window {
	private Notebook m_notebook;
	private RadioButton m_linear;
	private RadioButton m_tanh;

	public TreeView m_net_model;
	public Scale m_glyph_size;
	public Scale m_layer_size;
	public ComboBoxText m_start_output;
	public ComboBoxText m_end_output;

	public MainWindow() {
		title = "PerceptVala";
		border_width = 5;
		window_position = WindowPosition.CENTER;
		set_default_size(640, 480);
		destroy.connect(Gtk.main_quit);

		m_notebook = new Notebook();

		// create the network setup tab
		var net_setup_label = new Label("Network setup");
		var net_setup_page = create_net_setup_page();
		m_notebook.append_page(net_setup_page, net_setup_label);

		// create the learning tab
		var learning_label = new Label("Teaching");
		var learning_page = create_teaching_page();
		m_notebook.append_page(learning_page, learning_label);

		// create the testing tab
		var testing_label = new Label("Testing");
		var testing_page = create_testing_page();
		m_notebook.append_page(testing_page, testing_label);

		add(m_notebook);
	}

	private Widget create_net_setup_page() {
		var grid = new Grid();

		grid.column_spacing = 5;
		grid.row_spacing = 5;
		grid.column_homogeneous = true;
		grid.row_homogeneous = false;

		grid.attach(new Label("Glyph size"), 0, 0, 1, 1);
		m_glyph_size = new Scale.with_range(Orientation.HORIZONTAL, 8, 128, 1);
		grid.attach(m_glyph_size, 1, 0, 1, 1);

		grid.attach(new Label("Layer size"), 0, 1, 1, 1);
		m_layer_size = new Scale.with_range(Orientation.HORIZONTAL, 1,
			2 * m_glyph_size.adjustment.upper * m_glyph_size.adjustment.upper,
			1);
		grid.attach(m_layer_size, 1, 1, 1, 1);

		grid.attach(new Label("First output character"), 0, 2, 1, 1);
		m_start_output = new ComboBoxText();
		grid.attach(m_start_output, 1, 2, 1, 1);

		grid.attach(new Label("Last output character"), 0, 3, 1, 1);
		m_end_output = new ComboBoxText();
		grid.attach(m_end_output, 1, 3, 1, 1);

		for (int i = 32; i < 256; ++i) {
			string id = "%d".printf(i);
			string text = "%d: '%c'".printf(i, (char)i);
			m_start_output.append(id, text);
			m_end_output.append(id, text);
		}

		m_net_model = new TreeView.with_model(new ListStore(1));
		m_net_model.expand = true;
		grid.attach(m_net_model, 0, 4, 1, 1);

		var subgrid = new Grid();
		subgrid.column_spacing = 5;
		subgrid.row_spacing = 5;
		subgrid.column_homogeneous = true;
		subgrid.row_homogeneous = false;

		m_linear = new RadioButton.with_label(null, "Linear");
		m_tanh = new RadioButton.with_label_from_widget(m_linear, "tanh()");
		subgrid.attach(m_linear, 0, 0, 4, 1);
		subgrid.attach(m_tanh, 0, 1, 4, 1);
		m_linear.active = true;

		var filler = new Label(" ");
		filler.expand = true;
		subgrid.attach(filler, 0, 2, 4, 1);

		subgrid.attach(new Button.from_stock(Gtk.Stock.ADD), 0, 3, 1, 1);
		subgrid.attach(new Button.from_stock(Gtk.Stock.GO_UP), 1, 3, 1, 1);
		subgrid.attach(new Button.from_stock(Gtk.Stock.GO_DOWN), 2, 3, 1, 1);
		subgrid.attach(new Button.from_stock(Gtk.Stock.DELETE), 3, 3, 1, 1);

		grid.attach(subgrid, 1, 4, 1, 1);

		return grid;
	}

	private Widget create_teaching_page() {
		return new Grid();
	}

	private Widget create_testing_page() {
		return new Grid();
	}
}
