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

	public override float get_signal() {
		if (image == null)
			return 0.0f;
		uint8[] pixel = image.get_pixel(m_x, m_y);
		return 0.2126f * ((float)pixel[0] / 255.0f)
				+ 0.7152f * ((float)pixel[1] / 255.0f)
				+ 0.0722f * ((float)pixel[2] / 255.0f);
	}

	public CharacterRenderer? image;
	private uint m_x;
	private uint m_y;
}
