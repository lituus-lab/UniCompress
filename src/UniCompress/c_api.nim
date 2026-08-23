# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 lituus-lab
## Stable C ABI for one-shot Deflate and zlib operations. Every entry point is
## `raises: []`: a Defect escaping here would unwind across the ABI boundary,
## which is undefined behaviour, so the compiler enforces that none can.

import ../UniCompress

const UniCompressVersionC: cstring = "0.1.0"

proc copyResult(data: seq[byte]; output: ptr UncheckedArray[byte];
    capacity: csize_t): int64 =
  if output == nil or capacity < csize_t(data.len): return int64(data.len)
  if data.len > 0: copyMem(output, unsafeAddr data[0], data.len)
  int64(data.len)

proc inputView(input: ptr UncheckedArray[byte]; inputLen: csize_t): seq[byte] =
  if inputLen == 0: return @[]
  if input == nil: raise newException(ValueError, "nil input")
  if inputLen > csize_t(high(int)):
    raise newException(ValueError, "input exceeds platform index range")
  result = newSeq[byte](int(inputLen))
  copyMem(addr result[0], input, result.len)

{.push exportc, cdecl, dynlib.}

proc ucmp_deflate(input: ptr UncheckedArray[byte]; inputLen: csize_t;
    output: ptr UncheckedArray[byte]; capacity: csize_t): int64 {.raises: [].} =
  try: copyResult(compress(inputView(input, inputLen)), output, capacity)
  except CatchableError, Defect: -1

proc ucmp_inflate(input: ptr UncheckedArray[byte]; inputLen: csize_t;
    output: ptr UncheckedArray[byte]; capacity, maxOutput: csize_t): int64
    {.raises: [].} =
  if maxOutput == 0 or maxOutput > csize_t(high(int64)): return -1
  try:
    copyResult(inflate(inputView(input, inputLen),
      maxOutput = int64(maxOutput)), output, capacity)
  except CatchableError, Defect: -1

proc ucmp_zlib_deflate(input: ptr UncheckedArray[byte]; inputLen: csize_t;
    output: ptr UncheckedArray[byte]; capacity: csize_t): int64 {.raises: [].} =
  try: copyResult(zlibDeflate(inputView(input, inputLen)), output, capacity)
  except CatchableError, Defect: -1

proc ucmp_zlib_inflate(input: ptr UncheckedArray[byte]; inputLen: csize_t;
    output: ptr UncheckedArray[byte]; capacity, maxOutput: csize_t): int64
    {.raises: [].} =
  if maxOutput == 0 or maxOutput > csize_t(high(int64)): return -1
  try:
    copyResult(zlibInflate(inputView(input, inputLen),
      maxOutput = int64(maxOutput)), output, capacity)
  except CatchableError, Defect: -1

proc ucmp_version(): cstring = UniCompressVersionC

{.pop.}
