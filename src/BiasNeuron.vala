/**
PerceptVala unit bias neuron input class
Written by Leszek Godlewski <github@inequation.org>
*/

/**
 * A specialized, singleton bias neuron class.
 *
 * A bias neuron is one that has no inputs, only a constant 1.0 output. It's
 * used to bias the activation (with a proper weight) of all the other neurons.
 */
public class BiasNeuron : Neuron {
	/**
	 * Base constructor.
	 */
	public BiasNeuron() { base(false); }
	/**
	 * Queries the activation signal.
	 * @return a constant value of 1.0
	 */
	public override double get_signal() { return 1.0; }
	/**
	 * Checks if neuron is a bias neuron.
	 * @return always true
	 */
	public override bool is_bias_neuron() { return true; }
}
