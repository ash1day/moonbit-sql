# Archived pg and decode packages

These directories preserve the old source and tests for reference. They are
outside the module's `src` root and are not built, tested in CI, or exported as
`ash1day/sql/pg` and `ash1day/sql/decode`. No tests were removed from the archive.

The maintained module is `ast` + `builder`. Use `CompiledQuery { sql, params }`
with an application-owned driver adapter; see the [migration guide](../README.md#migrating-from-pg-and-decode)
and [node-postgres example](../examples/node-postgres.mjs).

The legacy dependencies were `moonbitlang/async@0.16.6` and
`mattn/postgres@0.10.4`. Legacy package checks were last verified with
`moonc v0.8.2+3382e0600`. The pinned `moonc 0.10.14` cannot compile the old async
source, including on native. These directories are not a standalone module;
restoring them under `src` also requires restoring both dependencies and using
the old toolchain. Do that only in a separate checkout for investigation.

The published `ash1day/sql@0.1.0` is unchanged. Its source is available at
[the pre-maintenance commit](https://github.com/ash1day/moonbit-sql/tree/d2e83380dea16b9de26da74007f3050788cf58f7/src).
The archived working files also retain the unreleased deprecation annotations,
compiler compatibility edits, and removal of the global JS rejection handler.
See the migration guide for the unfixed data correctness limitations.
