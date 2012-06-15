/**
PerceptVala neuron class
Written by Leszek Godlewski <github@inequation.org>
*/

public class Neuron {
#if DEBUG
	private static const float ACTIVATION_DANGER_THRESHOLD = 10.0f;
#endif

	/** Neuron connection. */
	public class Synapse {
		public Neuron? post;
		public Neuron? ant;
		public float weight;
		public Synapse(Neuron? posterior, Neuron? anterior, float _weight) {
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
		if (s.ant == this)
			m_posterior += s;
		else
			m_anterior += s;
	}

	public virtual float get_signal() {
		float activation = 0.0f;
#if DEBUG
		int i = 0;
		float last_activation = activation;
#endif
		foreach (Synapse s in m_anterior) {
			float sgnl = s.ant.get_signal();
			if (m_is_tanh)
				sgnl = Math.tanhf(sgnl);
			activation += s.weight * sgnl;
#if DEBUG
			// FIXME: report bug that is_infinity() returns int?
			if (Math.fabsf(activation) > ACTIVATION_DANGER_THRESHOLD
				|| activation.is_nan() || (bool)activation.is_infinity()) {
				if (!last_activation.is_nan()
					&& !(bool)last_activation.is_infinity()) {
					stdout.printf("get_signal(): Activation became %f in "
						+ "synapse #%d after %f + w = %f * s = %f\n",
						activation, i, last_activation, s.weight, sgnl);
				}
			}
			last_activation = activation;
			++i;
#endif
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
#if DEBUG
		int i = 0;
		float last_activation = activation;
#endif
		foreach (Synapse s in m_anterior) {
			if (!s.ant.is_bias_neuron()) {
				activation += s.weight;
#if DEBUG
				// FIXME: report bug that is_infinity() returns int?
				if (Math.fabsf(activation) > ACTIVATION_DANGER_THRESHOLD
					|| activation.is_nan() || (bool)activation.is_infinity()) {
					if (!last_activation.is_nan()
						&& !(bool)last_activation.is_infinity()) {
						stdout.printf("get_signal_derivative(): Activation "
							+ "became %f in synapse #%d after %f + w = %f\n",
							activation, i, last_activation, s.weight);
					}
				}
				last_activation = activation;
				++i;
#endif
			}
		}
		return activation;
	}

	public float get_signal_error() {
		float activation = 0.0f;
#if DEBUG
		int i = 0;
		float last_activation = activation;
#endif
		foreach (Synapse s in m_posterior) {
			if (!s.post.is_bias_neuron()) {
				activation += s.weight * s.post.error;
#if DEBUG
				// FIXME: report bug that is_infinity() returns int?
				if (Math.fabsf(activation) > ACTIVATION_DANGER_THRESHOLD
					|| activation.is_nan() || (bool)activation.is_infinity()) {
					if (!last_activation.is_nan()
						&& !(bool)last_activation.is_infinity()) {
						stdout.printf("get_signal_error(): Activation became "
							+ "%f in synapse #%d after %f + w = %f * e = %f\n",
							activation, i, last_activation, s.weight,
							s.post.error);
					}
				}
				last_activation = activation;
				++i;
#endif
			}
		}
		return activation;
	}

	public void update_weights(float rate) {
		foreach (Synapse s in m_anterior)
			s.weight += rate * error * s.ant.get_signal();
	}

	public Synapse[] posterior_synapses { get { return m_posterior; } }
	public Synapse[] anterior_synapses { get { return m_anterior; } }
	public bool is_tanh { get { return m_is_tanh; } }

	public virtual bool is_bias_neuron() { return false; }

	public float error;
	private Synapse[] m_posterior;
	private Synapse[] m_anterior;
	private bool m_is_tanh;
}
