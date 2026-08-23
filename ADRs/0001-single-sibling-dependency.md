<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 lituus-lab -->
# ADR-0001: One sibling dependency, and no way back up

- Status: Accepted
- Date: 2026-08-21
- Scope: UniCompress

## Decision

UniCompress depends on exactly one library of the family, UniChecksum, for the
Adler-32 an RFC 1950 stream carries. Nothing else is admitted.

The formats that need DEFLATE — PNG in UniImage, ZIP in UniArchive — sit above
this repo. Depending on either of them, directly or through a third library,
would close a cycle in the family graph. `vgraph.cfg` therefore lists
UniChecksum as the only allowed engine, and `nimble checkVGraph` fails the build
on any other `requires` line naming a `Uni*` package.

## Consequences

Everything here works on byte spans and integers. A file format, a stream
abstraction, an archive index or an encryption scheme belongs in the consumer.

Inside `src/`, `deflate` and `errors` sit below `formats/`, which sits below the
C ABI. The layer check rejects an import that climbs that order; it is one-way,
so it constrains what may reach upward, not what a lower module may reuse.
