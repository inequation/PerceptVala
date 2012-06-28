/**
PerceptVala image pixel neuron input class
Written by Leszek Godlewski <github@inequation.org>
*/

/**
 * The specialized neuron class that percepts a single character bitmap pixel.
 *
 * It has no inputs, just the output signal, which is calculated as luminance
 * (weighted average of the RGB channels) and normalized to the [-1, 1] range
 * (-1 is black, 1 is white).
 */
public class ImagePixel : Neuron {
	/**
	 * Base constructor.
	 * @param x X coordinate of the pixel to look at
	 * @param y Y coordinate of the pixel to look at
	 */
	public ImagePixel(uint x, uint y) {
		base(false);
		m_x = x;
		m_y = y;
		image = null;
	}

	/**
	 * Queries the luminance of the pixel looked at.
	 * @return luminance of the pixel looked at
	 */
	public override double get_signal() {
		if (image == null)
			return 0.0;
		uint8[] pixel = image.get_pixel(m_x, m_y);
		// desaturation + normalization
		return -1.0 + 2.0 *
			(0.2126 * ((double)pixel[0] / 255.0)
			+ 0.7152 * ((double)pixel[1] / 255.0)
			+ 0.0722 * ((double)pixel[2] / 255.0));
	}

	/**
	 * Reference to the CharacterRenderer whose bitmap is examined.
	 */
	public CharacterRenderer? image;
	private uint m_x;
	private uint m_y;
}
