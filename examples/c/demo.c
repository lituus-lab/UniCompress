// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 lituus-lab
#include <stdint.h>
#include <stdio.h>
#include "UniCompress.h"
int main(void) {
  const uint8_t data[] = "deflate deflate";
  uint8_t output[128];
  int64_t size = ucmp_deflate(data, sizeof(data) - 1, output, sizeof(output));
  printf("packed bytes: %lld\n", (long long)size);
  return size < 0;
}

