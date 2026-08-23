# cython: language_level=3
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 lituus-lab
from libc.stdint cimport uint8_t, int64_t
from libc.stddef cimport size_t
from cpython.bytearray cimport PyByteArray_AS_STRING

cdef extern from "UniCompress.h":
    int64_t ucmp_deflate(const uint8_t *, size_t, uint8_t *, size_t)
    int64_t ucmp_inflate(const uint8_t *, size_t, uint8_t *, size_t, size_t)
    int64_t ucmp_zlib_deflate(const uint8_t *, size_t, uint8_t *, size_t)
    int64_t ucmp_zlib_inflate(const uint8_t *, size_t, uint8_t *, size_t, size_t)
    const char *ucmp_version()

# zlib is the same call shape one container up, so one helper drives both:
# it asks for the length first, then fills a buffer of exactly that size.
cdef bytes run_codec(bytes data, bint decode, bint zlib_wrapped,
                     size_t max_output):
    cdef int64_t needed
    cdef bytearray output
    cdef int64_t written
    if decode:
        if zlib_wrapped:
            needed = ucmp_zlib_inflate(<const uint8_t *>data, len(data), NULL, 0, max_output)
        else:
            needed = ucmp_inflate(<const uint8_t *>data, len(data), NULL, 0, max_output)
    else:
        if zlib_wrapped:
            needed = ucmp_zlib_deflate(<const uint8_t *>data, len(data), NULL, 0)
        else:
            needed = ucmp_deflate(<const uint8_t *>data, len(data), NULL, 0)
    if needed < 0:
        raise ValueError("codec operation failed")
    output = bytearray(needed)
    if decode:
        if zlib_wrapped:
            written = ucmp_zlib_inflate(<const uint8_t *>data, len(data),
                <uint8_t *>PyByteArray_AS_STRING(output), needed, max_output)
        else:
            written = ucmp_inflate(<const uint8_t *>data, len(data),
                <uint8_t *>PyByteArray_AS_STRING(output), needed, max_output)
    else:
        if zlib_wrapped:
            written = ucmp_zlib_deflate(<const uint8_t *>data, len(data),
                <uint8_t *>PyByteArray_AS_STRING(output), needed)
        else:
            written = ucmp_deflate(<const uint8_t *>data, len(data),
                <uint8_t *>PyByteArray_AS_STRING(output), needed)
    if written != needed:
        raise ValueError("codec operation failed")
    return bytes(output)

def deflate(bytes data):
    return run_codec(data, False, False, 0)

def inflate(bytes data, max_output=1 << 30):
    return run_codec(data, True, False, max_output)

def zlib_deflate(bytes data):
    return run_codec(data, False, True, 0)

def zlib_inflate(bytes data, max_output=1 << 30):
    return run_codec(data, True, True, max_output)

def version():
    return ucmp_version()

