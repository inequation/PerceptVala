/**
PerceptVala main file
Written by Leszek Godlewski <github@inequation.org>

@author Leszek Godlewski
*/

using Gee;

void main() {
	stdout.printf("Building network...\n");
	var img = new Image();

	var net = new NeuralNetwork(8);

	var hidden_layer = new ArrayList<Neuron>();
	for (uint i = 0; i < 8 * 8; ++i)
		hidden_layer.add(new Neuron());
	net.insert_layer(hidden_layer);

	var input_layer = new ArrayList<ImagePixel>();
	for (uint y = 0; y < 8; ++y) {
		for (uint x = 0; x < 8; ++x)
			input_layer.add(new ImagePixel(img, x, y));
	}
	net.insert_layer(input_layer);

	stdout.printf("Running network...\n");
	var results = net.run();
	stdout.printf("Results:\n");
	foreach (bool b in results)
		stdout.printf("%s\n", b ? "true" : "false");
}
