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


## Table of Contents

<details><summary><a href="#file-range">📘 <b>range</b></a></summary>
<blockquote>
• <a href="#range-ch-How%20to%20Import">📑 <i>How to Import</i></a><br>
• <a href="#range-ch-Purpose">📑 <i>Purpose</i></a><br>
<details><summary><a href="#range-ch-Test">📑 <i>Test</i></a></summary>
<blockquote>
• <a href="#f-is_range">⚙️is_range</a><br>
</blockquote>
</details>
<details><summary><a href="#range-ch-Functions">📑 <i>Functions</i></a></summary>
<blockquote>
• <a href="#f-range">⚙️range</a><br>
• <a href="#f-range_len">⚙️range_len</a><br>
• <a href="#f-range_el">⚙️range_el</a><br>
• <a href="#f-range_el_pos_idx">⚙️range_el_pos_idx</a><br>
• <a href="#f-range_idx">⚙️range_idx</a><br>
</blockquote>
</details>
<details><summary><a href="#range-ch-range%20types">📑 <i>range types</i></a></summary>
<blockquote>
• <a href="#t-range">🧩range</a><br>
</blockquote>
</details>
</blockquote>
</details>

<details><summary><a href="#file-types">📘 <b>types</b></a></summary>
<blockquote>
• <a href="#types-ch-Purpose">📑 <i>Purpose</i></a><br>
<details><summary><a href="#types-ch-Tests">📑 <i>Tests</i></a></summary>
<blockquote>
• <a href="#f-is_indexable_te">⚙️is_indexable_te</a><br>
• <a href="#f-is_int">⚙️is_int</a><br>
• <a href="#f-is_float">⚙️is_float</a><br>
• <a href="#f-is_nan">⚙️is_nan</a><br>
</blockquote>
</details>
<details><summary><a href="#types-ch-Type%20Introspection">📑 <i>Type Introspection</i></a></summary>
<blockquote>
• <a href="#f-type_enum">⚙️type_enum</a><br>
• <a href="#f-type_enum_to_str">⚙️type_enum_to_str</a><br>
• <a href="#f-type">⚙️type</a><br>
• <a href="#f-type_structure">⚙️type_structure</a><br>
• <a href="#f-type_value">⚙️type_value</a><br>
</blockquote>
</details>
<details><summary><a href="#types-ch-types%20types">📑 <i>types types</i></a></summary>
<blockquote>
• <a href="#t-type_enum">🧩type_enum</a><br>
</blockquote>
</details>
</blockquote>
</details>

<details><summary><a href="#file-birlei">📘 <b>birlei</b></a></summary>
<blockquote>
• <a href="#birlei-ch-How%20to%20Import">📑 <i>How to Import</i></a><br>
• <a href="#birlei-ch-Purpose">📑 <i>Purpose</i></a><br>
<details><summary><a href="#birlei-ch-Functions">📑 <i>Functions</i></a></summary>
<blockquote>
• <a href="#f-birlei_to_begin_i_end_i">⚙️birlei_to_begin_i_end_i</a><br>
• <a href="#f-birlei_to_indices">⚙️birlei_to_indices</a><br>
</blockquote>
</details>
<details><summary><a href="#birlei-ch-birlei%20types">📑 <i>birlei types</i></a></summary>
<blockquote>
• <a href="#t-Birl">🧩Birl</a><br>
• <a href="#t-EndI">🧩EndI</a><br>
• <a href="#t-SpaceshipFn">🧩SpaceshipFn</a><br>
• <a href="#t-PredFn">🧩PredFn</a><br>
• <a href="#t-ReductionFn">🧩ReductionFn</a><br>
• <a href="#t-ReductionAirFn">🧩ReductionAirFn</a><br>
• <a href="#t-PredMapFn">🧩PredMapFn</a><br>
• <a href="#t-MapperFn">🧩MapperFn</a><br>
• <a href="#t-PpmrrairFn">🧩PpmrrairFn</a><br>
• <a href="#t-MapBackFn">🧩MapBackFn</a><br>
</blockquote>
</details>
</blockquote>
</details>

<details><summary><a href="#file-base_algos">📘 <b>base_algos</b></a></summary>
<blockquote>
• <a href="#base_algos-ch-How%20to%20Import">📑 <i>How to Import</i></a><br>
• <a href="#base_algos-ch-Purpose">📑 <i>Purpose</i></a><br>
• <a href="#base_algos-ch-FYI:%20Functions%20and%20Iterating%20are%20Abound!">📑 <i>FYI: Functions and Iterating are Abound!</i></a><br>
• <a href="#base_algos-ch-Iterators:">📑 <i>Iterators:</i></a><br>
• <a href="#base_algos-ch-Algorithms">📑 <i>Algorithms</i></a><br>
• <a href="#base_algos-ch-Algorithm%20Signatures">📑 <i>Algorithm Signatures</i></a><br>
<details><summary><a href="#base_algos-ch-PPMRRAIR%20functions">📑 <i>PPMRRAIR functions</i></a></summary>
<blockquote>
• <a href="#predicate-functioni--result">Predicate (`function(i) : result`)</a><br>
• <a href="#predicatemap-functioni-v--any">Predicate/Map (`function(i, v) : any`)</a><br>
• <a href="#reduction-functioni-acc--acc">Reduction (`function(i, acc) : acc`)</a><br>
• <a href="#reduction-allow-incomplete-reduction-functioni-acc--cont-acc">Reduction, Allow Incomplete Reduction (`function(i, acc) : [cont, acc]`)</a><br>
</blockquote>
</details>
<details><summary><a href="#base_algos-ch-The%20Base%20Algorithms">📑 <i>The Base Algorithms</i></a></summary>
<blockquote>
• <a href="#f-find_lower">⚙️find_lower</a><br>
• <a href="#f-find_upper">⚙️find_upper</a><br>
• <a href="#f-find">⚙️find</a><br>
• <a href="#f-reduce">⚙️reduce</a><br>
• <a href="#f-reduce_air">⚙️reduce_air</a><br>
• <a href="#f-filter">⚙️filter</a><br>
• <a href="#f-map">⚙️map</a><br>
</blockquote>
</details>
<details><summary><a href="#base_algos-ch-base_algos%20types">📑 <i>base_algos types</i></a></summary>
<blockquote>
• <a href="#t-BoundIndexFn">🧩BoundIndexFn</a><br>
• <a href="#t-FindLowerFn">🧩FindLowerFn</a><br>
• <a href="#t-FindUpperFn">🧩FindUpperFn</a><br>
• <a href="#t-OptionalBirl">🧩OptionalBirl</a><br>
• <a href="#t-AlgoFn">🧩AlgoFn</a><br>
• <a href="#t-FindLowerBirleiFn">🧩FindLowerBirleiFn</a><br>
• <a href="#t-FindUpperFn">🧩FindUpperFn</a><br>
• <a href="#t-FindUpperBirleiFn">🧩FindUpperBirleiFn</a><br>
• <a href="#t-FindFn">🧩FindFn</a><br>
• <a href="#t-FindBirleiFn">🧩FindBirleiFn</a><br>
• <a href="#t-ReduceFn">🧩ReduceFn</a><br>
• <a href="#t-ReduceBirleiFn">🧩ReduceBirleiFn</a><br>
• <a href="#t-ReduceAirFn">🧩ReduceAirFn</a><br>
• <a href="#t-ReduceAirBirleiFn">🧩ReduceAirBirleiFn</a><br>
• <a href="#t-FilterFn">🧩FilterFn</a><br>
• <a href="#t-FilterBirleiFn">🧩FilterBirleiFn</a><br>
• <a href="#t-MapFn">🧩MapFn</a><br>
• <a href="#t-MapBirleiFn">🧩MapBirleiFn</a><br>
</blockquote>
</details>
</blockquote>
</details>

<details><summary><a href="#file-indexable">📘 <b>indexable</b></a></summary>
<blockquote>
• <a href="#indexable-ch-How%20to%20Import">📑 <i>How to Import</i></a><br>
<details><summary><a href="#indexable-ch-Purpose">📑 <i>Purpose</i></a></summary>
<blockquote>
• <a href="#example">Example</a><br>
</blockquote>
</details>
<details><summary><a href="#indexable-ch-Slices">📑 <i>Slices</i></a></summary>
<blockquote>
• <a href="#f-is_slice">⚙️is_slice</a><br>
• <a href="#f-slice">⚙️slice</a><br>
• <a href="#f-slice_to_range">⚙️slice_to_range</a><br>
</blockquote>
</details>
<details><summary><a href="#indexable-ch-Algorithm%20Adaptors">📑 <i>Algorithm Adaptors</i></a></summary>
<blockquote>
• <a href="#f-it_each">⚙️it_each</a><br>
• <a href="#f-it_idxs">⚙️it_idxs</a><br>
• <a href="#f-it_enum">⚙️it_enum</a><br>
</blockquote>
</details>
<details><summary><a href="#indexable-ch-Treat%20All%20Indexables%20the%20Same">📑 <i>Treat All Indexables the Same</i></a></summary>
<blockquote>
• <a href="#f-slr_len">⚙️slr_len</a><br>
• <a href="#f-idx">⚙️idx</a><br>
• <a href="#f-el">⚙️el</a><br>
• <a href="#f-el_pos_idx">⚙️el_pos_idx</a><br>
• <a href="#f-els">⚙️els</a><br>
• <a href="#f-range_els">⚙️range_els</a><br>
</blockquote>
</details>
<details><summary><a href="#indexable-ch-Getting/Traversing%20Indices">📑 <i>Getting/Traversing Indices</i></a></summary>
<blockquote>
• <a href="#f-idxs">⚙️idxs</a><br>
• <a href="#f-fwd_i">⚙️fwd_i</a><br>
• <a href="#f-rev_i">⚙️rev_i</a><br>
• <a href="#f-next_in">⚙️next_in</a><br>
• <a href="#f-prev_in">⚙️prev_in</a><br>
</blockquote>
</details>
<details><summary><a href="#indexable-ch-Functions%20to%20Manipulate%20Strings%20and%20Lists">📑 <i>Functions to Manipulate Strings and Lists</i></a></summary>
<blockquote>
• <a href="#f-push">⚙️push</a><br>
• <a href="#f-pop">⚙️pop</a><br>
• <a href="#f-unshift">⚙️unshift</a><br>
• <a href="#f-shift">⚙️shift</a><br>
• <a href="#f-insert">⚙️insert</a><br>
• <a href="#f-remove">⚙️remove</a><br>
• <a href="#f-remove_adjacent_dups">⚙️remove_adjacent_dups</a><br>
• <a href="#f-remove_each">⚙️remove_each</a><br>
• <a href="#f-replace">⚙️replace</a><br>
• <a href="#f-replace_each">⚙️replace_each</a><br>
• <a href="#f-swap">⚙️swap</a><br>
• <a href="#f-rotate_left">⚙️rotate_left</a><br>
• <a href="#f-rotate_right">⚙️rotate_right</a><br>
• <a href="#f-head">⚙️head</a><br>
• <a href="#f-head_multi">⚙️head_multi</a><br>
• <a href="#f-tail">⚙️tail</a><br>
• <a href="#f-tail_multi">⚙️tail_multi</a><br>
• <a href="#f-osearch">⚙️osearch</a><br>
• <a href="#f-csearch">⚙️csearch</a><br>
</blockquote>
</details>
<details><summary><a href="#indexable-ch-indexable%20types">📑 <i>indexable types</i></a></summary>
<blockquote>
• <a href="#t-slice">🧩slice</a><br>
• <a href="#t-Birls">🧩Birls</a><br>
• <a href="#t-slr_cache">🧩slr_cache</a><br>
• <a href="#t-GetPpmrrairFn">🧩GetPpmrrairFn</a><br>
• <a href="#t-EqualFn">🧩EqualFn</a><br>
• <a href="#t-GetEqualFn">🧩GetEqualFn</a><br>
• <a href="#t-RemoveAdjacentDupsFn">🧩RemoveAdjacentDupsFn</a><br>
• <a href="#t-ReplaceEachFn">🧩ReplaceEachFn</a><br>
• <a href="#t-SearchFn">🧩SearchFn</a><br>
• <a href="#t-SearchNeedleFn">🧩SearchNeedleFn</a><br>
</blockquote>
</details>
</blockquote>
</details>

<details><summary><a href="#file-function">📘 <b>function</b></a></summary>
<blockquote>
• <a href="#function-ch-Purpose">📑 <i>Purpose</i></a><br>
<details><summary><a href="#function-ch-Function%20Introspection">📑 <i>Function Introspection</i></a></summary>
<blockquote>
• <a href="#f-param_count">⚙️param_count</a><br>
• <a href="#f-param_count_direct_recursion_demo">⚙️param_count_direct_recursion_demo</a><br>
• <a href="#f-apply_to_fn">⚙️apply_to_fn</a><br>
• <a href="#f-apply_to_fn2">⚙️apply_to_fn2</a><br>
</blockquote>
</details>
</blockquote>
</details>

<details><summary><a href="#file-test">📘 <b>test</b></a></summary>
<blockquote>
• <a href="#test-ch-Purpose">📑 <i>Purpose</i></a><br>
<details><summary><a href="#test-ch-Test%20Your%20Code!">📑 <i>Test Your Code!</i></a></summary>
<blockquote>
• <a href="#m-test_eq">🧪test_eq</a><br>
• <a href="#m-test_approx_eq">🧪test_approx_eq</a><br>
• <a href="#m-test_ne">🧪test_ne</a><br>
• <a href="#m-test_lt">🧪test_lt</a><br>
• <a href="#m-test_le">🧪test_le</a><br>
• <a href="#m-test_gt">🧪test_gt</a><br>
• <a href="#m-test_ge">🧪test_ge</a><br>
• <a href="#m-test_truthy">🧪test_truthy</a><br>
• <a href="#m-test_falsy">🧪test_falsy</a><br>
</blockquote>
</details>
</blockquote>
</details>

<details><summary><a href="#file-transform">📘 <b>transform</b></a></summary>
<blockquote>
• <a href="#transform-ch-Purpose">📑 <i>Purpose</i></a><br>
<details><summary><a href="#transform-ch-Generate%20Matrices%20for%20Vector%20Transforms">📑 <i>Generate Matrices for Vector Transforms</i></a></summary>
<blockquote>
• <a href="#f-transpose">⚙️transpose</a><br>
• <a href="#f-homogenise">⚙️homogenise</a><br>
• <a href="#f-dehomogenise">⚙️dehomogenise</a><br>
• <a href="#f-homogenise_transform">⚙️homogenise_transform</a><br>
• <a href="#f-rot_x">⚙️rot_x</a><br>
• <a href="#f-rot_y">⚙️rot_y</a><br>
• <a href="#f-rot_z">⚙️rot_z</a><br>
• <a href="#f-is_point">⚙️is_point</a><br>
• <a href="#f-is_vector">⚙️is_vector</a><br>
• <a href="#f-is_bound_vector">⚙️is_bound_vector</a><br>
• <a href="#f-rot_axis">⚙️rot_axis</a><br>
• <a href="#f-rotate">⚙️rotate</a><br>
• <a href="#f-translate">⚙️translate</a><br>
• <a href="#f-scale">⚙️scale</a><br>
• <a href="#f-transform">⚙️transform</a><br>
• <a href="#f-reorient">⚙️reorient</a><br>
</blockquote>
</details>
<details><summary><a href="#transform-ch-Matrix%20Math">📑 <i>Matrix Math</i></a></summary>
<blockquote>
• <a href="#f-invert">⚙️invert</a><br>
• <a href="#f-row_reduction">⚙️row_reduction</a><br>
• <a href="#f-identity">⚙️identity</a><br>
• <a href="#f-augment">⚙️augment</a><br>
</blockquote>
</details>
<details><summary><a href="#transform-ch-transform%20types">📑 <i>transform types</i></a></summary>
<blockquote>
• <a href="#t-Matrix">🧩Matrix</a><br>
• <a href="#t-Point2D">🧩Point2D</a><br>
• <a href="#t-Point3D">🧩Point3D</a><br>
• <a href="#t-Point">🧩Point</a><br>
• <a href="#t-Vector2D">🧩Vector2D</a><br>
• <a href="#t-Vector3D">🧩Vector3D</a><br>
• <a href="#t-Vector">🧩Vector</a><br>
• <a href="#t-BVector2D">🧩BVector2D</a><br>
• <a href="#t-BVector3D">🧩BVector3D</a><br>
• <a href="#t-BVector">🧩BVector</a><br>
</blockquote>
</details>
</blockquote>
</details>

<details><summary><a href="#file-helpers">📘 <b>helpers</b></a></summary>
<blockquote>
• <a href="#helpers-ch-Purpose">📑 <i>Purpose</i></a><br>
<details><summary><a href="#helpers-ch-Conversion%20functions">📑 <i>Conversion functions</i></a></summary>
<blockquote>
• <a href="#f-r2d">⚙️r2d</a><br>
• <a href="#f-d2r">⚙️d2r</a><br>
</blockquote>
</details>
<details><summary><a href="#helpers-ch-Circular%20/%20Spherical%20Calculations">📑 <i>Circular / Spherical Calculations</i></a></summary>
<blockquote>
• <a href="#f-arc_len">⚙️arc_len</a><br>
• <a href="#f-arc_len_angle">⚙️arc_len_angle</a><br>
• <a href="#f-arc_len_for_shift">⚙️arc_len_for_shift</a><br>
• <a href="#f-shift_for_arc_len">⚙️shift_for_arc_len</a><br>
</blockquote>
</details>
<details><summary><a href="#helpers-ch-Miscellaneous">📑 <i>Miscellaneous</i></a></summary>
<blockquote>
• <a href="#f-not">⚙️not</a><br>
• <a href="#f-clamp">⚙️clamp</a><br>
• <a href="#f-vector_info">⚙️vector_info</a><br>
• <a href="#f-equal">⚙️equal</a><br>
• <a href="#f-function_equal">⚙️function_equal</a><br>
• <a href="#f-default">⚙️default</a><br>
• <a href="#f-INCOMPLETE">⚙️INCOMPLETE</a><br>
• <a href="#f-offset_angle">⚙️offset_angle</a><br>
• <a href="#m-arrow">🧊arrow</a><br>
• <a href="#m-axis">🧊axis</a><br>
• <a href="#f-fl">⚙️fl</a><br>
• <a href="#f-Assert">⚙️Assert</a><br>
• <a href="#f-interpolated_values">⚙️interpolated_values</a><br>
</blockquote>
</details>
<details><summary><a href="#helpers-ch-helpers%20types">📑 <i>helpers types</i></a></summary>
<blockquote>
• <a href="#t-VectorInfo">🧩VectorInfo</a><br>
• <a href="#t-IdentityFn">🧩IdentityFn</a><br>
</blockquote>
</details>
</blockquote>
</details>

<details><summary><a href="#file-skin">📘 <b>skin</b></a></summary>
<blockquote>
• <a href="#skin-ch-Purpose">📑 <i>Purpose</i></a><br>
<details><summary><a href="#skin-ch-Design">📑 <i>Design</i></a></summary>
<blockquote>
• <a href="#f-skin_to_string">⚙️skin_to_string</a><br>
• <a href="#f-layer_pt">⚙️layer_pt</a><br>
• <a href="#f-layer_pts">⚙️layer_pts</a><br>
• <a href="#f-layer_side_faces">⚙️layer_side_faces</a><br>
• <a href="#f-is_skin">⚙️is_skin</a><br>
• <a href="#f-skin_new">⚙️skin_new</a><br>
• <a href="#f-skin_extrude">⚙️skin_extrude</a><br>
• <a href="#f-skin_create_faces">⚙️skin_create_faces</a><br>
• <a href="#f-skin_transform">⚙️skin_transform</a><br>
• <a href="#m-skin_to_polyhedron">🧊skin_to_polyhedron</a><br>
• <a href="#f-skin_add_layer_if">⚙️skin_add_layer_if</a><br>
• <a href="#m-skin_show_debug_axes">🧊skin_show_debug_axes</a><br>
• <a href="#f-interpolate">⚙️interpolate</a><br>
• <a href="#f-skin_limit">⚙️skin_limit</a><br>
• <a href="#f-skin_verify">⚙️skin_verify</a><br>
• <a href="#f-skin_max_layer_distance_fn">⚙️skin_max_layer_distance_fn</a><br>
</blockquote>
</details>
<details><summary><a href="#skin-ch-skin%20types">📑 <i>skin types</i></a></summary>
<blockquote>
• <a href="#t-skin">🧩skin</a><br>
• <a href="#t-Face">🧩Face</a><br>
• <a href="#t-SkinExtrude">🧩SkinExtrude</a><br>
• <a href="#t-ColourLst">🧩ColourLst</a><br>
• <a href="#t-ColourStr">🧩ColourStr</a><br>
• <a href="#t-ColourName">🧩ColourName</a><br>
• <a href="#t-DebugStyle">🧩DebugStyle</a><br>
• <a href="#f-sas_cutter">⚙️sas_cutter</a><br>
• <a href="#f-sas2_cutter">⚙️sas2_cutter</a><br>
• <a href="#f-scs_cutter">⚙️scs_cutter</a><br>
</blockquote>
</details>
</blockquote>
</details>


## <span style="font-size: 1.1em; color: yellow">📘range</span><a id='file-range'></a>

### <i>📑How to Import</i><a id='range-ch-How to Import'></a>

    use <range>

### <i>📑Purpose</i><a id='range-ch-Purpose'></a>

A range is a structure that can be iterated over, like one can do with a
list.  However, unlike in python, it:

1. Doesn't have the ability to index an element in the range
2. Doesn't have a simple means to determine if an object is a range object.
3. Doesn't have a way to interrogate it for its length.
4. Has a feature which if the end value is unreachable given an initial start
   and step value, it generates a a warning.

This library is to help with those deficiencies.

> ℹ️ NOTE:
>
> Ranges in OpenSCAD are closed ranges.  This means that if the step allows,
> the specified end value will be part of the iteration.  E.g. `range(1, 5)`
> will iterate on `1`, `2`, `3`, `4` *and* `5`, opposed to half open ranges
> like that used in python, where `range(1, 5)` would iterate on `1`, `2`,
> `3`, and `4`.

### <i>📑Test</i><a id='range-ch-Test'></a>

#### ⚙️is\_range<a id='f-is_range'></a>

<code>*function* is_range(o: any) : bool</code>

Tests if the object is a range object.

<details><summary>parameters</summary>

**<code>o</code>**: <code>any</code>

Object to test.

</details>

<details><summary>returns</summary>

**Returns**: <code>bool</code>

Returns `true` if object is a range, otherwise `false`.

</details>

### <i>📑Functions</i><a id='range-ch-Functions'></a>

#### ⚙️range<a id='f-range'></a>

<code>*function* range(count\_or\_begin\_i: number, step\_or\_end\_i: number, end\_i: number) : <a href="#t-range">range</a>|list</code>

Creates a range object.

> ℹ️ NOTE:
>
> Will **not** generate a warning if step results in no elements in range,
> unlike `[ begin_i : end_i ]` or `[ begin_i : step : end_i ]`.  Instead,
> generates an empty list.

<details><summary>parameters</summary>

**<code>count_or_begin_i</code>**: <code>number</code>

- If `step_i_end_i` is `undef`, the number of indices to count, from `0` to
  `count_or_begin_i-1`.
  - If `≤ 0` then returns an empty list.
- Else the beginning index.

**<code>step_or_end_i</code>**: <code>number</code>

- If `end_i` is `undef`, then this is the end index.
- Else this is the step.

**<code>end_i</code>**: <code>number</code>

- If a number, then this is the ending index.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-range">range</a>|list</code>

This is the range to iterate over.  If `step < 0 and begin_i < end_i or
step > 0 and begin_i > end_i or count <= 0`, then returns an empty list.

</details>

#### ⚙️range\_len<a id='f-range_len'></a>

<code>*function* range_len(r: <a href="#t-range">range</a>) : number</code>

Will return the number of elements the range will return.

