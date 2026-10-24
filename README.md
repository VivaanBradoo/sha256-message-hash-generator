# SHA-256 Message Hash Generator

A Verilog implementation of SHA-256 for byte-aligned messages from **0 to 55 bytes**, with a self-checking Vivado simulation. The design computes all 64 SHA-256 rounds and outputs the standard 256-bit digest. The supported message length fits into one padded 512-bit block.

## How it works

1. The input wrapper accepts the message and its length when `start` is high and `busy` is low.
2. It appends a `1` bit, zero padding, and the original message length as a 64-bit big-endian bit count.
3. The core initializes eight 32-bit working registers using the standard SHA-256 initial values.
4. It processes one compression round per clock, combining message words, round constants, rotations, XOR, choice, majority and addition modulo 2^32.
5. After 64 rounds, the core adds the final working registers to the initial hash values and publishes the 256-bit digest.

Hashing is deterministic: the same message produces the same digest. Hash comparison can reveal message changes when the reference digest is trusted. There is no decryption operation, and an unkeyed hash alone does not authenticate a sender.

## Files

| Path | Purpose |
|---|---|
| `rtl/sha256_core.v` | Iterative 64-round compression core |
| `rtl/sha256_message_hash.v` | Message input, padding and length checks |
| `sim/tb_sha256_message_hash.sv` | Testbench with automatic checks |
| `sim/test_vectors.mem` | Independent reference messages and digests |
| `scripts/create_project.tcl` | Create or open the Vivado project |
| `scripts/verify_project.tcl` | Run the project simulation to completion |
| `scripts/generate_vectors.py` | Regenerate test vectors using Python hashlib |
| `evidence/` | Simulation results and reference values |
| `SIMULATION_GUIDE.md` | Signal list and screenshot instructions |

## Run in Vivado

1. Clone or download this repository.
2. Open Vivado and use its Tcl Console to run:

   ```tcl
   source {C:/path/to/sha256-message-hash-generator/scripts/create_project.tcl}
   ```

3. Select **Run Simulation > Run Behavioral Simulation**.
4. Click **Run All**, or enter `run all` in the Tcl Console.
5. Look for the final `PASS` message. The test finishes at approximately 44.486 microseconds of simulated time.

The script creates `vivado_project/sha256_hash.xpr` using target part `xc7a35tcpg236-1`. Subsequent sessions can open that file directly. Simulation inputs and test vectors are included. Vivado-generated files are excluded from version control.

## Interface and timing

| Signal | Meaning |
|---|---|
| `clk` | Clock input |
| `reset` | Synchronous reset, highest priority |
| `start` | Pulse for one clock to request a hash |
| `message[439:0]` | Up to 55 bytes, first byte in bits 439:432 |
| `message_length[6:0]` | Number of message bytes |
| `busy` | Core is processing a block |
| `round_index[5:0]` | Current processing round, from 0 to 63 |
| `digest[255:0]` | Most recently completed hash |
| `digest_valid` | One-clock pulse identifying a completed hash |
| `length_error` | Invalid length request while idle |

The core accepts a request at a rising edge while idle. It completes 64 processing clocks later. With a 10 ns testbench clock, this is 640 ns after acceptance. The digest holds until another result completes or reset clears it. Inputs may change while busy because the accepted padded block is already stored. Requests while busy are ignored. Hold `start` for only one clock to avoid starting another operation after completion.

For `abc`, set the first three bytes to `61 62 63` and length to 3. In a Verilog testbench:

```verilog
message = {24'h616263, 416'b0};
message_length = 7'd3;
```

The expected digest is:

```text
ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
```

## Verification

Vivado / XSim 2026.1 completed **12,823 checks** across **65 hash operations**. The tests cover every supported length from 0 through 55 bytes, empty input, embedded zero bytes, repeated input, a one-bit message change, ignored busy requests, input changes during processing, invalid lengths 56 through 127, reset cancellation and recovery.

Reference digests come from Python's independent `hashlib.sha256` implementation. The testbench contains no software hashing substitute for the hardware design. See `VERIFICATION.md` for results.

## Scope

This implementation supports single-block, byte-aligned messages only. SHA-256 also supports longer messages through block chaining, which this core does not implement. Requests above 55 bytes are rejected instead of producing an incorrect truncated hash. The design does not provide HMAC, encryption, side-channel countermeasures, a hardware entropy source or a security certification. No FPGA synthesis, hardware timing or board validation is claimed.

## Reference

[NIST FIPS 180-4, Secure Hash Standard](https://csrc.nist.gov/pubs/fips/180-4/upd1/final) specifies SHA-256 padding, initial values, constants and compression functions.
