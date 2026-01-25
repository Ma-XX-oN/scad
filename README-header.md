# OpenSCAD Standard Library (OSL) (potential)

## Purpose

OpenSCAD is a really great programming language to parametrically describe a 3D
object, allowing binary union, difference and intersection operations.  However,
for those coming from a procedural rather than a functional programming
paradigm, it may be a bit difficult to get a handle on.  This library is to help
with that by taking some ideas from C++ and python and incorporating them into
the current OpenSCAD language without actually changing the language itself.

Although you may be able to write faster specific implementations of many of
these functions, they give an abstraction layer that makes it easier to code and
read.  From there, once you've created whatever code you want and you feel it's
not fast enough, optimisation is always an option.  Code readability and
mantainabilty are the primary goal of this library.  Speed is secondary (though
performance was also considered and it is quite fast).

> ℹ️ **NOTE:**
>
> Currently, to import libraries in OpenSCAD there are two methods, `use<>` and
> `include<>`.  This library uses both methods. For `*_consts` files, use the
> `include<>` idiom.  For all other files, use the `use<>` idiom.  This is
> because non-function symbols are not exported when using `use<>`, and the
> `*_consts` files only contain such symbols.

> ℹ️ **NOTE:**
>
> All of these files have no extension, that is by design.

### Reading the Documentation

#### Callout Blocks

Throughout the documentation, you'll find callout blocks with emojis:

| Callout                | Meaning                                                                  |
| ---------------------- | ------------------------------------------------------------------------ |
| ℹ️ **NOTE:**           | Information to bring attention to the reader.                            |
| ⚠️ **WARNING:**        | Important warning about potential issues or pitfalls.                    |
| 🤔 **TO THINK ABOUT:** | Notes for the library developer about items needing more consideration.  |
| 📌 **TO DO:**          | Planned work or improvements.                                            |

#### Section Emojis

The Table of Contents and documentation sections use these emojis:

| Emoji | Meaning                 |
| ----- | ----------------------- |
| 📘    | File section header.    |
| 📑    | Chapter within a file.  |

#### Symbol Emojis

Each documented symbol is prefixed with an emoji indicating its type:

| Emoji | Symbol Type                                   |
| ----- | --------------------------------------------- |
| ⚙️    | Function                                      |
| 🧊    | Module (builds geometry)                      |
| 🧪    | Module (test module, prefixed with `test_`)   |
| 💠    | Value                                         |
| 🧩    | Type definition (`@typedef`)                  |
| 🧩⚙️  | Callback type (`@callback`)                   |

### Signature Specifications

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

### Libraries

#### Parameter Names That Infer Types

Many parameters names imply the types that they accept.

- `s` - A `string`.
- `l` - A `list`.
- `r` - A `range`.
- `sl` - A type being either a `string` or `list`.
- `slr` - A type being either a `string`, `list` or `range`.
- `birl` - A type being either a `number` starting a `(number, number)` pair, a
  `range` or a `list`.
- `birls` - A type being either a `number` starting a `(number, number)` pair, a
  `range`, a `list` or a `slice`.
- `end_i` - A `number` being the end of the `(number, number)` pair or `undef`
  if `birl` is not a `number`.  As these are usually the last element, if a
  non-number is used for the `birl`/`birls` then this parameter can just be
  omitted.

### Files
There are several files in this library set.

 1. [range](#file-range)
    - Wraps OpenSCAD ranges `[start:stop]`/`[start:step:stop]`, adds extra
      functionality and remove warnings when creating null ranges.  Ranges are
      considered indexable and can be dereferenced using `range_el`.
 2. [types](#file-types)
    - Allows for classifying object types that are beyond the standard
      `is_num`, `is_string`, `is_list`, `is_undef`, `is_function`, `is_bool` by
      adding `is_int`, `is_float` and `is_nan`.  `is_range` is defined in range
      library.
    - Enumerates object types.
    - Generates a minimal string representing the type of an object.
 3. [birlei](#file-birlei)
    - Refers to the two parameters describing a number of items to iterate
      over.
    - `birl` refers to `B`egin `I`ndex, `R`ange or `L`ist.  `ei` (a.k.a.
      `end_i`) refers to `E`nd `I`ndex.  Together, they give a range of
      numeric values, usually used as indices to dereference elements from
      indexable objects like strings, lists, or ranges.
    - When birlei are two numbers, `birl` **must be <=** `end_i` or nothing is
      iterated over.  There is no warning (unlike the built in range syntax).
      This is by design so as to be able to iterate over no elements.
    - Why bother with the `end_i` part?  Using a `(number, number)` pair is the
      way all the algorithms that don't rely on list comprehension work to
      recursively iterate.  Bringing this to the user API allows the user to
      benefit from the fastest way of executing the algorithms.
 4. [base_algos](#file-base_algos)
    - The base algorithms which most of the rest of the library uses.
    - When not passed the `birlei`, the algorithm, it returns a lambda that
      only take a `birlei`.
    - When passing a `birlei`, returns a lambda that takes a `PPMRRAIR`
      function which is called over the `birlei` set.
 5. [indexable](#file-indexable), [indexable_consts](#file-indexable_consts)
    - Functions to manipulate a list or string as a stack / queue, use negative
      indices to get the indices / elements from the end, insert /
      remove / replace elements, any / all tests and additional search
      algorithms.
    - Adds a new type `SLICE` that works like python's slice, but still uses
      the closed range paradigm.  This is not indexable, but can be used with
      indexable functions that have a `birls` parameter (`s` for slice).
 6. [function](#file-function)
    - Allow counting of function parameters and applying an array to a function
      as parameters.
 7. [test](#file-test)
    - Testing modules for TDD.
 8. [transform](#file-transform)
    - Functions that allow transforming single points or a series of points
      quickly, usually by creating transformation matrices that can be multiplied
      against the point or points.
 9. [helpers](#file-helpers)
    - Miscellaneous functions that don't fit elsewhere.
10. [skin](#file-skin)
    - Generates a polyhedron using slices.
11. [sas_cutter](#file-sas_cutter)
    - Creates a skin which is used as a cutting tool help to align two separate
      parts together.

