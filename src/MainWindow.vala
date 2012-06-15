/**
PerceptVala main window class
Written by Leszek Godlewski <github@inequation.org>
*/

using Gtk;
using Gee;

public class MainWindow : Window {
	private Notebook m_notebook;

	// network setup widgets
	private RadioButton m_linear;
	private RadioButton m_tanh;
	private TreeView m_view;
	private Button m_add;
	private Button m_up;
	private Button m_down;
	private Button m_delete;

	// network model widgets and stuff
	private ListStore m_net_model;
	private TreeIter m_input_layer;
	private TreeIter m_output_layer;
	private SpinButton m_glyph_size;
	private SpinButton m_layer_size;
	private ComboBoxText m_start_output;
	private ComboBoxText m_end_output;

	// training widgets
	private FontButton m_train_font_button;
	private CharacterRenderer m_training_renderer;
	private Scale m_x_train_jitter;
	private Scale m_y_train_jitter;
	private Scale m_train_charsel;

	// testing widgets
	private FontButton m_test_font_button;
	private Scale m_x_test_jitter;
	private Scale m_y_test_jitter;
	private Scale m_noise;
	private CharacterRenderer m_testing_renderer;
	private Scale m_test_charsel;
	private Label m_test_result;

	// training dialog widgets
	private SpinButton m_rate;
	private SpinButton m_cycles;
	private RadioButton m_random;
	private RadioButton m_sequential;
	private bool m_break_training;

	// testing dialog widgets
	private bool m_break_testing;

	public NeuralNetwork? m_network;

	private enum ViewColumn {
		TYPE,
		SIZE,
		IS_TANH
	}

	private static const int CHARSEL_WIDTH_REQUEST = 256 * 2;
	private static const int TICK_UPDATE_FREQUENCY = 2;

	public MainWindow() {
		title = "PerceptVala";
		border_width = 5;
		window_position = WindowPosition.CENTER;
		set_default_size(640, 480);
		destroy.connect(Gtk.main_quit);

		m_network = null;
		m_rate = null;

		m_notebook = new Notebook();

		// create the network setup tab
		var net_setup_label = new Label("Network setup");
		var net_setup_page = create_net_setup_page();
		m_notebook.append_page(net_setup_page, net_setup_label);

		// create the learning tab
		var learning_label = new Label("Training");
		var learning_page = create_training_page();
		m_notebook.append_page(learning_page, learning_label);

		// create the testing tab
		var testing_label = new Label("Testing");
		var testing_page = create_testing_page();
		m_notebook.append_page(testing_page, testing_label);

		// create the about tab
		var about_label = new Label("About");
		var about_page = create_about_page();
		m_notebook.append_page(about_page, about_label);

		m_notebook.switch_page.connect((page, page_num) => {
			if (m_network == null)
				return;

			CharacterRenderer? r;
			switch (page_num) {
				case 1: r = m_training_renderer; break;
				case 2: r = m_testing_renderer; break;
				default: r = null; break;
			}
			foreach (ImagePixel i in m_network.inputs)
				i.image = r;
		});

		m_start_output.changed();
		m_end_output.changed();

		add(m_notebook);
	}

