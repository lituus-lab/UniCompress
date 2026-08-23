# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 lituus-lab
## Errors shared by compression codecs and stream formats.

type
  UniCompressError* = enum
    ## Stable categories for codec and stream-format failures.
    ucUnsupported
    ucTruncated
    ucInvalidData
    ucResourceLimit

  UniCompressException* = ref object of CatchableError
    ## Exception carrying a machine-readable compression error category.
    code*: UniCompressError

