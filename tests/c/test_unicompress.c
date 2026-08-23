// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 lituus-lab
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "UniCompress.h"

int main(void) {
  const uint8_t input[] = "deflate deflate deflate";
  uint8_t packed[128], output[128];
  int64_t packed_len = ucmp_deflate(input, sizeof(input) - 1, packed, sizeof(packed));
  if (packed_len <= 0) return 1;
  int64_t output_len = ucmp_inflate(packed, (size_t)packed_len, output,
    sizeof(output), sizeof(output));
  if (output_len != (int64_t)sizeof(input) - 1) return 2;
  if (memcmp(input, output, (size_t)output_len) != 0) return 3;
  if (ucmp_deflate(NULL, 1, packed, sizeof(packed)) != -1) return 4;
  if (ucmp_inflate(packed, (size_t)packed_len, output,
      sizeof(output), 0) != -1) return 5;
  /* The zlib container: 0x78 0x01 header, Deflate body, Adler-32 trailer. */
  uint8_t wrapped[128], unwrapped[128];
  int64_t wrapped_len = ucmp_zlib_deflate(input, sizeof(input) - 1, wrapped,
    sizeof(wrapped));
  if (wrapped_len <= 6) return 6;
  if (wrapped[0] != 0x78 || wrapped[1] != 0x01) return 7;
  int64_t unwrapped_len = ucmp_zlib_inflate(wrapped, (size_t)wrapped_len,
    unwrapped, sizeof(unwrapped), sizeof(unwrapped));
  if (unwrapped_len != (int64_t)sizeof(input) - 1) return 8;
  if (memcmp(input, unwrapped, (size_t)unwrapped_len) != 0) return 9;
  /* A corrupted trailer must fail the Adler-32 check, not return garbage. */
  wrapped[wrapped_len - 1] ^= 0xFF;
  if (ucmp_zlib_inflate(wrapped, (size_t)wrapped_len, unwrapped,
      sizeof(unwrapped), sizeof(unwrapped)) != -1) return 10;

  puts("All C ABI tests passed.");
  return 0;
}
