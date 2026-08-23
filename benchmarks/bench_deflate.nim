# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 lituus-lab
import std/[monotimes, strformat, times]
import UniCompress

var data = newSeq[byte](16 * 1024 * 1024)
for i in 0 ..< data.len: data[i] = byte(i and 0xFF)
let started = getMonoTime()
let packed = compress(data)
let encoded = (getMonoTime() - started).inNanoseconds.float / 1e9
let decodeStarted = getMonoTime()
doAssert inflate(packed) == data
let decoded = (getMonoTime() - decodeStarted).inNanoseconds.float / 1e9
echo &"Deflate encode: {data.len.float / encoded / 1e6:.2f} MB/s"
echo &"Deflate decode: {data.len.float / decoded / 1e6:.2f} MB/s"

