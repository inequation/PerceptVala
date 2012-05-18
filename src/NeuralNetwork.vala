/**
PerceptVala neural network class
Written by Leszek Godlewski <github@inequation.org>
*/

using Gee;

public class NeuralNetwork {
	/** Initializes a neural network with the given count of outputs. */
	public NeuralNetwork(uint outputs) {
		m_outputs = new ArrayList<Neuron>();
		for (uint i = 0; i < outputs; ++i)
			m_outputs.add(new Neuron(false));
		m_top_layer = m_outputs;
	}

	/**
	 * Appends the given neuron layer to the beginning of the network and
	 * creates synapses with random weights between them.
	 */
	public void insert_layer(ArrayList<Neuron> layer) {
		foreach (Neuron n2 in layer) {
			// add the bias neuron first
			n2.add_synapse({m_bias_neuron,
				2.0f * (float)Random.next_double() - 1.0f});
			// no reverse synapse for the bias neuron!
			// add synapses for the lower layer to pull the signal from
			foreach (Neuron n1 in m_top_layer) {
				n1.add_synapse({n2, 2.0f * (float)Random.next_double() - 1.0f});
				// also add a backward synapse for backprop
				n2.add_reverse_synapse(n1);
			}
		}
		m_top_layer = layer;
	}

	/**
	 * Runs the neural network.
	 * @return array of output signals
	 */
	public ArrayList<float?> run() {
		var results = new ArrayList<float?>();
		foreach (Neuron n in m_outputs)
			results.add(n.get_signal());
		return results;
	}

	/**
	 * Trains the neural network with the given example.
	 * @param target	array of target weights to descend to
	 */
	public void train(ArrayList<float?> target) {
		var r = run();
	}

	public ArrayList<Neuron> outputs {
		get { return m_outputs; }
	}

	public ArrayList<ImagePixel>? inputs {
		get { return (ArrayList<ImagePixel>)m_top_layer; }
	}

	private ArrayList<Neuron> m_outputs;
	private ArrayList<Neuron> m_top_layer;
	private static BiasNeuron m_bias_neuron = new BiasNeuron();
}
