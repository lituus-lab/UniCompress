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

# A shared library runs NimMain from DllMain (Windows) or an ELF constructor;
# a static one has neither, so nothing initializes the Nim runtime. Anything
# that reads the environment then faults — proven on Windows, where the Python
# extension is the one consumer that links the static build. The static-library
# tasks pass -d:staticNoAutoInit; shared builds must not, or NimMain runs twice.
when defined(staticNoAutoInit):
  # A C static, not a Nim global: module initialization would reset a Nim one
  # back to false and NimMain would run again on the next call. NimMain is
  # declared here too — the generated prototype comes after this section.
  {.emit: """/*VARSECTION*/
void NimMain(void);
static int ucmp_runtime_ready = 0;
""".}
  template ensureRuntime() =
    {.emit: """
  if (!ucmp_runtime_ready) { ucmp_runtime_ready = 1; NimMain(); }
""".}
else:
  template ensureRuntime() = discard

{.push exportc, cdecl, dynlib.}

proc ucmp_deflate(input: ptr UncheckedArray[byte]; inputLen: csize_t;
    output: ptr UncheckedArray[byte]; capacity: csize_t): int64 {.raises: [].} =
  ensureRuntime()
  try: copyResult(compress(inputView(input, inputLen)), output, capacity)
  except CatchableError, Defect: -1

proc ucmp_inflate(input: ptr UncheckedArray[byte]; inputLen: csize_t;
    output: ptr UncheckedArray[byte]; capacity, maxOutput: csize_t): int64
    {.raises: [].} =
  ensureRuntime()
  if maxOutput == 0 or maxOutput > csize_t(high(int64)): return -1
  try:
    copyResult(inflate(inputView(input, inputLen),
      maxOutput = int64(maxOutput)), output, capacity)
  except CatchableError, Defect: -1

proc ucmp_zlib_deflate(input: ptr UncheckedArray[byte]; inputLen: csize_t;
    output: ptr UncheckedArray[byte]; capacity: csize_t): int64 {.raises: [].} =
  ensureRuntime()
  try: copyResult(zlibDeflate(inputView(input, inputLen)), output, capacity)
  except CatchableError, Defect: -1

proc ucmp_zlib_inflate(input: ptr UncheckedArray[byte]; inputLen: csize_t;
    output: ptr UncheckedArray[byte]; capacity, maxOutput: csize_t): int64
    {.raises: [].} =
  ensureRuntime()
  if maxOutput == 0 or maxOutput > csize_t(high(int64)): return -1
  try:
    copyResult(zlibInflate(inputView(input, inputLen),
      maxOutput = int64(maxOutput)), output, capacity)
  except CatchableError, Defect: -1

proc ucmp_version(): cstring = UniCompressVersionC

{.pop.}
