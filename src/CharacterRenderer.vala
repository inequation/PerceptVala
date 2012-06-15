/**
PerceptVala character renderer widget
Written by Leszek Godlewski <github@inequation.org>
*/

using Gtk;
using Pango;
using Cairo;

public class CharacterRenderer : Gtk.Misc {
	public delegate unichar CharacterDelegate();

	private FontChooser m_font_chooser;
	private int m_dim;
	private CharacterDelegate m_char;
	private int m_x_jitter;
	private int m_y_jitter;
	private int m_noise;

	private ImageSurface m_surf;
	private Cairo.Context m_ctx;
	private Pango.Layout m_playout;

	public int dimension {
		get { return m_dim; }
		set {
			if (value != m_dim) {
				height_request = width_request = m_dim = value;
				//int stride = m_dim * 3;
				//m_pixels.resize(stride * m_dim * 2);
				m_surf = new ImageSurface(Format.RGB24, m_dim, m_dim);
				m_ctx = new Cairo.Context(m_surf);
				m_playout = Pango.cairo_create_layout(m_ctx);
				queue_draw();
			}
		}
	}

	public int x_jitter {
		get { return m_x_jitter; }
		set {
			if (m_x_jitter != value) {
				m_x_jitter = value;
				queue_draw();
			}
		}
	}

	public int y_jitter {
		get { return m_y_jitter; }
		set {
			if (m_y_jitter != value) {
				m_y_jitter = value;
				queue_draw();
			}
		}
	}

	public int noise {
		get { return m_noise; }
		set {
			if (m_noise != value) {
				m_noise = value;
				queue_draw();
			}
		}
	}

	public CharacterRenderer(FontChooser fch, CharacterDelegate d, int dim) {
		m_font_chooser = fch;
		m_char = d;
		dimension = dim;
		m_x_jitter = 0;
		m_y_jitter = 0;
		m_noise = 0;
	}

	public void render() {
		m_ctx.save();

		m_playout.set_font_description(m_font_chooser.get_font_desc());
		m_playout.set_markup(m_char().to_string(), -1);

		m_ctx.set_source_rgb(1, 1, 1);
		m_ctx.paint();

		// bounds debugging
		/*m_ctx.set_source_rgba(0, 1, 0, 0.7);
		m_ctx.set_line_width (1);
		m_ctx.rectangle(0, 0, m_dim - 1, m_dim - 1);
		m_ctx.stroke();*/

		m_ctx.set_source_rgb(0, 0, 0);

		m_playout.set_width((int)(m_dim * Pango.SCALE) );
		m_playout.set_ellipsize(Pango.EllipsizeMode.MIDDLE);
		m_playout.set_alignment(Pango.Alignment.CENTER);
		m_playout.set_justify(false);

		// apply jitter
		int xoffset = 0;
		int yoffset = m_dim / 2 - m_playout.get_baseline() / Pango.SCALE / 2;
		xoffset += m_dim * ((int)Random.next_int() % (2 * m_x_jitter + 1) - m_x_jitter) / 100;
		yoffset += m_dim * ((int)Random.next_int() % (2 * m_y_jitter + 1) - m_y_jitter) / 100;
		m_ctx.translate(xoffset, yoffset);

		m_playout.set_height((int)((m_dim - yoffset) * Pango.SCALE));

		cairo_show_layout(m_ctx, m_playout);

		// apply noise
		m_ctx.set_line_width(1.0);
		for (int y = 0; y < m_dim; ++y) {
			for (int x = 0; x < m_dim; ++x) {
				int val = 255 * ((int)Random.next_int() % (2 * m_noise + 1) - m_noise) / 100;
				if (val >= 0)
					m_ctx.set_source_rgba(1.0, 1.0, 1.0, (double)val / 255.0);
				else
					m_ctx.set_source_rgba(0.0, 0.0, 0.0, (double)(-val) / 255.0);
				m_ctx.rectangle(x, y, 1.0, 1.0);
				m_ctx.fill();
			}
		}

		m_ctx.restore();

		// make sure the surface pixels are accessible
		m_surf.flush();
	}

	public override bool draw (Cairo.Context ctx)
	{
		render();
		ctx.set_source_surface(m_surf, 0, 0);
		ctx.paint();
		return false;
	}

	public uint8[] get_pixel(uint x, uint y) {
		uint offset = (y * m_dim + x) * 3;
		return m_surf.get_data()[offset:offset + 3];
	}
}
