# API Reference

See [README](README.md) for project overview, installation, and conventions.

## Reading the Documentation

### Callout Blocks

Throughout the documentation, you'll find callout blocks with emojis:

| Callout                | Meaning                                                                  |
| ---------------------- | ------------------------------------------------------------------------ |
| ℹ️ **NOTE:**           | Information to bring attention to the reader.                            |
| ⚠️ **WARNING:**        | Important warning about potential issues or pitfalls.                    |
| 🤔 **TO THINK ABOUT:** | Notes for the library developer about items needing more consideration.  |
| 📌 **TO DO:**          | Planned work or improvements.                                            |

### Section Emojis

The Table of Contents and documentation sections use these emojis:

| Emoji | Meaning                 |
| ----- | ----------------------- |
| 📘    | File section header.    |
| 📑    | Chapter within a file.  |

### Symbol Emojis

Each documented symbol is prefixed with an emoji indicating its type:

| Emoji | Symbol Type                                   |
| ----- | --------------------------------------------- |
| ⚙️    | Function                                      |
| 🧊    | Module (builds geometry)                      |
| 🧪    | Module (test module, prefixed with `test_`)   |
| 💠    | Value                                         |
| 🧩    | Type definition (`@typedef`)                  |
| 🧩⚙️  | Callback type (`@callback`)                   |

## Signature Specifications

This library uses curried functions.  There is no clean way to document a full
curried call chain using standard JSDoc or TypeScript JSDoc today, so this
project defines a small extension.

Using the `@callchain` tag, the full curried call chain is written inline, for
example:

- `@callchain replace_each(a, a_birls, a_end_i) (b, b_birls, b_end_i): (string | list)`

This makes the intended usage obvious to readers and makes it straightforward to
generate the `.md` documentation with a custom tool.  Different overloads may
also be stated using this syntax, and a call chain may comprise of only one
link.  E.g. The call to the first function may just end right there, if it
doesn't curry.