	private Widget create_net_setup_page() {
		var grid = new Grid();

		grid.column_spacing = 5;
		grid.row_spacing = 5;
		grid.column_homogeneous = true;
		grid.row_homogeneous = false;

		grid.attach(new Label("Glyph size"), 0, 0, 1, 1);
		m_glyph_size = new SpinButton.with_range(8, 128, 1);
		m_glyph_size.adjustment.value = 8;
		m_glyph_size.value_changed.connect(() => {
			m_net_model.set_value(m_input_layer, ViewColumn.SIZE,
				(int)(m_glyph_size.adjustment.value
					* m_glyph_size.adjustment.value));
			m_training_renderer.dimension = m_testing_renderer.dimension =
				(int)(m_glyph_size.adjustment.value);
		});
		grid.attach(m_glyph_size, 1, 0, 1, 1);

		grid.attach(new Label("First output character"), 0, 1, 1, 1);
		m_start_output = new ComboBoxText();
		grid.attach(m_start_output, 1, 1, 1, 1);

		grid.attach(new Label("Last output character"), 0, 2, 1, 1);
		m_end_output = new ComboBoxText();
		grid.attach(m_end_output, 1, 2, 1, 1);

		for (int i = 32; i < 256; ++i) {
			string id = "%d".printf(i);
			string text = "%d: '%c'".printf(i, (char)i);
			m_start_output.append(id, text);
			m_end_output.append(id, text);
		}
		m_start_output.active = '0' - 32;
		m_end_output.active = '9' - 32;
		m_start_output.changed.connect(() => {
			if (m_end_output.active < m_start_output.active)
				m_end_output.active = m_start_output.active;
			m_net_model.set_value(m_output_layer, ViewColumn.SIZE,
				(int)(m_end_output.active - m_start_output.active + 1));
			m_train_charsel.set_range(32 + m_start_output.active,
				m_train_charsel.adjustment.upper);
			m_test_charsel.set_range(32 + m_start_output.active,
				m_test_charsel.adjustment.upper);
		});
		m_end_output.changed.connect(() => {
			if (m_start_output.active >= m_end_output.active)
				m_start_output.active = m_end_output.active;
			m_net_model.set_value(m_output_layer, ViewColumn.SIZE,
				(int)(m_end_output.active - m_start_output.active + 1));
			m_train_charsel.set_range(m_train_charsel.adjustment.lower,
				32 + m_end_output.active);
			m_test_charsel.set_range(m_test_charsel.adjustment.lower,
				32 + m_end_output.active);
		});

		m_net_model = new ListStore(3,
			typeof(string),
			typeof(int),
			typeof(bool));
		m_view = new TreeView.with_model(m_net_model);
		m_view.expand = true;
		m_view.get_selection().mode = SelectionMode.SINGLE;
		m_view.insert_column_with_attributes(-1, "Layer type",
			new CellRendererText(), "text", 0);
		m_view.insert_column_with_attributes(-1, "Layer size",
			new CellRendererText(), "text", 1);
		var checkbox = new CellRendererToggle();
		m_view.insert_column_with_attributes(-1, "Is tanh()?",
			checkbox, "active", 2);
		checkbox.activatable = false;
		grid.attach(m_view, 0, 3, 1, 1);
		m_view.get_selection().changed.connect(() => {
			TreeIter? it;
			m_view.get_selection().get_selected(null, out it);

			if (it == null) {
				m_linear.sensitive = false;
				m_tanh.sensitive = false;
				m_layer_size.sensitive = false;
				m_up.sensitive = false;
				m_down.sensitive = false;
				m_delete.sensitive = false;
				return;
			}

			GLib.Value val;
			bool is_tanh;
			int count;

			m_net_model.get_value(it, ViewColumn.SIZE, out val);
			count = val.get_int();
			m_net_model.get_value(it, ViewColumn.IS_TANH, out val);
			is_tanh = val.get_boolean();

			if (is_tanh)
				m_tanh.active = true;
			else
				m_linear.active = true;
			m_layer_size.adjustment.value = count;

			bool enabled = it != m_input_layer && it != m_output_layer;
			m_linear.sensitive = enabled;
			m_tanh.sensitive = enabled;
			m_layer_size.sensitive = enabled;
			m_up.sensitive = enabled;
			m_down.sensitive = enabled;
			m_delete.sensitive = enabled;
		});

		m_net_model.append(out m_input_layer);
		m_net_model.set(m_input_layer,
			ViewColumn.TYPE, "Input",
			ViewColumn.SIZE, (int)(m_glyph_size.adjustment.value
				* m_glyph_size.adjustment.value),
			ViewColumn.IS_TANH, false);
		m_net_model.append(out m_output_layer);
		m_net_model.set(m_output_layer,
			ViewColumn.TYPE, "Output",
			ViewColumn.SIZE, (int)(m_end_output.active - m_start_output.active
				+ 1),
			ViewColumn.IS_TANH, false);

		var subgrid = new Grid();
		subgrid.column_spacing = 5;
		subgrid.row_spacing = 5;
		subgrid.column_homogeneous = true;
		subgrid.row_homogeneous = false;

		m_linear = new RadioButton.with_label(null, "Linear");
		m_tanh = new RadioButton.with_label_from_widget(m_linear, "tanh()");
		subgrid.attach(m_linear, 0, 0, 4, 1);
		subgrid.attach(m_tanh, 0, 1, 4, 1);
		m_linear.clicked.connect(() => {
			TreeIter? it;
			m_view.get_selection().get_selected(null, out it);
			if (it != null && it != m_input_layer && it != m_output_layer)
				m_net_model.set_value(it, ViewColumn.IS_TANH, m_tanh.active);
		});
		m_tanh.clicked.connect(() => {
			TreeIter? it;
			m_view.get_selection().get_selected(null, out it);
			if (it != null && it != m_input_layer && it != m_output_layer)
				m_net_model.set_value(it, ViewColumn.IS_TANH, m_tanh.active);
		});

		subgrid.attach(new Label("Layer size"), 0, 2, 1, 1);
		m_layer_size = new SpinButton.with_range(1,
			m_glyph_size.adjustment.upper * m_glyph_size.adjustment.upper, 1);
		subgrid.attach(m_layer_size, 1, 2, 3, 1);
		m_layer_size.value_changed.connect(() => {
			TreeIter? it;
			m_view.get_selection().get_selected(null, out it);
			if (it != null && it != m_input_layer && it != m_output_layer)
				m_net_model.set_value(it, ViewColumn.SIZE,
					(int)m_layer_size.adjustment.value);
		});

		var filler = new Label(" ");
		filler.expand = true;
		subgrid.attach(filler, 0, 3, 4, 1);

		m_add = new Button.from_stock(Gtk.Stock.ADD);
		subgrid.attach(m_add, 0, 4, 1, 1);
		m_add.clicked.connect(() => {
			TreeIter it;
			m_net_model.insert_before(out it, m_output_layer);
			m_net_model.set(it,
				ViewColumn.TYPE, "Hidden",
				ViewColumn.SIZE, (int)(m_glyph_size.adjustment.value
					* m_glyph_size.adjustment.value),
				ViewColumn.IS_TANH, false);
			m_view.get_selection().select_iter(it);
		});

		m_up = new Button.from_stock(Gtk.Stock.GO_UP);
		subgrid.attach(m_up, 1, 4, 1, 1);
		m_up.clicked.connect(() => {
			TreeIter? it;
			m_view.get_selection().get_selected(null, out it);
			if (it != null && it != m_input_layer && it != m_output_layer) {
				TreeIter prev = it;
				m_net_model.iter_previous(ref prev);
				if (prev == m_input_layer)
					return;
				m_net_model.swap(it, prev);
			}
		});

		m_down = new Button.from_stock(Gtk.Stock.GO_DOWN);
		subgrid.attach(m_down, 2, 4, 1, 1);
		m_down.clicked.connect(() => {
			TreeIter? it;
			m_view.get_selection().get_selected(null, out it);
			if (it != null && it != m_input_layer && it != m_output_layer) {
				TreeIter next = it;
				m_net_model.iter_next(ref next);
				if (next == m_output_layer)
					return;
				m_net_model.swap(it, next);
			}
		});

		m_delete = new Button.from_stock(Gtk.Stock.DELETE);
		subgrid.attach(m_delete, 3, 4, 1, 1);
		m_delete.clicked.connect(() => {
			TreeIter? it;
			m_view.get_selection().get_selected(null, out it);
			if (it != null && it != m_input_layer && it != m_output_layer) {
				m_net_model.remove(it);
				m_view.get_selection().select_iter(m_input_layer);
			}
		});

		var apply = new Button.from_stock(Gtk.Stock.APPLY);
		subgrid.attach(apply, 0, 5, 2, 1);
		apply.clicked.connect(() => {
			GLib.Value val;
			bool is_tanh;
			int count;

			m_net_model.get_value(m_output_layer, ViewColumn.SIZE, out val);
			count = val.get_int();
			stdout.printf("Building network - %d outputs...\n", count);
			m_network = new NeuralNetwork(count, 32 + m_start_output.active);

			TreeIter it = m_output_layer;
			bool valid = m_net_model.iter_previous(ref it);
			while (valid && it != m_input_layer) {
				// retrieve layer properties from the list store
				m_net_model.get_value(it, ViewColumn.SIZE, out val);
				count = val.get_int();
				m_net_model.get_value(it, ViewColumn.IS_TANH, out val);
				is_tanh = val.get_boolean();

				stdout.printf("Inserting hidden layer of %d %s neurons...\n",
					count, is_tanh ? "tanh()" : "linear");
				var hidden_layer = new ArrayList<Neuron>();
				for (int i = 0; i < count; ++i)
					hidden_layer.add(new Neuron(is_tanh));
				m_network.insert_layer(hidden_layer);

				valid = m_net_model.iter_previous(ref it);
			}

			m_net_model.get_value(m_input_layer, ViewColumn.SIZE, out val);
			count = val.get_int();
			stdout.printf("Inserting input layer of %d neurons...\n", count);
			var input_layer = new ArrayList<ImagePixel>();
			for (uint y = 0; y < (uint)Math.sqrt(count); ++y) {
				for (uint x = 0; x < (uint)Math.sqrt(count); ++x)
					input_layer.add(new ImagePixel(x, y));
			}
			m_network.insert_layer(input_layer);

			stdout.printf("Network built.\n");

			m_notebook.page = 1;
		});

		var load = new Button.from_stock(Gtk.Stock.OPEN);
		subgrid.attach(load, 2, 5, 1, 1);
		load.clicked.connect(() => {
			var fc = new FileChooserDialog("Load network from file", this,
				FileChooserAction.OPEN, Stock.CANCEL, 0, Stock.OPEN, 1);
			var ff = new FileFilter();
			ff.set_filter_name("Network structure (*.net)");
			ff.add_pattern("*.net");
			fc.filter = ff;
			if (fc.run() == 1)
				m_network = NeuralNetwork.deserialize(fc.get_filename());
			fc.destroy();

			infer_model_from_network();
		});

		var save = new Button.from_stock(Gtk.Stock.SAVE_AS);
		subgrid.attach(save, 3, 5, 1, 1);
		save.clicked.connect(() => {
			if (!is_network_ready())
				return;

			var fc = new FileChooserDialog("Save network to file", this,
				FileChooserAction.SAVE, Stock.CANCEL, 0, Stock.SAVE, 1);
			var ff = new FileFilter();
			ff.set_filter_name("Network structure (*.net)");
			ff.add_pattern("*.net");
			fc.filter = ff;
			if (fc.run() == 1)
				m_network.serialize(fc.get_filename());
			fc.destroy();
		});

		grid.attach(subgrid, 1, 3, 1, 1);

		m_view.get_selection().select_iter(m_input_layer);

		return grid;
	}

