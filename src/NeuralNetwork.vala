/**
PerceptVala neural network class
Written by Leszek Godlewski <github@inequation.org>
*/

using Gee;

public class NeuralNetwork {
	/** Initializes a neural network with the given count of outputs. */
	public NeuralNetwork(uint outputs) {
		m_outputs = new ArrayList<Neuron>();
		m_layers = new ArrayList<ArrayList<Neuron>>();
		for (uint i = 0; i < outputs; ++i)
			m_outputs.add(new Neuron(false));
		m_layers.insert(0, m_outputs);
	}

	/**
	 * Appends the given neuron layer to the beginning of the network and
	 * creates synapses with random weights between them.
	 */
	public void insert_layer(ArrayList<Neuron> layer) {
		foreach (Neuron n2 in layer) {
			// add the bias neuron first
			n2.add_synapse(new Neuron.Synapse(n2, m_bias_neuron,
				get_initial_weight()));
			foreach (Neuron n1 in m_layers[0]) {
				var s = new Neuron.Synapse(n1, n2, get_initial_weight());
				n1.add_synapse(s);
				n2.add_synapse(s);
			}
		}
		m_layers.insert(0, layer);
	}

	/**
	 * Runs the neural network.
	 * @return array of output signals
	 */
	public ArrayList<float?> run() {
		var results = new ArrayList<float?>();
		foreach (Neuron n in m_outputs) {
			float f = n.get_signal();
			//stdout.printf("Activation: %f\n", f);
			results.add(f);
		}
		return results;
	}

	/**
	 * Trains the neural network with the given example.
	 * @param rate		learning rate
	 * @param target	array of target weights to descend to
	 */
	public void train(float rate, ArrayList<float?> target) {
		// clear all errors
		/*foreach (ArrayList<Neuron> layer in m_layers) {
			foreach (Neuron n in layer)
				n.error = 0.0f;
		}*/

		// compute forward activation
		var output = run();

		assert(output.size == target.size);

		// compute output error
		int i = 0;
		foreach (Neuron n in m_outputs) {
			n.error = target[i] - output[i];
			//stdout.printf("Output error %d: %f - %f = %f\n", i, target[i], output[i], n.error);
			++i;
		}

		int j;
		// backpropagation - don't affect input and output layers
		for (i = m_layers.size - 2; i > 0; --i) {
			j = 0;
			foreach (Neuron n in m_layers[i]) {
				stdout.printf("layer: %d neuron: %d der: %f err: %f\n", i, j,
					n.get_signal_derivative(), n.get_signal_error());
				n.error = n.get_signal_derivative() * n.get_signal_error();
				++j;
			}
		}

		// update weights
		//i = 0;
		foreach (ArrayList<Neuron> layer in m_layers) {
			//j = 0;
			foreach (Neuron n in layer) {
				/*if (i > 0)
					stdout.printf("layer: %d neuron: %d error: %f\n", i, j, n.error);*/
				n.update_weights(rate);
				//++j;
			}
			//++i;
		}
	}

	private float get_initial_weight() {
		return 0.0f;//(float)Random.next_double() - 0.5f);
	}

	public ArrayList<Neuron> outputs {
		get { return m_outputs; }
	}

	public ArrayList<ImagePixel>? inputs {
		get {
			ArrayList<Neuron> l = m_layers[0];
			return (ArrayList<ImagePixel>)l;
		}
	}

	private ArrayList<Neuron> m_outputs;
	private ArrayList<ArrayList<Neuron>> m_layers;
	private static BiasNeuron m_bias_neuron = new BiasNeuron();
}
