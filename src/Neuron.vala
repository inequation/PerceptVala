/**
PerceptVala neuron class
Written by Leszek Godlewski <github@inequation.org>
*/

public class Neuron {
	/** Neuron connection. */
	public class Synapse {
		public Neuron post;
		public Neuron ant;
		public float weight;
		public Synapse(Neuron posterior, Neuron anterior, float _weight) {
			post = posterior;
			ant = anterior;
			weight = _weight;
		}
	}

	public Neuron(bool is_tanh) {
		m_is_tanh = is_tanh;
		error = 0.0f;
	}

	public void add_synapse(Synapse s) {
		m_synapses += s;
	}

	public virtual float get_signal() {
		float activation = 0.0f;
		foreach (Synapse s in m_synapses) {
			activation += s.weight *
				(m_is_tanh ? (float)Math.tanh(s.ant.get_signal())
					: s.ant.get_signal());
		}
		return activation;
	}

	public float get_signal_derivative() {
		if (m_is_tanh) {
			// tanh(x)' = 1 - tanh^2(x)
			float y = get_signal();
			return 1.0f - y * y;
		}
		float activation = 0.0f;
		foreach (Synapse s in m_synapses) {
			if (!s.ant.is_bias_neuron())
				activation += s.weight;
		}
		return activation;
	}

	public float get_signal_error() {
		float activation = 0.0f;
		foreach (Synapse s in m_synapses) {
			if (!s.post.is_bias_neuron())
				activation += s.weight * s.post.error;
		}
		return activation;
	}

	public void update_weights(float rate) {
		foreach (Synapse s in m_synapses)
			s.weight += rate * error * s.ant.get_signal();
	}

	public virtual bool is_bias_neuron() { return false; }

	public float error;
	private Synapse[] m_synapses;
	private bool m_is_tanh;
}