	private Widget create_training_page() {
		var grid = new Grid();

		grid.column_spacing = 5;
		grid.row_spacing = 5;
		grid.column_homogeneous = false;
		grid.row_homogeneous = false;

		grid.attach(new Label("Font"), 0, 0, 1, 1);
		m_train_font_button = new FontButton();
		m_train_font_button.use_font = true;
		m_train_font_button.use_size = true;
		var fd = m_train_font_button.font_desc.copy();
		fd.set_size(7 * 1024);
		m_train_font_button.font_desc = fd;
		m_train_font_button.font_set.connect(() => {
			m_training_renderer.queue_draw();
		});
		grid.attach(m_train_font_button, 1, 0, 1, 1);

		grid.attach(new Label("X jitter [%]"), 0, 1, 1, 1);
		m_x_train_jitter = new Scale.with_range(Orientation.HORIZONTAL,
			0, 100, 1);
		m_x_train_jitter.change_value.connect((scroll, new_value) => {
			m_training_renderer.x_jitter = (int)m_x_train_jitter.adjustment.value;
			return false;
		});
		grid.attach(m_x_train_jitter, 1, 1, 1, 1);

		grid.attach(new Label("Y jitter [%]"), 0, 2, 1, 1);
		m_y_train_jitter = new Scale.with_range(Orientation.HORIZONTAL,
			0, 100, 1);
		m_y_train_jitter.change_value.connect((scroll, new_value) => {
			m_training_renderer.y_jitter = (int)m_y_train_jitter.adjustment.value;
			return false;
		});
		grid.attach(m_y_train_jitter, 1, 2, 1, 1);

		grid.attach(new Label("Learning rate"), 0, 3, 1, 1);
		m_rate = new SpinButton.with_range(0.00001, 1.0, 0.00001);
		m_rate.adjustment.value = 0.005;
		grid.attach(m_rate, 1, 3, 1, 1);

		grid.attach(new Label("Number of cycles"), 0, 4, 1, 1);
		m_cycles = new SpinButton.with_range(1, 9999999, 1);
		m_cycles.adjustment.value = 3000;
		grid.attach(m_cycles, 1, 4, 1, 1);

		grid.attach(new Label("Example order"), 0, 5, 1, 2);
		m_random = new RadioButton.with_label(null, "Random");
		m_sequential = new RadioButton.with_label_from_widget(m_random,
			"Sequential");
		m_random.active = true;
		grid.attach(m_random, 1, 5, 1, 1);
		grid.attach(m_sequential, 1, 6, 1, 1);

		grid.attach(new Label("Preview character code"), 0, 8, 1, 1);
		m_train_charsel = new Scale.with_range(Orientation.HORIZONTAL, 32, 255, 1);
		m_train_charsel.width_request = CHARSEL_WIDTH_REQUEST;
		m_train_charsel.set_increments(1, 10);
		m_train_charsel.change_value.connect((scroll, new_value) => {
			m_training_renderer.queue_draw();
			return false;
		});
		grid.attach(m_train_charsel, 0, 9, 1, 1);

		var subgrid = new Grid();
		subgrid.column_spacing = 5;
		subgrid.row_spacing = 5;
		subgrid.column_homogeneous = true;
		subgrid.row_homogeneous = false;

		var rand = new Button.with_label("Re-randomize");
		rand.clicked.connect(() => {
			m_training_renderer.queue_draw();
		});
		subgrid.attach(rand, 0, 0, 1, 1);

		var train = new Button.from_stock(Gtk.Stock.OK);
		train.clicked.connect(() => {
			if (!is_network_ready())
				return;

			var td = new Dialog.with_buttons("Network training progress", this,
				DialogFlags.MODAL);
			td.has_resize_grip = false;
			td.deletable = false;
			var contents = td.get_content_area();
			Container buttons = (Container)td.get_action_area();

			var total_progbar = new ProgressBar();
			total_progbar.width_request = 320;
			total_progbar.height_request = 20;
			total_progbar.show_text = true;
			total_progbar.text = "Total: 0%";
			contents.add(total_progbar);

			var cycle_progbar = new ProgressBar();
			cycle_progbar.width_request = 320;
			cycle_progbar.height_request = 20;
			cycle_progbar.show_text = true;
			total_progbar.text = "Cycle: 0%";
			contents.add(cycle_progbar);

			var btn = new Button.from_stock(Stock.CANCEL);
			btn.clicked.connect(() => { m_break_training = true; });
			buttons.add(btn);

			td.show_all();
			// make sure the window pops up
			for (int i = 0; i < 10; ++i)
				main_iteration_do(false);

			m_break_training = false;

			GLib.Value val;
			m_net_model.get_value(m_output_layer, ViewColumn.SIZE, out val);
			int examples = val.get_int();
			int cycles = (int)m_cycles.adjustment.value;
			int ticks = examples * cycles;

			var target = new ArrayList<float?>();
			for (int e = 0; e < examples; ++e)
				target.add(0.0f);

			for (int c = 0; c < cycles; ++c) {
				// stop if user clicked cancel
				if (m_break_training)
					break;

				stdout.printf("Training cycle #%d at rate %f\n", c, m_rate.value);

				// define an example visiting order, random or sequential
				ArrayList<int> order = new ArrayList<int>();
				if (m_sequential.active) {
					for (int e = 0; e < examples; ++e)
						order.add(e);
				} else {
					var pool = new LinkedList<int>();
					for (int e = 0; e < examples; ++e)
						pool.add(e);
					while (pool.size > 0) {
						int i = (int)(Random.next_int() % pool.size);
						order.add(pool[i]);
						pool.remove_at(i);
					}
				}

				for (int e = 0; e < examples; ++e) {
					// stop if user clicked cancel
					if (m_break_training)
						break;

					// update progress bar
					int tick = c * examples + e;
					if (tick % TICK_UPDATE_FREQUENCY == 0) {
						double frac = (double)tick / (double)ticks;
						total_progbar.fraction = frac;
						total_progbar.text = "Total: %.0f%%".printf(frac * 100.0);
						frac = (double)e / (double)examples;
						cycle_progbar.fraction = frac;
						cycle_progbar.text = "Cycle: %.0f%%".printf(frac * 100.0);
						for (int i = 0; i < 10; ++i)
							main_iteration_do(false);
					}

					int t = order[e];
					// pick a character and render
					m_train_charsel.change_value(ScrollType.JUMP,
						32 + m_start_output.active + t);
					m_training_renderer.render();

					// set new target and learn, then reset the target array
					target.set(t, 1.0f);
					m_network.train((float)m_rate.value, target);
					target.set(t, 0.0f);
				}
			}

			td.destroy();
		});
		subgrid.attach(train, 1, 0, 1, 1);

		grid.attach(subgrid, 0, 10, 1, 1);

		var fixed = new Fixed();
		grid.attach(fixed, 1, 8, 1, 2);

		m_training_renderer = new CharacterRenderer(
			(FontChooser)m_train_font_button,
			() => {return (unichar)(m_train_charsel.adjustment.value);},
			(int)m_glyph_size.adjustment.value);
		fixed.put(m_training_renderer, 0, 0);

		return grid;
	}

