from cpython.pycapsule cimport PyCapsule_New

try:
    from threading import Lock
except ImportError:
    from dummy_threading import Lock

import numpy as np

from randomgen.common cimport *
from randomgen.distributions cimport bitgen_t
from randomgen.entropy import random_entropy, seed_by_array

__all__ = ['Philox']

np.import_array()

DEF PHILOX_BUFFER_SIZE=4

# Keeping these here makes a large difference (2x) to performance
cdef uint64_t philox2x64_uint64(void*st) nogil:
    return philox2x64_next64(<philox_all_t *> st)
cdef uint32_t philox2x64_uint32(void *st) nogil:
    return philox2x64_next32(<philox_all_t *> st)
cdef double philox2x64_double(void*st) nogil:
    return philox2x64_next_double(<philox_all_t *> st)

cdef uint64_t philox4x64_uint64(void*st) nogil:
    return philox4x64_next64(<philox_all_t *> st)
cdef uint32_t philox4x64_uint32(void *st) nogil:
    return philox4x64_next32(<philox_all_t *> st)
cdef double philox4x64_double(void*st) nogil:
    return philox4x64_next_double(<philox_all_t *> st)

cdef uint64_t philox4x32_uint64(void*st) nogil:
    return philox4x32_next64(<philox_all_t *> st)
cdef uint32_t philox4x32_uint32(void *st) nogil:
    return philox4x32_next32(<philox_all_t *> st)
cdef double philox4x32_double(void*st) nogil:
    return philox4x32_next_double(<philox_all_t *> st)
cdef uint64_t philox4x32_raw(void *st) nogil:
    return <uint64_t>philox4x32_next32(<philox_all_t *> st)

cdef uint64_t philox2x32_uint64(void*st) nogil:
    return philox2x32_next64(<philox_all_t *> st)
cdef uint32_t philox2x32_uint32(void *st) nogil:
    return philox2x32_next32(<philox_all_t *> st)
cdef double philox2x32_double(void*st) nogil:
    return philox2x32_next_double(<philox_all_t *> st)
cdef uint64_t philox2x32_raw(void *st) nogil:
    return <uint64_t>philox2x32_next32(<philox_all_t *> st)

