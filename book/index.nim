# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 lituus-lab
import nimib
import std/strutils

nbInit
nb.title = "UniCompress"

nbText: """
# UniCompress

Two layers, often confused. **DEFLATE** (RFC 1951) is a raw bitstream: LZ77
back-references and Huffman codes, with no header saying where it starts or
checksum saying it arrived intact. **zlib** (RFC 1950) is the framing around it
— two bytes of parameters, the DEFLATE body, and an Adler-32 of the *original*
data. PNG stores zlib streams; a ZIP entry stores raw DEFLATE. Passing one where
the other is expected is the most common way to get "invalid data" from a stream
that is perfectly fine.

This page is a nimib book: every Nim block below is compiled and run when the
book is built, and the output shown is what the code actually produced.

## The raw codec
"""

nbCode:
  import UniCompress

  let text = "deflate deflate deflate deflate"
  let raw = @(text.toOpenArrayByte(0, text.high))
  let packed = compress(raw)
  echo "in  ", text.len, " bytes"
  echo "out ", packed.len, " bytes"
  echo "round-trips ", inflate(packed) == raw

nbText: """
The input repeats, which is what LZ77 is for: after the first `deflate ` the
encoder emits back-references instead of literals. On data with no repetition
the same encoder can produce output slightly *larger* than its input — that is
inherent to the format, not a defect.

## The zlib container

Same payload, one layer up. The two header bytes are fixed here: `0x78` says
DEFLATE with a 32 KiB window, and `0x01` is the check byte that makes the
16-bit header a multiple of 31.
"""

nbCode:
  # UniChecksum is this library's one dependency; the trailer is its Adler-32.
  import UniChecksum

  let stream = zlibDeflate(raw)
  echo "header  ", stream[0].toHex(2), " ", stream[1].toHex(2)
  echo "total   ", stream.len, " bytes (body ", packed.len, " + 6 framing)"
  echo "trailer ", stream[^4].toHex(2), stream[^3].toHex(2),
       stream[^2].toHex(2), stream[^1].toHex(2)
  echo "adler32 ", adler32(raw).toHex(8)

nbText: """
The trailer is the Adler-32 of the uncompressed input, big-endian — the same
value UniChecksum computes directly, which is the whole reason this library
depends on it. `zlibInflate` recomputes it over what it decoded and refuses the
stream on a mismatch, so a corrupted byte surfaces as an error rather than as
plausible-looking output.

## Decompression is bounded

A compressed stream is a compact description of a much larger one. Left
unbounded, a few kilobytes can ask for gigabytes — so every decode here takes a
ceiling, and refuses rather than allocating past it.
"""

nbCode:
  # A stream whose output is far larger than its input.
  let bomb = zlibDeflate(newSeq[byte](200_000))
  echo "compressed to ", bomb.len, " bytes"
  try:
    discard zlibInflate(bomb, maxOutput = 1024)
    echo "unbounded — this line should not print"
  except UniCompressException as e:
    echo "refused: ", e.code

nbText: """
The ceiling is a required argument on the C ABI, with no default: a caller that
has not thought about the bound cannot inherit one by accident. Work is bounded
too, not just output size, so a stream that decodes slowly rather than largely
is refused on the same grounds.

## References

- [RFC 1951](https://www.rfc-editor.org/rfc/rfc1951) — the DEFLATE bitstream:
  block types, the LZ77 length/distance alphabets, and canonical Huffman coding.
- [RFC 1950](https://www.rfc-editor.org/rfc/rfc1950) — the zlib container, its
  CMF/FLG header and the Adler-32 trailer.
- [PNG specification](https://www.w3.org/TR/png/) — a format that stores zlib
  streams, and the source of this library's regression vectors.
- [.ZIP File Format Specification](https://support.pkware.com/pkzip/appnote) —
  a format that stores raw DEFLATE instead, framed by its own records.
- [zlib](https://zlib.net/) — the reference implementation the test suite
  differentially compares against, through CPython's `zlib` module.
"""

nbSave