> ℹ️ NOTE:
>
> Assumes range was created with [`range()`](#f-range), so that the elements
> must be valid. E.g. `[ -B : +S : -E ]` will never occur as it would have
> been converted to `[]`.

<details><summary>parameters</summary>

**<code>r</code>**: <code><a href="#t-range">range</a></code>

The range to count how many indices it will iterate over.

</details>

<details><summary>returns</summary>

**Returns**: <code>number</code>

The number of indices the range contains.

</details>

#### ⚙️range\_el<a id='f-range_el'></a>

<code>*function* range_el(r: <a href="#t-range">range</a>, i: number, \_r\_len: number|undef) : number</code>

Will return the element that would have been returned if left to iterate `i`
times.

> ℹ️ NOTE:
>
> It is **UB** to dereference at an index that is not in the range.

<details><summary>parameters</summary>

**<code>r</code>**: <code><a href="#t-range">range</a></code>

The range to get index from if left to iterate `i` times.

**<code>i</code>**: <code>number</code>

The number iterations to have been done to get the return value.
If negative then start counting from end to beginning.

**<code>_r_len</code>**: <code>number|undef</code>

Cached length of `r`.  Will calculate it if `undef`.

> ℹ️ NOTE:
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!

</details>

<details><summary>returns</summary>

**Returns**: <code>number</code>

The index to have retrieved if iterated over `i` times.

</details>

#### ⚙️range\_el\_pos\_idx<a id='f-range_el_pos_idx'></a>

<code>*function* range_el_pos_idx(r: <a href="#t-range">range</a>, i: number) : number</code>

Dereference range at index `i`, allowing only positive indices.

> ℹ️ NOTE:
>
> It is **UB** to dereference at an index that is not in the range.

<details><summary>parameters</summary>

**<code>r</code>**: <code><a href="#t-range">range</a></code>

The range to get index from if left to iterate `i` times.

**<code>i</code>**: <code>number</code>

The number iterations to have been done to get the return value.
Must be positive `(i >= 0)`.

</details>

<details><summary>returns</summary>

**Returns**: <code>number</code>

The index to have retrieved if iterated over `i` times.

</details>

#### ⚙️range\_idx<a id='f-range_idx'></a>

<code>*function* range_idx(r: <a href="#t-range">range</a>, i: number, \_r\_len: number|undef) : number</code>

Gets the index for an range.  Allows for negative values to reference
elements starting from the end going backwards.

<details><summary>parameters</summary>

**<code>r</code>**: <code><a href="#t-range">range</a></code>

The range to get the index for.

**<code>i</code>**: <code>number</code>

The index of the element.  If value is negative, then goes backward from
end of range.

**<code>_r_len</code>**: <code>number|undef</code>

Cached length of `r`.  Will calculate it if `undef`.

> ℹ️ NOTE:
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!

</details>

<details><summary>returns</summary>

**Returns**: <code>number</code>

The positive index.

</details>

### <i>📑range types</i><a id='range-ch-range types'></a>

#### 🧩range<a id='t-range'></a>

<code>*type* range = list</code>

An iterable range of numeric values that consists of a start, step and stop.
If step allows, stop is included in the range.

> ℹ️ NOTE:
>
> Ranges in OpenSCAD are closed ranges.  This means that if the step allows,
> the specified end value will be part of the iteration.  E.g. `range(1, 5)`
> will iterate on `1`, `2`, `3`, `4` *and* `5`, opposed to half open ranges
> like that used in python, where `range(1, 5)` would iterate on `1`, `2`,
> `3`, and `4`.

> ℹ️ NOTE:
>
> `len()` doesn't work on a range.  Use [`range_len()`](#f-range_len)
> instead.

<details><summary>slots</summary>
<code><b>0</b></code>: <code>number</code>

Beginning value.

<code><b>1</b></code>: <code>number</code>

Step value.

<code><b>2</b></code>: <code>number</code>

Stop value.

</details>


## <span style="font-size: 1.1em; color: yellow">📘types</span><a id='file-types'></a>

### <i>📑Purpose</i><a id='types-ch-Purpose'></a>

This library allows representing types as enumerated values, strings or
minimal strings for complex types.

### <i>📑Tests</i><a id='types-ch-Tests'></a>

#### ⚙️is\_indexable\_te<a id='f-is_indexable_te'></a>

<code>*function* is_indexable_te(type\_enum: <a href="#t-type_enum">type_enum</a>) : bool</code>

States if a te (type_enum) represents an indexable type, either directly with
`sl[index]` or indirectly with `range_el(r, index)`.

<details><summary>parameters</summary>

**<code>type_enum</code>**: <code><a href="#t-type_enum">type_enum</a></code>

Enum for type (See [type_enum](#t-type_enum))

</details>

<details><summary>returns</summary>

**Returns**: <code>bool</code>

Returns `true` if indexable, `false` otherwise.

</details>

#### ⚙️is\_int<a id='f-is_int'></a>

<code>*function* is_int(o: any) : bool</code>

States if object is an integer (has no fractional part).

<details><summary>parameters</summary>

**<code>o</code>**: <code>any</code>

Object to query.

</details>

<details><summary>returns</summary>

**Returns**: <code>bool</code>

Returns `true` if integer, `false` otherwise.

</details>

#### ⚙️is\_float<a id='f-is_float'></a>

<code>*function* is_float(o: any) : bool</code>

States if object is a float (has a fractional part).

<details><summary>parameters</summary>

**<code>o</code>**: <code>any</code>

Object to query.

</details>

<details><summary>returns</summary>

**Returns**: <code>bool</code>

Returns `true` if float, `false` otherwise.

</details>

#### ⚙️is\_nan<a id='f-is_nan'></a>

<code>*function* is_nan(n: any) : bool</code>

States if object is a NaN object.

<details><summary>parameters</summary>

**<code>n</code>**: <code>any</code>

Object to query.

</details>

<details><summary>returns</summary>

**Returns**: <code>bool</code>

Returns `true` if NaN, `false` otherwise.

</details>

### <i>📑Type Introspection</i><a id='types-ch-Type Introspection'></a>

#### ⚙️type\_enum<a id='f-type_enum'></a>

<code>*function* type_enum(o: any, distinguish\_float\_from\_int: bool) : number</code>

Function to get the type of an object as an enum.

<details><summary>parameters</summary>

**<code>o</code>**: <code>any</code>

The object to get the type from.

**<code>distinguish_float_from_int</code>**: <code>bool</code>
 *(Default: `false`)*

Flag to indicate if to distinguish floats from integers rather than
grouping them together as numbers.

</details>

<details><summary>returns</summary>

**Returns**: <code>number</code>

The number corresponding to the type enum.

</details>

#### ⚙️type\_enum\_to\_str<a id='f-type_enum_to_str'></a>

<code>*function* type_enum_to_str(i: number) : string</code>

Convert the type enum to a string.

<details><summary>parameters</summary>

**<code>i</code>**: <code>number</code>

Type enum to convert.

</details>

<details><summary>returns</summary>

**Returns**: <code>string</code>

The string corresponding to the type enum.  If type enum is not recognised,
return "*INVALID TYPE*".

</details>

#### ⚙️type<a id='f-type'></a>

<code>*function* type(o: any) : bool</code>

Gets a string representation of the type of `o`.

<details><summary>parameters</summary>

**<code>o</code>**: <code>any</code>

Object to query.

</details>

<details><summary>returns</summary>

**Returns**: <code>bool</code>

Returns string representation of `o`'s type.

</details>

#### ⚙️type\_structure<a id='f-type_structure'></a>

<code>*function* type_structure(o: any) : string</code>

Attempts to simplify the type structure of object o recursively.

- If o is a list
  - if all elements in that list contain the same type structure,
    - simplify the list by only showing that structure once and append to it
      how many times it is repeated.
  - else if not the same, then recursively simplify each element.
- else it's some other type, so will just output the type of the object.

<details><summary>parameters</summary>

**<code>o</code>**: <code>any</code>

Gets the simplified type structure of o.

</details>

<details><summary>returns</summary>

**Returns**: <code>string</code>

This string is a representation of the type structure of o.

</details>

#### ⚙️type\_value<a id='f-type_value'></a>

<code>*function* type_value(o: any) : string</code>

Gives a string that outputs the type_structure and value of object passed in.

<details><summary>parameters</summary>

**<code>o</code>**: <code>any</code>

The object to list information about.

</details>

<details><summary>returns</summary>

**Returns**: <code>string</code>

Give info for `o` as string.

</details>

### <i>📑types types</i><a id='types-ch-types types'></a>

#### 🧩type\_enum<a id='t-type_enum'></a>

<code>*type* type_enum = number</code>

Number representing a type.  Use [`type_enum_to_str()`](#f-type_enum_to_str)
to get name of type.


## <span style="font-size: 1.1em; color: yellow">📘birlei</span><a id='file-birlei'></a>

### <i>📑How to Import</i><a id='birlei-ch-How to Import'></a>

    use <birlei>

### <i>📑Purpose</i><a id='birlei-ch-Purpose'></a>

This is the core of the library's algorithm set.  It evolved from having two
indices,
`begin_i` and `end_i` so that functions could be made to recursively iterate
over them.  However, it didn't contain a step, but there was already an
object that worked for list comprehension and it worked the same way as lists
would.

However, to actually use a range or list recursively, they would have to be
indexable in a similar way, so the [ranges](#file-range) library was made.
`begin_i` would be used to count to `end_i` over the length of the object,
dereferencing each element as needed.

Keeping this in the user facing API was done because just counting from N to
M is very common, and without dereferencing a list or range it's marginally
faster.

### <i>📑Functions</i><a id='birlei-ch-Functions'></a>

#### ⚙️birlei\_to\_begin\_i\_end\_i<a id='f-birlei_to_begin_i_end_i'></a>

<code>*function* birlei_to_begin_i_end_i(algo\_fn: function, ppmrrair\_fn: <a href="#t-PpmrrairFn">PpmrrairFn</a>, birl: <a href="#t-Birl">Birl</a>, end\_i: <a href="#t-EndI">EndI</a>) : any</code>

Helper which calls `algo_fn` but remaps signature `function(fn, birl, end_i)`
to signature `function(fn, begin_i, end_i, map_back_fn)`.

<details><summary>parameters</summary>

**<code>algo_fn</code>**: <code>function</code>

Function with `(fn, begin_i, end_i, map_back_fn)` signature to call, where:

- `fn`: `number`
  - ppmrrair function to call.
- `begin_i`: `number`
  - Starting index to operate on.
- `end_i`: `number`
  - Ending index to operate on.
- `map_back_fn`: `function(i: number|undef): (number|undef)`
  - When the algorithm is returning a number from the `birlei`, the
    algorithm is to pass the index it found to this function, which will
    remap it back to the `birlei` value.
  - If this function is passed `undef`, it returns `undef` for
    convenience.

**<code>ppmrrair_fn</code>**: <code><a href="#t-PpmrrairFn">PpmrrairFn</a></code>

- Takes index or element and possibly a second param and returns a value.

**<code>birl</code>**: <code><a href="#t-Birl">Birl</a></code>

- If `number`, start index to iterate over
- If `range`, indices to iterate over
- If `list`, indices to iterate over

**<code>end_i</code>**: <code><a href="#t-EndI">EndI</a></code>

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

</details>

<details><summary>returns</summary>

**Returns**: <code>any</code>

Result of `algo_fn()`.

</details>

#### ⚙️birlei\_to\_indices<a id='f-birlei_to_indices'></a>

<code>*function* birlei_to_indices(birl: <a href="#t-Birl">Birl</a>, end\_i: <a href="#t-EndI">EndI</a>) : list|<a href="#t-range">range</a></code>

Helper to convert birlei parameters to an lr to traverse.

<details><summary>parameters</summary>

**<code>birl</code>**: <code><a href="#t-Birl">Birl</a></code>

- If `number`, start index to iterate over
- If `range`, indices to iterate over
- If `list`, indices to iterate over

**<code>end_i</code>**: <code><a href="#t-EndI">EndI</a></code>

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

</details>

<details><summary>returns</summary>

**Returns**: <code>list|<a href="#t-range">range</a></code>

Returns a list or range describing the indices to traverse.

</details>

### <i>📑birlei types</i><a id='birlei-ch-birlei types'></a>

#### 🧩Birl<a id='t-Birl'></a>

<code>*type* Birl = number|<a href="#t-range">range</a>|list</code>

- If `number`, start index to iterate over
- If `range`, indices to iterate over
- If `list`, indices to iterate over

#### 🧩EndI<a id='t-EndI'></a>

<code>*type* EndI = number|undef</code>

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

#### 🧩SpaceshipFn<a id='t-SpaceshipFn'></a>

<code>*callback* SpaceshipFn(probe: any) : number</code>

Compares a derived comparison value against an internally stored value.

Definitions:

- probe: the argument passed to this callback by the algorithm.
- comparison value: the value derived from the probe that is actually
  compared to the stored value.

Probe convention:

- Without an [Algorithm Adaptor](#algorithm-adaptors), the probe is a number
  within the `birlei`.
- With an Algorithm Adaptor, the probe is the adaptor's output:
  - [`it_each`](#f-it_each): `slr_element`.
  - [`it_enum`](#f-it_enum): `[index, slr_element]`.
  - [`it_idxs`](#f-it_idxs): `index`.

The callback is responsible for mapping probe → comparison value.  The
mapping is defined by the callback's closure over the searched structure (slr
or any other abstract structure) and/or by how it interprets adaptor outputs.

<details><summary>parameters</summary>

**<code>probe</code>**: <code>any</code>

The probe value as defined above.

</details>

<details><summary>returns</summary>

**Returns**: <code>number</code>

- comparison value < stored value: return < 0
- comparison value == stored value: return 0
- comparison value > stored value: return > 0

</details>

#### 🧩PredFn<a id='t-PredFn'></a>

<code>*callback* PredFn(probe: any) : bool</code>

Compares a derived comparison value against an internally stored value.

Definitions:

- probe: the argument passed to this callback by the algorithm.
- comparison value: the value derived from the probe that is actually
  compared to the stored value.

Probe convention:

- Without an [Algorithm Adaptor](#algorithm-adaptors), the probe is a number
  within the `birlei`.
- With an Algorithm Adaptor, the probe is the adaptor's output:
  - [`it_each`](#f-it_each): `slr_element`.
  - [`it_enum`](#f-it_enum): `[index, slr_element]`.
  - [`it_idxs`](#f-it_idxs): `index`.

The callback is responsible for mapping probe → comparison value.  The
mapping is defined by the callback's closure over the searched structure (slr
or any other abstract structure) and/or by how it interprets adaptor outputs.

<details><summary>parameters</summary>

**<code>probe</code>**: <code>any</code>

The probe value as defined above.

</details>

<details><summary>returns</summary>

**Returns**: <code>bool</code>

- comparison value matches stored value: return `true`
- comparison value doesn't match stored value: return `false`

</details>

#### 🧩ReductionFn<a id='t-ReductionFn'></a>

<code>*callback* ReductionFn(probe: any, accumulator: any) : any</code>

Mutates the accumulator given a derived comparison value.

Definitions:

- probe: the argument passed to this callback by the algorithm.
- comparison value: the value derived from the probe that is actually
  compared to the stored value.

Probe convention:

- Without an [Algorithm Adaptor](#algorithm-adaptors), the probe is a number
  within the `birlei`.
- With an Algorithm Adaptor, the probe is the adaptor's output:
  - [`it_each`](#f-it_each): `slr_element`.
  - [`it_enum`](#f-it_enum): `[index, slr_element]`.
  - [`it_idxs`](#f-it_idxs): `index`.

The callback is responsible for mapping probe → comparison value.  The
mapping is defined by the callback's closure over the searched structure (slr
or any other abstract structure) and/or by how it interprets adaptor outputs.

> ℹ️ NOTE:
>
> `acc` **is the second parameter** which is different from most languages.
> This is to keep it consistent with the rest of the `PPMRRAIR` functions
> and this library in general.  You have been warned.

<details><summary>parameters</summary>

**<code>probe</code>**: <code>any</code>

The probe value as defined above.

**<code>accumulator</code>**: <code>any</code>

The accumulator being mutated.

</details>

<details><summary>returns</summary>

**Returns**: <code>any</code>

The newly mutated accumulator value or the initial value if the `birlei`
was empty.

</details>

#### 🧩ReductionAirFn<a id='t-ReductionAirFn'></a>

<code>*callback* ReductionAirFn(probe: any, accumulator: any) : list\[bool,any]</code>

Mutates the accumulator given a derived comparison value.

Definitions:

- probe: the argument passed to this callback by the algorithm.
- comparison value: the value derived from the probe that is actually
  compared to the stored value.

Probe convention:

- Without an [Algorithm Adaptor](#algorithm-adaptors), the probe is a number
  within the `birlei`.
- With an Algorithm Adaptor, the probe is the adaptor's output:
  - [`it_each`](#f-it_each): `slr_element`.
  - [`it_enum`](#f-it_enum): `[index, slr_element]`.
  - [`it_idxs`](#f-it_idxs): `index`.

The callback is responsible for mapping probe → comparison value.  The
mapping is defined by the callback's closure over the searched structure (slr
or any other abstract structure) and/or by how it interprets adaptor outputs.

> ℹ️ NOTE:
>
> `acc` **is the second parameter** which is different from most languages.
> This is to keep it consistent with the rest of the `PPMRRAIR` functions
> and this library in general.  You have been warned.

<details><summary>parameters</summary>

**<code>probe</code>**: <code>any</code>

The probe value as defined above.

**<code>accumulator</code>**: <code>any</code>

The accumulator being mutated.

</details>

<details><summary>returns</summary>

**Returns**: <code>list\[bool,any]</code>

List containing if to continue Boolean and the newly mutated accumulator
value.

</details>

#### 🧩PredMapFn<a id='t-PredMapFn'></a>

<code>*callback* PredMapFn(probe: any, get\_value: bool) : any</code>

Compares a derived comparison value against an internally stored value and
returns a value if:

Definitions:

- probe: the argument passed to this callback by the algorithm.
- comparison value: the value derived from the probe that is actually
  compared to the stored value.

Probe convention:

- Without an [Algorithm Adaptor](#algorithm-adaptors), the probe is a number
  within the `birlei`.
- With an Algorithm Adaptor, the probe is the adaptor's output:
  - [`it_each`](#f-it_each): `slr_element`.
  - [`it_enum`](#f-it_enum): `[index, slr_element]`.
  - [`it_idxs`](#f-it_idxs): `index`.

The callback is responsible for mapping probe → comparison value.  The
mapping is defined by the callback's closure over the searched structure (slr
or any other abstract structure) and/or by how it interprets adaptor outputs.

<details><summary>parameters</summary>

**<code>probe</code>**: <code>any</code>

The probe value as defined above.

**<code>get_value</code>**: <code>bool</code>

States if to return the predicate result or the probed value.

</details>

<details><summary>returns</summary>

**Returns**: <code>any</code>

- if `get_value` is falsy, then
  - comparison value matches stored value: return `true`
  - comparison value doesn't match stored value: return `false`
- else returns the probed value

</details>

#### 🧩MapperFn<a id='t-MapperFn'></a>

<code>*callback* MapperFn(probe: any) : any</code>

Maps a probed value to a list.

Definitions:

- probe: the argument passed to this callback by the algorithm.

Probe convention:

- Without an [Algorithm Adaptor](#algorithm-adaptors), the probe is a number
  within the `birlei`.
- With an Algorithm Adaptor, the probe is the adaptor's output:
  - [`it_each`](#f-it_each): `slr_element`.
  - [`it_enum`](#f-it_enum): `[index, slr_element]`.
  - [`it_idxs`](#f-it_idxs): `index`.

The callback is responsible for mapping probe value.  The mapping is defined
by the callback's closure over the searched structure (slr or any other
abstract structure) and/or by how it interprets adaptor outputs.

<details><summary>parameters</summary>

**<code>probe</code>**: <code>any</code>

The probe value as defined above.

</details>

<details><summary>returns</summary>

**Returns**: <code>any</code>

Value that was mapped given the probe.

</details>

#### 🧩PpmrrairFn<a id='t-PpmrrairFn'></a>

<code>*type* PpmrrairFn = <a href="#t-SpaceshipFn">SpaceshipFn</a>|<a href="#t-PredFn">PredFn</a>|<a href="#t-ReductionFn">ReductionFn</a>|<a href="#t-ReductionAirFn">ReductionAirFn</a>|<a href="#t-PredMapFn">PredMapFn</a>|<a href="#t-MapperFn">MapperFn</a></code>

The exact meaning depends on the type expected.  For more info, go to the
type you are interested in.

#### 🧩MapBackFn<a id='t-MapBackFn'></a>

<code>*callback* MapBackFn(i: number|undef) : number|undef</code>

When an algorithm is iterating, it iterates over a contiguous set of
integers.  The original set of values don't have to be contiguous.  This
function, remaps the contiguous integers back to the original set of values.

<details><summary>parameters</summary>

**<code>i</code>**: <code>number|undef</code>

Index to remap or undef if no index to remap.

</details>

<details><summary>returns</summary>

**Returns**: <code>number|undef</code>

- If originating algo_fn is returning an index, this function will map it
  to the correct index.
- If passed undef, returns undef.

</details>


## <span style="font-size: 1.1em; color: yellow">📘base_algos</span><a id='file-base_algos'></a>

### <i>📑How to Import</i><a id='base_algos-ch-How to Import'></a>

    use <base_algos>

### <i>📑Purpose</i><a id='base_algos-ch-Purpose'></a>

The purpose of this library is to provide the minimum number of abstracted
composable algorithms to be able to make coding easier, both when reading and
writing.  They are quite fast, and although you could prolly make faster hand
rolled implementations, IMHO this makes it easier to read and rationalise as
to intent.  Also, the pattern used is repeated everywhere, making it easier
to learn how to use.

### <i>📑FYI: Functions and Iterating are Abound!</i><a id='base_algos-ch-FYI: Functions and Iterating are Abound!'></a>

There is a lot of currying and passing of functions in this library.  (Mmmmmm
curry!)  No, not that type of curry.  Currying relates to having a function
return a function and using that function immediately.  For instance.  Say I
want to find the first instance of the letter "t" in a string.  Using this
library, the following could be done:

    s = "Hello there!";
    i = find(fwd_i(s))(function(i)
          s[i] == "t"
        );

Or it could be done using the algorithm adaptor `it_each` (See
[Algorithm Adaptors](#algorithm-adaptors)):

    s = "Hello there!";
    i = it_each(s, find())(function(c)
          c == "t"
        );

You'll notice the occurrence of `)(`.  This ends the algorithm or adaptor
call and start the next call which takes a function to test each element.
Also, observe that when the algorithm's `birlei` parameter is omitted, a
`function(birl, end_i)` is returned, which in this case is `find()`.  The
adaptor needs this function signature to be passed to it so that it can apply
the algorithm while passing the element to the `PPMRRAIR` function.

These 2 basic patterns are used everywhere in the library set, and though it
might look odd at first, you'll find that it becomes natural quite quickly.

### <i>📑Iterators:</i><a id='base_algos-ch-Iterators:'></a>

The algorithms are index, not element centric, which means that a physical
container (i.e. a list) is *not* needed.  A virtual container (i.e. function)
is all that is required.  The indices act as iterators as one might find in
C++.  However, unlike C++ and python ranges, which are half open ranges
`[begin, end)`, these are closed ranges `[begin, end]`, meaning that the end
item is the last item in the range, not one past the end.

For each of these algorithms, the `birl` parameter (formally
`begin_i_range_or_list`, but it became too much to type) state either:

1. Starting index (number)
   - Implies that a second `end_i` parameter will indicate the inclusive end
     index (number), conforming to OpenSCAD's closed range paradigm.
2. Indices (range)
   - Will go through each item in the range and use them as indices to pass
     to the algorithm.  `end_i` must be `undef`.
3. Indices (list)
   - Will go through each element in the list and use them as indices to pass
     to the algorithm.  `end_i` must be `undef`.

### <i>📑Algorithms</i><a id='base_algos-ch-Algorithms'></a>

There are 4 basic algorithms (`reduce`, `reduce_air`, `filter` and `map`),
from which most other algorithms can be built.  For optimisation purposes,
`reduce_air` adds the ability to `A`llow an `I`ncomplete `R`eduction (hence
the `_air` suffix) over the range and filter adds a hybrid filter/map
feature.

A few others (`find`, `find_upper`, `find_lower`) could have been implemented
with `reduce_air` but have been optimised with their own implementations.

The `find*` and `reduce*` algorithms rely on recursive descent, but conform
to TCO (Tail Call Optimisation) so don't have a maximum depth.  The `filter`
and `map` algorithms use list comprehension so also have no limit to their
range size.

> 🤔 TO THINK ABOUT:
>
> Should reduce_air's `init` param be `[ start, init ]` instead?  This would
> allow it to do nothing without the need for a special ternary check
> preceding it.
>
> A: I've yet not seen a good reason to do this.

### <i>📑Algorithm Signatures</i><a id='base_algos-ch-Algorithm Signatures'></a>

All of the algorithms have a compatible signature that have a `birlei` (one
or two parameters, a `birl` and optional `end_i`).  When you call the
algorithm without the `birlei` parameter, it returns a function that takes
only a `birlei` parameter.  This is used with the
[Algorithms Adaptor](#algorithm-adaptors), potentially simplifying your code.
When it's passed a `birlei`, it returns a function that requires a PPMRRAIR
function.  That function that is then called by the algorithm on each index
that the `birlei` refers to.

### <i>📑PPMRRAIR functions</i><a id='base_algos-ch-PPMRRAIR functions'></a>

Named after the 4 function types: `P`redicate, `P`redicate/`M`ap, `R`eduction
and `R`eduction that `A`llows for `I`ncomplete `R`eduction, these functions
are passed to the algorithms where the algorithms then call them iteratively
over each `birlei` element:

#### **Predicate** (`function(i) : result`)

- A binary predicate is used by `find`, `filter` and `map`.  It has 2
  results, truthy or falsely.
- A trinary predicate is used with `find_lower` and `find_upper`.  It has 3
  results: less than 0, equal to 0 and greater than 0.  This is akin to the
  spaceship operator in c++20.

#### **Predicate/Map** (`function(i, v) : any`)

- Optionally used by `filter`.
- If v is not passed then it has a falsy value (`undef`) indicating that the
  function is to act like a binary predicate.  Otherwise, if passed a true
  value, then it the function usually returns the element at that index,
  though can return anything which is to be placed in the resulting list.
- This 2 parameter function is a performance and memory allocation
  optimisation, allowing `filter` to do a `map` in the same step.

#### **Reduction** (`function(i, acc) : acc`)

> ℹ️ NOTE:
>
> `acc` **is the second parameter** which is different from most languages.
> This is to keep it consistent with the rest of the `PPMRRAIR` functions
> and this library in general.  You have been warned.

- Used by `reduce`.
- Takes in the index and the previous accumulated object and returns the
  new accumulated object.
- This is roughly equivalent to a for_each loop in C++.

#### **Reduction, Allow Incomplete Reduction** (`function(i, acc) : [cont, acc]`)

> ℹ️ NOTE:
>
> `acc` **is the second parameter** which is different from most languages.
> This is to keep it consistent with the rest of the `PPMRRAIR` functions
> and this library in general.  You have been warned.

- Used by `reduce_air`.
- Takes in the index and the previous accumulated object and returns a
  list `[ cont, new_acc ]`, where `cont` states if to continue looping if not
  finished iterating over the `birlei`.
- This is roughly equivalent to a for loop in C++.

**See also** [Algorithm Adaptors](#algorithm-adaptors).

### <i>📑The Base Algorithms</i><a id='base_algos-ch-The Base Algorithms'></a>

#### ⚙️find\_lower<a id='f-find_lower'></a>

<code>*function* find_lower(birl: <a href="#t-OptionalBirl">OptionalBirl</a>, end\_i: <a href="#t-EndI">EndI</a>) : <a href="#t-FindLowerFn">FindLowerFn</a>|<a href="#t-FindLowerBirleiFn">FindLowerBirleiFn</a></code>

Possible callchains:

    find_lower(birl, end_i)    (spaceship_fn) : (number|undef)
    find_lower() (birl, end_i) (spaceship_fn) : (number|undef)

Like C++'s `lower_bound`: returns the first index `i` for which
`spaceship_fn(i) >= 0`.

> ℹ️ NOTE:
>
> The specified `birlei` of indices must be such that `spaceship_fn(i)`
> is monotonically nondecreasing over the searched indices; or the results
> are **UB**.

<details><summary>parameters</summary>

**<code>birl</code>**: <code><a href="#t-OptionalBirl">OptionalBirl</a></code>

- If `number`, start index to iterate over
- If `range`, indices to iterate over
- If `list`, indices to iterate over
- If `undef`, then tells function to return a curried version of itself,
  that only takes parameters of types `Birl` and `EndI`.

**<code>end_i</code>**: <code><a href="#t-EndI">EndI</a></code>

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-FindLowerFn">FindLowerFn</a>|<a href="#t-FindLowerBirleiFn">FindLowerBirleiFn</a></code>

- If `birl` is omitted, then will return type `FindLowerBirleiFn`.
- Else returns type `FindLowerFn`.

Possible callchains:

    FindLowerFn(spaceship_fn) : (number|undef)
    FindLowerBirleiFn(birl, end_i) (spaceship_fn) : (number|undef)

</details>

#### ⚙️find\_upper<a id='f-find_upper'></a>

<code>*function* find_upper(birl: <a href="#t-OptionalBirl">OptionalBirl</a>, end\_i: <a href="#t-EndI">EndI</a>) : <a href="#t-FindUpperFn">FindUpperFn</a>|<a href="#t-FindUpperBirleiFn">FindUpperBirleiFn</a></code>

Possible callchains:

    find_upper(birl, end_i)    (spaceship_fn) : (number|undef)
    find_upper() (birl, end_i) (spaceship_fn) : (number|undef)

Like C++'s `upper_bound`: returns the first index `i` for which
`spaceship_fn(i) > 0`.

> ℹ️ NOTE:
>
> The specified `birlei` of indices must be such that `spaceship_fn(i)`
> is monotonically nondecreasing over the searched indices; or the results
> are **UB**.

<details><summary>parameters</summary>

**<code>birl</code>**: <code><a href="#t-OptionalBirl">OptionalBirl</a></code>

- If `number`, start index to iterate over
- If `range`, indices to iterate over
- If `list`, indices to iterate over
- If `undef`, then tells function to return a curried version of itself,
  that only takes parameters of types `Birl` and `EndI`.

**<code>end_i</code>**: <code><a href="#t-EndI">EndI</a></code>

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-FindUpperFn">FindUpperFn</a>|<a href="#t-FindUpperBirleiFn">FindUpperBirleiFn</a></code>

- If `birl` is omitted, then will return type `FindUpperBirleiFn`.
- Else returns type `FindUpperFn`.

Possible callchains:

    FindUpperFn(spaceship_fn) : (number|undef)
    FindUpperBirleiFn(birl, end_i) (spaceship_fn) : (number|undef)

</details>

#### ⚙️find<a id='f-find'></a>

<code>*function* find(birl: <a href="#t-OptionalBirl">OptionalBirl</a>, end\_i: <a href="#t-EndI">EndI</a>) : <a href="#t-FindFn">FindFn</a>|<a href="#t-FindBirleiFn">FindBirleiFn</a></code>

Possible callchains:

    find(birl, end_i)    (pred_fn) : (number|undef)
    find() (birl, end_i) (pred_fn) : (number|undef)

Returns the first index that results in `pred_fn(i)` returning a truthy
result.

<details><summary>parameters</summary>

**<code>birl</code>**: <code><a href="#t-OptionalBirl">OptionalBirl</a></code>

- If `number`, start index to iterate over
- If `range`, indices to iterate over
- If `list`, indices to iterate over
- If `undef`, then tells function to return a curried version of itself,
  that only takes parameters of types `Birl` and `EndI`.

**<code>end_i</code>**: <code><a href="#t-EndI">EndI</a></code>

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-FindFn">FindFn</a>|<a href="#t-FindBirleiFn">FindBirleiFn</a></code>

- If `birl` is omitted, then will return type `FindBirleiFn`.
- Else returns type `FindFn`.

Possible callchains:

    FindFn(pred_fn) : (number|undef)
    FindBirleiFn(birl, end_i) (pred_fn) : (number|undef)

</details>

#### ⚙️reduce<a id='f-reduce'></a>

<code>*function* reduce(init: any, birl: <a href="#t-OptionalBirl">OptionalBirl</a>, end\_i: <a href="#t-EndI">EndI</a>) : <a href="#t-ReduceFn">ReduceFn</a>|<a href="#t-ReduceBirleiFn">ReduceBirleiFn</a></code>

Possible callchains:

    reduce(init, birl, end_i)  (op_fn) : result
    reduce(init) (birl, end_i) (op_fn) : result

Reduces (a.k.a. folds) a set of indices to produce some value/object based on
the indices.

<details><summary>parameters</summary>

**<code>init</code>**: <code>any</code>

This is the initial value that is passed to the first iteration of `op_fn`
as the accumulator.

**<code>birl</code>**: <code><a href="#t-OptionalBirl">OptionalBirl</a></code>

- If `number`, start index to iterate over
- If `range`, indices to iterate over
- If `list`, indices to iterate over
- If `undef`, then tells function to return a curried version of itself,
  that only takes parameters of types `Birl` and `EndI`.

**<code>end_i</code>**: <code><a href="#t-EndI">EndI</a></code>

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-ReduceFn">ReduceFn</a>|<a href="#t-ReduceBirleiFn">ReduceBirleiFn</a></code>

- If `birl` is omitted, then will return type `ReduceBirleiFn`.
- Else returns type `ReduceFn`.

Possible callchains:

    ReduceFn(reduction_fn) : any
    ReduceBirleiFn(birl, end_i) (reduction_fn) : any

</details>

#### ⚙️reduce\_air<a id='f-reduce_air'></a>

<code>*function* reduce_air(init: any, birl: <a href="#t-OptionalBirl">OptionalBirl</a>, end\_i: <a href="#t-EndI">EndI</a>) : <a href="#t-ReduceAirFn">ReduceAirFn</a>|<a href="#t-ReductionAirFn">ReductionAirFn</a></code>

Possible callchains:

    reduce_air(init, birl, end_i)  (op_fn) : [cont, init_result]
    reduce_air(init) (birl, end_i) (op_fn) : [cont, init_result]

Reduces (a.k.a. folds) a set of indices to produce some value/object based on
the indices.  This Reduction Allows for Incomplete Reduction.

<details><summary>parameters</summary>

**<code>init</code>**: <code>any</code>

This is the initial value that is passed to the first iteration of `op_fn`
as the accumulator.

**<code>birl</code>**: <code><a href="#t-OptionalBirl">OptionalBirl</a></code>

- If `number`, start index to iterate over
- If `range`, indices to iterate over
- If `list`, indices to iterate over
- If `undef`, then tells function to return a curried version of itself,
  that only takes parameters of types `Birl` and `EndI`.

**<code>end_i</code>**: <code><a href="#t-EndI">EndI</a></code>

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-ReduceAirFn">ReduceAirFn</a>|<a href="#t-ReductionAirFn">ReductionAirFn</a></code>

- If `birl` is omitted, then will return type `ReduceAirBirleiFn`.
- Else returns type `ReduceAirFn`.

Possible callchains:

    ReduceAirFn(reduction_fn) : list[bool,any]
    ReductionAirFn(probe, accumulator) : list[bool,any]

</details>

#### ⚙️filter<a id='f-filter'></a>

<code>*function* filter(birl: <a href="#t-OptionalBirl">OptionalBirl</a>, end\_i: <a href="#t-EndI">EndI</a>) : <a href="#t-FilterFn">FilterFn</a>|<a href="#t-FilterBirleiFn">FilterBirleiFn</a></code>

Possible callchains:

    filter(birl, end_i)    (ppm_fn) : list
    filter() (birl, end_i) (ppm_fn) : list

Filter function.

<details><summary>parameters</summary>

**<code>birl</code>**: <code><a href="#t-OptionalBirl">OptionalBirl</a></code>

- If `number`, start index to iterate over
- If `range`, indices to iterate over
- If `list`, indices to iterate over
- If `undef`, then tells function to return a curried version of itself,
  that only takes parameters of types `Birl` and `EndI`.

**<code>end_i</code>**: <code><a href="#t-EndI">EndI</a></code>

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-FilterFn">FilterFn</a>|<a href="#t-FilterBirleiFn">FilterBirleiFn</a></code>

- If `birl` is omitted, then will return type `FilterBirleiFn`.
- Else returns type `FilterFn`.

Possible callchains:

    FilterFn(reduction_fn) : list[any,...]
    FilterBirleiFn(birl, end_i) (reduction_fn) : list[any,...]

</details>

#### ⚙️map<a id='f-map'></a>

<code>*function* map(birl: <a href="#t-OptionalBirl">OptionalBirl</a>, end\_i: <a href="#t-EndI">EndI</a>) : <a href="#t-MapFn">MapFn</a>|<a href="#t-MapBirleiFn">MapBirleiFn</a></code>

Possible callchains:

    map(birl, end_i)    (map_fn) : list
    map() (birl, end_i) (map_fn) : list

Map indices or list elements to values, producing an list that has as many
elements as indices provided.

<details><summary>parameters</summary>

**<code>birl</code>**: <code><a href="#t-OptionalBirl">OptionalBirl</a></code>

- If `number`, start index to iterate over
- If `range`, indices to iterate over
- If `list`, indices to iterate over
- If `undef`, then tells function to return a curried version of itself,
  that only takes parameters of types `Birl` and `EndI`.

**<code>end_i</code>**: <code><a href="#t-EndI">EndI</a></code>

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-MapFn">MapFn</a>|<a href="#t-MapBirleiFn">MapBirleiFn</a></code>

- If `birl` is omitted, then will return type `MapBirleiFn`.
- Else returns type `MapFn`.

Possible callchains:

    MapFn(map_fn) : list[any,...]
    MapBirleiFn(birl, end_i) (map_fn) : list[any,...]

</details>

### <i>📑base_algos types</i><a id='base_algos-ch-base_algos types'></a>

#### 🧩BoundIndexFn<a id='t-BoundIndexFn'></a>

<code>*callback* BoundIndexFn(spaceship\_fn: <a href="#t-SpaceshipFn">SpaceshipFn</a>) : number|undef</code>

<details><summary>parameters</summary>

**<code>spaceship_fn</code>**: <code><a href="#t-SpaceshipFn">SpaceshipFn</a></code>

Compares a derived comparison value against an internally stored value.

Definitions:

- probe: the argument passed to this callback by the algorithm.
- comparison value: the value derived from the probe that is actually
  compared to the stored value.

Probe convention:

- Without an [Algorithm Adaptor](#algorithm-adaptors), the probe is a number
  within the `birlei`.
- With an Algorithm Adaptor, the probe is the adaptor's output:
  - [`it_each`](#f-it_each): `slr_element`.
  - [`it_enum`](#f-it_enum): `[index, slr_element]`.
  - [`it_idxs`](#f-it_idxs): `index`.

The callback is responsible for mapping probe → comparison value.  The
mapping is defined by the callback's closure over the searched structure (slr
or any other abstract structure) and/or by how it interprets adaptor outputs.

</details>

<details><summary>returns</summary>

**Returns**: <code>number|undef</code>

Index of the selected bound, or `undef` if no such index exists.

> ℹ️ NOTE:
>
> `undef` is returned rather than `end_i+1` because the searched indices
> can be noncontiguous (range/list selectors).

</details>

#### 🧩FindLowerFn<a id='t-FindLowerFn'></a>

<code>*callback* FindLowerFn(spaceship\_fn: <a href="#t-SpaceshipFn">SpaceshipFn</a>) : number|undef</code>

Returns the first index `i` where `spaceship_fn(i) >= 0`.

#### 🧩FindUpperFn<a id='t-FindUpperFn'></a>

<code>*callback* FindUpperFn(spaceship\_fn: <a href="#t-SpaceshipFn">SpaceshipFn</a>) : number|undef</code>

Returns the first index `i` where `spaceship_fn(i) > 0`.

#### 🧩OptionalBirl<a id='t-OptionalBirl'></a>

<code>*type* OptionalBirl = number|<a href="#t-range">range</a>|list|undef</code>

- If `number`, start index to iterate over
- If `range`, indices to iterate over
- If `list`, indices to iterate over
- If `undef`, then tells function to return a curried version of itself,
  that only takes parameters of types `Birl` and `EndI`.

#### 🧩AlgoFn<a id='t-AlgoFn'></a>

<code>*callback* AlgoFn(birl: <a href="#t-Birl">Birl</a>, end\_i: <a href="#t-EndI">EndI</a>) : any</code>

Executes the algorithm.

<details><summary>parameters</summary>

**<code>birl</code>**: <code><a href="#t-Birl">Birl</a></code>

- If `number`, start index to iterate over
- If `range`, indices to iterate over
- If `list`, indices to iterate over

**<code>end_i</code>**: <code><a href="#t-EndI">EndI</a></code>

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

</details>

<details><summary>returns</summary>

**Returns**: <code>any</code>

Returned value is based on the result of the function doing the iterating.

</details>

#### 🧩FindLowerBirleiFn<a id='t-FindLowerBirleiFn'></a>

<code>*callback* FindLowerBirleiFn(birl: <a href="#t-Birl">Birl</a>, end\_i: <a href="#t-EndI">EndI</a>) : any</code>

#### 🧩FindUpperFn<a id='t-FindUpperFn'></a>

<code>*callback* FindUpperFn(spaceship\_fn: <a href="#t-SpaceshipFn">SpaceshipFn</a>) : number|undef</code>

Possible callchains:

    FindUpperFn(spaceship_fn) : (number|undef)

<details><summary>parameters</summary>

**<code>spaceship_fn</code>**: <code><a href="#t-SpaceshipFn">SpaceshipFn</a></code>

Compares a derived comparison value against an internally stored value.

Definitions:

- probe: the argument passed to this callback by the algorithm.
- comparison value: the value derived from the probe that is actually
  compared to the stored value.

Probe convention:

- Without an [Algorithm Adaptor](#algorithm-adaptors), the probe is a number
  within the `birlei`.
- With an Algorithm Adaptor, the probe is the adaptor's output:
  - [`it_each`](#f-it_each): `slr_element`.
  - [`it_enum`](#f-it_enum): `[index, slr_element]`.
  - [`it_idxs`](#f-it_idxs): `index`.

The callback is responsible for mapping probe → comparison value.  The
mapping is defined by the callback's closure over the searched structure (slr
or any other abstract structure) and/or by how it interprets adaptor outputs.

</details>

<details><summary>returns</summary>

**Returns**: <code>number|undef</code>

First index where `spaceship_fn(i) > 0`.  If none are found, returns
`undef`.

> ℹ️ NOTE:
>
> The reason for returning `undef` rather than `end_i+1`, is because `birl`
> could be a noncontiguous `range` or `list` of indices.

</details>

#### 🧩FindUpperBirleiFn<a id='t-FindUpperBirleiFn'></a>

<code>*callback* FindUpperBirleiFn(birl: <a href="#t-Birl">Birl</a>, end\_i: <a href="#t-EndI">EndI</a>) : any</code>

Possible callchains:

    FindUpperBirleiFn(birl, end_i) (spaceship_fn) : (number|undef)

#### 🧩FindFn<a id='t-FindFn'></a>

<code>*callback* FindFn(pred\_fn: <a href="#t-PredFn">PredFn</a>) : number|undef</code>

<details><summary>parameters</summary>

**<code>pred_fn</code>**: <code><a href="#t-PredFn">PredFn</a></code>

Compares a derived comparison value against an internally stored value.

Definitions:

- probe: the argument passed to this callback by the algorithm.
- comparison value: the value derived from the probe that is actually
  compared to the stored value.

Probe convention:

- Without an [Algorithm Adaptor](#algorithm-adaptors), the probe is a number
  within the `birlei`.
- With an Algorithm Adaptor, the probe is the adaptor's output:
  - [`it_each`](#f-it_each): `slr_element`.
  - [`it_enum`](#f-it_enum): `[index, slr_element]`.
  - [`it_idxs`](#f-it_idxs): `index`.

The callback is responsible for mapping probe → comparison value.  The
mapping is defined by the callback's closure over the searched structure (slr
or any other abstract structure) and/or by how it interprets adaptor outputs.

</details>

<details><summary>returns</summary>

**Returns**: <code>number|undef</code>

First index where `pred_fn(i)` is `true`.  If none are found, returns
`undef`.

> ℹ️ NOTE:
>
> The reason for returning `undef` rather than `end_i+1`, is because `birl`
> could be a noncontiguous `range` or `list` of indices.

</details>

#### 🧩FindBirleiFn<a id='t-FindBirleiFn'></a>

<code>*callback* FindBirleiFn(birl: <a href="#t-Birl">Birl</a>, end\_i: <a href="#t-EndI">EndI</a>) : any</code>

#### 🧩ReduceFn<a id='t-ReduceFn'></a>

<code>*callback* ReduceFn(reduction\_fn: <a href="#t-ReductionFn">ReductionFn</a>) : any</code>

<details><summary>parameters</summary>

**<code>reduction_fn</code>**: <code><a href="#t-ReductionFn">ReductionFn</a></code>

Mutates the accumulator given a derived comparison value.

Definitions:

- probe: the argument passed to this callback by the algorithm.
- comparison value: the value derived from the probe that is actually
  compared to the stored value.

Probe convention:

- Without an [Algorithm Adaptor](#algorithm-adaptors), the probe is a number
  within the `birlei`.
- With an Algorithm Adaptor, the probe is the adaptor's output:
  - [`it_each`](#f-it_each): `slr_element`.
  - [`it_enum`](#f-it_enum): `[index, slr_element]`.
  - [`it_idxs`](#f-it_idxs): `index`.

The callback is responsible for mapping probe → comparison value.  The
mapping is defined by the callback's closure over the searched structure (slr
or any other abstract structure) and/or by how it interprets adaptor outputs.

> ℹ️ NOTE:
>
> `acc` **is the second parameter** which is different from most languages.
> This is to keep it consistent with the rest of the `PPMRRAIR` functions
> and this library in general.  You have been warned.

</details>

<details><summary>returns</summary>

**Returns**: <code>any</code>

Final value of accumulator.

</details>

#### 🧩ReduceBirleiFn<a id='t-ReduceBirleiFn'></a>

<code>*callback* ReduceBirleiFn(birl: <a href="#t-Birl">Birl</a>, end\_i: <a href="#t-EndI">EndI</a>) : any</code>

#### 🧩ReduceAirFn<a id='t-ReduceAirFn'></a>

<code>*callback* ReduceAirFn(reduction\_fn: <a href="#t-ReductionAirFn">ReductionAirFn</a>) : list\[bool,any]</code>

<details><summary>parameters</summary>

**<code>reduction_fn</code>**: <code><a href="#t-ReductionAirFn">ReductionAirFn</a></code>

Mutates the accumulator given a derived comparison value.

Definitions:

- probe: the argument passed to this callback by the algorithm.
- comparison value: the value derived from the probe that is actually
  compared to the stored value.

Probe convention:

- Without an [Algorithm Adaptor](#algorithm-adaptors), the probe is a number
  within the `birlei`.
- With an Algorithm Adaptor, the probe is the adaptor's output:
  - [`it_each`](#f-it_each): `slr_element`.
  - [`it_enum`](#f-it_enum): `[index, slr_element]`.
  - [`it_idxs`](#f-it_idxs): `index`.

The callback is responsible for mapping probe → comparison value.  The
mapping is defined by the callback's closure over the searched structure (slr
or any other abstract structure) and/or by how it interprets adaptor outputs.

> ℹ️ NOTE:
>
> `acc` **is the second parameter** which is different from most languages.
> This is to keep it consistent with the rest of the `PPMRRAIR` functions
> and this library in general.  You have been warned.

</details>

<details><summary>returns</summary>

**Returns**: <code>list\[bool,any]</code>

Last continue value and the final value of accumulator.  If the original
 `birlei` was empty will contain `[true, init]`.

</details>

#### 🧩ReduceAirBirleiFn<a id='t-ReduceAirBirleiFn'></a>

<code>*callback* ReduceAirBirleiFn(birl: <a href="#t-Birl">Birl</a>, end\_i: <a href="#t-EndI">EndI</a>) : any</code>

#### 🧩FilterFn<a id='t-FilterFn'></a>

<code>*callback* FilterFn(reduction\_fn: <a href="#t-PredFn">PredFn</a>|<a href="#t-PredMapFn">PredMapFn</a>) : list\[any,...]</code>

<details><summary>parameters</summary>

**<code>reduction_fn</code>**: <code><a href="#t-PredFn">PredFn</a>|<a href="#t-PredMapFn">PredMapFn</a></code>

</details>

<details><summary>returns</summary>

**Returns**: <code>list\[any,...]</code>

A list of elements where the predicate returned true.

</details>

#### 🧩FilterBirleiFn<a id='t-FilterBirleiFn'></a>

<code>*callback* FilterBirleiFn(birl: <a href="#t-Birl">Birl</a>, end\_i: <a href="#t-EndI">EndI</a>) : any</code>

#### 🧩MapFn<a id='t-MapFn'></a>

<code>*callback* MapFn(map\_fn: <a href="#t-MapperFn">MapperFn</a>) : list\[any,...]</code>

<details><summary>parameters</summary>

**<code>map_fn</code>**: <code><a href="#t-MapperFn">MapperFn</a></code>

Maps a probed value to a list.

Definitions:

- probe: the argument passed to this callback by the algorithm.

Probe convention:

- Without an [Algorithm Adaptor](#algorithm-adaptors), the probe is a number
  within the `birlei`.
- With an Algorithm Adaptor, the probe is the adaptor's output:
  - [`it_each`](#f-it_each): `slr_element`.
  - [`it_enum`](#f-it_enum): `[index, slr_element]`.
  - [`it_idxs`](#f-it_idxs): `index`.

The callback is responsible for mapping probe value.  The mapping is defined
by the callback's closure over the searched structure (slr or any other
abstract structure) and/or by how it interprets adaptor outputs.

</details>

<details><summary>returns</summary>

**Returns**: <code>list\[any,...]</code>

A list of elements that were mapped.

</details>

#### 🧩MapBirleiFn<a id='t-MapBirleiFn'></a>

<code>*callback* MapBirleiFn(birl: <a href="#t-Birl">Birl</a>, end\_i: <a href="#t-EndI">EndI</a>) : any</code>


## <span style="font-size: 1.1em; color: yellow">📘indexable</span><a id='file-indexable'></a>

### <i>📑How to Import</i><a id='indexable-ch-How to Import'></a>

    use <indexable>

### <i>📑Purpose</i><a id='indexable-ch-Purpose'></a>

Treats all indexable objects similarly.  As a group, they are referred to as
`slr`s (`s`tring, `l`ist or `r`ange).  Any function that can take an indexable
reference and a `birlsei` can have the `birlsei` partially or completely
omitted (defaults to the start and end indices of the indexable).  To iterate
backwards, use a reverse `range`, `rev_i`, or a reverse `slice` (step < 0).

#### Example

    hello = "hello"
    echo(els(hello, range(4, -1, 0)));
    echo(els(hello, rev_i(hello)));
    echo(els(hello, slice(-1, -1, 0)));

Would output

    ECHO: "olleh"
    ECHO: "olleh"
    ECHO: "olleh"

> ℹ️ NOTE:
>
> `birlei` (`begin_i`, `range`, or `list`, and `end_i`) is not the same as
> `birlsei` (`begin_i`, `range`, `list`, or `slice`, and `end_i`).
>
> - `birlei` is a general index specification and is not tied to any `slr`.
>   It may contain any integers (including negatives).
>
> - `birlsei` is a `birlei` that is tied to a specific `slr`.  It consists of
>   positive `slr` indices `(0..slr_len(slr)-1)` or no indices.
>
> <details><summary><b>TL;DR</b></summary>
>
> **`birlei` (not tied to any `slr`) can represent any number:**
>
> - `(begin_i, end_i)` pair.
>
>   Produces an empty `birlei` if `end_i < begin_i`.  Otherwise iterates over
>   the contiguous indices `begin_i .. end_i` (inclusive).
>
> - `list`: any list of integers `[ e₁, e₂, ... eₙ ]`.
>
>   Produces an empty `birlei` if `n == 0`.  Otherwise iterates over all list
>   elements in order.
>
> - `range`: closed `range(begin_i, step, end_i)`.
>
>   Requires `step ≠ 0`.  Produces an empty `birlei` if:
>
>   - `step > 0` and `end_i < begin_i`, or
>   - `step < 0` and `begin_i < end_i`.
>
>   Otherwise iterates the closed range.
>
>
> **`birlsei` (tied to an `slr`) can only represent positive numbers:**
>
> - `(begin_i, end_i)` pair.
>
>   `begin_i` and `end_i` are indices, so they must satisfy:
>
>       0 ≤ begin_i < slr_len(slr) and 0 ≤ end_i < slr_len(slr)
>
>   Produces an empty `birlsei` if `end_i < begin_i`.  Otherwise iterates over
>   the contiguous indices `begin_i .. end_i` (inclusive), and requires:
>
>       0 ≤ begin_i ≤ end_i < slr_len(slr)
>
> - `list`: any list of indices `[ e₁, e₂, ... eₙ ]`.
>
>   Produces an empty `birlsei` if `n == 0`.  Otherwise requires for every
>   element:
>
>       0 ≤ eᵢ < slr_len(slr)
>
> - `range`: closed `range(begin_i, step, end_i)`.
>
>   Requires `step ≠ 0` and:
>
>       0 ≤ begin_i < slr_len(slr) and 0 ≤ end_i < slr_len(slr)
>
>   Produces an empty `birlsei` if:
>
>   - `step > 0` and `end_i < begin_i`, or
>   - `step < 0` and `begin_i < end_i`.
>
>   Otherwise iterates the closed range.
>
> - slice: closed `slice(begin_i, step, end_i)`.
>
>   Requires `step ≠ 0`.  A slice becomes iterable only when applied to an
>   `slr` (implicit call to `slice_to_range()`).
>
>   The resulting range may be empty.  When non-empty, its endpoints are
>   valid indices:
>
>       0 ≤ begin_i < slr_len(slr) and 0 ≤ end_i < slr_len(slr)
>
>   Iteration rules then follow the range rules above (based on `step` and
>   the ordering of `begin_i` and `end_i`).
>
> </details>

### <i>📑Slices</i><a id='indexable-ch-Slices'></a>

A `slice` is an object similar to a `range`, but it's not a realised
indexable object until it is paired with an `slr`.

#### ⚙️is\_slice<a id='f-is_slice'></a>

<code>*function* is_slice(o: any) : bool</code>

Check if object is a `slice` object.

<details><summary>parameters</summary>

**<code>o</code>**: <code>any</code>

Object to check.

</details>

<details><summary>returns</summary>

**Returns**: <code>bool</code>

`true` if object is a slice, `false` otherwise.

</details>

#### ⚙️slice<a id='f-slice'></a>

<code>*function* slice(begin\_i: number, step\_or\_end\_i: number, end\_i: number|undef) : <a href="#t-slice">slice</a></code>

Create a `slice` object.

<details><summary>parameters</summary>

**<code>begin_i</code>**: <code>number</code>

The first index of the slice.  If negative, then counts backward from end
of slr being referred to.

**<code>step_or_end_i</code>**: <code>number</code>

- If `end_i` not defined, then refers to the lat index of the sequence.
  - If negative, then counts backward from end of `slr` being referred to.
- If `end_i` is defined, then refers to the step count used to go between
  `begin_i` and `end_i`.

**<code>end_i</code>**: <code>number|undef</code>

If defined, then the last index of the slice.  If negative, then counts
backward from end of slr being referred to.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-slice">slice</a></code>

Returns a slice object.

</details>

#### ⚙️slice\_to\_range<a id='f-slice_to_range'></a>

<code>*function* slice_to_range(slice: <a href="#t-slice">slice</a>, slr: string|list|<a href="#t-range">range</a>, \_slr\_len: number) : <a href="#t-range">range</a>|list</code>

Possible callchains:

    slice_to_range(slice, slr)
    slice_to_range(slice, slr, _slr_len)

Converts a slice to a range when given a particular `slr`.

<details><summary>parameters</summary>

**<code>slice</code>**: <code><a href="#t-slice">slice</a></code>

The slice being converted.

**<code>slr</code>**: <code>string|list|<a href="#t-range">range</a></code>

The `slr` used as reference.

**<code>_slr_len</code>**: <code>number</code>

If passed, then use that cached value instead of calculating `len(slr)`.

> ℹ️ NOTE:
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-range">range</a>|list</code>

A range that corresponds to what the slice is to do given an `slr`.
If the slice is completely before or after the slr, returns [].

</details>

### <i>📑Algorithm Adaptors</i><a id='indexable-ch-Algorithm Adaptors'></a>

The `PPMRRAIR` functions usually are passed an integer as it's first
parameter, referring to the current index.  For convenience, there are
adaptor functions which allow referencing a `slr`'s element values.

- [`it_each`](#f-it_each): passes `slr_element`.
- [`it_enum`](#f-it_enum): passes `[index, slr_element]`.
- [`it_idxs`](#f-it_idxs): passes `index`.

Using these adaptors allows the use the length of the `slr` as reference if
the `birlsei` is partially or fully omitted.

#### ⚙️it\_each<a id='f-it_each'></a>

<code>*function* it_each(slr: string|list|<a href="#t-range">range</a>, algo\_fn: <a href="#t-AlgoFn">AlgoFn</a>, birls: <a href="#t-Birls">Birls</a>, end\_i: <a href="#t-EndI">EndI</a>) : <a href="#t-GetPpmrrairFn">GetPpmrrairFn</a></code>

Possible callchains:

    it_each(slr, algo_fn, birls, end_i) (ppmrrair_fn) : any

This convenience function will execute function `algo_fn` as if it were used
on a collection, remapping the first parameter being passed to `ppmrrair_fn`
so that it receives the <i>`element`</i> rather than the *index*.  Uses the
`slr` as a reference so that `birlsei` can be partially or fully omitted.
The `birlsei` is then normalised to a `birlei` and forwarded to `algo_fn`.

**Example:**

Normal usage:

    a = [1,2,3,4,5]
    even_indices = filter(fwd_i(a))(function(i) a[i] % 2);
    even_values  = filter(fwd_i(a))(function(i, v) v ? a[i] : a[i] % 2);

vs `it_each()` usage:

    a = [1,2,3,4,5]
    even_indices = it_each(a, filter())(function(e) e % 2);
    even_values  = it_each(a, filter())(function(e, v) v ? e : e % 2);

<details><summary>parameters</summary>

**<code>slr</code>**: <code>string|list|<a href="#t-range">range</a></code>

This is the list to take element data from.

**<code>algo_fn</code>**: <code><a href="#t-AlgoFn">AlgoFn</a></code>

This is the operation function that is called. E.g. find(), filter(), etc.

**<code>birls</code>**: <code><a href="#t-Birls">Birls</a></code>
 *(Default: `0`)*

- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, to convert to range providing indices to iterate over.

**<code>end_i</code>**: <code><a href="#t-EndI">EndI</a></code>
 *(Default: `undef`)*

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-GetPpmrrairFn">GetPpmrrairFn</a></code>

The ppmrrair function that the specified `algo_fn()` will call.

Possible callchains:

    GetPpmrrairFn(ppmrrair_fn) : any

</details>

#### ⚙️it\_idxs<a id='f-it_idxs'></a>

<code>*function* it_idxs(slr: string|list|<a href="#t-range">range</a>, algo\_fn: <a href="#t-AlgoFn">AlgoFn</a>, birls: <a href="#t-Birls">Birls</a>, end\_i: <a href="#t-EndI">EndI</a>) : <a href="#t-GetPpmrrairFn">GetPpmrrairFn</a></code>

Possible callchains:

    it_idxs(slr, algo_fn, birl, end_i) (ppmrrair_fn) : any

This convenience function will execute function `algo_fn` as if it were used
on a collection, `ppmrrair_fn` will still receive the *index*.  Uses the
`slr` as a reference so that `birlsei` can be partially or fully omitted.
The `birlsei` is then normalised to a `birlei` and forwarded to `algo_fn`.

**Example:**

Normal usage:

    a = [1,2,3,4,5]
    even_indices = filter(fwd_i(a))(function(i) a[i] % 2);
    even_values  = filter(fwd_i(a))(function(i, v) v ? a[i] : a[i] % 2);

vs `it_idxs()` usage:

    a = [1,2,3,4,5]
    even_indices = it_idxs(a, filter())(function(i) a[i] % 2);
    even_values  = it_idxs(a, filter())(function(i, v) v ? a[i] : a[i] % 2);

<details><summary>parameters</summary>

**<code>slr</code>**: <code>string|list|<a href="#t-range">range</a></code>

This is the list to take element data from.

**<code>algo_fn</code>**: <code><a href="#t-AlgoFn">AlgoFn</a></code>

This is the operation function that is called. E.g. find(), filter(), etc.

**<code>birls</code>**: <code><a href="#t-Birls">Birls</a></code>
 *(Default: `0`)*

- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, to convert to range providing indices to iterate over.

**<code>end_i</code>**: <code><a href="#t-EndI">EndI</a></code>
 *(Default: `undef`)*

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-GetPpmrrairFn">GetPpmrrairFn</a></code>

The ppmrrair function that the specified `algo_fn()` will call.

Possible callchains:

    GetPpmrrairFn(ppmrrair_fn) : any

</details>

#### ⚙️it\_enum<a id='f-it_enum'></a>

<code>*function* it_enum(slr: string|list|<a href="#t-range">range</a>, algo\_fn: <a href="#t-AlgoFn">AlgoFn</a>, birls: <a href="#t-Birls">Birls</a>, end\_i: <a href="#t-EndI">EndI</a>) : <a href="#t-GetPpmrrairFn">GetPpmrrairFn</a></code>

Possible callchains:

    it_enum(slr, algo_fn, birl, end_i) (ppmrrair_fn) : any

This convenience function will execute function `algo_fn` as if it were used
on a collection, remapping the first parameter being passed to `ppmrrair_fn`
so that it receives <i>`[index, element]`</i> rather than the *index*.  Uses
the `slr` as a reference so that `birlsei` can be partially or fully omitted.
The `birlsei` is then normalised to a `birlei` and forwarded to `algo_fn`.

**Example:**

Normal usage:

    a = [1,2,3,4,5]
    even_indices = filter(fwd_i(a))(function(i) a[i] % 2);
    even_values  = filter(fwd_i(a))(function(i, v) v ? a[i] : a[i] % 2);

vs `it_enum()` usage:

    a = [1,2,3,4,5]
    even_indices = it_enum(a, filter())(function(p) p[0] % 2);
    even_values  = it_enum(a, filter())(function(p, v) v ? p[1] : p[0] % 2);

<details><summary>parameters</summary>

**<code>slr</code>**: <code>string|list|<a href="#t-range">range</a></code>

This is the list to take element data from.

**<code>algo_fn</code>**: <code><a href="#t-AlgoFn">AlgoFn</a></code>

This is the operation function that is called. E.g. find(), filter(), etc.

**<code>birls</code>**: <code><a href="#t-Birls">Birls</a></code>
 *(Default: `0`)*

- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, to convert to range providing indices to iterate over.

**<code>end_i</code>**: <code><a href="#t-EndI">EndI</a></code>
 *(Default: `undef`)*

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-GetPpmrrairFn">GetPpmrrairFn</a></code>

The ppmrrair function that the specified `algo_fn()` will call.

Possible callchains:

    GetPpmrrairFn(ppmrrair_fn) : any

</details>

### <i>📑Treat All Indexables the Same</i><a id='indexable-ch-Treat All Indexables the Same'></a>

#### ⚙️slr\_len<a id='f-slr_len'></a>

<code>*function* slr_len(slr: string|list|<a href="#t-range">range</a>) : number</code>

Will return the number of elements the string, list or range contains.

<details><summary>parameters</summary>

**<code>slr</code>**: <code>string|list|<a href="#t-range">range</a></code>

The `slr` to count how many elements it would iterate over.

</details>

<details><summary>returns</summary>

**Returns**: <code>number</code>

The number of elements the `slr` contains.

</details>

#### ⚙️idx<a id='f-idx'></a>

<code>*function* idx(slr: string|list|<a href="#t-range">range</a>, i: number, \_slr\_len: number) : number</code>

If `i` is positive then returns `i`, otherwise add the slr's length to it so
as to count backwards from the end of the slr.

> ℹ️ NOTE:
>
> If not `-slr_len(slr) ≤ i < slr_len(slr)`, then using the returned value to
> dereference the `slr` is **UB**.

<details><summary>parameters</summary>

**<code>slr</code>**: <code>string|list|<a href="#t-range">range</a></code>

The `slr` to get the index for.

**<code>i</code>**: <code>number</code>

The index of the element.  If value is negative, then goes backward from
end of slr, where -1 represents the last indexable index.

**<code>_slr_len</code>**: <code>number</code>

If passed, then use that cached value instead of calculating `len(slr)`.

> ℹ️ NOTE:
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!

</details>

<details><summary>returns</summary>

**Returns**: <code>number</code>

The positive index.

</details>

#### ⚙️el<a id='f-el'></a>

<code>*function* el(slr: string|list|<a href="#t-range">range</a>, i: number) : any</code>

Dereference `slr` at index `i`, allowing for negative indices to go backward
from end.

> ℹ️ NOTE:
>
> It is **UB** to dereference at an index that is not in the `slr`.

<details><summary>parameters</summary>

**<code>slr</code>**: <code>string|list|<a href="#t-range">range</a></code>

The `slr` to get the element from.

**<code>i</code>**: <code>number</code>

The index of the element.  If value is negative, then goes backward from
end of the `slr`.

</details>

<details><summary>returns</summary>

**Returns**: <code>any</code>

The element at the index specified.

</details>

#### ⚙️el\_pos\_idx<a id='f-el_pos_idx'></a>

<code>*function* el_pos_idx(slr: string|list|<a href="#t-range">range</a>, i: number) : any</code>

Dereference `slr` at index `i`, allowing only positive indices.

> ℹ️ NOTE:
>
> It is **UB** to dereference at an index that is not in the `slr`.

<details><summary>parameters</summary>

**<code>slr</code>**: <code>string|list|<a href="#t-range">range</a></code>

The `slr` to get the element from.

**<code>i</code>**: <code>number</code>

The number iterations to have been done to get the return value.
Must be positive `(i >= 0)`.

</details>

<details><summary>returns</summary>

**Returns**: <code>any</code>

The element at the index specified.

</details>

#### ⚙️els<a id='f-els'></a>

<code>*function* els(slr: string|list|<a href="#t-range">range</a>, birls: <a href="#t-Birls">Birls</a>, end\_i: <a href="#t-EndI">EndI</a>) : string|list|<a href="#t-range">range</a></code>

Gets a substring, sub-range or sub-elements of a string, list or range.

> ℹ️ NOTE:
>
> To expand a range to a list, use `[ each range_to_expand ]`.

<details><summary>parameters</summary>

**<code>slr</code>**: <code>string|list|<a href="#t-range">range</a></code>

The `slr` to get the elements from.

**<code>birls</code>**: <code><a href="#t-Birls">Birls</a></code>
 *(Default: `0`)*

- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, to convert to range providing indices to iterate over.

**<code>end_i</code>**: <code><a href="#t-EndI">EndI</a></code>
 *(Default: `undef`)*

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

</details>

<details><summary>returns</summary>

**Returns**: <code>string|list|<a href="#t-range">range</a></code>

The elements at the indices specified or the substring.

</details>

#### ⚙️range\_els<a id='f-range_els'></a>

<code>*function* range_els(r: <a href="#t-range">range</a>, birls: <a href="#t-Birls">Birls</a>, end\_i: <a href="#t-EndI">EndI</a>) : <a href="#t-range">range</a>|list</code>

Optimised version of `els` for ranges.  Gets elements from a range as a range
or list.

- If the `birlsei` is a list, then the subset of the range `r` will be a
  list.
- Else a new range is computed

Example:

    range_els([1 : 10], [2 : 2 : 5])
    //  1  2  3  4  5  6  7  8  9 10  // element of     [ 1 : 1 : 10 ]
    //     2     3                    // indices        [ 2 : 2 :  5 ]
    //     2     3                    // final elements [ 2 : 2 :  4 ]

    range_els([1 : 2 : 15], [2 : 3 : 5])
    //  1  3  5  7  9  11 13 15       // elements of    [ 1 : 2 : 15 ]
    //        2         5             // indices        [ 2 : 3 :  5 ]
    //        5        11             // final elements [ 5 : 6 : 11 ]

    range_els([2 : 10], [1, 3, 6])
    //  2  3  4  5  6  7  8  9 10     // elements of    [ 2 : 1 : 10 ]
    //     1     4        6           // indices        [ 1, 3, 6 ]
    //     3     5        8           // final elements [ 3, 5, 8 ]

<details><summary>parameters</summary>

**<code>r</code>**: <code><a href="#t-range">range</a></code>

The r to get the elements from.

**<code>birls</code>**: <code><a href="#t-Birls">Birls</a></code>
 *(Default: `0`)*

- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, to convert to range providing indices to iterate over.

**<code>end_i</code>**: <code><a href="#t-EndI">EndI</a></code>
 *(Default: `undef`)*

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-range">range</a>|list</code>

The elements at the indices specified or the substring.

</details>

### <i>📑Getting/Traversing Indices</i><a id='indexable-ch-Getting/Traversing Indices'></a>

#### ⚙️idxs<a id='f-idxs'></a>

<code>*function* idxs(slr: string|list|<a href="#t-range">range</a>, birls: <a href="#t-Birls">Birls</a>, end\_i: <a href="#t-EndI">EndI</a>) : list\[number,...]</code>

Gets the indices from a `birlsei` as a list.

<details><summary>parameters</summary>

**<code>slr</code>**: <code>string|list|<a href="#t-range">range</a></code>

The `slr` to get the indices from.

**<code>birls</code>**: <code><a href="#t-Birls">Birls</a></code>
 *(Default: `0`)*

- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, to convert to range providing indices to iterate over.

**<code>end_i</code>**: <code><a href="#t-EndI">EndI</a></code>
 *(Default: `undef`)*

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

</details>

<details><summary>returns</summary>

**Returns**: <code>list\[number,...]</code>

The indices the `birlsei` would iterate over.

</details>

#### ⚙️fwd\_i<a id='f-fwd_i'></a>

<code>*function* fwd_i(slr: string|list|<a href="#t-range">range</a>, start\_offset: number, end\_offset: number, \_slr\_len: number) : <a href="#t-range">range</a></code>

Return a range representing indices to iterate over a list forwards.

> ℹ️ NOTE:
>
> Dev is responsible for ensuring that when using start_offset / end_offset,
> that they don't go out of bounds, or if they do, the underlying PPMRRAIR
> function will handle it gracefully.

<details><summary>parameters</summary>

**<code>slr</code>**: <code>string|list|<a href="#t-range">range</a></code>

slr to iterate over

**<code>start_offset</code>**: <code>number</code>
 *(Default: `0`)*

Offset to start the starting point from.

- Should prolly be positive to not give an undefined index.

**<code>end_offset</code>**: <code>number</code>
 *(Default: `0`)*

Offset to end the ending point to.

- Should prolly be negative to not give an undefined index.

**<code>_slr_len</code>**: <code>number</code>

If passed, then use that cached value instead of calculating `len(slr)`.

> ℹ️ NOTE:
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-range">range</a></code>

An ascending range that goes from `start_offset` to idx(slr, -1) +
end_offset.

</details>

#### ⚙️rev\_i<a id='f-rev_i'></a>

<code>*function* rev_i(slr: string|list|<a href="#t-range">range</a>, start\_offset: number, end\_offset: number, \_slr\_len: number) : <a href="#t-range">range</a></code>

Return a range representing indices to iterate over slr backwards.

> ℹ️ NOTE:
>
> Dev is responsible for ensuring that when using start_offset / end_offset,
> that they don't go out of bounds, or if they do, the underlying PPMRRAIR
> function will handle it gracefully.

<details><summary>parameters</summary>

**<code>slr</code>**: <code>string|list|<a href="#t-range">range</a></code>

slr to iterate over

**<code>start_offset</code>**: <code>number</code>
 *(Default: `0`)*

Offset to start the starting point from.

- Should prolly be negative to not give an undefined index.

**<code>end_offset</code>**: <code>number</code>
 *(Default: `0`)*

Offset to end the ending point to.

- Should prolly be positive to not give an undefined index.

**<code>_slr_len</code>**: <code>number</code>

If passed, then use that cached value instead of calculating `len(slr)`.

> ℹ️ NOTE:
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-range">range</a></code>

A descending range that goes from idx(slr, -1) + start_offset to
end_offset.

</details>

#### ⚙️next\_in<a id='f-next_in'></a>

<code>*function* next_in(slr: string|list|<a href="#t-range">range</a>, i: number, inc: number, wrap\_to\_0: bool, \_slr\_len: number) : number</code>

Gets the next index, wrapping if goes to or beyond slr_len(slr).

<details><summary>parameters</summary>

**<code>slr</code>**: <code>string|list|<a href="#t-range">range</a></code>

slr used for knowing when to wrap.

**<code>i</code>**: <code>number</code>

Index to start from.  Assumed: `0 <= i < slr_len(slr)`.

**<code>inc</code>**: <code>number</code>
 *(Default: `1`)*

Count to increase i by.

**<code>wrap_to_0</code>**: <code>bool</code>
 *(Default: `false`)*

If true, then when i+inc >= slr_len(slr), result is 0.  Otherwise, it wraps
to modulo slr_len(slr).

**<code>_slr_len</code>**: <code>number</code>

If passed, then use that cached value instead of calculating `len(slr)`.

> ℹ️ NOTE:
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!

</details>

<details><summary>returns</summary>

**Returns**: <code>number</code>

Next element index in list.

</details>

#### ⚙️prev\_in<a id='f-prev_in'></a>

<code>*function* prev_in(slr: string|list|<a href="#t-range">range</a>, i: number, dec: number, wrap\_to\_last: bool, \_slr\_len: number) : number</code>

Gets the prev index, wrapping if goes negative.

<details><summary>parameters</summary>

**<code>slr</code>**: <code>string|list|<a href="#t-range">range</a></code>

slr used for knowing when to wrap.

**<code>i</code>**: <code>number</code>

Index to start from.  Assumed: `0 <= i < slr_len(slr)`.

**<code>dec</code>**: <code>number</code>
 *(Default: `1`)*

Count to decrease i by.

**<code>wrap_to_last</code>**: <code>bool</code>
 *(Default: `false`)*

If true, then when i-dec < 0, result is idx(slr, -1).  Otherwise, it wraps
to modulo slr_len(slr).

**<code>_slr_len</code>**: <code>number</code>

If passed, then use that cached value instead of calculating `len(slr)`.

> ℹ️ NOTE:
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!

</details>

<details><summary>returns</summary>

**Returns**: <code>number</code>

Previous element index in list.

</details>

### <i>📑Functions to Manipulate Strings and Lists</i><a id='indexable-ch-Functions to Manipulate Strings and Lists'></a>

#### ⚙️push<a id='f-push'></a>

<code>*function* push(sl: string|list, es: string|list|<a href="#t-range">range</a>) : string|list</code>

Push elements onto the head (which is after the last element) of the `sl`.

<details><summary>parameters</summary>

**<code>sl</code>**: <code>string|list</code>

sl to add to.

**<code>es</code>**: <code>string|list|<a href="#t-range">range</a></code>

- if string, then
  - a string of characters to append to string or
  - list of characters to append to list.
- if list, then a list of elements to append to list.
- if range, then a range of elements to append to list.

</details>

<details><summary>returns</summary>

**Returns**: <code>string|list</code>

The updated string or list.

</details>

#### ⚙️pop<a id='f-pop'></a>

<code>*function* pop(sl: string|list, count: number, \_sl\_len: number) : string|list</code>

Pops 0 or more elements off the head (which are the last elements) of the
`sl`.

> ℹ️ NOTE:
>
> It is **UB** to pop off more elements than are available.

<details><summary>parameters</summary>

**<code>sl</code>**: <code>string|list</code>

sl to remove from.

**<code>count</code>**: <code>number</code>
 *(Default: `1`)*

Number of elements to pop off end of list.

**<code>_sl_len</code>**: <code>number</code>

If passed, then use that cached value instead of calculating `len(sl)`.

> ℹ️ NOTE:
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!

</details>

<details><summary>returns</summary>

**Returns**: <code>string|list</code>

The updated sl.

</details>

#### ⚙️unshift<a id='f-unshift'></a>

<code>*function* unshift(sl: string|list, es: string|list|<a href="#t-range">range</a>) : string|list</code>

Unshift elements onto the tail (which are before the beginning) of the `sl`.

<details><summary>parameters</summary>

**<code>sl</code>**: <code>string|list</code>

List to add to.

**<code>es</code>**: <code>string|list|<a href="#t-range">range</a></code>

- if string, then
  - a string of characters to prepend to string or
  - list of characters to prepend to list.
- if list, then a list of elements to prepend to list.
- if range, then a range of elements to prepend to list.

</details>

<details><summary>returns</summary>

**Returns**: <code>string|list</code>

The updated sl.

</details>

#### ⚙️shift<a id='f-shift'></a>

<code>*function* shift(sl: string|list, count: number, \_sl\_len: number) : string|list</code>

Shift elements off of the tail (which are at the beginning) of the `sl`.

> ℹ️ NOTE:
>
> It is **UB** to shift off more elements than are available.

<details><summary>parameters</summary>

**<code>sl</code>**: <code>string|list</code>

sl to remove from.

**<code>count</code>**: <code>number</code>
 *(Default: `1`)*

Number of elements to shift off beginning of list.

**<code>_sl_len</code>**: <code>number</code>

If passed, then use that cached value instead of calculating `len(sl)`.

> ℹ️ NOTE:
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!

</details>

<details><summary>returns</summary>

**Returns**: <code>string|list</code>

The updated sl.

</details>

#### ⚙️insert<a id='f-insert'></a>

<code>*function* insert(sl: string|list, i: number, es: string|list|<a href="#t-range">range</a>, es\_birls: <a href="#t-Birls">Birls</a>, es\_end\_i: <a href="#t-EndI">EndI</a>) : string|list</code>

Possible callchains:

    insert(sl, i, es, es_birls, es_end_i) : (string | list)

Insert specified elements in `es` into `sl` starting at index `i`.

<details><summary>parameters</summary>

**<code>sl</code>**: <code>string|list</code>

String or list to insert into.

**<code>i</code>**: <code>number</code>

Index to insert into.

- `0` to insert at beginning of list (like unshift)
- `len(sl)` to insert at end of list (like push)
- Negative values will insert starting from the end.
  - `-1` will insert between the second last element and the last element.
  - `-len(sl)` will insert at the beginning of list (like unshift)
  - **UB** if `i < -len(sl) or len(sl) < i`.

**<code>es</code>**: <code>string|list|<a href="#t-range">range</a></code>

Elements to insert.

**<code>es_birls</code>**: <code><a href="#t-Birls">Birls</a></code>
 *(Default: `0`)*

- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, to convert to range providing indices to iterate over.

**<code>es_end_i</code>**: <code><a href="#t-EndI">EndI</a></code>
 *(Default: `undef`)*

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

</details>

<details><summary>returns</summary>

**Returns**: <code>string|list</code>

The updated sl.

</details>

#### ⚙️remove<a id='f-remove'></a>

<code>*function* remove(sl: string|list, begin\_i: number, end\_i: number, \_sl\_len: number) : string|list</code>

Removes a contiguous set of elements from a sl.

> ℹ️ NOTE:
>
> `begin_i` and `end_i` accept negative values (`-1` is last element). Both
> are first converted to their non-negative equivalents by adding `len(sl)`.
> If the converted `end_i < begin_i`, nothing is removed. Otherwise the
> inclusive range `[begin_i..end_i]` is removed.
>
> Unless `end_i < begin_i`, it is **UB** if `begin_i` or `end_i` don't
> resolve to an index in the sl.

<details><summary>parameters</summary>

**<code>sl</code>**: <code>string|list</code>

List to remove elements from.

**<code>begin_i</code>**: <code>number</code>

The first index to remove. Can be negative to represent counting from end.

**<code>end_i</code>**: <code>number</code>

The last index to remove. Can be negative to represent counting from end.

**<code>_sl_len</code>**: <code>number</code>

If passed, then use that cached value instead of calculating `len(sl)`.

> ℹ️ NOTE:
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!

</details>

<details><summary>returns</summary>

**Returns**: <code>string|list</code>

The updated sl.

</details>

#### ⚙️remove\_adjacent\_dups<a id='f-remove_adjacent_dups'></a>

<code>*function* remove_adjacent_dups(sl: string|list, wrap: bool, \_sl\_len: number) : <a href="#t-RemoveAdjacentDupsFn">RemoveAdjacentDupsFn</a></code>

Possible callchains:

    remove_adjacent_dups(sl, wrap, _sl_len) (equal_fn) : (string | list)

Removes the same consecutive values, where same is defined by `equal_fn`.

<details><summary>parameters</summary>

**<code>sl</code>**: <code>string|list</code>

List to remove duplicate consecutive elements from.

**<code>wrap</code>**: <code>bool</code>
 *(Default: `false`)*

If true, then will consider the first and last element consecutive.

**<code>_sl_len</code>**: <code>number</code>

If passed, then use that cached value instead of calculating `len(sl)`.

> ℹ️ NOTE:
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-RemoveAdjacentDupsFn">RemoveAdjacentDupsFn</a></code>

Callback that removes the adjacent duplicates.

Possible callchains:

    RemoveAdjacentDupsFn(equal_fn) : (string|list)

</details>

#### ⚙️remove\_each<a id='f-remove_each'></a>

<code>*function* remove_each(sl: string|list, birls: <a href="#t-Birls">Birls</a>, end\_i: <a href="#t-EndI">EndI</a>) : string|list</code>

Removes each element indexed in the `birlsei`.

> ℹ️ NOTE:
>
> **UB** if resulting `birlei` is not strictly increasing.

<details><summary>parameters</summary>

**<code>sl</code>**: <code>string|list</code>

List to remove elements from.

**<code>birls</code>**: <code><a href="#t-Birls">Birls</a></code>
 *(Default: `0`)*

- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, to convert to range providing indices to iterate over.

**<code>end_i</code>**: <code><a href="#t-EndI">EndI</a></code>
 *(Default: `undef`)*

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

</details>

<details><summary>returns</summary>

**Returns**: <code>string|list</code>

The updated sl.

</details>

#### ⚙️replace<a id='f-replace'></a>

<code>*function* replace(a: string|list, a\_begin\_i: number, a\_end\_i: number, b: string|list|<a href="#t-range">range</a>, b\_birls: <a href="#t-Birls">Birls</a>, b\_end\_i: <a href="#t-EndI">EndI</a>) : string|list</code>

Replaces contiguous index set \[`a_begin_i`, `a_end_i`] from list `a` with
`birlsei` index set of list `b`.

<details><summary>parameters</summary>

**<code>a</code>**: <code>string|list</code>

List to have elements replaced.

**<code>a_begin_i</code>**: <code>number</code>

The starting index of a to replace.

**<code>a_end_i</code>**: <code>number</code>

The ending index of a to replace.

**<code>b</code>**: <code>string|list|<a href="#t-range">range</a></code>

List to draw elements from to replace the a element range with.

**<code>b_birls</code>**: <code><a href="#t-Birls">Birls</a></code>
 *(Default: `0`)*

- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, to convert to range providing indices to iterate over.

**<code>b_end_i</code>**: <code><a href="#t-EndI">EndI</a></code>
 *(Default: `undef`)*

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

</details>

<details><summary>returns</summary>

**Returns**: <code>string|list</code>

This is the updated list of elements.

</details>

#### ⚙️replace\_each<a id='f-replace_each'></a>

<code>*function* replace_each(a: string|list, a\_birls: <a href="#t-Birls">Birls</a>, a\_end\_i: <a href="#t-EndI">EndI</a>) : <a href="#t-ReplaceEachFn">ReplaceEachFn</a></code>

Possible callchains:

    replace_each(a, a_birl a_end_i) (b, b_birl b_end_i) : (string | list)

Replaces each element specified by `a_birls, a_end_i` with each element
specified by `b_birls, b_end_i`.

> ℹ️ NOTE:
>
> `a_birlsei` must be strictly increasing.

> ℹ️ NOTE:
>
> Both `birlsei`s MUST iterate over the same number of elements.

<details><summary>parameters</summary>

**<code>a</code>**: <code>string|list</code>

sl to have elements replaced.

**<code>a_birls</code>**: <code><a href="#t-Birls">Birls</a></code>
 *(Default: `0`)*

- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, to convert to range providing indices to iterate over.

**<code>a_end_i</code>**: <code><a href="#t-EndI">EndI</a></code>
 *(Default: `undef`)*

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-ReplaceEachFn">ReplaceEachFn</a></code>

Get the replacement set and execute replacement.

Possible callchains:

    ReplaceEachFn(b, b_birls, b_end_i) : (string|list)

</details>

#### ⚙️swap<a id='f-swap'></a>

<code>*function* swap(sl: string|list, begin\_i1: number, end\_i1: number, begin\_i2: number, end\_i2: number) : string|list</code>

Swap the elements between \[begin_i1 : end_i1] and \[begin_i2 : end_i2].
Range must be nondecreasing or there will not be any elements in that
range.  Negative values are normalised to positive by adding `len(sl)` to
them.

<details><summary>parameters</summary>

**<code>sl</code>**: <code>string|list</code>

List to swap elements in.

**<code>begin_i1</code>**: <code>number</code>

Starting index of group 1.

**<code>end_i1</code>**: <code>number</code>

Ending index of group 1.

**<code>begin_i2</code>**: <code>number</code>

Starting index of group 2.

**<code>end_i2</code>**: <code>number</code>

Ending index of group 2.

</details>

<details><summary>returns</summary>

**Returns**: <code>string|list</code>

List with ranges swapped.

</details>

#### ⚙️rotate\_left<a id='f-rotate_left'></a>

<code>*function* rotate_left(sl: string|list, i: number, \_sl\_len: number) : string|list</code>

Does a left rotation of the elements in the `sl` so that the elements are
reordered as if indices were `[i : len(sl)-1]` followed by `[0 : i - 1]`.

<details><summary>parameters</summary>

**<code>sl</code>**: <code>string|list</code>

This is the list to rotate.

**<code>i</code>**: <code>number</code>

- Number of elements to rotate left.
- If negative, rotates right.

**<code>_sl_len</code>**: <code>number</code>

If passed, then use that cached value instead of calculating `len(sl)`.

> ℹ️ NOTE:
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!

</details>

<details><summary>returns</summary>

**Returns**: <code>string|list</code>

Returns the rotated list.

</details>

#### ⚙️rotate\_right<a id='f-rotate_right'></a>

<code>*function* rotate_right(sl: string|list, i: number, \_sl\_len: number) : string|list</code>

Does a right rotation of the elements in the `sl` so that the elements are
reordered as if indices were `[len(sl)-i : len(sl)-1]` followed by
`[0 : len(sl)-i - 1]`.

<details><summary>parameters</summary>

**<code>sl</code>**: <code>string|list</code>

This is the list to rotate.

**<code>i</code>**: <code>number</code>

- Number of elements to rotate right.
- If negative, rotates left.

**<code>_sl_len</code>**: <code>number</code>

If passed, then use that cached value instead of calculating `len(sl)`.

> ℹ️ NOTE:
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!

</details>

<details><summary>returns</summary>

**Returns**: <code>string|list</code>

Returns the rotated list.

</details>

#### ⚙️head<a id='f-head'></a>

<code>*function* head(sl: string|list, \_sl\_len: number) : any</code>

Gets the element at the head (which is the last element) of the `sl`.

<details><summary>parameters</summary>

**<code>sl</code>**: <code>string|list</code>

List to get from.

**<code>_sl_len</code>**: <code>number</code>

If passed, then use that cached value instead of calculating `len(sl)`.

> ℹ️ NOTE:
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!

</details>

<details><summary>returns</summary>

**Returns**: <code>any</code>

Object at the head of the list.

</details>

#### ⚙️head\_multi<a id='f-head_multi'></a>

<code>*function* head_multi(sl: string|list, i: number, \_sl\_len: number) : string|list</code>

Gets the elements at the head (which are the last elements) of the `sl`.

<details><summary>parameters</summary>

**<code>sl</code>**: <code>string|list</code>

List to get from.

**<code>i</code>**: <code>number</code>

Number of elements to retrieve from the head.

**<code>_sl_len</code>**: <code>number</code>

If passed, then use that cached value instead of calculating `len(sl)`.

> ℹ️ NOTE:
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!

</details>

<details><summary>returns</summary>

**Returns**: <code>string|list</code>

Objects at the head of the list.

</details>

#### ⚙️tail<a id='f-tail'></a>

<code>*function* tail(sl: string|list) : any</code>

Gets the element at the tail (which is the first element) of the `sl`.

<details><summary>parameters</summary>

**<code>sl</code>**: <code>string|list</code>

List to get from.

</details>

<details><summary>returns</summary>

**Returns**: <code>any</code>

Object at the tail of the list.

</details>

#### ⚙️tail\_multi<a id='f-tail_multi'></a>

<code>*function* tail_multi(sl: string|list, i: number) : string|list</code>

Gets the elements at the tail (which are the first elements) of the `sl`.

<details><summary>parameters</summary>

**<code>sl</code>**: <code>string|list</code>

List to get from.

**<code>i</code>**: <code>number</code>

Number of elements to retrieve from the tail.

</details>

<details><summary>returns</summary>

**Returns**: <code>string|list</code>

Objects at the tail of the list.

</details>

#### ⚙️osearch<a id='f-osearch'></a>

<code>*function* osearch(haystack: string|list, birls: <a href="#t-Birls">Birls</a>, end\_i: <a href="#t-EndI">EndI</a>) : <a href="#t-SearchNeedleFn">SearchNeedleFn</a></code>

Possible callchains:

    osearch(haystack, birls, end_i) (needle, n_birls, n_end_i) (equal_fn) : (undef | number)

Searches for an ordered set of elements specified in needle that occurs as an
ordered set of elements in haystack.  Similar to built-in search() function,
but allows specifying an index range to search and exposes the equal()
operator to allow for non-exact matches.

<details><summary>parameters</summary>

**<code>haystack</code>**: <code>string|list</code>

String or list of consecutive items to search through.

**<code>birls</code>**: <code><a href="#t-Birls">Birls</a></code>
 *(Default: `0`)*

- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, to convert to range providing indices to iterate over.

**<code>end_i</code>**: <code><a href="#t-EndI">EndI</a></code>
 *(Default: `undef`)*

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-SearchNeedleFn">SearchNeedleFn</a></code>

Curry function to get needle data.

Possible callchains:

    SearchNeedleFn(needle, n_birls, n_end_i) (equal_fn) : (number|undef)

</details>

#### ⚙️csearch<a id='f-csearch'></a>

<code>*function* csearch(haystack: string|list, birls: <a href="#t-Birls">Birls</a>, end\_i: <a href="#t-EndI">EndI</a>) : <a href="#t-SearchNeedleFn">SearchNeedleFn</a></code>

Possible callchains:

    csearch(haystack, birls, end_i) (needle, n_birls, n_end_i) (equal_fn) : (undef | number)

Searches haystack for contiguous set of elements that starts from an ordered
set of indices that match an ordered set of elements specified in needle.
Similar to built-in search() function, but allows specifying an index range
to search and exposes the equal() operator to allow for non-exact matches.

<details><summary>parameters</summary>

**<code>haystack</code>**: <code>string|list</code>

String or list of consecutive items to search through.

**<code>birls</code>**: <code><a href="#t-Birls">Birls</a></code>
 *(Default: `0`)*

- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, to convert to range providing indices to iterate over.

**<code>end_i</code>**: <code><a href="#t-EndI">EndI</a></code>
 *(Default: `undef`)*

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-SearchNeedleFn">SearchNeedleFn</a></code>

Curry function to get needle data.

Possible callchains:

    SearchNeedleFn(needle, n_birls, n_end_i) (equal_fn) : (number|undef)

</details>

### <i>📑indexable types</i><a id='indexable-ch-indexable types'></a>

#### 🧩slice<a id='t-slice'></a>

<code>*type* slice = list</code>

Slice is an unresolved range that works with an indexable.  It itself is
**not indexable**.  Use [`slice_to_range`](#f-slice_to_range) to convert to an
indexable range.

> ℹ️ NOTE:
>
> Due to ranges using inclusive values, and slices adhering to that same
> paradigm, a slice cannot refer to an empty range unless `step` precludes
> `begin_i` from getting to `end_i` or the referred to `slr` has a length of
> `0`.

#### 🧩Birls<a id='t-Birls'></a>

<code>*type* Birls = number|<a href="#t-range">range</a>|list|<a href="#t-slice">slice</a></code>

- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, to convert to range providing indices to iterate over.

#### 🧩slr\_cache<a id='t-slr_cache'></a>

<code>*type* slr_cache = list</code>

Cache returned by `_slr_cache(slr, birls, end_i)`.  Usage example:

    len_of_slr = cache_obj[_SLR_LEN]

<details><summary>slots</summary>
<code><b>_SLR_LEN</b></code>: <code>number</code>

Length of `slr`.

<code><b>_SLR_TE</b></code>: <code><a href="#t-type_enum">type_enum</a></code>

Type enum of `slr`.

<code><b>_SLR_ELD</b></code>: <code>function(i: number): any</code>

`i` is the index to dereference the `slr` (Direct addressing).

Returns roughly `slr[i]`, where `0 <= i < slr_len`.

- If backward indexing is wanted, manually calculating it by the formula
  `slr_len - i` is required.  This maximises throughput for most common
  case.

<code><b>_SLR_BLEN</b></code>: <code>number</code>

Length of normalised `birlsei`.

<code><b>_SLR_ELI</b></code>: <code>function(j: number): any</code>

`j` is the index to dereference the normalised `birlsei` to index the `slr`
(Indirect addressing).  Returns roughly `slr[birlei[j]]`, where
`0 <= j < birlei_len`.

- If backward indexing is wanted, manually calculating it by the formula
  `birlei_len - j` is required.  This maximises throughput for most common
  case.

<code><b>_SLR_IDX</b></code>: <code>function(k: number): number</code>

`k` is the index to dereference the normalised `birlsei`.  Returns roughly
`birlei[k]`, where `0 <= k < birlei_len`.

- If backward indexing is wanted, manually calculating it by the formula
  `birlei_len - k` is required.  This maximises throughput for most common
  case.

<code><b>_SLR_STR</b></code>: <code>function(): string</code>

String representation of normalised `birlsei`.

<code><b>_SLR_BIRL</b></code>: <code>number|<a href="#t-range">range</a>|list</code>

Normalised birls.

<code><b>_SLR_END_I</b></code>: <code>number|undef</code>

Normalised end_i.

</details>

#### 🧩GetPpmrrairFn<a id='t-GetPpmrrairFn'></a>

<code>*callback* GetPpmrrairFn(ppmrrair\_fn: <a href="#t-PpmrrairFn">PpmrrairFn</a>) : any</code>

Gets the PPMRRAIR function to apply the [AlgoFn](#t-AlgoFn) to.

<details><summary>parameters</summary>

**<code>ppmrrair_fn</code>**: <code><a href="#t-PpmrrairFn">PpmrrairFn</a></code>

The PPMRRAIR function to iterate with.

</details>

<details><summary>returns</summary>

**Returns**: <code>any</code>

The result of the adaptor call.

</details>

#### 🧩EqualFn<a id='t-EqualFn'></a>

<code>*callback* EqualFn(lhs: any, rhs: any) : bool</code>

Represents the equation `lhs == rhs`, but allows user to define what `==`
means.  For a less strict equality check, try
[`function_equal`](#f-function_equal).

<details><summary>parameters</summary>

**<code>lhs</code>**: <code>any</code>

The left hand side of the equality.

**<code>rhs</code>**: <code>any</code>

The right hand side of the equality.

</details>

<details><summary>returns</summary>

**Returns**: <code>bool</code>

The result of the equality test.

</details>

#### 🧩GetEqualFn<a id='t-GetEqualFn'></a>

<code>*callback* GetEqualFn(equal\_fn: <a href="#t-EqualFn">EqualFn</a>) : any</code>

Gets the equality function and perform a function with it.

<details><summary>parameters</summary>

**<code>equal_fn</code>**: <code><a href="#t-EqualFn">EqualFn</a></code>

The equality function.

</details>

<details><summary>returns</summary>

**Returns**: <code>any</code>

The resulting value when done.

</details>

#### 🧩RemoveAdjacentDupsFn<a id='t-RemoveAdjacentDupsFn'></a>

<code>*callback* RemoveAdjacentDupsFn(equal\_fn: <a href="#t-EqualFn">EqualFn</a>) : any</code>

Callback that removes the adjacent duplicates.

#### 🧩ReplaceEachFn<a id='t-ReplaceEachFn'></a>

<code>*callback* ReplaceEachFn(b: string|list|<a href="#t-range">range</a>, b\_birls: <a href="#t-Birls">Birls</a>, b\_end\_i: <a href="#t-EndI">EndI</a>) : string|list</code>

<details><summary>parameters</summary>

**<code>b</code>**: <code>string|list|<a href="#t-range">range</a></code>

sl to have elements replaced.

**<code>b_birls</code>**: <code><a href="#t-Birls">Birls</a></code>

- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, to convert to range providing indices to iterate over.

**<code>b_end_i</code>**: <code><a href="#t-EndI">EndI</a></code>

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

</details>

<details><summary>returns</summary>

**Returns**: <code>string|list</code>

This is the updated list of elements.

</details>

#### 🧩SearchFn<a id='t-SearchFn'></a>

<code>*callback* SearchFn(equal\_fn: <a href="#t-EqualFn">EqualFn</a>) : any</code>

Perform search.

#### 🧩SearchNeedleFn<a id='t-SearchNeedleFn'></a>

<code>*callback* SearchNeedleFn(needle: string|list, n\_birls: <a href="#t-Birls">Birls</a>, n\_end\_i: <a href="#t-EndI">EndI</a>) : <a href="#t-SearchFn">SearchFn</a></code>

Gets the needle data.

<details><summary>parameters</summary>

**<code>needle</code>**: <code>string|list</code>

String or list of items being searched for.

**<code>n_birls</code>**: <code><a href="#t-Birls">Birls</a></code>

- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, to convert to range providing indices to iterate over.

**<code>n_end_i</code>**: <code><a href="#t-EndI">EndI</a></code>

- If related `birl` is a number, then this is the end index to iterate
  over.
  - If this value is less than the related birl's value, then nothing is
    iterated over.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-SearchFn">SearchFn</a></code>

Callback to get the equality function.

Possible callchains:

    SearchFn(equal_fn) : (number|undef)

</details>


## <span style="font-size: 1.1em; color: yellow">📘function</span><a id='file-function'></a>

### <i>📑Purpose</i><a id='function-ch-Purpose'></a>

Allows doing things with functions using introspection.

### <i>📑Function Introspection</i><a id='function-ch-Function Introspection'></a>

#### ⚙️param\_count<a id='f-param_count'></a>

<code>*function* param_count(fn: function) : number</code>

Counts the number of parameters that can be passed to the function fn.

<details><summary>parameters</summary>

**<code>fn</code>**: <code>function</code>

</details>

<details><summary>returns</summary>

**Returns**: <code>number</code>

The number of parameters that the function can take.

</details>

#### ⚙️param\_count\_direct\_recursion\_demo<a id='f-param_count_direct_recursion_demo'></a>

<code>*function* param_count_direct_recursion_demo(fn: function) : number</code>

Counts the number of parameters that can be passed to the function fn.

THIS IS A DEMO of how this would look if using direct recursion.

@see _pc_loop for processing function.

TODO: Should benchmark this against main param_count() version which uses
      reduce_air() to see how much overhead reduce_air() adds.

<details><summary>parameters</summary>

**<code>fn</code>**: <code>function</code>

</details>

<details><summary>returns</summary>

**Returns**: <code>number</code>

The number of parameters that the function can take.

</details>

#### ⚙️apply\_to\_fn<a id='f-apply_to_fn'></a>

<code>*function* apply_to_fn(fn: function, p: list) : any</code>

Applies each element in an list to a function's parameter list.

TODO: apply_to_fn has allocation overhead, where as apply_to_fn2 has lookup
      overhead.  NEED TO BENCHMARK to determine which to keep.

<details><summary>parameters</summary>

**<code>fn</code>**: <code>function</code>

A lambda that takes between 0 and 15 parameters.

**<code>p</code>**: <code>list</code>

A list of elements to apply to the function fn.  Must have the same or
fewer elements than `fn` can take and must be less than 15 elements.

</details>

<details><summary>returns</summary>

**Returns**: <code>any</code>

The return value of fn().

</details>

#### ⚙️apply\_to\_fn2<a id='f-apply_to_fn2'></a>

<code>*function* apply_to_fn2(fn: function, p: list) : any</code>

Applies each element in an list to a function's parameter list.

TODO: apply_to_fn has allocation overhead, where as apply_to_fn2 has lookup
      overhead.  NEED TO BENCHMARK to determine which to keep.

<details><summary>parameters</summary>

**<code>fn</code>**: <code>function</code>

A lambda that takes between 0 and 15 parameters.

**<code>p</code>**: <code>list</code>

A list of elements to apply to the function fn.  Must have the same or
fewer elements than `fn` can take and must be less than 15 elements.

</details>

<details><summary>returns</summary>

**Returns**: <code>any</code>

The return value of fn().

</details>


## <span style="font-size: 1.1em; color: yellow">📘test</span><a id='file-test'></a>

### <i>📑Purpose</i><a id='test-ch-Purpose'></a>

Used to generate code for using TDD methodology.  Tries to report useful
error messages with an optional user configurable message.

### <i>📑Test Your Code!</i><a id='test-ch-Test Your Code!'></a>

#### 🧪test\_eq<a id='m-test_eq'></a>

<code>*module* test_eq(expected: any, got: any, msg: string)</code>

Tests if `expected` is equal to `got`.

<details><summary>parameters</summary>

**<code>expected</code>**: <code>any</code>

Expected value.

**<code>got</code>**: <code>any</code>

The value actually received.

**<code>msg</code>**: <code>string</code>
 *(Default: `""`)*

A user message to append to failure message.

</details>

#### 🧪test\_approx\_eq<a id='m-test_approx_eq'></a>

<code>*module* test_approx_eq(expected: any, got: any, epsilon: number, msg: string)</code>

Tests if `expected` is approx equal to `got` within `epsilon`.

<details><summary>parameters</summary>

**<code>expected</code>**: <code>any</code>

Expected value.

**<code>got</code>**: <code>any</code>

The value actually received.

**<code>epsilon</code>**: <code>number</code>

How much tolerance to say that two numbers are equal.

**<code>msg</code>**: <code>string</code>
 *(Default: `""`)*

A user message to append to failure message.

</details>

#### 🧪test\_ne<a id='m-test_ne'></a>

<code>*module* test_ne()</code>

Tests if `not_expected` is not equal to `got`.

#### 🧪test\_lt<a id='m-test_lt'></a>

<code>*module* test_lt()</code>

Tests if `lhs < rhs`.

#### 🧪test\_le<a id='m-test_le'></a>

<code>*module* test_le()</code>

Tests if `lhs ≤ rhs`.

#### 🧪test\_gt<a id='m-test_gt'></a>

<code>*module* test_gt()</code>

Tests if `lhs > rhs`.

#### 🧪test\_ge<a id='m-test_ge'></a>

<code>*module* test_ge()</code>

Tests if `lhs ≥ rhs`.

#### 🧪test\_truthy<a id='m-test_truthy'></a>

<code>*module* test_truthy()</code>

Tests if `val` is a truthy value

#### 🧪test\_falsy<a id='m-test_falsy'></a>

<code>*module* test_falsy()</code>

Tests if `val` is a falsy value


## <span style="font-size: 1.1em; color: yellow">📘transform</span><a id='file-transform'></a>

### <i>📑Purpose</i><a id='transform-ch-Purpose'></a>

This library is for matrix math for a verity of things.

### <i>📑Generate Matrices for Vector Transforms</i><a id='transform-ch-Generate Matrices for Vector Transforms'></a>

#### ⚙️transpose<a id='f-transpose'></a>

<code>*function* transpose(A: <a href="#t-Matrix">Matrix</a>) : <a href="#t-Matrix">Matrix</a></code>

Transpose of a matrix.

- Matrix (list of equal-length rows) → transposed matrix

> ℹ️ NOTE:
>
> There is no need to transpose a vector to a column vector.  When OpenSCAD
> sees M \* V or V \* M, the vector V is automatically treated as a column or
> row vector as appropriate.

<details><summary>parameters</summary>

**<code>A</code>**: <code><a href="#t-Matrix">Matrix</a></code>

The matrix to transpose.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-Matrix">Matrix</a></code>

The transpose of matrix A.

</details>

#### ⚙️homogenise<a id='f-homogenise'></a>

<code>*function* homogenise(pts: list\[<a href="#t-Point">Point</a>,...], n: number) : list\[<a href="#t-Point">Point</a>,...]</code>

Convert points to homogeneous coordinates.

Each point is padded with zeros up to dimension n-1, then a trailing 1 is
appended.

<details><summary>parameters</summary>

**<code>pts</code>**: <code>list\[<a href="#t-Point">Point</a>,...]</code>

List of points.  Each point must have dimension < n.

**<code>n</code>**: <code>number</code>
 *(Default: `4`)*

Target homogeneous dimension.  Must be greater than the dimension of every
point in pts.

</details>

<details><summary>returns</summary>

**Returns**: <code>list\[<a href="#t-Point">Point</a>,...]</code>

List of n-dimensional points with homogeneous coordinate 1 at index n-1.

</details>

#### ⚙️dehomogenise<a id='f-dehomogenise'></a>

<code>*function* dehomogenise(pts: list\[<a href="#t-Point">Point</a>,...], n: number) : list\[<a href="#t-Point">Point</a>,...]</code>

Dehomogenises a list of homogeneous points to Euclidean points.

Each input point must have at least n+1 coordinates.  The homogeneous divisor w is the
last coordinate of the point (index len(pt)-1).  This function returns the first n
coordinates divided by w, and discards all remaining coordinates.

This is the companion to homogenise() when homogenise() places w at the last coordinate.  A
typical pipeline is: homogenise points to match an M×M transform, multiply, then project
back to N dimensions with dehomogenise(..., N).

Preconditions (enforced by asserts):

- Every point pt satisfies len(pt) > n.  (There must be a last coordinate to use as w.)
- w != 0.  (Homogeneous projection is undefined for w == 0.)

<details><summary>parameters</summary>

**<code>pts</code>**: <code>list\[<a href="#t-Point">Point</a>,...]</code>

List of homogeneous points.

**<code>n</code>**: <code>number</code>
 *(Default: `3`)*

Number of Euclidean coordinates to return per point.

</details>

<details><summary>returns</summary>

**Returns**: <code>list\[<a href="#t-Point">Point</a>,...]</code>

List of n-dimensional Euclidean points.

</details>

#### ⚙️homogenise\_transform<a id='f-homogenise_transform'></a>

<code>*function* homogenise_transform(A: <a href="#t-Matrix">Matrix</a>, n: number) : <a href="#t-Matrix">Matrix</a></code>

Embed a non-homogeneous square transform into a larger homogeneous matrix.

Returns a **homogeneous column-vector** matrix H (n×n).  A is placed in the
top-left block.

Use:

- If H is used as a transform matrix, apply it like any other homogeneous
  column-vector matrix:
  - Single point p: treat p as homogeneous when multiplying.
  - Point list Ps: use transform(Ps, transpose(H)).

<details><summary>parameters</summary>

**<code>A</code>**: <code><a href="#t-Matrix">Matrix</a></code>

Square M×M transform matrix.

**<code>n</code>**: <code>number</code>
 *(Default: `4`)*

Target homogeneous dimension.  Must satisfy M < n.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-Matrix">Matrix</a></code>

Homogeneous matrix H (n×n) with A in the top-left block and identity
elsewhere.

</details>

#### ⚙️rot\_x<a id='f-rot_x'></a>

<code>*function* rot_x(a: number) : <a href="#t-Matrix">Matrix</a></code>

Rotation matrix about the X axis.

Returns a **non-homogeneous column-vector** rotation matrix M (3×3).

Use:

- Single Point    p:  p' = M * p
- List of Points Ps:  Ps' = Ps * transpose(M)

<details><summary>parameters</summary>

**<code>a</code>**: <code>number</code>

Rotation angle in degrees.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-Matrix">Matrix</a></code>

Column-vector rotation matrix M.

</details>

#### ⚙️rot\_y<a id='f-rot_y'></a>

<code>*function* rot_y(a: number) : <a href="#t-Matrix">Matrix</a></code>

Rotation matrix about the Y axis.

Returns a **non-homogeneous column-vector** rotation matrix M (3×3).

Use:

- Single Point    p:  p' = M * p
- List of Points Ps:  Ps' = Ps * transpose(M)

<details><summary>parameters</summary>

**<code>a</code>**: <code>number</code>

Rotation angle in degrees.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-Matrix">Matrix</a></code>

Column-vector rotation matrix M.

</details>

#### ⚙️rot\_z<a id='f-rot_z'></a>

<code>*function* rot_z(a: number) : <a href="#t-Matrix">Matrix</a></code>

Rotation matrix about the Z axis.

Returns a **non-homogeneous column-vector** rotation matrix M (3×3).

Use:

- Single Point    p:  p' = M * p
- List of Points Ps:  Ps' = Ps * transpose(M)

<details><summary>parameters</summary>

**<code>a</code>**: <code>number</code>

Rotation angle in degrees.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-Matrix">Matrix</a></code>

Column-vector rotation matrix M.

</details>

#### ⚙️is\_point<a id='f-is_point'></a>

<code>*function* is_point(o: any, dim: number) : bool</code>

Checks if `o` has the shape of a vector of `dim` `number`s.

<details><summary>parameters</summary>

**<code>o</code>**: <code>any</code>

Object to test.

**<code>dim</code>**: <code>number</code>
 *(Default: `3`)*

Number of dimensions the vector should represent.

</details>

<details><summary>returns</summary>

**Returns**: <code>bool</code>

True if has the shape of a point of `dim` `number`s.

</details>

#### ⚙️is\_vector<a id='f-is_vector'></a>

<code>*function* is_vector(o: any, dim: number) : bool</code>

Checks if `o` has the shape of a free vector of `dim` `number`s.

<details><summary>parameters</summary>

**<code>o</code>**: <code>any</code>

Object to test.

**<code>dim</code>**: <code>number</code>
 *(Default: `3`)*

Number of dimensions the vector should represent.

</details>

<details><summary>returns</summary>

**Returns**: <code>bool</code>

True if has the shape of a free vector of `dim` `number`s.

</details>

#### ⚙️is\_bound\_vector<a id='f-is_bound_vector'></a>

<code>*function* is_bound_vector(o: any, dim: number) : bool</code>

Checks if `o` has the shape of 2 bound points of `dim` `number`s.  This
represents the starting and ending points of a bound vector.

<details><summary>parameters</summary>

**<code>o</code>**: <code>any</code>

Object to test.

**<code>dim</code>**: <code>number</code>
 *(Default: `3`)*

Number of dimensions the vector should represent.

</details>

<details><summary>returns</summary>

**Returns**: <code>bool</code>

True if has the shape of 2 bound points of `dim` `number`s.

</details>

#### ⚙️rot\_axis<a id='f-rot_axis'></a>

<code>*function* rot_axis(angle: number, axis: <a href="#t-Vector3D">Vector3D</a>) : <a href="#t-Matrix">Matrix</a></code>

Rotation matrix about an arbitrary axis.

Returns a **non-homogeneous column-vector** rotation matrix M (3×3) that
rotates around the specified vector 'axis' rooted in the origin of the
coordinate system.

Use:

- Single Point    p:  p' = M * p
- List of Points Ps:  Ps' = Ps * transpose(M)

<details><summary>parameters</summary>

**<code>angle</code>**: <code>number</code>

Rotation angle in degrees.

**<code>axis</code>**: <code><a href="#t-Vector3D">Vector3D</a></code>

Rotation axis vector (must be non-zero).

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-Matrix">Matrix</a></code>

Column-vector rotation matrix M.

</details>

#### ⚙️rotate<a id='f-rotate'></a>

<code>*function* rotate(a: number|list\[number,number,number], v: <a href="#t-Vector3D">Vector3D</a>|<a href="#t-BVector3D">BVector3D</a>) : <a href="#t-Matrix">Matrix</a></code>

Rotation matrix that parallels OpenSCAD's rotate() module, with the
additional feature that it can also take a `BVector3D` for `v`, meaning that
it can rotate about the point stipulated by the point in slot 0 of the
BVector.

If `v` is a `Vector3D`, returns a **non-homogeneous column-vector** rotation
matrix M (3×3) that rotates around the specified vector 'axis' rooted in the
origin of the coordinate system.

If `v` is a `BVector3D`, returns a **homogeneous column-vector** rotation
matrix M (4x4) that rotates around the specified vector 'axis' (`v[1]-v[0]`)
around point `v[0]`.

To not have to worry about the matrix size, it's recommended that you use the
[`transform()`](#f-transform) API.

Use if `p` or elements of `Ps` are homogeneous/non-homogeneous as `M` is:

- Single Point    p:  p' = M * p
- List of Points Ps:  Ps' = Ps * transpose(M)
or if don't want to worry about having to use
[`homogenise()`](#f-homogenise)/[`dehomogenise()`](#f-dehomogenise), use
[`transform()`](#f-transform) API:
- Single Point    p:  `p' = transform([p], transpose(M))`
- List of Points Ps:  `Ps' = transform(Ps, transpose(M))`

<details><summary>parameters</summary>

**<code>a</code>**: <code>number|list\[number,number,number]</code>

- If `number` and `v` is not supplied: rotate CCW around Z.
- If `number` and `v` is a `Vector3D`: rotate CCW around axis defined by
  `v`.
- If `list` `[rx,ry,rz]`: apply rotations about X then Y then Z (degrees).
  (v is ignored.)

**<code>v</code>**: <code><a href="#t-Vector3D">Vector3D</a>|<a href="#t-BVector3D">BVector3D</a></code>
 *(Default: `undef`)*

- If `a` is a number
  - If `v` is a specified Vector3D, then this is the axis vector.
  - If `v` is a specified BVector3D, then use direction for the axis vector
    and `v[0]` as the rotation point.
  - Otherwise axis vector is Z.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-Matrix">Matrix</a></code>

Column-vector rotation matrix M.

- If `v` is a `BVector3D`, then returns a homogenised transform matrix
  (4x4).
- If `v` is a `Vector3D`, then returns a non-homogenised transform matrix
  (3x3).

</details>

#### ⚙️translate<a id='f-translate'></a>

<code>*function* translate(v: list\[number]) : <a href="#t-Matrix">Matrix</a></code>

Translation matrix that parallels OpenSCAD's translate() module.

Returns a **homogeneous column-vector** translation matrix T (4×4).

Use:

- Single 3D point `p`: `p` must be as homogeneous (`[x,y,z,1]`) when multiplying.
- Point list `Ps` (3D): use `transform(Ps, transpose(T))`.

<details><summary>parameters</summary>

**<code>v</code>**: <code>list\[number]</code>

Translation vector.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-Matrix">Matrix</a></code>

Homogeneous column-vector translation matrix T.

</details>

#### ⚙️scale<a id='f-scale'></a>

<code>*function* scale(v: list\[number]) : <a href="#t-Matrix">Matrix</a></code>

Scale matrix that parallels OpenSCAD's scale() module.

Returns a **non-homogeneous column-vector** scaling matrix S (3×3).

Use:

- Single point p (3-vector):  p' = S * p
- Point list Ps:              Ps' = Ps * transpose(S)

<details><summary>parameters</summary>

**<code>v</code>**: <code>list\[number]</code>

Per-axis scale factors.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-Matrix">Matrix</a></code>

Column-vector scaling matrix S.

</details>

#### ⚙️transform<a id='f-transform'></a>

<code>*function* transform(pts: list\[<a href="#t-Point">Point</a>], matrix\_or\_fn: <a href="#t-Matrix">Matrix</a>|function) : list\[<a href="#t-Point">Point</a>]</code>

Transform a list of points using either a matrix or a point-mapping function.

Points in pts are treated as **row vectors** (each point is a 1×d row).

- If `matrix_or_fn` is a `Matrix`, and since all matrices generated by this
  library are column-vector matrices `M`, you must pass `transpose(M)` here.

- If matrix_or_fn is a homogeneous matrix (e.g.  4×4 for 3D points), this
  function homogenises pts, multiplies, then dehomogenises back to the
  original point dimension.

<details><summary>parameters</summary>

**<code>pts</code>**: <code>list\[<a href="#t-Point">Point</a>]</code>

List of points (rows).  All points must have the same dimension.

**<code>matrix_or_fn</code>**: <code><a href="#t-Matrix">Matrix</a>|function</code>

Either:

- a matrix in row-vector orientation (typically `transpose(M)`), or
- a function that maps a single point to a transformed point.

</details>

<details><summary>returns</summary>

**Returns**: <code>list\[<a href="#t-Point">Point</a>]</code>

Transformed points.

</details>

#### ⚙️reorient<a id='f-reorient'></a>

<code>*function* reorient(start\_line\_seg: list\[<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>]|list\[<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>]|list\[<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>], end\_line\_seg: list\[<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>]|list\[<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>]|list\[<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>], scale\_to\_vectors: bool) : <a href="#t-Matrix">Matrix</a></code>

Returns a homogeneous column-vector transform matrix T (4×4) that maps one
line segment to another.

Use:

- Single 3D point `p`: `p` must be as homogeneous (`[x,y,z,1]`) when multiplying.
- Point list `Ps` (3D): use `transform(Ps, transpose(T))`.

<details><summary>parameters</summary>

**<code>start_line_seg</code>**: <code>list\[<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>]|list\[<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>]|list\[<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>]</code>

The source line segment: `[P0, P1]`.

**<code>end_line_seg</code>**: <code>list\[<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>]|list\[<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>]|list\[<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>]</code>

The target line segment: `[Q0, Q1]`.

**<code>scale_to_vectors</code>**: <code>bool</code>
 *(Default: `false`)*

Only affects the 2-point overload.  If true, also apply uniform scaling by
`|Q1-Q0|/|P1-P0|`.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-Matrix">Matrix</a></code>

Homogeneous column-vector transform matrix T.

- if start/end line_seg consist of 2 points, then
  - Rigid reorientation.  If scale_to_vectors is true, also apply uniform
    scaling.
- if start/end line_seg consist of 3 points, then
  - Reorientation that maps one 2D basis (plus translation) to another.
- otherwise start/end line_seg consist of 4 points
  - Reorientation that maps one 3D basis (plus translation) to another.

</details>

### <i>📑Matrix Math</i><a id='transform-ch-Matrix Math'></a>

#### ⚙️invert<a id='f-invert'></a>

<code>*function* invert(A: <a href="#t-Matrix">Matrix</a>, eps: number) : <a href="#t-Matrix">Matrix</a></code>

Invert a square matrix using Gauss-Jordan elimination with partial pivoting.

<details><summary>parameters</summary>

**<code>A</code>**: <code><a href="#t-Matrix">Matrix</a></code>

Non-empty square numeric matrix (list of equal-length lists).

**<code>eps</code>**: <code>number</code>
 *(Default: `1e-12`)*

Pivot tolerance.  Must be > 0.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-Matrix">Matrix</a></code>

The inverse matrix `A⁻¹`.

Assertion failure if `A` is not a valid square numeric matrix or if any
pivot has `|pivot| < eps`.

Example

    invert([[4,7],[2,6]])  // -> [[0.6,-0.7],[-0.2,0.4]]

</details>

#### ⚙️row\_reduction<a id='f-row_reduction'></a>

<code>*function* row_reduction(aug: <a href="#t-Matrix">Matrix</a>, k: number, n: number, eps: number) : <a href="#t-Matrix">Matrix</a></code>

Performs Gauss-Jordan row reduction with partial pivoting on an augmented
matrix.

<details><summary>parameters</summary>

**<code>aug</code>**: <code><a href="#t-Matrix">Matrix</a></code>

Augmented matrix of shape `n×(2n)`, typically `[A | I]`.

**<code>k</code>**: <code>number</code>

Current column index (0-based).  External callers pass 0.

**<code>n</code>**: <code>number</code>

Matrix order.  Must equal the row count of aug.

**<code>eps</code>**: <code>number</code>

Pivot tolerance.  Must be > 0.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-Matrix">Matrix</a></code>

The reduced augmented matrix.  For a non-singular A this is `[I | A⁻¹]`.

Assertion failure if `|pivot| < eps` at any step.

</details>

#### ⚙️identity<a id='f-identity'></a>

<code>*function* identity(n: number) : <a href="#t-Matrix">Matrix</a></code>

Creates an n×n identity matrix.

<details><summary>parameters</summary>

**<code>n</code>**: <code>number</code>

Matrix order.  Must be > 0.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-Matrix">Matrix</a></code>

The identity matrix of order n.

</details>

#### ⚙️augment<a id='f-augment'></a>

<code>*function* augment(A: <a href="#t-Matrix">Matrix</a>, B: <a href="#t-Matrix">Matrix</a>) : <a href="#t-Matrix">Matrix</a></code>

Horizontally concatenates two matrices with the same row count.

<details><summary>parameters</summary>

**<code>A</code>**: <code><a href="#t-Matrix">Matrix</a></code>

Left matrix with r rows.

**<code>B</code>**: <code><a href="#t-Matrix">Matrix</a></code>

Right matrix with r rows.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-Matrix">Matrix</a></code>

The augmented matrix `[A | B]`.

Assertion failure if A and B do not have the same non-zero row count.

</details>

### <i>📑transform types</i><a id='transform-ch-transform types'></a>

#### 🧩Matrix<a id='t-Matrix'></a>

<code>*type* Matrix = list\[list\[number,...],...]</code>

Placeholder for NxM matrix.

#### 🧩Point2D<a id='t-Point2D'></a>

<code>*type* Point2D = list</code>

A 2D point.

<details><summary>slots</summary>
<code><b>0</b></code>: <code>number</code>

This is the dimension `0` or x dimension of the point.  Can also be accessed
by property `.x`.

<code><b>1</b></code>: <code>number</code>

This is the dimension `1` or y dimension of the point.  Can also be accessed
by property `.y`.

</details>

#### 🧩Point3D<a id='t-Point3D'></a>

<code>*type* Point3D = list</code>

A 3D point.

<details><summary>slots</summary>
<code><b>0</b></code>: <code>number</code>

This is the dimension `0` or x dimension of the point.  Can also be accessed
by property `.x`.

<code><b>1</b></code>: <code>number</code>

This is the dimension `1` or y dimension of the point.  Can also be accessed
by property `.y`.

<code><b>2</b></code>: <code>number</code>

This is the dimension `2` or z dimension of the point.  Can also be accessed
by property `.z`.

</details>

#### 🧩Point<a id='t-Point'></a>

<code>*type* Point = list</code>

An ND point.

<details><summary>slots</summary>
<code><b>0</b></code>: <code>number</code>

This is the dimension `0` or x dimension of the point.  Can also be accessed
by property `.x`.

<code><b>1</b></code>: <code>number</code>

This is the dimension `1` or y dimension of the point.  Can also be accessed
by property `.y`.

<code><b>2</b></code>: <code>number</code>

This is the dimension `2` or z dimension of the point.  Can also be accessed
by property `.z`.

<code><b>n</b></code>: <code>number</code>

This is the dimension `n` dimension of the point.

</details>

#### 🧩Vector2D<a id='t-Vector2D'></a>

<code>*type* Vector2D = list</code>

A bound 2D vector, which starts from the origin.

<details><summary>slots</summary>
<code><b>0</b></code>: <code>number</code>

This is the dimension `0` or x dimension of the vector.  Can also be
accessed by property `.x`.

<code><b>1</b></code>: <code>number</code>

This is the dimension `1` or y dimension of the vector.  Can also be
accessed by property `.y`.

</details>

#### 🧩Vector3D<a id='t-Vector3D'></a>

<code>*type* Vector3D = list</code>

A bound 3D vector, which starts from the origin.

<details><summary>slots</summary>
<code><b>0</b></code>: <code>number</code>

This is the dimension `0` or x dimension of the vector.  Can also be
accessed by property `.x`.

<code><b>1</b></code>: <code>number</code>

This is the dimension `1` or y dimension of the vector.  Can also be
accessed by property `.y`.

<code><b>2</b></code>: <code>number</code>

This is the dimension `2` or z dimension of the vector.  Can also be
accessed by property `.z`.

</details>

#### 🧩Vector<a id='t-Vector'></a>

<code>*type* Vector = list</code>

A bound ND vector, which starts from the origin.

<details><summary>slots</summary>
<code><b>0</b></code>: <code>number</code>

This is the dimension `0` or x dimension of the vector.  Can also be
accessed by property `.x`.

<code><b>1</b></code>: <code>number</code>

This is the dimension `1` or y dimension of the vector.  Can also be
accessed by property `.y`.

<code><b>2</b></code>: <code>number</code>

This is the dimension `2` or z dimension of the vector.  Can also be
accessed by property `.z`.

<code><b>n</b></code>: <code>number</code>

This is the dimension `n` dimension of the vector.

</details>

#### 🧩BVector2D<a id='t-BVector2D'></a>

<code>*type* BVector2D = list\[<a href="#t-Point2D">Point2D</a>,<a href="#t-Point2D">Point2D</a>]</code>

A bound 2D vector, which starts from point in slot 0 and goes to point in
slot 1.

<details><summary>slots</summary>
<code><b>0</b></code>: <code><a href="#t-Point2D">Point2D</a></code>

This is the starting point for this bound vector.

<code><b>1</b></code>: <code><a href="#t-Point2D">Point2D</a></code>

This is the ending point for this bound vector.

</details>

#### 🧩BVector3D<a id='t-BVector3D'></a>

<code>*type* BVector3D = list\[<a href="#t-Point3D">Point3D</a>,<a href="#t-Point3D">Point3D</a>]</code>

A bound 3D vector, which starts from point in slot 0 and goes to point in
slot 1.

<details><summary>slots</summary>
<code><b>0</b></code>: <code><a href="#t-Point3D">Point3D</a></code>

This is the starting point for this bound vector.

<code><b>1</b></code>: <code><a href="#t-Point3D">Point3D</a></code>

This is the ending point for this bound vector.

</details>

#### 🧩BVector<a id='t-BVector'></a>

<code>*type* BVector = list\[<a href="#t-Point">Point</a>,<a href="#t-Point">Point</a>]</code>

A bound ND vector, which starts from point in slot 0 and goes to point in
slot 1.

<details><summary>slots</summary>
<code><b>0</b></code>: <code><a href="#t-Point">Point</a></code>

This is the starting point for this bound vector.

<code><b>1</b></code>: <code><a href="#t-Point">Point</a></code>

This is the ending point for this bound vector.

</details>


## <span style="font-size: 1.1em; color: yellow">📘helpers</span><a id='file-helpers'></a>

### <i>📑Purpose</i><a id='helpers-ch-Purpose'></a>

Miscellaneous helper functions.

### <i>📑Conversion functions</i><a id='helpers-ch-Conversion functions'></a>

#### ⚙️r2d<a id='f-r2d'></a>

<code>*function* r2d(radians: number) : number</code>

Convert radians to degrees.

<details><summary>parameters</summary>

**<code>radians</code>**: <code>number</code>

radians to convert.

</details>

<details><summary>returns</summary>

**Returns**: <code>number</code>

Equivalent degrees.

</details>

#### ⚙️d2r<a id='f-d2r'></a>

<code>*function* d2r(degrees: number) : number</code>

Convert degrees to radians.

<details><summary>parameters</summary>

**<code>degrees</code>**: <code>number</code>

degrees to convert.

</details>

<details><summary>returns</summary>

**Returns**: <code>number</code>

Equivalent radians.

</details>

### <i>📑Circular / Spherical Calculations</i><a id='helpers-ch-Circular / Spherical Calculations'></a>

#### ⚙️arc\_len<a id='f-arc_len'></a>

<code>*function* arc_len(A: list, B: list, R: number) : number</code>

Calculates the arc length between vectors A and B for a circle/sphere of
radius R.  If A and B are the same magnitude, R can be omitted.

<details><summary>parameters</summary>

**<code>A</code>**: <code>list</code>

First vector.

**<code>B</code>**: <code>list</code>

Second vector.

**<code>R</code>**: <code>number</code>
 *(Default: `undef`)*

Radius to use to measure the length along a sphere's great arc.

- If not specified, then will use the magnitude of A. Asserts if magnitude
  of B is not the same.
- If R=1, then the result is equivalent to the arc angle in radians.
- If R=180/PI, then the result is equivalent to the arc angle in degrees.

</details>

<details><summary>returns</summary>

**Returns**: <code>number</code>

The length of the great arc between the two vectors for a sphere of radius
R.

</details>

#### ⚙️arc\_len\_angle<a id='f-arc_len_angle'></a>

<code>*function* arc_len_angle(arc\_len: number, radius: number) : number</code>

Given the length of an arc and the radius of a circle/sphere that it's
traversing, returns the angle traversed in degrees.

`arc_len` and `radius` have the same units.

<details><summary>parameters</summary>

**<code>arc_len</code>**: <code>number</code>

Arc length along the circle.

**<code>radius</code>**: <code>number</code>

Circle radius (must be non-zero).

</details>

<details><summary>returns</summary>

**Returns**: <code>number</code>

Angle in degrees. Sign follows arc_len.

</details>

#### ⚙️arc\_len\_for\_shift<a id='f-arc_len_for_shift'></a>

<code>*function* arc_len_for_shift(R: number, m: number, a: number, b: number) : number</code>

Given a `circle R = sqrt(x^2 + y^2)` and a line `y = m*x + (b + a)`,
compute the arc-length difference `Δs` along the circle between the
intersection of the original line `y = m*x + b` and the shifted line
`y = m*x + (b + a)`. Only the right-side `(x >= 0)` intersection is tracked.

<details><summary>parameters</summary>

**<code>R</code>**: <code>number</code>

circle radius

**<code>m</code>**: <code>number</code>

slope (dy/dx)

**<code>a</code>**: <code>number</code>

vertical shift of the line relative to b

**<code>b</code>**: <code>number</code>
 *(Default: `0`)*

original y-intercept (default 0)

</details>

<details><summary>returns</summary>

**Returns**: <code>number</code>

Δs (nonnegative) or undef if the right-side intersection does not exist
before or after the shift.

</details>

#### ⚙️shift\_for\_arc\_len<a id='f-shift_for_arc_len'></a>

<code>*function* shift_for_arc_len(R: number, m: number, delta\_s: number, b: number) : list\[number|undef,number|undef]</code>

Given a circle `R = sqrt(x^2 + y^2)` and line `y = m*x + b`, compute the
vertical (y-axis) shift values a that would produce a specified arc-length
difference `Δs` between the original intersection and the shifted line
`y = m*x + (b + a)`, tracking only the right-side `(x >= 0)` intersection.

<details><summary>parameters</summary>

**<code>R</code>**: <code>number</code>

circle radius

**<code>m</code>**: <code>number</code>

slope (dy/dx)

**<code>delta_s</code>**: <code>number</code>

desired arc length difference

**<code>b</code>**: <code>number</code>
 *(Default: `0`)*

original y-intercept (default 0)

</details>

<details><summary>returns</summary>

**Returns**: <code>list\[number|undef,number|undef]</code>

Slot 0 is `a_up` and slot 1 is `a_down`, where:
    (is_undef(a_up) or a_up ≥ 0) and (is_undef(a_down) or a_down ≤ 0)
They would be undef if there is no solution for that direction.

</details>

### <i>📑Miscellaneous</i><a id='helpers-ch-Miscellaneous'></a>

#### ⚙️not<a id='f-not'></a>

<code>*function* not(not\_fn: function) : function(p: <a href="#t-PredFn">PredFn</a>): bool</code>

Wrap a lambda so that it negates its return value.

<details><summary>parameters</summary>

**<code>not_fn</code>**: <code>function</code>

The function to invert the boolean's (or equivalent truthy/falsy) value.

</details>

<details><summary>returns</summary>

**Returns**: <code>function(p: <a href="#t-PredFn">PredFn</a>): bool</code>

Return the lambda that will invert a lambda's truth value.

</details>

#### ⚙️clamp<a id='f-clamp'></a>

<code>*function* clamp(v: number, lo: number, hi: number) : number</code>

Clamps a value between `[lo, hi]`.

<details><summary>parameters</summary>

**<code>v</code>**: <code>number</code>

Value to clamp.

**<code>lo</code>**: <code>number</code>

Lowest value v should take.

**<code>hi</code>**: <code>number</code>

Highest value v should take.

</details>

<details><summary>returns</summary>

**Returns**: <code>number</code>

Value v that is clamped between `[lo, hi]`.

</details>

#### ⚙️vector\_info<a id='f-vector_info'></a>

<code>*function* vector_info(a: <a href="#t-Point">Point</a>, b: <a href="#t-Point">Point</a>) : <a href="#t-VectorInfo">VectorInfo</a></code>

Computes direction, length, unit vector and normal to unit vector, and puts
them into an list.

Add `include <helpers_consts>` to use the appropriate constants.

<details><summary>parameters</summary>

**<code>a</code>**: <code><a href="#t-Point">Point</a></code>

Starting point of vector

**<code>b</code>**: <code><a href="#t-Point">Point</a></code>

Ending point of vector

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-VectorInfo">VectorInfo</a></code>

Object containing the info of all the operations.  See `VectorInfo` type
for details.

</details>

#### ⚙️equal<a id='f-equal'></a>

<code>*function* equal(v1: any, v2: any, epsilon: number) : bool</code>

Checks the equality of two items.  If v1 and v2 are lists of the same length,
then check the equality of each element.  If each are numbers, then check to
see if they are both equal to each other within an error of epsilon.  All
other types are done using the == operator.

<details><summary>parameters</summary>

**<code>v1</code>**: <code>any</code>

First item to compare against.

**<code>v2</code>**: <code>any</code>

Second item to compare against.

**<code>epsilon</code>**: <code>number</code>
 *(Default: `1e-6`)*

The max error tolerated for a number.

</details>

<details><summary>returns</summary>

**Returns**: <code>bool</code>

True if the objects are equal within tolerance.  False otherwise.

</details>

#### ⚙️function\_equal<a id='f-function_equal'></a>

<code>*function* function_equal()</code>

Hoists function into variable namespace to be able to be passed as a lambda.

#### ⚙️default<a id='f-default'></a>

<code>*function* default(v: any, d: any) : any</code>

If v is undefined, then return the default value d.

<details><summary>parameters</summary>

**<code>v</code>**: <code>any</code>

The value to test if defined.

**<code>d</code>**: <code>any</code>

The result to give if v is undefined.

</details>

<details><summary>returns</summary>

**Returns**: <code>any</code>

If v is defined, then return v, else d.

</details>

#### ⚙️INCOMPLETE<a id='f-INCOMPLETE'></a>

<code>*function* INCOMPLETE()</code>

Used to mark code as incomplete.

#### ⚙️offset\_angle<a id='f-offset_angle'></a>

<code>*function* offset_angle(ref\_vec: <a href="#t-Point">Point</a>, vec: <a href="#t-Point">Point</a>, delta\_angle\_deg: number) : <a href="#t-Point">Point</a></code>

Rotate vec so that the angle between ref_vec and vec increases by
delta_angle_deg.

Uses rotate(delta_angle_deg, cross(ref_vec, vec)) and applies it to vec.

<details><summary>parameters</summary>

**<code>ref_vec</code>**: <code><a href="#t-Point">Point</a></code>

Reference vector.  Must have norm(ref_vec) > 0.

**<code>vec</code>**: <code><a href="#t-Point">Point</a></code>

Vector to rotate.  Must have norm(vec) > 0 and must not be (anti)parallel to
ref_vec.

**<code>delta_angle_deg</code>**: <code>number</code>

Angle increase in degrees.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-Point">Point</a></code>

The rotated vector.

</details>

#### 🧊arrow<a id='m-arrow'></a>

<code>*module* arrow(l: number, t: number, c: list|string|undef, a: number)</code>

Create an arrow pointing up in the positive z direction.  Primarily used for
debugging.

<details><summary>parameters</summary>

**<code>l</code>**: <code>number</code>

Length of arrow.

**<code>t</code>**: <code>number</code>
 *(Default: `1`)*

Thickness of arrowhead shaft.

**<code>c</code>**: <code>list|string|undef</code>

Same as color() module's first parameter. `[r, g, b]`, `[r, g, b, a]`,
`"color_name"`, `"#hex_value"`.  If not defined, no colour is applied.

**<code>a</code>**: <code>number</code>

Same as color() module's optional second parameter.  Alpha value between
`[0, 1]`.

</details>

#### 🧊axis<a id='m-axis'></a>

<code>*module* axis(l: number, t: number)</code>

Create 3 arrows aligning to x, y and z axis coloured red, green and blue
respectively.

<details><summary>parameters</summary>

**<code>l</code>**: <code>number</code>

Length of arrow.

**<code>t</code>**: <code>number</code>
 *(Default: `1`)*

Thickness of arrowhead shaft.

</details>

#### ⚙️fl<a id='f-fl'></a>

<code>*function* fl(f: string, l: number) : string</code>

File line function to output something that looks like a file line to be able
to jump to the file/line in VSCode easier.

To make it easier in a file, create the following variable in that file:

    _fl = function(l) fl("<this-file-name>", l);

As a variable, it won't get exported.  Use that in your file.

<details><summary>parameters</summary>

**<code>f</code>**: <code>string</code>

Name of file.

**<code>l</code>**: <code>number</code>

Line number in file.

</details>

<details><summary>returns</summary>

**Returns**: <code>string</code>

Returns a string which will allow you to ctrl-click on the string text from
the terminal window.

</details>

#### ⚙️Assert<a id='f-Assert'></a>

<code>*function* Assert(truth: bool, msg: string|function) : <a href="#t-IdentityFn">IdentityFn</a></code>

Possible callchains:

    Assert(truth, msg) (value) : any

Asserts that `truth` is `true`.

Currently, `assert()` will evaluate the parameters prior to testing the
truthiness of `truth`.  If the `msg` is an expensive operation, this can have
performance consequences.  This function allows the `msg` to be a function,
preventing evaluation of the `msg` if not needed.

This also returns an identity function which allows to embed this inside of
an expression with minimal effort.

> ℹ️ NOTE:
>
> There is an enhancement to potentially resolve this reported by me here:
> <https://github.com/openscad/openscad/issues/6240>

<details><summary>parameters</summary>

**<code>truth</code>**: <code>bool</code>

- If truthy, returns function that takes a parameter  which it returns
  unmodified.

**<code>msg</code>**: <code>string|function</code>
 *(Default: `""`)*

- If truth is falsy, then
  - If msg is a function, execute it to get the actual message.
  - Otherwise pass msg unmolested.
  - Assert fails with msg.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-IdentityFn">IdentityFn</a></code>

Returns a function that returns the `return_value` unmolested.  This allows
to put the `Assert()` function in the middle of an expression if desired.

Possible callchains:

    IdentityFn(return_value) : any

</details>

#### ⚙️interpolated\_values<a id='f-interpolated_values'></a>

<code>*function* interpolated_values(p0: number|list, p1: number|list) : list\[number|list]</code>

Gets a list of `number_of_values` between `p0` and `p1`.

> ℹ️ NOTE:
>
> `p0` and `p1` must be the same shape and must comprise of values that have
> `+`, `-` and `/` operations defined for them.

Example

    interpolated_values(1, 2, 1) == [1.5]
    interpolated_values(1, 2, 3) == [1.25, 1.5, 1.75]

<details><summary>parameters</summary>

**<code>p0</code>**: <code>number|list</code>

Starting point.

**<code>p1</code>**: <code>number|list</code>

Ending point.

</details>

<details><summary>returns</summary>

**Returns**: <code>list\[number|list]</code>

List of `number_of_values` that are the interpolated values between `p0`
and `p1`.

</details>

### <i>📑helpers types</i><a id='helpers-ch-helpers types'></a>

#### 🧩VectorInfo<a id='t-VectorInfo'></a>

<code>*type* VectorInfo = list</code>

Results of the [vector_info()](#f-vector_info) call.

<details><summary>slots</summary>
<code><b>VI_VECTOR</b></code>: <code><a href="#t-Point">Point</a></code>

Direction of the ab vector.

<code><b>VI_LENGTH</b></code>: <code>number</code>

Length of ab vector.

<code><b>VI_DIR</b></code>: <code><a href="#t-Point">Point</a></code>

Unit ab vector.

<code><b>VI_NORMAL</b></code>: <code><a href="#t-Point">Point</a></code>

A normal unit vector by swapping first two dimensions and then making the
resulting first dimension negative.

</details>

#### 🧩IdentityFn<a id='t-IdentityFn'></a>

<code>*callback* IdentityFn(return\_value: any) : any</code>

Returns the value passed.

<details><summary>parameters</summary>

**<code>return_value</code>**: <code>any</code>

</details>

<details><summary>returns</summary>

**Returns**: <code>any</code>

Returns `return_value`.

</details>


## <span style="font-size: 1.1em; color: yellow">📘skin</span><a id='file-skin'></a>

### <i>📑Purpose</i><a id='skin-ch-Purpose'></a>

The built in extrude module isn't powerful or flexible enough so this library
was made.  It creates a skin by making layers of polygons with the same
number of vertices and then skins them by putting faces between layers.

### <i>📑Design</i><a id='skin-ch-Design'></a>

This requires keeping track of a bunch of data, which was put into a list.

#### ⚙️skin\_to\_string<a id='f-skin_to_string'></a>

<code>*function* skin_to_string(obj: <a href="#t-skin">skin</a>, only\_first\_and\_last\_layers: bool, precision: number) : string</code>

Converts a skin object to a human readable string.

<details><summary>parameters</summary>

**<code>obj</code>**: <code><a href="#t-skin">skin</a></code>

This is the skin object to view.

**<code>only_first_and_last_layers</code>**: <code>bool</code>
 *(Default: `true`)*

Show only the first and last layers if true, otherwise all layers.

**<code>precision</code>**: <code>number</code>
 *(Default: `4`)*

The number of decimal places to show the layers.

</details>

<details><summary>returns</summary>

**Returns**: <code>string</code>

The string representation of the skin object.

</details>

#### ⚙️layer\_pt<a id='f-layer_pt'></a>

<code>*function* layer_pt(pts\_in\_layer: number, pt\_i: number, layer\_i: number) : number</code>

Computes the index of a point in a layered point array.  This is like a 2D
coordinate map, where `pt_i` is the x-axis (limited by modulo `pts_in_layer`
so that it wraps) and `layer_i` is the y-axis.

This allows to more easily visualise what points are being referenced,
relative to different layers.

Assumes that points are stored consecutively per layer, and layers are
stacked consecutively in memory.

<details><summary>parameters</summary>

**<code>pts_in_layer</code>**: <code>number</code>

Number of points in each layer.

**<code>pt_i</code>**: <code>number</code>

Index of the point on a layer (0-based).  If > pts_in_layer, then wraps
back to 0.

**<code>layer_i</code>**: <code>number</code>

Index of the layer (0-based).

</details>

<details><summary>returns</summary>

**Returns**: <code>number</code>

The linear index of the specified point.

</details>

#### ⚙️layer\_pts<a id='f-layer_pts'></a>

<code>*function* layer_pts(pts\_in\_layer: number, pt\_offset\_and\_layer\_list: list\[list\[number,number]]) : list\[number,...]</code>

Computes a list of layer indices for multiple points in a layered point
array.

This allows to more easily visualise what points are being referenced,
relative to different layers.

Assumes points are stored consecutively per layer, with each layer laid out
sequentially.

<details><summary>parameters</summary>

**<code>pts_in_layer</code>**: <code>number</code>

Number of points per layer.

**<code>pt_offset_and_layer_list</code>**: <code>list\[list\[number,number]]</code>

List of (point index, layer index) pairs.

</details>

<details><summary>returns</summary>

**Returns**: <code>list\[number,...]</code>

A list of linear layer_i corresponding to the given points.

</details>

#### ⚙️layer\_side\_faces<a id='f-layer_side_faces'></a>

<code>*function* layer_side_faces(pts\_in\_layer: number, layers: number, wall\_diagonal: list\[bool,...]) : list\[<a href="#t-Face">Face</a>]</code>

Helper to generate side wall faces between consecutive layers.

Assumes the points are arranged in a flat list, with each layer's points
stored contiguously, and layers stored in sequence. Points within each
layer must be ordered **clockwise when looking into the object**.

Each wall segment is formed from two triangles connecting corresponding
points between adjacent layers.  Each triangle is a [`Face`](#t-Face).

<details><summary>parameters</summary>

**<code>pts_in_layer</code>**: <code>number</code>

Number of points per layer.

**<code>layers</code>**: <code>number</code>
 *(Default: `1`)*

Number of vertical wall segments to generate (requires one more point
layer).

**<code>wall_diagonal</code>**: <code>list\[bool,...]</code>
 *(Default: `[0, 1]`)*

This is used to allow changing the diagonal of neighbouring square polygons
on a layer.

E.g.

- `[1]` will have all diagonals go one way.
- `[1,0]` will alternate.
- `[0,1]` will alternate the opposite way to `[1,0]`.
- `[0,0,1]` will have it go one way for 2 consecutive 4 point face, and
  then the other way, and then repeat.

</details>

<details><summary>returns</summary>

**Returns**: <code>list\[<a href="#t-Face">Face</a>]</code>

A list of triangle layer_i forming the side walls.

</details>

#### ⚙️is\_skin<a id='f-is_skin'></a>

<code>*function* is_skin()</code>

Checks to see if object is a skin object

#### ⚙️skin\_new<a id='f-skin_new'></a>

<code>*function* skin_new(pt\_count\_per\_layer: number, layers: number, pts3d: list\[<a href="#t-Point3D">Point3D</a>,...], comment: string, operation: string, wall\_diagonal: list\[bool,...], debug\_axes: list\[list\[<a href="#t-Point3D">Point3D</a>,...],...]) : <a href="#t-skin">skin</a></code>

Create a new skin object.

<details><summary>parameters</summary>

**<code>pt_count_per_layer</code>**: <code>number</code>

number of points per layer (must be ≥ 3)

**<code>layers</code>**: <code>number</code>

Number of wall segments (requires `layers + 1` total point layers).

**<code>pts3d</code>**: <code>list\[<a href="#t-Point3D">Point3D</a>,...]</code>

The full list of points arranged in stacked layers.

**<code>comment</code>**: <code>string</code>

Usually a string, this is just a comment for reading and debugging purposes.

**<code>operation</code>**: <code>string</code>

This is used by skin_to_polyhedron() when passing a list of skins.
If a skin has an operation attached, then that skin will have
the operation specified applied to the next element in the list which can
be an object or list of objects.

**<code>wall_diagonal</code>**: <code>list\[bool,...]</code>

This is used to allow changing the diagonal of neighbouring square polygons
on a layer.

E.g.

- `[1]` will have all diagonals go one way.
- `[1,0]` will alternate.
- `[0,1]` will alternate the opposite way to `[1,0]`.
- `[0,0,1]` will have it go one way for 2 consecutive 4 point face, and
  then the other way, and then repeat.

**<code>debug_axes</code>**: <code>list\[list\[<a href="#t-Point3D">Point3D</a>,...],...]</code>

This is a list of point groups.  When rendering, arrows will be drawn from
the first point to each succeeding point in list.  When debugging, call
skin_show_debug_axis().

> ⚠️ WARNING:
>
> INCOMPLETE and UNTESTED.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-skin">skin</a></code>

</details>

#### ⚙️skin\_extrude<a id='f-skin_extrude'></a>

<code>*function* skin_extrude(birl: number|<a href="#t-range">range</a>|list, end\_i: number|undef, comment: string, operation: string, wall\_diagonal: list\[bool,...], debug\_axes: list\[list\[<a href="#t-Point3D">Point3D</a>,...],...]) : <a href="#t-SkinExtrude">SkinExtrude</a></code>

Possible callchains:

    skin_extrude(birl, end_i, comment, operation, wall_diagonal, debug_axes) (pts_fn) : skin

Generates an extruded point list from a number range, range or list of
indices.

<details><summary>parameters</summary>

**<code>birl</code>**: <code>number|<a href="#t-range">range</a>|list</code>

- If number, start index to check
- If range, indices to check
- If list, indices to check

**<code>end_i</code>**: <code>number|undef</code>

- If birl is a number, then end index to check.  end_i
  could be less than birl if there's nothing to iterate
  over.

**<code>comment</code>**: <code>string</code>

Usually a string, this is just a comment for reading and debugging purposes.

**<code>operation</code>**: <code>string</code>

This is used by skin_to_polyhedron() when passing a list of skins.
If a skin has an operation attached, then that skin will have
the operation specified applied to the next element in the list which can
be an object or list of objects.

**<code>wall_diagonal</code>**: <code>list\[bool,...]</code>

This is used to allow changing the diagonal of neighbouring square polygons
on a layer.

E.g.

- `[1]` will have all diagonals go one way.
- `[1,0]` will alternate.
- `[0,1]` will alternate the opposite way to `[1,0]`.
- `[0,0,1]` will have it go one way for 2 consecutive 4 point face, and
  then the other way, and then repeat.

**<code>debug_axes</code>**: <code>list\[list\[<a href="#t-Point3D">Point3D</a>,...],...]</code>

This is a list of point groups.  When rendering, arrows will be drawn from
the first point to each succeeding point in list.  When debugging, call
skin_show_debug_axis().

> ⚠️ WARNING:
>
> INCOMPLETE and UNTESTED.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-SkinExtrude">SkinExtrude</a></code>

Lambda that takes a function that returns one layer of points.

Possible callchains:

    SkinExtrude(pts_fn) : skin

</details>

#### ⚙️skin\_create\_faces<a id='f-skin_create_faces'></a>

<code>*function* skin_create_faces(skin: <a href="#t-skin">skin</a>) : list\[<a href="#t-Face">Face</a>]</code>

Generates face layer_i to skin a layered structure, including:

- bottom cap (layer 0)
- top cap (layer = layers)
- side wall faces between adjacent layers

Assumes that points are stored in a flat array, with `pts_in_layer`
points per layer, and layers stored consecutively. Points within each
layer must be ordered clockwise when looking into the object.

<details><summary>parameters</summary>

**<code>skin</code>**: <code><a href="#t-skin">skin</a></code>

The skin object generating the faces from.

</details>

<details><summary>returns</summary>

**Returns**: <code>list\[<a href="#t-Face">Face</a>]</code>

A list of triangle face definitions.

</details>

#### ⚙️skin\_transform<a id='f-skin_transform'></a>

<code>*function* skin_transform(obj\_or\_objs: <a href="#t-skin">skin</a>, matrix\_or\_fn: <a href="#t-Matrix">Matrix</a>|function) : <a href="#t-skin">skin</a></code>

Performs a transformation on the points stored in the skin object.

<details><summary>parameters</summary>

**<code>obj_or_objs</code>**: <code><a href="#t-skin">skin</a></code>

The skin object where the points are coming from to transform.
TODO: Update doc to state `list[skin]`

**<code>matrix_or_fn</code>**: <code><a href="#t-Matrix">Matrix</a>|function</code>

The matrix or function to do the transformation with.  If the
transformation is homogenous, then will convert the points to a homogeneous
basis, perform the transformation and then remove the basis.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-skin">skin</a></code>

A new skin object with the points transformed.

</details>

#### 🧊skin\_to\_polyhedron<a id='m-skin_to_polyhedron'></a>

<code>*module* skin_to_polyhedron(obj\_or\_objs: <a href="#t-skin">skin</a>|list\[<a href="#t-skin">skin</a>,...])</code>

Takes the skin object and make it into a polyhedron.  If obj is a list, will
assume all are skin objects and attempt to skin them all.

<details><summary>parameters</summary>

**<code>obj_or_objs</code>**: <code><a href="#t-skin">skin</a>|list\[<a href="#t-skin">skin</a>,...]</code>

The skin object or list of skin objects to make into a polyhedron.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-skin">skin</a></code>

A new skin object with the points transformed.

</details>

#### ⚙️skin\_add\_layer\_if<a id='f-skin_add_layer_if'></a>

<code>*function* skin_add_layer_if(obj: <a href="#t-skin">skin</a>, add\_layers\_fn: function) : <a href="#t-skin">skin</a></code>

Adds a number of interpolated layers between layers based how many
add_layers_fn(i) returns.

<details><summary>parameters</summary>

**<code>obj</code>**: <code><a href="#t-skin">skin</a></code>

Object to add to.

**<code>add_layers_fn</code>**: <code>function</code>

Callback that will return the first index of a layer, expecting that the
point it refers to or its brethren on that layer to be compared to the
points on the very next layer.

It is guaranteed that there is a next layer of points to compare with.

`i` is the first index of the layer to be analyzed and will return the
number of additional layers to add between the current layer and the next.
Negative numbers are treated as 0.

E.g.

- 0 or less means add no additional layers.
- 1 means add another layer that is half way in between the current and
  next layer.
- 2 means add 2 layers, 1/3 and 2/3 between.
- etc...

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-skin">skin</a></code>

Updated skin.

</details>

#### 🧊skin\_show\_debug\_axes<a id='m-skin_show_debug_axes'></a>

<code>*module* skin_show_debug_axes(obj: <a href="#t-skin">skin</a>, styles: list\[<a href="#t-DebugStyle">DebugStyle</a>])</code>

UNTESTED!
Shows the debug axes to verify where you think things should be.

<details><summary>parameters</summary>

**<code>obj</code>**: <code><a href="#t-skin">skin</a></code>

Object to show debug axes for.

**<code>styles</code>**: <code>list\[<a href="#t-DebugStyle">DebugStyle</a>]</code>
 *(Default: `[["red", 1, .1], ["green"], ["blue"]]`)*

Contains a list of styles that are reused when the number of points in a
debug group exceeds the the number of styles.

If a style doesn't contain a colour, alpha or thickness (set as undef),
will go backwards to find one that does and uses that.

</details>

#### ⚙️interpolate<a id='f-interpolate'></a>

<code>*function* interpolate()</code>

Interpolates value between v0 and v1?

> 📌 TO DO:
>
> This function is deprecated and should be replaced with
> [`interpolated_values()`](#f-interpolated_values).

#### ⚙️skin\_limit<a id='f-skin_limit'></a>

<code>*function* skin_limit(obj: <a href="#t-skin">skin</a>, extract\_order\_value\_fn: function, begin: number, end: number) : <a href="#t-skin">skin</a></code>

INCOMPLETE!
Truncates the beginning, end or both of the extrusion.

<details><summary>parameters</summary>

**<code>obj</code>**: <code><a href="#t-skin">skin</a></code>

Object to remove values before in points.  Value extracted from points MUST
BE monotonically nondecreasing over the points list.

**<code>extract_order_value_fn</code>**: <code>function</code>

This take in a point and returns some value.  This is to allow selection of
a particular axis or length for a given point to compare against value.

**<code>begin</code>**: <code>number</code>

The value to compare against the extracted value from a point.

**<code>end</code>**: <code>number</code>

The value to compare against the extracted value from a point.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-skin">skin</a></code>

Updated skin object with all of the points before value removed.  If
extracted value is not EXACTLY value, then will linearly interpolated to
cup off EXACTLY at value.

</details>

#### ⚙️skin\_verify<a id='f-skin_verify'></a>

<code>*function* skin_verify(obj: <a href="#t-skin">skin</a>, disp\_all\_pts: bool) : string</code>

For debugging, returns a string reporting the stats of a skin object.

Asserts if the object's number of points doesn't correspond to the equation:

  `(layers + 1) * pts_in_layer`

<details><summary>parameters</summary>

**<code>obj</code>**: <code><a href="#t-skin">skin</a></code>

Object to verify.

**<code>disp_all_pts</code>**: <code>bool</code>
 *(Default: `false`)*

- If false, only returns the first and last points in the list.
- If true, returns all points, with each layer of points on a separate line.

</details>

<details><summary>returns</summary>

**Returns**: <code>string</code>

A prettified/simplified view of points in the object.

</details>

#### ⚙️skin\_max\_layer\_distance\_fn<a id='f-skin_max_layer_distance_fn'></a>

<code>*function* skin_max_layer_distance_fn(obj: <a href="#t-skin">skin</a>, max\_diff: number, diff\_fn: function) : function(i: number): number</code>

Returns a function that can be used with skin_add_layer_if() to ensure that
the distance between layers don't exceed some length.

<details><summary>parameters</summary>

**<code>obj</code>**: <code><a href="#t-skin">skin</a></code>

Represents a skin object.

**<code>max_diff</code>**: <code>number</code>

Maximum distance before adding another layer to reduce the distance below
max_diff.

**<code>diff_fn</code>**: <code>function</code>
 *(Default: `function(p0, p1) p1.x - p0.x`)*

Callback that gives the distance between layers, where `p0` is the first
point of the current layer and `p1` is the first point of the next layer.
Will return a value that states the distance between layers.

</details>

<details><summary>returns</summary>

**Returns**: <code>function(i: number): number</code>

Function that can be used with skin_add_layer_if() and returns the number
of layers to add.

</details>

### <i>📑skin types</i><a id='skin-ch-skin types'></a>

#### 🧩skin<a id='t-skin'></a>

<code>*type* skin = list</code>

Represents a skin object.

<details><summary>slots</summary>
<code><b>SKIN_PTS_IN_LAYER</b></code>: <code>number</code>

Number of points in a layer.

<code><b>SKIN_LAYERS</b></code>: <code>number</code>

Number of layers-1.

<code><b>SKIN_PTS</b></code>: <code>list\[<a href="#t-Point3D">Point3D</a>,...]</code>

A list of points representing the skin object.  This is a flattened list of
points in layer order.  Points are in clockwise order when looking towards
the next layer.

<code><b>SKIN_DEBUG_AXES</b></code>: <code>...</code>

A set of points that gets transformed with the skin points.

> ℹ️ NOTE:
>
> Rendering is still under development.  **Untested**.

<code><b>SKIN_COMMENT</b></code>: <code>string</code>

A string to give meaning as to what this object represents.

<code><b>SKIN_OPERATION</b></code>: <code>...</code>

This is to allow operations between adjacent skin objects in a list.

> ℹ️ NOTE:
>
> Rendering is still under development.  **Untested**.

<code><b>SKIN_WALL_DIAG</b></code>: <code>list\[bool,...]</code>

When skinning the side walls of the skin, there are two ways to skin a 4
point polygon.  This allows controlling that by specifying the direction.
The first polygon is rendered by what slot 0 states.  The second, by what
slot 1 states.  This continues till the list slots are exhausted, at which
point, it starts at slot 0 again.

</details>

#### 🧩Face<a id='t-Face'></a>

<code>*type* Face = list</code>

<details><summary>slots</summary>
<code><b>0</b></code>: <code>number</code>

This is the first index to the point in the referenced point list.

<code><b>1</b></code>: <code>number</code>

This is the second index to the point in the referenced point list.

<code><b>2</b></code>: <code>number</code>

This is the third index to the point in the referenced point list.

</details>

#### 🧩SkinExtrude<a id='t-SkinExtrude'></a>

<code>*callback* SkinExtrude(pts\_fn: function) : <a href="#t-skin">skin</a></code>

<details><summary>parameters</summary>

**<code>pts_fn</code>**: <code>function</code>

Function that returns a list of points for layer i.  It's fine to have
duplicate points in list as degenerate triangles will be filtered when
calling skin_to_polyhedron.

> ℹ️ NOTE:
>
> Points **MUST** wind in clockwise order when looking into object from
> starting layer towards next layer.
>
> Non-coplanar points on a layer may result in **UB**. Especially on end caps.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-skin">skin</a></code>

The skin object.

</details>

#### 🧩ColourLst<a id='t-ColourLst'></a>

<code>*type* ColourLst = list</code>

<details><summary>slots</summary>
<code><b>0</b></code>: <code>number</code>

Red value between `[0,1]`.

<code><b>1</b></code>: <code>number</code>

Green value between `[0,1]`.

<code><b>2</b></code>: <code>number</code>

Blue value between `[0,1]`.

<code><b>3</b></code>: <code>number</code>

Alpha value between `[0,1]`, where 1 means solid and 0 is transparent.

</details>

#### 🧩ColourStr<a id='t-ColourStr'></a>

<code>*type* ColourStr = string</code>

Can be specified in 4 different formats:

- `"#rgb"`
- `"#rgba"`
- `"#rrggbb"`
- `"#rrggbbaa"`

Alpha value between `["0","f"]` or `["00","ff"]`, where `"f"` or `"ff"` means
solid and `"0"` or `"00"` is transparent.

#### 🧩ColourName<a id='t-ColourName'></a>

<code>*type* ColourName = string</code>

The available color names are taken from the World Wide Web consortium's SVG
color list. A chart of the color names is as follows, (note that both
spellings of grey/gray including slategrey/slategray etc are valid):

|                        |                        |                        |
|------------------------|------------------------|------------------------|
| **Purples**            | **Reds**               | **Browns**             |
| - Lavender             | - IndianRed            | - Cornsilk             |
| - Thistle              | - LightCoral           | - BlanchedAlmond       |
| - Plum                 | - Salmon               | - Bisque               |
| - Violet               | - DarkSalmon           | - NavajoWhite          |
| - Orchid               | - LightSalmon          | - Wheat                |
| - Fuchsia              | - Red                  | - BurlyWood            |
| - Magenta              | - Crimson              | - Tan                  |
| - MediumOrchid         | - FireBrick            | - RosyBrown            |
| - MediumPurple         | - DarkRed              | - SandyBrown           |
| - BlueViolet           |                        | - Goldenrod            |
| - DarkViolet           | **Greens**             | - DarkGoldenrod        |
| - DarkOrchid           | - GreenYellow          | - Peru                 |
| - DarkMagenta          | - Chartreuse           | - Chocolate            |
| - Purple               | - LawnGreen            | - SaddleBrown          |
| - Indigo               | - Lime                 | - Sienna               |
| - DarkSlateBlue        | - LimeGreen            | - Brown                |
| - SlateBlue            | - PaleGreen            | - Maroon               |
| - MediumSlateBlue      | - LightGreen           |                        |
|                        | - MediumSpringGreen    | **Whites**             |
| **Pinks**              | - SpringGreen          | - White                |
| - Pink                 | - MediumSeaGreen       | - Snow                 |
| - LightPink            | - SeaGreen             | - Honeydew             |
| - HotPink              | - ForestGreen          | - MintCream            |
| - DeepPink             | - Green                | - Azure                |
| - MediumVioletRed      | - DarkGreen            | - AliceBlue            |
| - PaleVioletRed        | - YellowGreen          | - GhostWhite           |
|                        | - OliveDrab            | - WhiteSmoke           |
| **Blues**              | - Olive                | - Seashell             |
| - Aqua                 | - DarkOliveGreen       | - Beige                |
| - Cyan                 | - MediumAquamarine     | - OldLace              |
| - LightCyan            | - DarkSeaGreen         | - FloralWhite          |
| - PaleTurquoise        | - LightSeaGreen        | - Ivory                |
| - Aquamarine           | - DarkCyan             | - AntiqueWhite         |
| - Turquoise            | - Teal                 | - Linen                |
| - MediumTurquoise      |                        | - LavenderBlush        |
| - DarkTurquoise        | **Oranges**            | - MistyRose            |
| - CadetBlue            | - LightSalmon          |                        |
| - SteelBlue            | - Coral                | **Grays**              |
| - LightSteelBlue       | - Tomato               | - Gainsboro            |
| - PowderBlue           | - OrangeRed            | - LightGrey            |
| - LightBlue            | - DarkOrange           | - Silver               |
| - SkyBlue              | - Orange               | - DarkGray             |
| - LightSkyBlue         |                        | - Gray                 |
| - DeepSkyBlue          | **Yellows**            | - DimGray              |
| - DodgerBlue           | - Gold                 | - LightSlateGray       |
| - CornflowerBlue       | - Yellow               | - SlateGray            |
| - RoyalBlue            | - LightYellow          | - DarkSlateGray        |
| - Blue                 | - LemonChiffon         | - Black                |
| - MediumBlue           | - LightGoldenrodYellow |                        |
| - DarkBlue             | - PapayaWhip           |                        |
| - Navy                 | - Moccasin             |                        |
| - MidnightBlue         | - PeachPuff            |                        |
|                        | - PaleGoldenrod        |                        |
|                        | - Khaki                |                        |
|                        | - DarkKhaki            |                        |

#### 🧩DebugStyle<a id='t-DebugStyle'></a>

<code>*type* DebugStyle = list</code>

Style for a debug vector.

<details><summary>slots</summary>
<code><b>0</b></code>: <code><a href="#t-ColourStr">ColourStr</a>|<a href="#t-ColourLst">ColourLst</a>|<a href="#t-ColourName">ColourName</a></code>

- If a string, then the name of a colour, or the hex representation of one.
- If a number, the the value of the hex value.

<code><b>1</b></code>: <code>number</code>

Alpha value between `[0, 1]`.

> 📌 TO DO:
>
> Need to verify if undef is allowed, otherwise this will always take
> precedence, even if alpha is specified in the ColourLst or ColourStr
> style specifications.

<code><b>2</b></code>: <code>number</code>

Thickness that is passed to [`arrow()`](#m-arrow) module.

</details>


#### ⚙️sas\_cutter<a id='f-sas_cutter'></a>

<code>*function* sas_cutter(a: <a href="#t-Point2D">Point2D</a>, b: <a href="#t-Point2D">Point2D</a>, y\_thickness: number, z\_thickness: number, lat\_wave\_segs: number, lat\_wave\_cycles: number, wave\_amp: number, long\_wave\_segs: number, long\_wave\_cycles: number, cutedge\_long\_overflow: number, cutedge\_lat\_overflow: number) : <a href="#t-skin">skin</a></code>

Self aligning seam cutter aligned along edge a → b, with sinusoidal cutface.

<details><summary>parameters</summary>

**<code>a</code>**: <code><a href="#t-Point2D">Point2D</a></code>

Starting point.

**<code>b</code>**: <code><a href="#t-Point2D">Point2D</a></code>

Ending point.

**<code>y_thickness</code>**: <code>number</code>

Thickness along y-axis of cutter from cutface to handle.

**<code>z_thickness</code>**: <code>number</code>

Hight of cutting tool (z-axis).

**<code>lat_wave_segs</code>**: <code>number</code>

Number of segments to break up the wave into.

**<code>lat_wave_cycles</code>**: <code>number</code>

Number of complete wave_cycles to apply along cutting edge.

**<code>wave_amp</code>**: <code>number</code>

Amplitude of the wave on cutting edge (peek to peek).

**<code>long_wave_segs</code>**: <code>number</code>
 *(Default: `4`)*

Number of segments to break up the wave into.

**<code>long_wave_cycles</code>**: <code>number</code>
 *(Default: `0.5`)*

Number of complete wave_cycles to apply perpendicular to the cutting edge.

**<code>cutedge_long_overflow</code>**: <code>number</code>
 *(Default: `1e-4`)*

Widens the cutter by this amount
     expanding from the centre.

**<code>cutedge_lat_overflow</code>**: <code>number</code>
 *(Default: `1`)*

Lengthens the cutter by this amount (rounded to the next segment length)
expanding from the centre.

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-skin">skin</a></code>

</details>

#### ⚙️sas2\_cutter<a id='f-sas2_cutter'></a>

<code>*function* sas2_cutter(a: <a href="#t-Point2D">Point2D</a>, b: <a href="#t-Point2D">Point2D</a>, y\_thickness: number, z\_thickness: number, lat\_wall\_percent: number, lat\_wave\_cycles: number, wave\_amp: number, long\_wave\_segs: number, long\_wave\_cycles: number, cutedge\_long\_overflow: number, cutedge\_lat\_overflow: number, x\_phase\_offset: number) : <a href="#t-skin">skin</a></code>

Self aligning seam cutter 2 aligned along edge a → b, with sinusoidal cutface.

Similar to sas, but uses overlapping tabs instead of bumps that fit into
indentations.

TODO: a and b parameters are misleading.  They are only used for the length.
      Need to fix.

<details><summary>parameters</summary>

**<code>a</code>**: <code><a href="#t-Point2D">Point2D</a></code>

Starting point.

**<code>b</code>**: <code><a href="#t-Point2D">Point2D</a></code>

Ending point.

**<code>y_thickness</code>**: <code>number</code>

Thickness of cutter along y-axis from lowest part of cutface to handle.

**<code>z_thickness</code>**: <code>number</code>

hight of cutting tool (z-axis).

**<code>lat_wall_percent</code>**: <code>number</code>

     When transitioning from the each half cycle to the next point, and a
     point to each half cycle, this is % of a 1/4 cycle traveled along the
     latitude direction.  A value of 0 is a results in a "square wave".  A
     value of 1 would result in a "sawtooth wave".

     E.g.          latitude travel   Square wave           Sawtooth wave
           ___     |↔|__              ___     ___
          /   \    |/   \            |   |   |   |           /\  /\
          |    \___/     \___/|      |   |___|   |___       |  \/  \/|
          |___________________|      |_______________|      |________|

**<code>lat_wave_cycles</code>**: <code>number</code>

number of complete wave_cycles to apply along cutting edge.

**<code>wave_amp</code>**: <code>number</code>

amplitude of the wave on cutting edge (peek to peek).

**<code>long_wave_segs</code>**: <code>number</code>
 *(Default: `_ignored(4)`)*

number of segments to break up the wave into.

**<code>long_wave_cycles</code>**: <code>number</code>
 *(Default: `_ignored(0.5)`)*

number of complete wave_cycles to apply perpendicular to the cutting edge.

**<code>cutedge_long_overflow</code>**: <code>number</code>
 *(Default: `1e-4`)*

widens the cutter by this amount
     expanding from the centre.

**<code>cutedge_lat_overflow</code>**: <code>number</code>
 *(Default: `1`)*

lengthens the cutter by this amount
     (rounded to the next segment length) expanding from the centre.

**<code>x_phase_offset</code>**: <code>number</code>
 *(Default: `0`)*

     The starting phase of the a point.  Value must be ∈ [0, 360).

</details>

<details><summary>returns</summary>

**Returns**: <code><a href="#t-skin">skin</a></code>

</details>

#### ⚙️scs\_cutter<a id='f-scs_cutter'></a>

<code>*function* scs_cutter(a: <a href="#t-Point2D">Point2D</a>, b: <a href="#t-Point2D">Point2D</a>, y\_thickness: number, z\_thickness: number, lat\_wave\_segs: number, lat\_wave\_cycles: number, wave\_amp: number, long\_wave\_segs: number, long\_wave\_cycles: number, cutedge\_long\_overflow: number, cutedge\_lat\_overflow: number)</code>

Self connecting seam cutter aligned along edge a → b, with sinusoidal cutface.
INCOMPLETE!

<details><summary>parameters</summary>

**<code>a</code>**: <code><a href="#t-Point2D">Point2D</a></code>

starting point.

**<code>b</code>**: <code><a href="#t-Point2D">Point2D</a></code>

ending point.

**<code>y_thickness</code>**: <code>number</code>

y_thickness of cutter from cutface to handle.

**<code>z_thickness</code>**: <code>number</code>

hight of cutting tool (z-axis).

**<code>lat_wave_segs</code>**: <code>number</code>

number of segments to break up the wave into.

**<code>lat_wave_cycles</code>**: <code>number</code>

number of complete wave_cycles to apply
     along cutting edge.

**<code>wave_amp</code>**: <code>number</code>

amplitude of the wave on cutting edge (peek to peek).

**<code>long_wave_segs</code>**: <code>number</code>
 *(Default: `4`)*

number of segments to break up the wave into.

**<code>long_wave_cycles</code>**: <code>number</code>
 *(Default: `0.5`)*

number of complete wave_cycles to apply
     perpendicular to the cutting edge.

**<code>cutedge_long_overflow</code>**: <code>number</code>
 *(Default: `1e-4`)*

widens the cutter by this amount
     expanding from the centre.

**<code>cutedge_lat_overflow</code>**: <code>number</code>
 *(Default: `1`)*

lengthens the cutter by this amount
     (rounded to the next segment length) expanding from the centre.

</details>


