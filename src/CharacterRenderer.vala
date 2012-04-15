/**
PerceptVala character renderer widget
Written by Leszek Godlewski <github@inequation.org>
*/

using Gtk;
using Pango;

public class CharacterRenderer : Gtk.Misc {
	public delegate unichar CharacterDelegate();

	private FontChooser m_font_chooser;
	private int m_dim;
	private CharacterDelegate m_char;

	public int dimension {
		get { return m_dim; }
		set {
			height_request = width_request = m_dim = value;
			queue_draw();
		}
	}

	public CharacterRenderer(FontChooser fch, CharacterDelegate d, int dim) {
		m_font_chooser = fch;
		m_char = d;
		dimension = dim;
	}

	public override bool draw (Cairo.Context ctx) {
		var playout = Pango.cairo_create_layout(ctx);
		playout.set_font_description(m_font_chooser.get_font_desc());
		playout.set_markup(m_char().to_string(), -1);

		ctx.set_source_rgb(1, 1, 1);
		ctx.rectangle(0, 0, m_dim, m_dim);
		ctx.fill();

		// bounds debugging
		/*ctx.set_source_rgba(0, 1, 0, 0.7);
		ctx.set_line_width (1);
		ctx.rectangle(0, 0, m_dim - 1, m_dim - 1);
		ctx.stroke();*/

		ctx.set_source_rgb(0, 0, 0);

		playout.set_width((int)(m_dim * Pango.SCALE) );
		playout.set_ellipsize(Pango.EllipsizeMode.MIDDLE);
		playout.set_alignment(Pango.Alignment.CENTER);
		playout.set_justify(false);

		int offset = m_dim / 2 - playout.get_baseline() / Pango.SCALE / 2;
		ctx.translate(0, offset);

		playout.set_height((int)((m_dim - offset) * Pango.SCALE));

		cairo_show_layout(ctx, playout);

		return false;
	}
}
