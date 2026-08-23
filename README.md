<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 lituus-lab -->
# UniCompress

Pure-Nim lossless compression: raw DEFLATE and the RFC 1950 zlib stream that
wraps it, in Nim, with a hand-written C ABI and a Cython Python binding.

Layer-2 in the `lituus-lab` `Uni*` family DAG: UniChecksum is its only sibling
dependency, for the Adler-32 a zlib stream carries. Outside the family it also
needs NimContracts, which is verification infra and compiles away under
`-d:release`. Archive containers belong to UniArchive and authenticated
encryption to UniCrypto; neither lives here.

## Quick start

```nim
import UniCompress

let text = "deflate deflate deflate"
let packed = compress(text.toOpenArrayByte(0, text.high))
echo packed.len                  # 11, from 23 bytes in
echo inflate(packed).len         # 23

let stream = zlibDeflate(text.toOpenArrayByte(0, text.high))
echo stream.len                  # 17: 2-byte header + body + Adler-32
echo zlibInflate(stream).len     # 23, trailer verified
```

```c
#include <stdint.h>
#include <string.h>
#include "UniCompress.h"

const char *text = "deflate deflate deflate";
uint8_t out[64];
int64_t n = ucmp_deflate((const uint8_t *)text, strlen(text), out, sizeof out);
if (n < 0) {
  /* invalid input, a truncated stream, or a refused budget */
}
```

```python
import unicompress
unicompress.zlib_inflate(unicompress.zlib_deflate(b"deflate" * 100))
```

See `book/index.nim` (nimib, built into `book/index.html`) for the full
walkthrough.

## What's inside

- **DEFLATE** (`deflate.nim`) — decoding of stored, fixed-Huffman and
  dynamic-Huffman blocks, with canonical Huffman trees validated before use; a
  deterministic fixed-Huffman/LZ77 encoder; and `inflateWithConsumed` for a
  caller that must know where the stream ended. Every decode takes an explicit
  output ceiling, defaulting to `MaxInflateOutput`.
- **zlib streams** (`formats/zlib.nim`) — the RFC 1950 container: a two-byte
  CMF/FLG header, the DEFLATE body, and a big-endian Adler-32 of the input,
  verified on the way back in.
- **Error categories** (`errors.nim`) — `UniCompressException` carries a
  `UniCompressError` code, so a caller distinguishes truncated input from
  invalid data or a refused resource budget without parsing a message.

Decompression is bounded on both output size and decoding work, so a hostile
stream cannot turn a small input into an unbounded allocation.

## The Uni* family

UniCompress is layer 2 of `lituus-lab`'s `Uni*` family: a set of Nim libraries,
each with a C ABI and a Python binding, unified by a shared dependency DAG and
documentation/testing conventions. See
[lituus-lab/.github](https://github.com/lituus-lab/.github) for the family's
purpose and philosophy. UniChecksum is its only dependency inside the family,
and it exists so that the formats needing DEFLATE — PNG in UniImage, ZIP in
UniArchive — share one implementation instead of each carrying its own.

## Provenance & development

DEFLATE is specified by RFC 1951 and the zlib container by RFC 1950; there is no
original compression research here. The decoder was cross-checked against
CPython's `zlib` in both directions, and against regression vectors inherited
from UniImage's PNG work.

Development used LLM/agent assistance extensively, on the terms described below.
One visible consequence: this repo's git history is short and linear, with
commits landing close together in time — that reflects an LLM/agent writing pass
over an already-specified format, not the codecs being designed at that speed.

## Layout

```text
src/UniCompress.nim              umbrella module
src/UniCompress/deflate.nim      DEFLATE decoder and encoder (NimContracts)
src/UniCompress/formats/zlib.nim RFC 1950 stream container
src/UniCompress/errors.nim       shared error categories
src/UniCompress/c_api.nim        C ABI
include/UniCompress.h            hand-written C header
tests/test_compress.nim          Nim tests
tests/c/                         C ABI test (links the header against the lib)
examples/                        Nim + C demos
py/                              Cython binding + pytest
ADRs/                            0001 no sibling cycles, 0002 license, 0003 engine & shell, 0004 public surfaces
.github/workflows/ci.yml         3-OS Nim matrix + C ABI + Python
```

## Build

```bash
nimble install -y
nimble test           # Nim, debug (contracts active)
nimble testRelease    # Nim, release (contracts compiled away)
nimble testAll        # debug + release + C ABI
nimble ctest          # C ABI: static lib + tests/c
nimble cexample       # C demo
nimble example        # Nim demo
nimble pyTest         # Cython + pytest
nimble oracle         # bidirectional differential tests against Python zlib
nimble benchmark      # DEFLATE throughput
nimble lint           # nimpretty check
nimble checkVGraph    # import-direction check
nimble coverage       # gcov + lcov -> coverage/
nimble book           # nimib book -> book/index.html
nimble docs           # book + API reference -> pages/
```

## CI

`test`, `cabi` and `python` on ubuntu/macOS/Windows. `consume-cabi` and
`consume-wheel` rebuild against the published artifacts on a machine without Nim,
so what ships is what was tested. `coverage` and `docs` run on ubuntu.

`dco` blocks PRs missing a `Signed-off-by` trailer; `commitizen` blocks PRs whose
commits or title are not [Conventional Commits](https://www.conventionalcommits.org/)
(`CONTRIBUTING.md`).

The same gates run locally with pre-commit:
`pip install pre-commit && pre-commit install`
(`CONTRIBUTING.md`).

`docs` publishes to GitHub Pages — skipped on push to a fork or while the repo
is private, on by default once public on `main`.

## AI-assisted contributions

Assistance from AI/LLM tools is welcome on the same terms as any other
contribution.

- **Accountability.** The human contributor is the author and remains fully
  responsible for the change. The DCO sign-off (`Signed-off-by`) is the mechanism:
  by signing you certify the content is yours or properly licensed — this covers
  AI-assisted work, provided you can stand behind it.
- **No third-party contamination.** Ensure AI output introduces no code from a
  third party without a compatible license and attribution. If an LLM reproduced
  protected material, do not submit it.
- **Correctness is yours.** The gates (tests, `nimble lint`, conventional commits,
  pre-commit) catch a lot, but you own the result — review and verify what you
  commit.
- **Atomic commits.** Each commit is one logical change. A PR may stack
  several atomic commits (one per element, say) — one monolithic big-bang
  commit is not.
- **Disclosure.** State in the PR whether AI assistance was used (see the PR
  template). It is not a hard requirement — the DCO remains the gate.

## License

Apache-2.0 (`LICENSE`). DCO sign-off on every commit (`CONTRIBUTING.md`).
