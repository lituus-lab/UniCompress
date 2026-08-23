// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 lituus-lab
#ifndef UNICOMPRESS_H
#define UNICOMPRESS_H
#include <stddef.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
#define UNICOMPRESS_VERSION_MAJOR 0
#define UNICOMPRESS_VERSION_MINOR 1
#define UNICOMPRESS_VERSION_PATCH 0
#define UNICOMPRESS_VERSION "0.1.0"

#define UNICOMPRESS_VERSION_AT_LEAST(ma, mi, pa) \
  ((UNICOMPRESS_VERSION_MAJOR > (ma)) || \
   (UNICOMPRESS_VERSION_MAJOR == (ma) && UNICOMPRESS_VERSION_MINOR > (mi)) || \
   (UNICOMPRESS_VERSION_MAJOR == (ma) && UNICOMPRESS_VERSION_MINOR == (mi) && \
    UNICOMPRESS_VERSION_PATCH >= (pa)))
/* Return bytes required/written, or -1 on invalid input or codec failure. */
int64_t ucmp_deflate(const uint8_t *, size_t, uint8_t *, size_t);
/* As above; max_output is a required non-zero decompression ceiling. */
int64_t ucmp_inflate(const uint8_t *, size_t, uint8_t *, size_t, size_t);
/* Same pair for an RFC 1950 zlib stream: header, Deflate body, Adler-32. */
int64_t ucmp_zlib_deflate(const uint8_t *, size_t, uint8_t *, size_t);
int64_t ucmp_zlib_inflate(const uint8_t *, size_t, uint8_t *, size_t, size_t);
/* Return a process-lifetime version string. */
const char *ucmp_version(void);
#ifdef __cplusplus
}
#endif
#endif
