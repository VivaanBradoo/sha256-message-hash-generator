# Verification results

Tested with AMD Vivado / XSim 2026.1 on 24 October 2026.

```text
AVALANCHE abc versus abb: 124 of 256 digest bits differ
PASS: 12823 checks; 65 hashes verified; lengths 0..55 covered; avalanche=124/256 bits
```

The testbench finishes at 44,486 ns. The result includes 64 stored test vectors and one hash after an interrupted transaction and reset. The 64 stored vectors cover all message lengths from 0 to 55 bytes, standard examples, repeated data and binary input. Golden digests come from Python hashlib. Repeated messages intentionally appear in the test set.

Tests also cover exact 64-clock processing latency, output-valid pulse width, digest retention, invalid length rejection, input latching, ignored busy requests, reset cancellation and successful restart.

`abc`:

```text
ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
```

`abb`:

```text
715edf8ba8729420cd4d1ce85ed61954a9f531f8c548df728c407effe839296d
```

The ASCII encodings of `c` and `b` differ by one bit. These two digests differ in 124 of their 256 bits. This is a measured example, not a universal bit-change guarantee.

`evidence/hash_results.csv` records the computed hashes. `evidence/reference_hashes.json` stores the independent example hashes. `evidence/vivado_simulation.txt` contains the simulation transcript with local machine paths normalized to `<PROJECT_ROOT>` and `<VIVADO_ROOT>`.

These functional checks do not constitute NIST certification, formal verification, a security audit, synthesis timing validation or FPGA board testing.
