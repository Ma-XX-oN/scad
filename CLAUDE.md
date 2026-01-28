# Project Notes for Claude

## Project Overview

This is an OpenSCAD standard library with auto-generated documentation.
Key files:

- library files have no extension.
- `scad-analysis.py` - Parses `.scad` files and generates markdown/JSON documentation.
- There's a separate branch where the `README-header.md`/`README.md` files have been
  separated into a `README.md`, `API-header.md`/`API.md` file.
  - `build-docs.py` - Reads `README.md` for the file list, runs `scad-analysis.py`,
    generates a TOC, and assembles `API.md`.
  - `API-header.md` - Hand-written header prepended to the auto-generated `API.md`.
  - `README.md` - Hand-maintained project synopsis (not auto-generated).
  - `API.md` - Auto-generated full API reference (do not edit directly).
- `master` branch just has the `README-header.md`/`README.md` file setup as it's
  easer.  Will switch to split up later.

## Lessons Learned

### Be thorough on review tasks

When asked "is there anything else?" or "check again", do a genuinely fresh
pass rather than assuming prior checks were exhaustive.  In this project,
repeated checks uncovered:

- A second instance of the same issue on an adjacent line (line 39 fixed but
  line 40 left inconsistent).
- Typos in comments near already-fixed code ("wan" instead of "want").
- A double negative ("isn't not") on a nearby line.
- Stale inline comments after fixing a docstring in the same function.

### When fixing one of a pair/group, check all siblings

If a comment or pattern appears in multiple places (e.g. parallel comment
lines, repeated constants, similar code blocks), fix all occurrences together.

### When fixing library usage bugs, use public APIs

When encountering issues with library functions, prefer using the correct public API (e.g., `els` instead of `_els`) that handles necessary preprocessing like caching. Avoid calling internal functions directly or modifying library internals, as this bypasses design safeguards and can lead to fragile fixes. Address the root cause at the call site first.

### GitHub markdown rendering

- GitHub strips `<svg>` tags from markdown for security.  Use Unicode
  characters (e.g. ☰) or plain text instead.
- GitHub does not reliably link to anchors containing colons or URL-specific
  punctuation.  This project sanitizes anchors via `sanitize_anchor_id()`:
  colons become `__`, spaces and other URL punctuation become `_`.

### Offensive programming and testing strategy

This library uses offensive programming: all input is assumed safe and trusted.
`verify_*` guards exist solely to tell developers when they've used a function
incorrectly — they should never be triggered in normal operation.

- **Do not** write tests that intentionally trigger `verify_*` guards.  A test
  that hits an assert is a buggy test, not a valid error-handling test.
- Tests should only exercise **valid usage paths**.
- When auditing `verify_*` guards, check that they exist where they should and
  that their conditions make sense — not that they can be bypassed or toggled.

## Conventions

- Anchor format: `<a id='prefix-sanitized_id'></a>` where the id is
  sanitized by `sanitize_anchor_id()` in `scad-analysis.py`.
- The `regex` module (not `re`) is used throughout for possessive quantifiers
  and named sub-patterns.
- Callout blocks in documentation use emoji prefixes (see API-header.md
  "Reading the Documentation" section).
