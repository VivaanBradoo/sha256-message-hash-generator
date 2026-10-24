# Vivado demonstration and image captures

Open `vivado_project/sha256_hash.xpr`, select Run Behavioral Simulation, then Run All.

## Signal setup

Add `clk`, `reset`, `start`, `test_index`, `message_prefix`, `message_length`, `busy`, `round_index`, `digest_valid`, `digest`, and `length_error` from the testbench to the waveform. `message_prefix` shows the first three message bytes and makes short examples readable. Use ASCII or hexadecimal for that signal, unsigned decimal for the length, index and round counter, and hexadecimal for the digest.

An empty message has length zero even if unused bytes in the input bus contain other values. The first three demo transactions contain `abc`, `abc`, and `abb`.

## Four images for the presentation

1. **RTL schematic:** Open RTL Analysis > Open Elaborated Design > Schematic for `sha256_message_hash`. Expand the `core` instance if needed. Export as PDF, or send a clear screenshot with readable block labels.
2. **SHA-256 computation:** Show **0–720 ns** with `message_prefix`, `message_length`, `start`, `busy`, `round_index`, `digest_valid`, and `digest`. The first `abc` request starts at 25 ns and completes at 665 ns. Place the cursor at 666 ns, after the output settles. The digest begins `ba7816bf` and ends `f20015ad`.
3. **Repeat and one-bit change:** Show **0–2050 ns** with `test_index`, `message_prefix`, `start`, `busy`, `digest_valid`, and `digest`. The first two inputs are `abc`; both hashes match. The third is `abb`, differing by one input bit. Its digest begins `715edf8b` and completes at 1985 ns. Place the cursor at 1986 ns. If the full hash is too wide to read in the waveform, include the matching console HASH lines in a second capture.
4. **Final simulation results:** Capture the console lines containing the avalanche count and final `PASS: 12823 checks; 65 hashes verified; lengths 0..55 covered; avalanche=124/256 bits`. The avalanche line appears after vector 2; the PASS line appears at the end. Two cropped screenshots are acceptable if they are far apart.

Maximize the waveform area, keep signal names and time units visible, and widen the Value column so a full 64-digit digest can be inspected. Hexadecimal digests have 64 digits, representing 256 bits. The complete run is approximately 44.486 microseconds, so zooming to the full run compresses the early examples.

## What to explain

- The first request demonstrates real hardware SHA-256 rounds and the known `abc` digest.
- Repeating `abc` demonstrates determinism.
- Changing `abc` to `abb` changes one input bit and, in this particular example, 124 digest bits. It does not mean every one-bit change always flips exactly 124 bits.
- Padding explains why the single-block message limit is 55 bytes: 440 message bits + 1 padding bit + at least 7 zero bits + 64 length bits = 512 bits.
- The console confirms that the hardware result matches the independent reference for all tested messages.
