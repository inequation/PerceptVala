/**
PerceptVala neural network class
Written by Leszek Godlewski <github@inequation.org>
*/

using Gee;

public class NeuralNetwork {
	private ArrayList<Neuron> m_outputs;
	private ArrayList<ArrayList<Neuron>> m_layers;
	private uint8 m_first_char;
	private uint m_age;
	private static BiasNeuron m_bias_neuron = new BiasNeuron();

	/**
	 * Initializes a neural network with the given count of outputs.
	 * @param	outputs		number of characters the network will distinguish between
	 * @param	first_char	code of first character
	 */
	public NeuralNetwork(uint outputs, uint8 first_char) {
		this.no_init(first_char);
		for (uint i = 0; i < outputs; ++i)
		{
			var neuron = new Neuron(false);
			neuron.add_synapse(new Neuron.Synapse(neuron, m_bias_neuron));
			m_outputs.add(neuron);
		}
		m_layers.insert(0, m_outputs);
	}

	/**
	 * A constructor that doesn't actually create the output layer. For
	 * internal use.
	 * @param	first_char	code of first character
	 */
	private NeuralNetwork.no_init(uint8 first_char) {
		m_outputs = new ArrayList<Neuron>();
		m_layers = new ArrayList<ArrayList<Neuron>>();
		m_first_char = first_char;
		m_age = 0;
	}

	/**
	 * Appends the given neuron layer to the beginning of the network and
	 * creates synapses with random weights between them.
	 */
	public void insert_layer(ArrayList<Neuron> layer) {
		foreach (Neuron n2 in layer) {
			// add the bias neuron first
			n2.add_synapse(new Neuron.Synapse(n2, m_bias_neuron));
			foreach (Neuron n1 in m_layers[0]) {
				var s = new Neuron.Synapse(n1, n2);
				n1.add_synapse(s);
				n2.add_synapse(s);
				// now initialize synapse weights to random ones, with the range
				// adjusted so that node paralysis and/or divergence is avoided
				n1.randomize_weights();
			}
		}
		m_layers.insert(0, layer);
	}

