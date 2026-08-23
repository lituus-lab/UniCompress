<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 lituus-lab -->
# Security Policy

Report vulnerabilities privately, not via a public issue: use GitHub's private
vulnerability reporting (Security → Report a vulnerability on this repository),
or email <lbartoletti@lituus-lab.com>. Include: description + impact, minimal
reproducer, affected version (`ucmp_version()`).

Only the latest released line is supported. The `0.1.x` C ABI is not yet frozen.

## Surface

- C callers must provide a non-null pointer for non-empty input. One-shot
  operations return `-1` on invalid input or decoding failure; no exception
  crosses the ABI.
- The Python binding translates an ABI failure into `ValueError`.
- Single-threaded, reentrant; no global mutable state.

Deflate rejects empty, incomplete and oversubscribed Huffman trees before
decoding. `maxOutput` bounds amplification and `maxWork` bounds the sum of
consumed bits and emitted bytes. Malformed input must result in a typed
`UniCompressException`, never an index defect or unbounded loop.
