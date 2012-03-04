/**
PerceptVala neuron class
Written by Leszek Godlewski <github@inequation.org>

@author Leszek Godlewski
*/

public class Neuron {
	/** Neuron connection struct. */
	public struct Synapse {
		public Neuron neuron;
		public float weight;
	}

	public void add_synapse(Synapse s) {
		m_synapses += s;
	}

	public virtual float get_signal() {
		float activation = 0.0f;
		foreach (Synapse s in m_synapses) {
			//stdout.printf("%f * %f\n", s.neuron.get_signal(), s.weight);
			activation += s.neuron.get_signal() * s.weight;
		}
		return (activation >= 1.0f ? 1.0f : 0.0f);
	}

	private Synapse[] m_synapses;
}
