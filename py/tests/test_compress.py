# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 lituus-lab
import pytest
import unicompress
import zlib

def test_roundtrip():
    value = b"deflate" * 1000
    assert unicompress.inflate(unicompress.deflate(value)) == value

def test_python_zlib_oracle_both_directions():
    value = bytes(range(256)) * 31
    assert zlib.decompress(unicompress.deflate(value), wbits=-15) == value
    compressor = zlib.compressobj(level=9, wbits=-15)
    packed = compressor.compress(value) + compressor.flush()
    assert unicompress.inflate(packed) == value


def test_zlib_roundtrip_against_stdlib_both_directions():
    value = bytes(range(256)) * 31
    assert zlib.decompress(unicompress.zlib_deflate(value)) == value
    assert unicompress.zlib_inflate(zlib.compress(value)) == value
    assert unicompress.zlib_inflate(unicompress.zlib_deflate(value)) == value


def test_zlib_rejects_a_corrupted_trailer():
    packed = bytearray(unicompress.zlib_deflate(b"deflate" * 100))
    packed[-1] ^= 0xFF
    with pytest.raises(ValueError):
        unicompress.zlib_inflate(bytes(packed))
