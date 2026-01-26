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
maintainability are the primary goal of this library.  Speed is secondary
(though performance was also considered and it is quite fast).

## Installation

OpenSCAD finds `use <>` / `include <>` targets in a small set of library
locations.  In particular, library files are searched for:

- in the same folder as the design file you opened,
- in the library folder of the OpenSCAD installation, and
- in folders listed by the `OPENSCADPATH` environment variable.  (See the
  OpenSCAD manual for the full details.)  OpenSCAD User Manual - Include
  Statement (https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Include_Statement)

A practical way to use this library is to place (or clone) it into your user
library folder and then import files by relative path from there.  OpenSCAD
exposes the library folder location via **File → Show Library Folder...**.
OpenSCAD User Manual - Libraries (https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Libraries)

### Importing Library Files

- For `*_consts` files: use the `include <>` idiom.
- For all other files: use the `use <>` idiom.

The include path must match the actual file names.  These files are
intentionally extensionless (similar to C++ standard library headers).

## Compatibility

- Intended to work across OpenSCAD versions.
- Known limitation: OpenSCAD **2021.01** has problems with some of the string
  formatting code paths due to incorrect recursion detection.  Upgrading to a
  newer OpenSCAD build avoids that issue.

## Status

- **Stable:** everything except `skin` and `sas_cutter`.
- **In development:** `skin`, `sas_cutter`.

## Licence

This project is licensed under the **BSD 3-Clause License**.  See
[`LICENSE`](./LICENSE).

## Documentation

For the full API reference with detailed documentation of every function,
module, and value, see [API Reference](API.md).

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

#### Synopses of Files

There are several files in this library set.

 1. [range](API.md#file-range)
    - Wraps OpenSCAD ranges `[start:stop]`/`[start:step:stop]`, adds extra
      functionality and remove warnings when creating null ranges.  Ranges are
      considered indexable and can be dereferenced using `range_el`.
 2. [types](API.md#file-types)
    - Allows for classifying object types that are beyond the standard
      `is_num`, `is_string`, `is_list`, `is_undef`, `is_function`, `is_bool` by
      adding `is_int`, `is_float` and `is_nan`.  `is_range` is defined in range
      library.
    - Enumerates object types.
    - Generates a minimal string representing the type of an object.
 3. [birlei](API.md#file-birlei)
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
 4. [base_algos](API.md#file-base_algos)
    - The base algorithms which most of the rest of the library uses.
    - When not passed the `birlei`, the algorithm, it returns a lambda that
      only take a `birlei`.
    - When passing a `birlei`, returns a lambda that takes a `PPMRRAIR`
      function which is called over the `birlei` set.
 5. [indexable](API.md#file-indexable), [indexable_consts](API.md#file-indexable_consts)
    - Functions to manipulate a list or string as a stack / queue, use negative
      indices to get the indices / elements from the end, insert /
      remove / replace elements, any / all tests and additional search
      algorithms.
    - Adds a new type `SLICE` that works like python's slice, but still uses
      the closed range paradigm.  This is not indexable, but can be used with
      indexable functions that have a `birls` parameter (`s` for slice).
 6. [function](API.md#file-function)
    - Allow counting of function parameters and applying an array to a function
      as parameters.
 7. [test](API.md#file-test)
    - Testing modules for TDD.
 8. [transform](API.md#file-transform)
    - Functions that allow transforming single points or a series of points
      quickly, usually by creating transformation matrices that can be multiplied
      against the point or points.
 9. [helpers](API.md#file-helpers)
    - Miscellaneous functions that don't fit elsewhere.
10. [skin](API.md#file-skin)
    - Generates a polyhedron using slices.
11. [sas_cutter](API.md#file-sas_cutter)
    - Creates a skin which is used as a cutting tool help to align two separate
      parts together.