	private Widget create_testing_page() {
		var grid = new Grid();

		grid.column_spacing = 5;
		grid.row_spacing = 5;
		grid.column_homogeneous = false;
		grid.row_homogeneous = false;

		grid.attach(new Label("Font"), 0, 0, 2, 1);
		m_test_font_button = new FontButton();
		m_test_font_button.use_font = true;
		m_test_font_button.use_size = true;
		var fd = m_test_font_button.font_desc.copy();
		fd.set_size(7 * 1024);
		m_test_font_button.font_desc = fd;
		m_test_font_button.font_set.connect(() => {
			m_testing_renderer.queue_draw();
		});
		grid.attach(m_test_font_button, 2, 0, 1, 1);

		grid.attach(new Label("X jitter [%]"), 0, 1, 2, 1);
		m_x_test_jitter = new Scale.with_range(Orientation.HORIZONTAL,
			0, 100, 1);
		m_x_test_jitter.change_value.connect((scroll, new_value) => {
			m_testing_renderer.x_jitter = (int)m_x_test_jitter.adjustment.value;
			return false;
		});
		grid.attach(m_x_test_jitter, 2, 1, 1, 1);

		grid.attach(new Label("Y jitter [%]"), 0, 2, 2, 1);
		m_y_test_jitter = new Scale.with_range(Orientation.HORIZONTAL,
			0, 100, 1);
		m_y_test_jitter.change_value.connect((scroll, new_value) => {
			m_testing_renderer.y_jitter = (int)m_y_test_jitter.adjustment.value;
			return false;
		});
		grid.attach(m_y_test_jitter, 2, 2, 1, 1);

		grid.attach(new Label("Noise level [%]"), 0, 3, 2, 1);
		m_noise = new Scale.with_range(Orientation.HORIZONTAL, 0, 100, 1);
		m_noise.change_value.connect((scroll, new_value) => {
			m_testing_renderer.noise = (int)m_noise.adjustment.value;
			return false;
		});
		grid.attach(m_noise, 2, 3, 1, 1);

		grid.attach(new Label("Character code"), 0, 4, 2, 1);
		m_test_charsel = new Scale.with_range(Orientation.HORIZONTAL, 32, 255, 1);
		m_test_charsel.width_request = CHARSEL_WIDTH_REQUEST;
		m_test_charsel.set_increments(1, 10);
		m_test_charsel.change_value.connect((scroll, new_value) => {
			test_current_character();
			return false;
		});
		grid.attach(m_test_charsel, 2, 5, 1, 1);

		grid.attach(new Label("Recognized character"), 0, 6, 2, 1);
		m_test_result = new Label(" ");
		grid.attach(m_test_result, 2, 6, 1, 1);

		var subgrid = new Grid();
		subgrid.column_spacing = 5;
		subgrid.row_spacing = 5;
		subgrid.column_homogeneous = true;
		subgrid.row_homogeneous = false;

		var rand = new Button.with_label("Re-randomize");
		rand.clicked.connect(test_current_character);
		subgrid.attach(rand, 0, 0, 1, 1);

		var dump = new Button.with_label("Dump net to text");
		dump.clicked.connect(() => {
			if (!is_network_ready())
				return;

			var fc = new FileChooserDialog("Dump network to text file", this,
				FileChooserAction.SAVE, Stock.CANCEL, 0, Stock.SAVE, 1);
			var ff = new FileFilter();
			ff.set_filter_name("Network text dump (*.txt)");
			ff.add_pattern("*.net");
			fc.set_filter(ff);
			if (fc.run() == 1)
				m_network.dump_to_text_file(fc.get_filename());
			fc.destroy();
		});
		subgrid.attach(dump, 1, 0, 1, 1);

		var test = new Button.from_stock(Gtk.Stock.OK);
		test.clicked.connect(() => {
			if (!is_network_ready())
				return;

			var td = new Dialog.with_buttons("Network test progress", this,
				DialogFlags.MODAL);
			td.has_resize_grip = false;
			td.deletable = false;
			var contents = td.get_content_area();
			Container buttons = (Container)td.get_action_area();

			var progbar = new ProgressBar();
			progbar.width_request = 320;
			progbar.height_request = 20;
			progbar.show_text = true;
			contents.add(progbar);

			var tgrid = new Grid();
			tgrid.column_spacing = 5;
			tgrid.row_spacing = 5;
			tgrid.column_homogeneous = false;
			tgrid.row_homogeneous = false;

			tgrid.attach(new Label("Unrecognized:"), 0, 0, 1, 1);
			var unrec_label = new Label("0");
			tgrid.attach(unrec_label, 1, 0, 1, 1);
			tgrid.attach(new Label("Recognized:"), 0, 1, 1, 1);
			var rec_label = new Label("0");
			tgrid.attach(rec_label, 1, 1, 1, 1);
			tgrid.attach(new Label("Ambiguous:"), 0, 2, 1, 1);
			var ambig_label = new Label("0");
			tgrid.attach(ambig_label, 1, 2, 1, 1);
			contents.add(tgrid);

			var cancel = new Button.from_stock(Stock.CANCEL);
			cancel.clicked.connect(() => { m_break_testing = true; });
			buttons.add(cancel);

			td.show_all();
			// make sure the window pops up
			for (int i = 0; i < 10; ++i)
				main_iteration_do(false);

			m_break_testing = false;

			GLib.Value val;
			m_net_model.get_value(m_output_layer, ViewColumn.SIZE, out val);
			int examples = val.get_int();
			int unrec = 0;
			int rec = 0;
			int ambig = 0;

			for (int e = 0; e < examples; ++e) {
				// stop if user clicked cancel
				if (m_break_testing)
					break;

				if (e % TICK_UPDATE_FREQUENCY == 0) {
					double frac = (double)e / (double)examples;
					progbar.fraction = frac;
					progbar.text = "%.0f%%".printf(frac * 100.0);
					for (int i = 0; i < 10; ++i)
						main_iteration_do(false);
				}

				// pick a character and render
				m_test_charsel.change_value(ScrollType.JUMP,
					32 + m_start_output.active + e);
				m_testing_renderer.render();

				int result = run_network(null);
				switch (result) {
					case -2:	unrec_label.label = "%d".printf(++unrec); break;
					case -1:	ambig_label.label = "%d".printf(++ambig); break;
					default:	rec_label.label = "%d".printf(++rec); break;
				}
			}

			// display percentage statistics
			progbar.fraction = 1.0;
			progbar.text = "100%";
			unrec_label.label = "%d/%d (%.1f%%)".printf(unrec, examples,
				100.0f * (float)unrec / (float)examples);
			ambig_label.label = "%d/%d (%.1f%%)".printf(ambig, examples,
				100.0f * (float)ambig / (float)examples);
			rec_label.label = "%d/%d (%.1f%%)".printf(rec, examples,
				100.0f * (float)rec / (float)examples);

			// set dialog to dismissable
			buttons.remove(cancel);
			td.deletable = true;
			td.add_action_widget(new Button.from_stock(Stock.OK), 0);
			td.show_all();
			td.run();
			td.destroy();
		});
		subgrid.attach(test, 2, 0, 1, 1);

		grid.attach(subgrid, 0, 7, 3, 1);

		var fixed = new Fixed();
		grid.attach(fixed, 2, 4, 1, 2);

		m_testing_renderer = new CharacterRenderer(
			(FontChooser)m_test_font_button,
			() => {return (unichar)(m_test_charsel.adjustment.value);},
			(int)m_glyph_size.adjustment.value);
		fixed.put(m_testing_renderer, 0, 0);

		return grid;
	}