	/**
	 * Runs the neural network.
	 * @return array of output signals
	 */
	public ArrayList<double?> run() throws ActivationError {
		var results = new ArrayList<double?>();
		foreach (Neuron n in m_outputs) {
			double f = n.get_signal();
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
	 * @param momentum	momentum term
	 * @param target	array of target weights to descend to
	 * @return	the sum-squared error after the current training cycle
	 */
	public double train(double rate, double momentum, ArrayList<double?> target)
		throws ActivationError {
#if DEBUG && VERBOSE
		stdout.printf("Training at %f\n", rate);
#endif

		// compute forward activation
		var output = run();

		assert(output.size == target.size);

		// compute output error vector
		int i = 0;
#if DEBUG && VERBOSE
		int j = 0;
#endif
		foreach (Neuron n in m_outputs) {
			n.error = target[i] - output[i];
#if DEBUG && VERBOSE
			stdout.printf("Output error %d: %f - %f = %f\n", i, target[i],
				output[i], n.error);
#endif
			++i;
		}

		// backpropagation - don't affect input and output layers
		for (i = m_layers.size - 2; i > 0; --i) {
#if DEBUG && VERBOSE
			int j = 0;
#endif
			foreach (Neuron n in m_layers[i]) {
				double der = n.get_signal_derivative();
				double err = n.get_signal_error();
				n.error = der * err;
#if DEBUG && VERBOSE
				stdout.printf("layer: %d neuron: %d err: %f * %f = %f\n", i, j,
					der, err, n.error);
				++j;
#endif
			}
		}

		// update weights
		for (i = m_layers.size - 1; i > 0; --i) {
			foreach (Neuron n in m_layers[i])
				n.update_weights(rate, momentum);
		}

		// calculate sum-squared error
		double sse = 0.0;
		double diff;
		for (i = 0; i < m_outputs.size; ++i) {
			diff = target[i] - output[i];
			sse += diff * diff;
			++i;
		}

		++m_age;

		return sse;
	}

	public void rollback_last_update() {
		for (int i = m_layers.size - 1; i > 0; --i) {
			foreach (Neuron n in m_layers[i])
				n.rollback_last_update();
		}
	}

	public void serialize(string in_fname) {
		assert(sizeof(double) == sizeof(uint64));
		string fname;
		if (!in_fname.down().has_suffix(".net"))
			fname = "%s.net".printf(in_fname);
		else
			fname = in_fname;

		try {
			stdout.printf("Serializing network to file %s\n", fname);
			var f = File.new_for_path(fname);
			if (f.query_exists())
				f.delete();

			var dos = new DataOutputStream(f.create(FileCreateFlags.REPLACE_DESTINATION));
			dos.set_byte_order(DataStreamByteOrder.LITTLE_ENDIAN);

			dos.put_byte(m_first_char);
			dos.put_uint32((uint32)m_age);
			dos.put_int32(m_layers.size);
			// iterate over all layers from output to the first hidden layer
			for (int i = m_layers.size - 1; i > 0; --i) {
				var layer = m_layers[i];
				dos.put_int32(layer.size);
				dos.put_byte(layer[0].is_tanh ? 1 : 0);
				for (int j = 0; j < layer.size; ++j) {
					var neuron = layer[j];
					if (neuron.is_bias_neuron())
						continue;
					dos.put_int32(neuron.anterior_synapses.length);
					int k = 0;
					foreach (Neuron.Synapse s in neuron.anterior_synapses) {
						if (k == 0)
							assert(s.ant == m_bias_neuron);
						double? w = s.weight;
						dos.put_uint64(*((uint64 *)w));
						++k;
					}
				}
			}
			// and now output the number of inputs (lol)
			dos.put_int32(m_layers[0].size);
		} catch (Error e) {
			stdout.printf("Error serializing to file: %s\n", e.message);
		} finally {
			stdout.printf("Serialization done\n");
		}
	}

	public static NeuralNetwork? deserialize(string fname) {
		NeuralNetwork? net = null;
		assert(sizeof(double) == sizeof(uint64));
		try {
			stdout.printf("Deserializing network from file %s\n", fname);
			var f = File.new_for_path(fname);
			if (!f.query_exists()) {
				stdout.printf("File doesn't exist\n");
				return null;
			}

			var dis = new DataInputStream(f.read());
			dis.set_byte_order(DataStreamByteOrder.LITTLE_ENDIAN);

			net = new NeuralNetwork.no_init(dis.read_byte());
			assert(net != null);

			net.m_age = dis.read_int32();

			// create all the layers; synapses will be disconnected at first,
			// we'll reconstruct the network after all file reading is done
			var num_layers = dis.read_int32();
			for (int i = 0; i < num_layers - 1; ++i) {
				var layer_size = dis.read_int32();

				bool is_tanh = dis.read_byte() != 0;
				var layer = new ArrayList<Neuron>();
				for (int j = 0; j < layer_size; ++j) {
					var neuron = new Neuron(is_tanh);
					layer.add(neuron);
					var num_synapses = dis.read_int32();
					for (int k = 0; k < num_synapses; ++k) {
						uint64? w_as_int = dis.read_uint64();
						neuron.add_synapse(new Neuron.Synapse.with_weight
							(neuron,
							// first synapse always leads to the bias neuron
							k == 0 ? m_bias_neuron : null,
							*(double *)w_as_int));
					}
				}
				net.m_layers.insert(0, layer);

				// if it's the output layer, map the first layer to outputs
				if (i == 0)
					net.m_outputs = layer;
			}

			// create the input layer
			var count = dis.read_int32();
			var input_layer = new ArrayList<ImagePixel>();
			for (uint y = 0; y < (uint)Math.sqrt(count); ++y) {
				for (uint x = 0; x < (uint)Math.sqrt(count); ++x)
					input_layer.add(new ImagePixel(x, y));
			}
			net.m_layers.insert(0, input_layer);

			// now connect all the synapses
			for (int i = num_layers - 1; i > 0; --i) {
				var layer = net.m_layers[i];
				var ant_layer = net.m_layers[i - 1];
				for (int j = 0; j < layer.size; ++j) {
					var neuron = layer[j];
					// skip k = 0 because it's the bias neuron synapse
					for (int k = 1; k < neuron.anterior_synapses.length; ++k) {
						var synapse = neuron.anterior_synapses[k];
						assert(synapse.ant == null);
						assert(ant_layer.size > k - 1);
						synapse.ant = ant_layer[k - 1];
						synapse.ant.add_synapse(synapse);
					}
				}
			}
		} catch (Error e) {
			stdout.printf("Error deserializing from file: %s\n", e.message);
			return null;
		} finally {
			stdout.printf("Deserialization done\n");
		}
		return net;
	}

	public void dump_to_text_file(string in_fname) {
		string fname;
		if (!in_fname.down().has_suffix(".txt"))
			fname = "%s.txt".printf(in_fname);
		else
			fname = in_fname;

		try {
			stdout.printf("Dumping network to text file %s\n", fname);
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
					foreach (Neuron.Synapse s in neuron.posterior_synapses) {
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

	public ArrayList<ArrayList<Neuron>> layers {
		get {
			return m_layers;
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

	public uint8 first_char {
		get {
			return m_first_char;
		}
	}

	public uint age {
		get {
			return m_age;
		}
	}
}
