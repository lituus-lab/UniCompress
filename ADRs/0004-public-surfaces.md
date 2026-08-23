<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 lituus-lab -->
# ADR-0004: Public surfaces

- Status: Accepted
- Date: 2026-08-21

## Decision

The Nim API is authoritative. The C ABI uses the `ucmp_` prefix and the Python
binding delegates to that ABI. Codec-specific options remain explicit rather
than being hidden behind a generic compression level.

## Completeness

Both container levels are reachable from every surface: raw DEFLATE as
`ucmp_deflate`/`ucmp_inflate`, the RFC 1950 stream as
`ucmp_zlib_deflate`/`ucmp_zlib_inflate`, each mirrored in Python. Exposing the
raw codec without its stream format would have left the Adler-32 verification —
the reason this library depends on UniChecksum at all — usable from Nim only.

Two exports stay Nim-side, deliberately:

- `inflateWithConsumed`, which returns how far into the input the stream ended.
  The ABI returns the output length only, so a C caller cannot derive that
  position; the variant exists for a Nim caller decoding several streams from
  one buffer. Exposing it to C would mean a second out-parameter, which no
  consumer has asked for.
- `UniCompressException` and its `UniCompressError` code. The ABI never raises,
  so it reports failure as a negative length; Python turns that back into a
  `ValueError`. Binding an exception type across the boundary would promise
  something the ABI's contract forbids.
