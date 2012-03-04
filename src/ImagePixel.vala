/**
PerceptVala image pixel neuron input class
Written by Leszek Godlewski <github@inequation.org>

@author Leszek Godlewski
*/

public class ImagePixel : Neuron {
	public ImagePixel(Image img, uint x, uint y) {
		m_img = img;
		m_x = x;
		m_y = y;
	}

	public override float get_signal() {
		uint8[] pixel = m_img.get_pixel(m_x, m_y);
		return 0.2126f * ((float)pixel[0] / 255.0f)
				+ 0.7152f * ((float)pixel[1] / 255.0f)
				+ 0.0722f * ((float)pixel[2] / 255.0f);
	}

	private Image m_img;
	private uint m_x;
	private uint m_y;
}