	private Widget create_about_page() {
		var label = new Label(null);

		label.use_markup = true;
		label.justify = Justification.LEFT;
		label.wrap = true;
		label.margin = 20;
		label.set_markup("<span font_size=\"x-large\" font_weight=\"bold\">"
			+ "PerceptVala</span>\n"
			+ "An experimentation environment in <b>optical "
			+ "character recognition</b> using <b>artificial neural "
			+ "networks</b> written in <a href=\"http://live.gnome.org/Vala\">"
			+ "Vala</a>\n\n"
			+ "<span font_size=\"small\">Author: <b>Leszek Godlewski</b> "
			+ "&lt;<a href=\"mailto:github [at] inequation [dot] org\">"
			+ "github@inequation.org</a>&gt;\n"
			+ "Computer Graphics and Software, group 1, sem. VI, 2011/2012\n"
			+ "Biologically-Motivated Artificial Intelligence Methods\n"
			+ "Faculty of Automatics, Electronics and Computer Science\n"
			+ "Silesian University of Technology</span>\n\n"
			+ "Reference used: <a href=\"http://www.idsia.ch/NNcourse/\">"
			+ "N. Schraudolph, F. Cummins - Introduction to Neural Networks"
			+ "</a>");

		return label;
	}

	private bool is_network_ready() {
		if (m_network == null) {
			var msgbox = new MessageDialog(this,
				DialogFlags.MODAL | DialogFlags.DESTROY_WITH_PARENT,
				MessageType.INFO, ButtonsType.OK,
				"A network needs to be built first using the setup tab.");
			msgbox.run();
			msgbox.destroy();
			m_notebook.page = 0;
			return false;
		}
		return true;
	}

