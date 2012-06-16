/**
PerceptVala unit bias neuron input class
Written by Leszek Godlewski <github@inequation.org>
*/

public class BiasNeuron : Neuron {
	public BiasNeuron() { base(false); }
	public override double get_signal() { return 1.0; }
	public override bool is_bias_neuron() { return true; }
}
