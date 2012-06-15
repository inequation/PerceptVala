/**
PerceptVala image pixel neuron input class
Written by Leszek Godlewski <github@inequation.org>
*/

public class ImagePixel : Neuron {
	public ImagePixel(uint x, uint y) {
		base(false);
		m_x = x;
		m_y = y;
		image = null;
	}

	public override double get_signal() {
		if (image == null)
			return 1.0;
		uint8[] pixel = image.get_pixel(m_x, m_y);
		return 0.2126 * ((double)pixel[0] / 255.0)
				+ 0.7152 * ((double)pixel[1] / 255.0)
				+ 0.0722 * ((double)pixel[2] / 255.0);
	}

	public CharacterRenderer? image;
	private uint m_x;
	private uint m_y;
}