	private void test_current_character() {
		if (!is_network_ready())
			return;

		m_testing_renderer.render();

		string outputs;
		int result = run_network(out outputs);
		switch (result) {
			case -2:
				m_test_result.set_text("not recognized");
				break;
			case -1:
				m_test_result.set_text("ambiguous: %s".printf(outputs));
				break;
			default:
				m_test_result.set_text("#%u: '%c'".printf(result,
					(char)(32 + m_start_output.active + result)));
				break;
		}

		m_testing_renderer.queue_draw();
	}

	private int run_network(out string outputs_str) {
		stdout.printf("Running network...");
		var net_output = m_network.run();
		stdout.printf("done.\n");
		int counter = 0;
		int result = -2;
		var outputs = new StringBuilder();
		foreach (float activation in net_output) {
			if (activation >= 1.0f) {
				outputs.append("1");
				if (result == -2)
					result = counter;
				else
					// ambiguous
					result = -1;
			} else
				outputs.append("0");
			++counter;
		}
		if (outputs_str != null)
			outputs_str = outputs.str;
		return result;
	}

	private void infer_model_from_network() requires (m_network != null) {
		// make a backup of the network reference as our GUI code may null it
		var backup = m_network;

		// first, clear out the current model
		TreeIter? it;
		if (!m_net_model.get_iter_first(out it))
			return;
		while (m_net_model.iter_next(ref it)) {
			if (it != m_input_layer && it != m_output_layer)
				m_net_model.remove(it);
		}

		// set the input and output parameters
		m_glyph_size.value = Math.sqrt(m_network.inputs.size);
		m_start_output.active = m_network.first_char - 32;
		m_end_output.active = m_start_output.active + m_network.outputs.size - 1;

		// now import all the hidden layers
		for (int i = m_network.layers.size - 2; i > 0; --i) {
			var layer = m_network.layers[i];
			m_add.clicked();
			m_layer_size.value = layer.size;
			if (layer[0].is_tanh)
				m_tanh.clicked();
			else
				m_linear.clicked();
		}

		// restore network reference from backup
		m_network = backup;
	}
}
