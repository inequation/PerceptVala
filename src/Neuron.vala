/**
PerceptVala neuron class
Written by Leszek Godlewski <github@inequation.org>
*/

public errordomain ActivationError {
	IS_NAN_OR_INF
}

public class Neuron {
#if DEBUG
	private static const double ACTIVATION_DANGER_THRESHOLD = 2.0;
#endif

	/** Neuron connection. */
	public class Synapse {
		public Neuron? post;
		public Neuron? ant;
		public double weight;
		public double last_weight_update;
		public Synapse(Neuron? posterior, Neuron? anterior) {
			post = posterior;
			ant = anterior;
			last_weight_update = weight = 0.0;
		}
		public Synapse.with_weight(Neuron? posterior, Neuron? anterior,
			double _weight) {
			this(posterior, anterior);
			weight = _weight;
		}
	}

	public Neuron(bool is_tanh) {
		m_is_tanh = is_tanh;
		error = 0.0;
	}

	public void add_synapse(Synapse s) {
		if (s.ant == this)
			m_posterior += s;
		else
			m_anterior += s;
	}

	public virtual double get_signal() throws ActivationError {
		double activation = 0.0;
#if DEBUG
		int i = 0;
		double last_activation = activation;
#endif
		foreach (Synapse s in m_anterior) {
			double sgnl = s.ant.get_signal();
			if (m_is_tanh)
				sgnl = Math.tanh(sgnl);
			activation += s.weight * sgnl;
#if DEBUG
			// FIXME: report bug that is_infinity() returns int?
			if (Math.fabs(activation) > ACTIVATION_DANGER_THRESHOLD
				|| activation.is_nan() || (bool)activation.is_infinity()) {
				if (Math.fabs(last_activation) <= ACTIVATION_DANGER_THRESHOLD
					&& !last_activation.is_nan() && !(bool)last_activation.is_infinity()) {
					stdout.printf("get_signal(): Activation became %f in "
						+ "synapse #%d after %f + w = %f * s = %f\n",
						activation, i, last_activation, s.weight, sgnl);
				}
			}
			last_activation = activation;
			++i;
#endif
			if (activation.is_nan() || (bool)activation.is_infinity())
				throw new ActivationError.IS_NAN_OR_INF("get_signal");
		}
		return activation;
	}

	public double get_signal_derivative() throws ActivationError {
		if (m_is_tanh) {
			// tanh(x)' = 1 - tanh^2(x)
			double y = get_signal();
			return 1.0 - y * y;
		}
		double activation = 0.0;
#if DEBUG
		int i = 0;
		double last_activation = activation;
#endif
		foreach (Synapse s in m_anterior) {
			if (!s.ant.is_bias_neuron()) {
				activation += s.weight;
#if DEBUG
				// FIXME: report bug that is_infinity() returns int?
				if (Math.fabs(activation) > ACTIVATION_DANGER_THRESHOLD
					|| activation.is_nan() || (bool)activation.is_infinity()) {
					if (Math.fabs(last_activation) <= ACTIVATION_DANGER_THRESHOLD
						&& !last_activation.is_nan() && !(bool)last_activation.is_infinity()) {
						stdout.printf("get_signal_derivative(): Activation "
							+ "became %f in synapse #%d after %f + w = %f\n",
							activation, i, last_activation, s.weight);
					}
				}
				last_activation = activation;
				++i;
#endif
				if (activation.is_nan() || (bool)activation.is_infinity())
					throw new ActivationError.IS_NAN_OR_INF("get_signal_derivative");
			}
		}
		return activation;
	}

	public double get_signal_error() throws ActivationError {
		double activation = 0.0;
#if DEBUG
		int i = 0;
		double last_activation = activation;
#endif
		foreach (Synapse s in m_posterior) {
			if (!s.post.is_bias_neuron()) {
				activation += s.weight * s.post.error;
#if DEBUG
				// FIXME: report bug that is_infinity() returns int?
				if (Math.fabs(activation) > ACTIVATION_DANGER_THRESHOLD
					|| activation.is_nan() || (bool)activation.is_infinity()) {
					if (Math.fabs(last_activation) <= ACTIVATION_DANGER_THRESHOLD
						&& !last_activation.is_nan() && !(bool)last_activation.is_infinity()) {
						stdout.printf("get_signal_error(): Activation became "
							+ "%f in synapse #%d after %f + w = %f * e = %f\n",
							activation, i, last_activation, s.weight,
							s.post.error);
					}
				}
				last_activation = activation;
				++i;
#endif
				if (activation.is_nan() || (bool)activation.is_infinity())
					throw new ActivationError.IS_NAN_OR_INF("get_signal_error");
			}
		}
		return activation;
	}

	public double get_error_variance() {
		double v;
		// output nodes have it simpler
		if (m_posterior.length == 0)
			v = 1.0;
		else {
			v = 0.0;
			foreach (Synapse s in m_posterior)
				v += s.post.get_error_variance();
		}
		return v / (double)m_anterior.length;
	}

	public void update_weights(double rate, double momentum) throws ActivationError {
		var local_rate = rate / (m_anterior.length
			* Math.sqrt(get_error_variance()));

		foreach (Synapse s in m_anterior) {
			s.weight += local_rate * error * s.ant.get_signal()
				+ momentum * s.last_weight_update;
			s.last_weight_update = s.weight;
		}
	}

	public void randomize_weights() {
		double r = 1.0 / Math.sqrt((double)m_anterior.length);
		foreach (Synapse s in m_anterior)
			s.weight = Random.double_range(-r, r);
	}

	public Synapse[] posterior_synapses { get { return m_posterior; } }
	public Synapse[] anterior_synapses { get { return m_anterior; } }
	public bool is_tanh { get { return m_is_tanh; } }

	public virtual bool is_bias_neuron() { return false; }

	public double error;
	private Synapse[] m_posterior;
	private Synapse[] m_anterior;
	private bool m_is_tanh;
}
