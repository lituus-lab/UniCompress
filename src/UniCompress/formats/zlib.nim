# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 lituus-lab
## zlib container (RFC 1950) reader wrapping `deflate.inflate`. PNG stores its
## compressed image data as a zlib stream; this parses the 2-byte header,
## skips an optional preset-dictionary id (dictionaries are not supported), and
## verifies the trailing Adler-32 checksum so silent corruption is caught.
import ../errors
import contracts
import UniChecksum
import ../deflate

proc zlibInflateImpl(data: openArray[byte]; maxOutput: int64): seq[byte] =
  ## Inflate a zlib-wrapped stream (the form PNG uses in IDAT). Raises
  ## `UniCompressException` on a bad header, an unsupported method, a preset
  ## dictionary (FDICT, not supported), a missing trailer, a checksum
  ## mismatch, or if the output would exceed `maxOutput`.
  if data.len < 2:
    raise UniCompressException(code: ucTruncated, msg: "zlib: header truncated")
  let cmf = data[0]
  let flg = data[1]
  if (cmf and 0x0F) != 8:
    raise UniCompressException(code: ucUnsupported,
        msg: "zlib: not a DEFLATE stream")
  if (cmf shr 4) > 7: # CINFO: log2(window) - 8; > 7 means a window > 32 KiB
    raise UniCompressException(code: ucInvalidData,
        msg: "zlib: CINFO exceeds 7 (window > 32 KiB)")
  if ((int(cmf) shl 8) or int(flg)) mod 31 != 0:
    raise UniCompressException(code: ucInvalidData,
        msg: "zlib: bad header check")
  if (flg and 0x20) != 0: # FDICT: preset dictionaries are not supported
    raise UniCompressException(code: ucUnsupported,
        msg: "zlib: preset dictionary (FDICT) unsupported")
  let start = 2
  let inflated = inflateWithConsumed(data, start, maxOutput)
  result = inflated.data
  if inflated.next + 4 <= data.len:
    let expect = (uint32(data[inflated.next]) shl 24) or
      (uint32(data[inflated.next + 1]) shl 16) or
      (uint32(data[inflated.next + 2]) shl 8) or
      uint32(data[inflated.next + 3])
    if expect != adler32(result):
      raise UniCompressException(code: ucInvalidData,
          msg: "zlib: Adler-32 mismatch")
  else:
    raise UniCompressException(code: ucTruncated,
        msg: "zlib: trailer truncated")

proc zlibInflate*(data: openArray[byte];
    maxOutput = MaxInflateOutput): seq[byte] {.contractual.} =
  ## Inflate and verify an RFC 1950 zlib stream under an explicit output cap.
  require:
    maxOutput > 0
  ensure:
    int64(result.len) <= maxOutput
  body:
    zlibInflateImpl(data, maxOutput)

proc zlibDeflate*(data: openArray[byte]): seq[byte] =
  ## Wrap `deflate.compress` output in a zlib container (RFC 1950): the 2-byte
  ## CMF/FLG header (CM=8 DEFLATE, CINFO=7 -> 32 KiB window, FLEVEL=0) followed
  ## by the raw DEFLATE stream and a big-endian Adler-32 of the input. The
  ## inverse of `zlibInflate` — round-trips byte-for-byte.
  result = newSeqOfCap[byte](data.len + data.len div 8 + 16)
  # CMF: CM=8 (DEFLATE), CINFO=7 (32 KiB window) -> 0x78.
  # FLG: FLEVEL=0, FDICT=0, FCHECK chosen so (CMF<<8 | FLG) mod 31 == 0 -> 0x01.
  result.add byte(0x78)
  result.add byte(0x01)
  let body = deflate.compress(data)
  result.add body
  let a = adler32(data)
  result.add byte((a shr 24) and 0xFF)
  result.add byte((a shr 16) and 0xFF)
  result.add byte((a shr 8) and 0xFF)
  result.add byte(a and 0xFF)

