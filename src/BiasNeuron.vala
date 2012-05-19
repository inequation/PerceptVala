/**
PerceptVala unit bias neuron input class
Written by Leszek Godlewski <github@inequation.org>
*/

public class BiasNeuron : Neuron {
	public BiasNeuron() {
		base(false);
	}

	public override float get_signal() {
		return 1.0f;
	}
}
