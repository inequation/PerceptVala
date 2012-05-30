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
#if DEBUG && VERBOSE
			stdout.printf("Result activation: %f\n", f);
#endif
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
		// compute forward activation
		var output = run();

		assert(output.size == target.size);

		// compute output error
		int i = 0;
#if DEBUG && VERBOSE
		int j = 0;
#endif
		foreach (Neuron n in m_outputs) {
			n.error = target[i] - output[i];
#if DEBUG && VERBOSE
			stdout.printf("Output error %d: %f - %f = %f\n", i, target[i],
				output[i], n.error);
			++i;
#endif
		}

		// backpropagation - don't affect input and output layers
		for (i = m_layers.size - 2; i > 0; --i) {
#if DEBUG && VERBOSE
			j = 0;
#endif
			foreach (Neuron n in m_layers[i]) {
				float der = n.get_signal_derivative();
				float err = n.get_signal_error();
				n.error = der * err;
#if DEBUG && VERBOSE
				stdout.printf("layer: %d neuron: %d err: %f * %f = %f\n", i, j,
					der, err, n.error);
				++j;
#endif
			}
		}

		// update weights
#if DEBUG && VERBOSE
		i = 0;
#endif
		foreach (ArrayList<Neuron> layer in m_layers) {
#if DEBUG && VERBOSE
			j = 0;
#endif
			foreach (Neuron n in layer) {
#if DEBUG && VERBOSE
				if (i > 0)
					stdout.printf("layer: %d neuron: %d error: %f\n", i, j,
						n.error);
#endif
				n.update_weights(rate);
#if DEBUG && VERBOSE
				++j;
#endif
			}
#if DEBUG && VERBOSE
			++i;
#endif
		}
	}

	private float get_initial_weight() {
		return 0.0f;//(float)Random.next_double() - 0.5f;
	}

	public void dump_to_file(string fname) {
		try {
			stdout.printf("Dumping network to file %s\n", fname);
			var f = File.new_for_path(fname);
			if (f.query_exists())
				f.delete();

			var dos = new DataOutputStream(f.create(FileCreateFlags.REPLACE_DESTINATION));

			for (int i = 0; i < m_layers.size; ++i) {
				var layer = m_layers[i];
				dos.put_string("Layer %d: %s, %s\n".printf(i, i == 0 ? "input" :
					(i == m_layers.size - 1 ? "output" : "hidden"),
					layer[0].is_tanh ? "tanh()" : "linear"));
				for (int j = 0; j < layer.size; ++j) {
					var neuron = layer[j];
					dos.put_string("\tLayer %d Neuron %d: err = %f\n".printf(i,
						j, neuron.error));
					int k = 0;
					foreach (Neuron.Synapse s in neuron.synapses) {
						if (s.ant == neuron)
							continue;
						dos.put_string("\t\t-> Layer %d Neuron %d: %f\n".printf(
							i + 1, k, s.weight));
						++k;
					}
				}
			}
		} catch (Error e) {
			stdout.printf("Error dumping to file: %s\n", e.message);
		} finally {
			stdout.printf("Dumping done\n");
		}
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
