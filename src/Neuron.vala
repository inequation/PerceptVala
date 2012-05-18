/**
PerceptVala neuron class
Written by Leszek Godlewski <github@inequation.org>
*/

public class Neuron {
	public Neuron(bool is_tanh) {
		m_is_tanh = is_tanh;
	}

	/** Neuron connection struct. */
	public struct Synapse {
		public Neuron neuron;
		public float weight;
	}

	public void add_synapse(Synapse s) {
		m_synapses += s;
	}

	public void add_reverse_synapse(Neuron n) {
		m_rev_synapses += n;
	}

	public virtual float get_signal() {
		float activation = 0.0f;
		foreach (Synapse s in m_synapses) {
			activation += s.weight *
				(m_is_tanh ? (float)Math.tanh(s.neuron.get_signal())
					: s.neuron.get_signal());
		}
		return activation;
	}

	private Synapse[] m_synapses;
	private Neuron[] m_rev_synapses;
	private bool m_is_tanh;
}
