# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 lituus-lab
"""Pure-Nim Deflate and zlib exposed through the UniCompress C ABI."""
from ._core import (
    deflate,
    inflate,
    version as _version,
    zlib_deflate,
    zlib_inflate,
)
__version__ = _version().decode("ascii")
def version():
    return _version().decode("ascii")
__all__ = ["__version__", "deflate", "inflate", "version", "zlib_deflate",
           "zlib_inflate"]

