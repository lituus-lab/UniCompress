# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 lituus-lab
"""Author py/notebooks/quickstart.ipynb, then execute it so the committed file
carries real outputs for GitHub to render. Run from the repo root:

    pip install -e 'py[notebook]'      # nbformat, nbclient, ipykernel
    python3 py/notebooks/build_quickstart.py

CI re-executes the notebook against an installed wheel; this script only
regenerates it after an API change."""
import os

import nbformat as nbf
from nbclient import NotebookClient

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(HERE, "quickstart.ipynb")

CELLS = [
    ("md", """# UniCompress — Python quickstart

`unicompress` is a Cython extension over the UniCompress C ABI, shipped as a
self-contained wheel: the native library travels inside the package, so
installing it needs neither Nim nor a compiler.

```
pip install unicompress
```

CI executes this notebook against the wheel the release actually publishes, so
an output below that stops matching fails the build."""),
    ("md", """## Two layers

`deflate`/`inflate` are the raw RFC 1951 bitstream. `zlib_deflate`/`zlib_inflate`
are the RFC 1950 framing around it: two header bytes, the body, and an Adler-32
of the original data."""),
    ("code", """import unicompress

payload = b"deflate " * 200
raw = unicompress.deflate(payload)
stream = unicompress.zlib_deflate(payload)
{
    "input": len(payload),
    "raw deflate": len(raw),
    "zlib stream": len(stream),
    "framing overhead": len(stream) - len(raw),
}"""),
    ("md", """## The standard library agrees

`zlib` reads what this writes and writes what this reads, in both directions and
at both layers — `wbits=-15` selects the raw bitstream, the default the
container."""),
    ("code", """import zlib

(zlib.decompress(raw, wbits=-15) == payload,
 zlib.decompress(stream) == payload,
 unicompress.inflate(zlib.compress(payload)[2:-4]) == payload,
 unicompress.zlib_inflate(zlib.compress(payload)) == payload)"""),
    ("md", """## Decompression is bounded

A small stream can describe a very large one. Every decode takes a ceiling and
refuses rather than allocating past it."""),
    ("code", """bomb = unicompress.zlib_deflate(bytes(200_000))
print("compressed to", len(bomb), "bytes")
try:
    unicompress.zlib_inflate(bomb, max_output=1024)
except ValueError as exc:
    print("refused:", exc)"""),
    ("md", """A corrupted trailer fails the Adler-32 check rather than returning
plausible-looking output."""),
    ("code", """damaged = bytearray(stream)
damaged[-1] ^= 0xFF
try:
    unicompress.zlib_inflate(bytes(damaged))
except ValueError as exc:
    print("refused:", exc)"""),
]


def main():
    nb = nbf.v4.new_notebook()
    nb.cells = [
        nbf.v4.new_markdown_cell(src) if kind == "md" else nbf.v4.new_code_cell(src)
        for kind, src in CELLS
    ]
    nb.metadata["kernelspec"] = {
        "display_name": "Python 3",
        "language": "python",
        "name": "python3",
    }
    # Execute from the repo root, never from py/: there, `import unicompress`
    # would resolve to the py/unicompress source tree instead of the installed
    # package, and the notebook would stop testing what it claims to test.
    NotebookClient(nb, timeout=120, kernel_name="python3",
                   resources={"metadata": {"path": ROOT}}).execute()
    with open(OUT, "w") as f:
        nbf.write(nb, f)
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
