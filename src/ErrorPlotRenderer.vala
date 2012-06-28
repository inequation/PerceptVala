/**
PerceptVala network error plot renderer
Written by Leszek Godlewski <github@inequation.org>
*/

using Gtk;
using Pango;
using Cairo;

/**
 * Network sum-squared error plot renderer widget.
 */
public class ErrorPlotRenderer : Gtk.Misc {
	private ImageSurface m_surf;
	private Cairo.Context m_ctx;
	private double m_x;
	private double m_y;
	private double m_x_step;
	private double m_y_scale;

	/**
	 * Base constructor.
	 * @param width     requested width of the widget
	 * @param height    requested height of the widget
	 * @param max_error maximum value on the Y axis (maximum error)
	 * @param num_ticks maximum value on the X axis (number of learning ticks, i.e. number of examples * number of epochs)
	 */
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
		m_y_scale = (double)height / (double)max_error;
		m_x_step = xscale / m_y_scale;
		m_ctx.set_line_width(1.0 / m_y_scale);
		m_ctx.scale(m_y_scale, -m_y_scale);
		m_ctx.set_source_rgb(1, 0, 0);
	}

	/**
	 * Appends a new data point to the plot.
	 * @param error_value   Y value (error) of the new data point
	 */
	public void next_value(double error_value) {
		if (m_x == 0.0) {
			m_y = (double)error_value;
			m_ctx.set_source_rgb(0, 0, 1);
			m_ctx.move_to(0.0, m_y);
			m_ctx.line_to(width_request / m_y_scale, m_y);
			m_ctx.stroke();
			m_ctx.set_source_rgb(1, 0, 0);
		}
		m_ctx.move_to(m_x, m_y);
		m_ctx.line_to(m_x += m_x_step, m_y = (double)error_value);
		m_ctx.stroke();
		m_surf.flush();
	}

	/**
	 * Places a square point at the last data point. May be used to visually
	 * distinguish passing and failing data points.
	 * @param pass  if true, the point will be drawn with the pass colour; with the fail one otherwise
	 */
	public void put_point(bool pass) {
		if (pass)
			m_ctx.set_source_rgb(0, 0.8, 0);
		else
			m_ctx.set_source_rgb(0.8, 0, 0);
		m_ctx.rectangle(m_x - 2.0 / m_y_scale, m_y - 2.0 / m_y_scale,
			4.0 / m_y_scale, 4.0 / m_y_scale);
		m_ctx.fill();
		m_ctx.set_source_rgb(1, 0, 0);
	}

	/**
	 * GTK widget drawing handler.
	 * @param ctx   Cairo context for drawing on the widget's surface
	 */
	public override bool draw (Cairo.Context ctx) {
		ctx.set_source_surface(m_surf, 0, 0);
		ctx.paint();
		return false;
	}
}
