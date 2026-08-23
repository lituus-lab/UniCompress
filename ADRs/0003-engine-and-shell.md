<!-- SPDX-License-Identifier: Apache-2.0 -->
<!-- Copyright 2026 lituus-lab -->
# ADR-0003: Engine and C ABI shape

- Status: Accepted
- Date: 2026-08-21
- Scope: UniCompress

## Decision

The Nim library is the engine and the source of truth. A thin C ABI
(`src/UniCompress/c_api.nim`) built `--app:staticlib`/`--app:lib --noMain
--mm:arc -d:release` produces `libUniCompress.a` / `libUniCompress.so`, and the
hand-written `include/UniCompress.h` is kept in sync with it by hand.

`tests/c` links that header against the built library on every CI run, so a
renamed or retyped symbol fails to link rather than shipping. The generated
`--header:` output is deliberately not used: it tracks Nim's codegen rather than
the contract we want to promise.

`--mm:arc` gives foreign callers a deterministic memory model with no cycle
collector; `--noMain` means C does not have to call `NimMain()`.

## Call shape

Every codec entry point is asked twice: once with a null output pointer, which
returns the number of bytes the result needs, then again with a buffer of that
size. A negative return means the operation failed — invalid input, a truncated
stream, or a refused resource budget — and the caller is told nothing more,
because an exception must never unwind across the ABI boundary.

Decompression takes a mandatory non-zero output ceiling. There is no default: a
caller that has not thought about the bound cannot accidentally inherit one.
