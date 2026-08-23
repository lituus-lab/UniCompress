# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 lituus-lab
import UniCompress

let source = @[byte 1, 2, 3, 1, 2, 3, 1, 2, 3]
let packed = compress(source)
doAssert inflate(packed) == source
echo source.len, " bytes -> ", packed.len, " bytes"

