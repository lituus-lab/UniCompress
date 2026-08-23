# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 lituus-lab
## Resolve the local UniChecksum checkout during family development.
switch("path", "../UniChecksum/src")
# when defined(amd64) and not defined(scalarUniCompress):
#   switch("passC", "-ffp-contract=off")
