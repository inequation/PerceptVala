/**
PerceptVala neuron class
Written by Leszek Godlewski <github@inequation.org>
*/

/**
 * Error domain for exceptions in activation calculation in neurons.
 */
public errordomain ActivationError {
	/**
	 * Activation has assumed the NaN or infinity value.
	 */
	IS_NAN_OR_INF
}

/**
 * Class representing a single neuron.
 */
public class Neuron {
#if DEBUG
	private static const double ACTIVATION_DANGER_THRESHOLD = 2.0;
#endif

	/**
	 * A connection between two neurons.
	 */
	public class Synapse {
		/**
		 * Reference to the posterior neuron, i.e. the receiving end.
		 */
		public Neuron? post;
		/**
		 * Reference to the posterior neuron, i.e. the transmitting end.
		 */
		public Neuron? ant;
		/**
		 * Weight that this synapse has for the posterior neuron.
		 */
		public double weight;
		/**
		 * Value of the last weight update. Used for learning momentum and
		 * rolling back weight updates that increase overall network error in
		 * the Bold Driver algorithm.
		 */
		public double last_weight_update;

		/**
		 * Basic constructor. Weight will be initialized to 0.0.
		 * @param posterior reference to the posterior (receiving) neuron
		 * @param anterior  reference to the anterior (transmitting) neuron
		 */
		public Synapse(Neuron? posterior, Neuron? anterior) {
			post = posterior;
			ant = anterior;
			last_weight_update = weight = 0.0;
		}
		/**
		 * Constructs the synapse with a pre-defined weight.
		 * @param posterior reference to the posterior (receiving) neuron
		 * @param anterior  reference to the anterior (transmitting) neuron
		 * @param _weight   weight to initialize the synapse with
		 */
		public Synapse.with_weight(Neuron? posterior, Neuron? anterior,
			double _weight) {
			this(posterior, anterior);
			weight = _weight;
		}
	}

	/**
	 * Basic neuron constructor.
	 * @param is_tanh   if true, this neuron will process its activation with the tanh() function
	 */
	public Neuron(bool is_tanh) {
		m_is_tanh = is_tanh;
		error = 0.0;
	}

	/**
	 * Adds a new synapse to one of the arrays, depending on this neuron's role
	 * in it (anterior or posterior).
	 */
	public void add_synapse(Synapse s) {
		assert(s.ant == this || s.post == this);
		if (s.ant == this)
			m_posterior += s;
		else
			m_anterior += s;
	}

	/**
	 * Queries the activation signal output.
	 * @return the activation signal output for this neuron
	 */
	public virtual double get_signal() throws ActivationError {
		double activation = 0.0;
#if DEBUG && VERBOSE
		int i = 0;
		double last_activation = activation;
#endif
		foreach (Synapse s in m_anterior) {
			double sgnl = s.ant.get_signal();
			if (m_is_tanh)
				sgnl = Math.tanh(sgnl);
			activation += s.weight * sgnl;
#if DEBUG && VERBOSE
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

	/**
	 * Queries the derivative of the activation signal output.
	 * @return derivative of the activation signal output for this neuron
	 */
	public double get_signal_derivative() throws ActivationError {
		if (m_is_tanh) {
			// tanh(x)' = 1 - tanh^2(x)
			double y = get_signal();
			return 1.0 - y * y;
		}
		double activation = 0.0;
#if DEBUG && VERBOSE
		int i = 0;
		double last_activation = activation;
#endif
		foreach (Synapse s in m_anterior) {
			if (!s.ant.is_bias_neuron()) {
				activation += s.weight;
#if DEBUG && VERBOSE
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

	/**
	 * Queries the error signal output.
	 * @return the error signal output for this neuron
	 */
	public double get_signal_error() throws ActivationError {
		double activation = 0.0;
#if DEBUG && VERBOSE
		int i = 0;
		double last_activation = activation;
#endif
		foreach (Synapse s in m_posterior) {
			if (!s.post.is_bias_neuron()) {
				activation += s.weight * s.post.error;
#if DEBUG && VERBOSE
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

	/**
	 * Queries the approximate variance of the error signal output.
	 * @return approximate variance of the error signal output for this neuron
	 */
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

	/**
	 * Updates all incoming synapse weights with the local learning rate,
	 * derived from the global one.
	 * @param rate      global learning rate
	 * @param momentum  momentum influence term
	 */
	public void update_weights(double rate, double momentum) throws ActivationError {
		var local_rate = rate / (m_anterior.length
			* Math.sqrt(get_error_variance()));

		foreach (Synapse s in m_anterior) {
			var update = local_rate * error * s.ant.get_signal()
				+ momentum * s.last_weight_update;
			s.weight += update;
			s.last_weight_update = update;
		}
	}

	/**
	 * Initializes all synapse weights to random values.
	 *
	 * The range of values is proportional to the square root of the number of
	 * anterior neurons.
	 */
	public void randomize_weights() {
		double r = 1.0 / Math.sqrt((double)m_anterior.length);
		foreach (Synapse s in m_anterior)
			s.weight = Random.double_range(-r, r);
	}

	/**
	 * Undoes the last weight update.
	 *
	 * A side effect is that the last weight update value is lost.
	 */
	public void rollback_last_update() {
		foreach (Synapse s in m_anterior) {
			s.weight -= s.last_weight_update;
			// clear out the last update - this disables momentum for the next
			// epoch, but prevents bugs
			s.last_weight_update = 0.0;
		}
	}

	/**
	 * Array of the posterior (receiving end) synapses.
	 */
	public Synapse[] posterior_synapses { get { return m_posterior; } }
	/**
	 * Array of the anterior (transmitting end) synapses.
	 */
	public Synapse[] anterior_synapses { get { return m_anterior; } }
	/**
	 * If true, this neuron processes its activation with the tanh() function.
	 */
	public bool is_tanh { get { return m_is_tanh; } }

	/**
	 * Queries whether this neuron is a bias neuron.
	 * @return if true, this neuron is the bias neuron
	 */
	public virtual bool is_bias_neuron() { return false; }

	/**
	 * Current signal error value.
	 */
	public double error;
	/**
	 * Array of the posterior (receiving end) synapses.
	 */
	private Synapse[] m_posterior;
	/**
	 * Array of the anterior (transmitting end) synapses.
	 */
	private Synapse[] m_anterior;
	/**
	 * The flag controlling whether this neuron processes the input with the
	 * tanh() function.
	 */
	private bool m_is_tanh;
}
