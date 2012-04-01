/**
PerceptVala neural network class
Written by Leszek Godlewski <github@inequation.org>
*/

using Gdk;

/** Wrapper for Gdk.Pixbuf-backed bitmap loader. */
public class Image {
	public uint8[] get_pixel(uint x, uint y) {
		// TODO
		uint8 p = m_the_character[y, x];
		return new uint8[] {p, p, p};
	}

	// this is a 'K' letter, in case you can't see
	private static uint8[,] m_the_character = {
		{0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00},
		{0x00, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0xFF, 0xFF},
		{0x00, 0xFF, 0x00, 0x00, 0xFF, 0x00, 0xFF, 0xFF},
		{0x00, 0x00, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF},
		{0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF},
		{0x00, 0xFF, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF},
		{0x00, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0xFF, 0xFF},
		{0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00}
	};
}
