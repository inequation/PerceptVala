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

	private ImageSurface m_surf;
	private Cairo.Context m_ctx;
	private Pango.Layout m_playout;

	public int dimension {
		get { return m_dim; }
		set {
			if (value != m_dim) {
				height_request = width_request = m_dim = value;
				m_surf = new ImageSurface(Format.RGB24, m_dim, m_dim);
				m_ctx = new Cairo.Context(m_surf);
				m_playout = Pango.cairo_create_layout(m_ctx);
				queue_draw();
			}
		}
	}

	public CharacterRenderer(FontChooser fch, CharacterDelegate d, int dim) {
		m_font_chooser = fch;
		m_char = d;
		dimension = dim;
	}

	private void render(Cairo.Context ctx) {
		ctx.save();

		m_playout.set_font_description(m_font_chooser.get_font_desc());
		m_playout.set_markup(m_char().to_string(), -1);

		ctx.set_source_rgb(1, 1, 1);
		ctx.paint();

		// bounds debugging
		/*ctx.set_source_rgba(0, 1, 0, 0.7);
		ctx.set_line_width (1);
		ctx.rectangle(0, 0, m_dim - 1, m_dim - 1);
		ctx.stroke();*/

		ctx.set_source_rgb(0, 0, 0);

		m_playout.set_width((int)(m_dim * Pango.SCALE) );
		m_playout.set_ellipsize(Pango.EllipsizeMode.MIDDLE);
		m_playout.set_alignment(Pango.Alignment.CENTER);
		m_playout.set_justify(false);

		int offset = m_dim / 2 - m_playout.get_baseline() / Pango.SCALE / 2;
		ctx.translate(0, offset);

		m_playout.set_height((int)((m_dim - offset) * Pango.SCALE));

		cairo_show_layout(ctx, m_playout);

		ctx.restore();
	}

	public override bool draw (Cairo.Context ctx)
	{
		render(m_ctx);
		ctx.set_source_surface(m_surf, 0, 0);
		ctx.paint();
		return false;
	}
}