cdef class Philox:
    """
    Philox(seed=None, counter=None, key=None, number=4, width=64)

    Container for the Philox (4x64) pseudo-random number generator.

    Parameters
    ----------
    seed : {None, int, array_like}, optional
        Random seed initializing the pseudo-random number generator.
        Can be an integer in [0, 2**64-1], array of integers in
        [0, 2**64-1] or ``None`` (the default). If `seed` is ``None``,
        data will be read from ``/dev/urandom`` (or the Windows analog)
        if available.  If unavailable, a hash of the time and process ID is
        used.
    counter : {None, int, array_like}, optional
        Counter to use in the Philox state. Can be either
        a Python int (long in 2.x) in [0, 2**256) or a 4-element uint64 array.
        If not provided, the RNG is initialized at 0.
    key : {None, int, array_like}, optional
        Key to use in the Philox state.  Unlike seed, which is run through
        another RNG before use, the value in key is directly set. Can be either
        a Python int (long in 2.x) in [0, 2**128) or a 2-element uint64 array.
        key and seed cannot both be used.
    number : {2, 4}, optional
        Number of values to produce in a single call. Maps to N in the Philox
        variant naming scheme PhiloxNxW.
    width : {32, 64}, optional
        Bit width the values produced. Maps to W in the Philox variant naming
        scheme PhiloxNxW.

    Attributes
    ----------
    lock: threading.Lock
        Lock instance that is shared so that the same bit git generator can
        be used in multiple Generators without corrupting the state. Code that
        generates values from a bit generator should hold the bit generator's
        lock.

    Notes
    -----
    Philox is a 64-bit PRNG that uses a counter-based design based on
    weaker (and faster) versions of cryptographic functions [1]_. Instances
    using different values of the key produce independent sequences.  ``Philox``
    has a period of :math:`2^{256} - 1` and supports arbitrary advancing and
    jumping the sequence in increments of :math:`2^{128}`. These features allow
    multiple non-overlapping sequences to be generated.

    ``Philox`` provides a capsule containing function pointers that produce
    doubles, and unsigned 32 and 64- bit integers. These are not
    directly consumable in Python and must be consumed by a ``Generator``
    or similar object that supports low-level access.

    See ``ThreeFry`` for a closely related PRNG.

    **State and Seeding**

    The ``Philox`` state vector consists of a 2 256-bit values encoded as
    4-element uint64 arrays. One is a counter which is incremented by 1 for
    every 4 64-bit randoms produced.  The second is a key which determined
    the sequence produced.  Using different keys produces independent
    sequences.

    ``Philox`` is seeded using either a single 64-bit unsigned integer
    or a vector of 64-bit unsigned integers.  In either case, the seed is
    used as an input for a second random number generator,
    SplitMix64, and the output of this PRNG function is used as the initial state.
    Using a single 64-bit value for the seed can only initialize a small range of
    the possible initial state values.

    **Parallel Features**

    ``Philox`` can be used in parallel applications by calling the ``jump``
    method  to advances the state as-if :math:`2^{128}` random numbers have
    been generated. Alternatively, ``advance`` can be used to advance the
    counter for any positive step in [0, 2**256). When using ``jump``, all
    generators should be initialized with the same seed to ensure that the
    segments come from the same sequence.

    >>> from randomgen import Generator, Philox
    >>> rg = [Generator(Philox(1234)) for _ in range(10)]
    # Advance each Philox instance by i jumps
    >>> for i in range(10):
    ...     rg[i].bit_generator.jump(i)

    Alternatively, ``Philox`` can be used in parallel applications by using
    a sequence of distinct keys where each instance uses different key.

    >>> key = 2**196 + 2**132 + 2**65 + 2**33 + 2**17 + 2**9
    >>> rg = [Generator(Philox(key=key+i)) for i in range(10)]

    **Compatibility Guarantee**

    ``Philox`` makes a guarantee that a fixed seed and will always produce
    the same random integer stream.

    Examples
    --------
    >>> from randomgen import Generator, Philox
    >>> rg = Generator(Philox(1234))
    >>> rg.standard_normal()
    0.123  # random

    Identical method using only Philox

    >>> rg = Philox(1234).generator
    >>> rg.standard_normal()
    0.123  # random

    References
    ----------
    .. [1] John K. Salmon, Mark A. Moraes, Ron O. Dror, and David E. Shaw,
           "Parallel Random Numbers: As Easy as 1, 2, 3," Proceedings of
           the International Conference for High Performance Computing,
           Networking, Storage and Analysis (SC11), New York, NY: ACM, 2011.
    """
    cdef philox_all_t rng_state

    cdef bitgen_t _bitgen
    cdef public object capsule
    cdef object _ctypes
    cdef object _cffi
    cdef public object lock
    cdef int n
    cdef int w

    def __init__(self, seed=None, counter=None, key=None, number=4, width=64):
        if number not in (2, 4):
            raise ValueError('number must be either 2 or 4')
        if width not in (32, 64):
            raise ValueError('width must be either 32 or 64')
        self.n = number
        self.w = width
        self.rng_state.number = number
        self.rng_state.width = width
        self._bitgen.state = <void *>&self.rng_state

        self.seed(seed, counter, key)
        self.lock = Lock()
        self._setup_generator()

        self._ctypes = None
        self._cffi = None

        cdef const char *name = 'BitGenerator'
        self.capsule = PyCapsule_New(<void *>&self._bitgen, name, NULL)

    def _setup_generator(self):
        """Set the functions that will generate the values"""
        if self.n==4 and self.w == 64:
            self._bitgen.next_uint64 = &philox4x64_uint64
            self._bitgen.next_uint32 = &philox4x64_uint32
            self._bitgen.next_double = &philox4x64_double
            self._bitgen.next_raw = &philox4x64_uint64
        elif self.n==2 and self.w == 64:
            self._bitgen.next_uint64 = &philox2x64_uint64
            self._bitgen.next_uint32 = &philox2x64_uint32
            self._bitgen.next_double = &philox2x64_double
            self._bitgen.next_raw = &philox2x64_uint64
        elif self.n==4 and self.w == 32:
            self._bitgen.next_uint64 = &philox4x32_uint64
            self._bitgen.next_uint32 = &philox4x32_uint32
            self._bitgen.next_double = &philox4x32_double
            self._bitgen.next_raw = &philox4x32_raw
        elif self.n==2 and self.w == 32:
            self._bitgen.next_uint64 = &philox2x32_uint64
            self._bitgen.next_uint32 = &philox2x32_uint32
            self._bitgen.next_double = &philox2x32_double
            self._bitgen.next_raw = &philox2x32_raw

    def __repr__(self):
        out = object.__repr__(self)
        out = out.replace('Philox',
                          'Philox (' + str(self.n) + 'x' + str(self.w) + ')')
        return out

    # Pickling support:
    def __getstate__(self):
        return self.state

    def __setstate__(self, state):
        self.state = state

    def __reduce__(self):
        from randomgen._pickle import __bit_generator_ctor
        return __bit_generator_ctor, (self.state['bit_generator'],), self.state

    cdef _reset_state_variables(self):
        self.rng_state.uinteger = 0
        self.rng_state.has_uint32 = 0
        self.rng_state.buffer_pos = PHILOX_BUFFER_SIZE
        for i in range(PHILOX_BUFFER_SIZE):
            self.rng_state.buffer[i].u64 = 0

    def random_raw(self, size=None, output=True):
        """
        random_raw(self, size=None)

        Return randoms as generated by the underlying BitGenerator

        Parameters
        ----------
        size : int or tuple of ints, optional
            Output shape.  If the given shape is, e.g., ``(m, n, k)``, then
            ``m * n * k`` samples are drawn.  Default is None, in which case a
            single value is returned.
        output : bool, optional
            Output values.  Used for performance testing since the generated
            values are not returned.

        Returns
        -------
        out : uint or ndarray
            Drawn samples.

        Notes
        -----
        This method directly exposes the the raw underlying pseudo-random
        number generator. All values are returned as unsigned 64-bit
        values irrespective of the number of bits produced by the PRNG.

        See the class docstring for the number of bits returned.
        """
        return random_raw(&self._bitgen, self.lock, size, output)

    def _benchmark(self, Py_ssize_t cnt, method=u'uint64'):
        return benchmark(&self._bitgen, self.lock, cnt, method)

    def seed(self, seed=None, counter=None, key=None):
        """
        seed(seed=None, counter=None, key=None)

        Seed the generator.

        This method is called when ``Philox`` is initialized. It can be
        called again to re-seed the generator. For details, see
        ``Philox``.

        Parameters
        ----------
        seed : int, optional
            Seed for ``Philox``.
        counter : {int array}, optional
            Positive integer less than 2**256 containing the counter position
            or a 4 element array of uint64 containing the counter
        key : {int, array}, options
            Positive integer less than 2**128 containing the key
            or a 2 element array of uint64 containing the key

        Raises
        ------
        ValueError
            If values are out of range for the PRNG.

        Notes
        -----
        The two representation of the counter and key are related through
        array[i] = (value // 2**(64*i)) % 2**64.
        """
        if seed is not None and key is not None:
            raise ValueError('seed and key cannot be both used')
        cdef int u32_size = (self.n // 2) * (self.w // 32)
        if key is not None:
            _seed = int_to_array(key, 'key', self.n // 2 * self.w, self.w)
        elif seed is not None:
            _seed = seed_by_array(seed, max(u32_size // 2, 1))
        else:
            try:
                _seed = random_entropy(u32_size)
            except RuntimeError:
                _seed = random_entropy(u32_size, 'fallback')
        dtype = np.uint64 if self.w==64 else np.uint32
        _seed = _seed.view(dtype)
        for i in range(self.n // 2):
            if self.w == 32 and self.n==2:
                self.rng_state.state2x32.key.v[i] = _seed[i]
            elif self.w == 32 and self.n==4:
                self.rng_state.state4x32.key.v[i] = _seed[i]
            elif self.w == 64 and self.n==2:
                self.rng_state.state2x64.key.v[i] = _seed[i]
            else:  # self.w == 64 and self.n==4:
                self.rng_state.state4x64.key.v[i] = _seed[i]

        counter = 0 if counter is None else counter
        counter = int_to_array(counter, 'counter', self.n * self.w, self.w)
        for i in range(self.n):
            if self.w == 32 and self.n==2:
                self.rng_state.state2x32.ctr.v[i] = counter[i]
            elif self.w == 32 and self.n==4:
                self.rng_state.state4x32.ctr.v[i] = counter[i]
            elif self.w == 64 and self.n==2:
                self.rng_state.state2x64.ctr.v[i] = counter[i]
            else:  # self.w == 64 and self.n==4:
                self.rng_state.state4x64.ctr.v[i] = counter[i]

        self._reset_state_variables()

    @property
    def state(self):
        """
        Get or set the PRNG state

        Returns
        -------
        state : dict
            Dictionary containing the information required to describe the
            state of the PRNG
        """
        dtype = np.uint64 if self.w == 64 else np.uint32
        ctr = np.empty(self.n, dtype=dtype)
        key = np.empty(self.n // 2, dtype=dtype)
        buffer = np.empty(self.n, dtype=dtype)
        for i in range(self.n):
            if  self.n==2 and self.w == 32:
                ctr[i] = self.rng_state.state2x32.ctr.v[i]
            elif self.n==4 and self.w == 32:
                ctr[i] = self.rng_state.state4x32.ctr.v[i]
            elif self.n==2 and self.w == 64:
                ctr[i] = self.rng_state.state2x64.ctr.v[i]
            else:  # self.n==4 and self.w == 64
                ctr[i] = self.rng_state.state4x64.ctr.v[i]

            if self.w == 64:
                buffer[i] = self.rng_state.buffer[i].u64
            else:
                buffer[i] = self.rng_state.buffer[i].u32
        for i in range(self.n // 2):
            if  self.n==2 and self.w == 32:
                key[i] = self.rng_state.state2x32.key.v[i]
            elif self.n==4 and self.w == 32:
                key[i] = self.rng_state.state4x32.key.v[i]
            elif self.n==2 and self.w == 64:
                key[i] = self.rng_state.state2x64.key.v[i]
            else:  # self.n==4 and self.w == 64
                key[i] = self.rng_state.state4x64.key.v[i]

        return {'bit_generator': self.__class__.__name__,
                'state': {'counter': ctr, 'key': key},
                'buffer': buffer,
                'buffer_pos': self.rng_state.buffer_pos,
                'has_uint32': self.rng_state.has_uint32,
                'uinteger': self.rng_state.uinteger,
                'number': self.rng_state.number,
                'width': self.rng_state.width}

    @state.setter
    def state(self, value):
        if not isinstance(value, dict):
            raise TypeError('state must be a dict')
        bitgen = value.get('bit_generator', '')
        if bitgen != self.__class__.__name__:
            raise ValueError('state must be for a {0} '
                             'PRNG'.format(self.__class__.__name__))
        # Default for previous version
        self.rng_state.number = self.n = value.get('number', 4)
        self.rng_state.width = self.w = value.get('width', 64)
        self._setup_generator()

        state = value['state']
        ctr = check_state_array(state['counter'], self.n, self.w, 'counter')
        key = check_state_array(state['key'], self.n // 2, self.w, 'key')
        buffer = check_state_array(value['buffer'], self.n, self.w, 'buffer')
        # Reset to make sure buffer is 0ed
        self._reset_state_variables()
        for i in range(self.n):
            if self.w == 32:
                self.rng_state.buffer[i].u32 = buffer[i]
                if self.n==2:
                    self.rng_state.state2x32.ctr.v[i] = ctr[i]
                else:  # self.n==4 :
                    self.rng_state.state4x32.ctr.v[i] = ctr[i]
            else:
                self.rng_state.buffer[i].u64 = buffer[i]
                if self.n==2:
                    self.rng_state.state2x64.ctr.v[i] = ctr[i]
                else:  # self.n==4
                    self.rng_state.state4x64.ctr.v[i] = ctr[i]
        for i in range(self.n // 2):
            if  self.n==2 and self.w == 32:
                self.rng_state.state2x32.key.v[i] = key[i]
            elif self.n==4 and self.w == 32:
                self.rng_state.state4x32.key.v[i] = key[i]
            elif self.n==2 and self.w == 64:
                self.rng_state.state2x64.key.v[i] = key[i]
            else:  # self.n==4 and self.w == 64
                self.rng_state.state4x64.key.v[i] = key[i]

        self.rng_state.has_uint32 = value['has_uint32']
        self.rng_state.uinteger = value['uinteger']
        self.rng_state.buffer_pos = value['buffer_pos']

    cdef jump_inplace(self, iter):
        """
        Jump state in-place

        Not part of public API

        Parameters
        ----------
        iter : integer, positive
            Number of times to jump the state of the rng.
        """
        step_size = (self.w * self.n) // 2
        self.advance(iter * int(2 ** step_size))

    def jump(self, iter=1):
        """
        jump(iter=1)

        Jumps the state as-if 2**(W*N/2) random numbers have been generated.

        Parameters
        ----------
        iter : integer, positive
            Number of times to jump the state of the rng.

        Returns
        -------
        self : Philox
            PRNG jumped iter times

        Notes
        -----
        Jumping the rng state resets any pre-computed random numbers. This is
        required to ensure exact reproducibility.
        """
        import warnings
        warnings.warn('jump (in-place) has been deprecated in favor of jumped'
                      ', which returns a new instance', DeprecationWarning)
        self.jump_inplace(iter)
        return self

    def jumped(self, np.npy_intp iter=1):
        """
        jumped(iter=1)

        Returns a new bit generator with the state jumped

        The state of the returned big generator is jumped as-if
        2**(2*W * iter) random numbers have been generated.

        Parameters
        ----------
        iter : integer, positive
            Number of times to jump the state of the bit generator returned

        Returns
        -------
        bit_generator : Philox
            New instance of generator jumped iter times
        """
        cdef Philox bit_generator

        bit_generator = self.__class__()
        bit_generator.state = self.state
        bit_generator.jump_inplace(iter)

        return bit_generator

    def advance(self, delta):
        """
        advance(delta)

        Advance the underlying RNG as-if delta draws have occurred.

        Parameters
        ----------
        delta : integer, positive
            Number of draws to advance the RNG. Must be less than the
            size state variable in the underlying RNG.

        Returns
        -------
        self : Philox
            RNG advanced delta steps

        Notes
        -----
        Advancing a RNG updates the underlying RNG state as-if a given
        number of calls to the underlying RNG have been made. In general
        there is not a one-to-one relationship between the number output
        random values from a particular distribution and the number of
        draws from the core RNG.  This occurs for two reasons:

        * The random values are simulated using a rejection-based method
          and so, on average, more than one value from the underlying
          RNG is required to generate an single draw.
        * The number of bits required to generate a simulated value
          differs from the number of bits generated by the underlying
          RNG.  For example, two 16-bit integer values can be simulated
          from a single draw of a 32-bit RNG.

        Advancing the RNG state resets any pre-computed random numbers.
        This is required to ensure exact reproducibility.
        """
        delta = wrap_int(delta, self.n * self.w)

        cdef np.ndarray delta_a
        delta_a = int_to_array(delta, 'step', self.n * self.w, self.w)

        if self.n == 2 and self.w == 32:
            philox2x32_advance(&self.rng_state, <uint32_t *>np.PyArray_DATA(delta_a))
        elif self.n == 4 and self.w == 32:
            philox4x32_advance(&self.rng_state, <uint32_t *>np.PyArray_DATA(delta_a))
        elif self.n == 2 and self.w == 64:
            philox2x64_advance(&self.rng_state, <uint64_t *>np.PyArray_DATA(delta_a))
        else:  # self.n == 4 and self.w == 64:
            philox4x64_advance(&self.rng_state, <uint64_t *>np.PyArray_DATA(delta_a))
        self._reset_state_variables()
        return self

    @property
    def ctypes(self):
        """
        ctypes interface

        Returns
        -------
        interface : namedtuple
            Named tuple containing ctypes wrapper

            * state_address - Memory address of the state struct
            * state - pointer to the state struct
            * next_uint64 - function pointer to produce 64 bit integers
            * next_uint32 - function pointer to produce 32 bit integers
            * next_double - function pointer to produce doubles
            * bitgen - pointer to the bit generator struct
        """
        if self._ctypes is None:
            self._ctypes = prepare_ctypes(&self._bitgen)

        return self._ctypes

    @property
    def cffi(self):
        """
        CFFI interface

        Returns
        -------
        interface : namedtuple
            Named tuple containing CFFI wrapper

            * state_address - Memory address of the state struct
            * state - pointer to the state struct
            * next_uint64 - function pointer to produce 64 bit integers
            * next_uint32 - function pointer to produce 32 bit integers
            * next_double - function pointer to produce doubles
            * bitgen - pointer to the bit generator struct
        """
        if self._cffi is not None:
            return self._cffi
        self._cffi = prepare_cffi(&self._bitgen)
        return self._cffi

    @property
    def generator(self):
        """
        Removed, raises NotImplementedError
        """
        raise NotImplementedError('This method for accessing a Generator has'
                                  'been removed.')
