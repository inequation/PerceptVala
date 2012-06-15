/**
PerceptVala network error plot renderer
Written by Leszek Godlewski <github@inequation.org>
*/

using Gtk;
using Pango;
using Cairo;

public class ErrorPlotRenderer : Gtk.Misc {
	private ImageSurface m_surf;
	private Cairo.Context m_ctx;
	private double m_x;
	private double m_y;
	private double m_x_step;
	private double m_y_step;

	public ErrorPlotRenderer(int width, int height, double max_error, int num_ticks) {
		width_request = width;
		height_request = height;
		m_x = 0.0;
		m_y = 0.0;

		m_surf = new ImageSurface(Format.RGB24, width, height);
		m_ctx = new Cairo.Context(m_surf);

		// clear plot area with white
		m_ctx.set_source_rgb(1, 1, 1);
		m_ctx.paint();

		// prepare for drawing
		m_ctx.translate(0.0, (double)height);
		double xscale = (double)width / (double)num_ticks;
		double yscale = (double)height / (double)max_error;
		m_x_step = xscale / yscale;
		m_y_step = 1.0 / yscale;
		m_ctx.set_line_width(1.0 / yscale);
		m_ctx.scale(yscale, -yscale);
		m_ctx.set_source_rgb(1, 0, 0);
	}

	public void next_value(double error_value) {
		if (m_x == 0.0) {
			m_y = (double)error_value;
			m_ctx.set_source_rgb(0, 0, 1);
			m_ctx.move_to(0.0, m_y);
			m_ctx.line_to(width_request * m_y_step, m_y);
			m_ctx.stroke();
			m_ctx.set_source_rgb(1, 0, 0);
		}
		m_ctx.move_to(m_x, m_y);
		m_ctx.line_to(m_x += m_x_step, m_y = (double)error_value);
		m_ctx.stroke();
		m_surf.flush();
	}

	public void put_point(bool recognized) {
		if (recognized)
			m_ctx.set_source_rgb(0, 0.8, 0);
		else
			m_ctx.set_source_rgb(0.8, 0, 0);
		m_ctx.rectangle(m_x - 3.0 * m_x_step * m_y_step, m_y - 1.5 * m_y_step,
			6.0 * m_x_step * m_y_step, 3.0 * m_y_step);
		m_ctx.stroke();
		m_ctx.set_source_rgb(1, 0, 0);
	}

	public override bool draw (Cairo.Context ctx) {
		ctx.set_source_surface(m_surf, 0, 0);
		ctx.paint();
		return false;
	}
}
