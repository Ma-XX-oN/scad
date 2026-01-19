`abc `[`def`](#ghi)`: jkl`
<code>abc [def](#ghi): jkl</code>
# OpenSCAD Standard Library (OSL) (potential)

## Purpose

OpenSCAD is a really great programming language, but it can be a bit difficult
to get a handle on.  It is a functional language, which are starting to become
more mainstream, but are somewhat difficult to understand for those coming from
the procedural language paradigm.  This library is to help with that by taking
some ideas from C++ and python and incorporating them into the current OpenSCAD
language without actually changing the language itself.

Although you could write faster specific implementations of many of these
functions, this allows an abstraction layer that makes it easier to code and
read.  From there, once you've created whatever code you want and you feel it's
not fast enough, then by all means, optimise items.  Code readability and
mantainabilty are the primary goal of this library.  Speed is secondary (though
performance was considered and it is quite fast).

> **NOTE:**
>
> Currently, to import libraries in OpenSCAD there are two methods, `use<>` and
> `include<>`.  This library uses both methods. For `*_consts` files, use the
> `include<>` idiom.  For all other files, use the `use<>` idiom.  This is
> because non-function symbols are not exported when using `use<>`, and the
> `*_consts` files only contain such symbols.

> **NOTE:**
>
> All of these files have no extension, that is by design.

### Reading the Documentation

There will be **NOTES:** scattered about to bring attention to things for the
reader.

There are also **TTA:** item which means `T`o `T`hink `A`bout, and are notes to
tell me (the library dev) that this item should have more thought brought to it.

### Signature Specifications

This library uses curried functions.  There is no clean way to document a full
curried call chain using standard JSDoc or TypeScript JSDoc today, so this
project defines a small extension.

Using the `@overload` tag, the full curried call chain is written inline, for
example:

- `@overload replace_each(a, a_birls, a_end_i) (b, b_birls, b_end_i): (string | list)`

This makes the intended usage obvious to readers and makes it straightforward to
generate the `.md` documentation with a custom tool.

This is not a standard JSDoc convention, and current editors do not provide
IntelliSense for OpenSCAD anyway, so this does not break the editing
experience.  If a future tool wanted to support it, it can be added alongside
existing `@overload` handling by only recognising this form when it matches a
strict grammar (and otherwise treating it as normal text).

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

 1. [birlei](#birlei)
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
 2. [base_algos](#base_algos)
    - The base algorithms which most of the rest of the library uses.
    - When not passed the `birlei`, the algorithm, it returns a lambda that
      only take a `birlei`.
    - When passing a `birlei`, returns a lambda that takes a `PPMRRAIR`
      function which is called over the `birlei` set.
 3. [indexable](#indexable), [indexable_consts](#indexable_consts)
    - Functions to manipulate a list or string as a stack / queue, use negative
      indices to get the indices / elements from the end, insert /
      remove / replace elements, any / all tests and additional search
      algorithms.
    - Adds a new type `SLICE` that works like python's slice, but still uses
      the closed range paradigm.  This is not indexable, but can be used with
      indexable functions that have a `birls` parameter (`s` for slice).
 4. [range](#range)
    - Wraps OpenSCAD ranges `[start:stop]`/`[start:step:stop]`, adds extra
      functionality and remove warnings when creating null ranges.  Ranges are
      considered indexable and can be dereferenced using `range_el`.
 5. [types](#types)
    - Allows for classifying object types that are beyond the standard
      `is_num`, `is_string`, `is_list`, `is_undef`, `is_function`, `is_bool` by
      adding `is_int`, `is_float` and `is_nan`.  `is_range` is defined in range
      library.
    - Enumerates object types.
    - Generates a minimal string representing the type of an object.
 6. [function](#function)
    - Allow counting of function parameters and applying an array to a function
      as parameters.
 6. [test](#test)
    - Testing modules for TDD.
 7. [transform](#transform)
    - Functions that allow transforming single points or a series of points
      quickly, usually by creating transformation matrices that can be multiplied
      against the point or points.
 8. [helpers](#helpers)
    - Miscellaneous functions that don't fit elsewhere.
 9. [skin](#skin)
    - Generates a polyhedron using slices.
10. [sas_cutter](#sas_cutter)
    - Creates a skin which is used as a cutting tool help to align two separate
      parts together.

## birlei

### Purpose

This is the core of the library's algorithm set.  It evolved from having two
indices,
`begin_i` and `end_i` so that functions could be made to recursively iterate
over them.  However, it didn't contain a step, but there was already an
object that worked for list comprehension and it worked the same way as lists
would.

However, to actually use a range or list recursively, they would have to be
indexable in a similar way, so the [range](#range) library was made.
`begin_i` would be used to count to `end_i` over the length of the object,
dereferencing each element as needed.

Keeping this in the user facing API was done because just counting from N to
M is very common, and without dereferencing a list or range marginally
faster.  It also looks cleaner.

### Iterate, Iterate, Iterate


#### `birlei_to_begin_i_end_i(algo_fn, ppmrrair_fn, birl, end_i)`

Used to centralise the logic of calling any algorithm function that requires
recursion to work (as opposed to list comprehension).  That is a function that
takes an internal function call signature `function(fn, begin_i, end_i, map_back_fn)`
and then call the [PPMRRAIR](#ppmrrair-functions) function with in it.


#### `birlei_to_indices(birl, end_i)`

Used to centralise the logic to generate a list or range that is used in list
comprehension to generate a list.


#### `birlei_verify(valid_min, valid_max, birl, end_i, raise_assertion)`

Verify that a `birlei` will always be within the valid bounds.


#### `birlei_end_i(birl, end_i, slr)`

Calculates the `end_i` if `is_num(birl)` and `is_undef(end_i)`.  Will reference
the `slr` parameter to generate it if needed.


#### `birlei(birl = 0, end_i = undef, indexable = undef)`

Returns a vector table to be able to treat all `birlei` items the same but
without having to check every time what type is the `birlei` or what type is the
`indexable`.  That would occur when using [`el()`](#elslr-i). It's powerful,
but just a little slower.  All of that info is calculated only once when calling
this function and encodes all of the correct logic to get the information as
fast as possible in the table.  This also centralises the logic, in case it's
needed for other algorithms.

To index the table, use the `BIRLEI_*()` function constants.  Functions are used
because variables are not exported.

##### `BIRLEI_LEN()` → `function() : number`
> Callback that returns the length of the `birlei`.

##### `BIRLEI_CONTIG()` → `function() : string`
> Callback that returns if `birlei` represents a contagious range.

##### `BIRLEI_STR` → `function() : string`
> Callback that returns a string representation of the `birlei`.

##### `BIRLEI_EL()` → `function(i) : number`
> Callback that will give element of `birlei`, where `0 <= i < length of birlei`.
  A negative `i` will count backwards from the end of the `birlei`.  Out of
  range index will result in undef, like when getting element from list.

##### `BIRLEI_ELS()` → `function() : (list | range)`
> Callback that will give an lr representation of the `birlei`.

##### `BIRLEI_INVOKE()` → `function(callback_fn) : any`
> Callback that takes a `callback_fn`.  This function either takes a `birlei`
  parameter set (`function(birl, end_i) : any`) or a `birlei` set with a
  dereference parameter (`function(birl, end_i, deref_fn) : any`).  The
  `deref_fn` is the same one that is being called when using `BIRLEI_DEREF()`.

##### `BIRLEI_DEREF()` → `function(i) : any`
> Callback that will dereference indexable with the indices provided by
  the birlei (not a number between `0 <= i < length of birlei`).  Asserts if
  indexable not provided.

## base_algos

### Purpose

The purpose of this library is to provide the minimum number of abstracted
composable algorithms to be able to make coding easier.  Both when reading and
writing.  They are quite fast, and although you could prolly make faster hand
rolled implementations, IMHO this makes it easier to read and rationalise as to
what's going on.  Also, the pattern used is repeated everywhere, making it
easier to learn how to use.

### FYI: Functions and Currying are Abound!

There is a lot of currying and passing of functions in this library.  (Mmmmmm
curry!)  No, not that type of curry.  Currying relates to having a function
return a function and using that function immediately.  For instance.  Say I
want to find the first instance of the letter "t" in a string.  Using this
library, the following could be done:

```
s = "Hello there!";
i = find(fwd_i(s))(function(i)
      s[i] == "t"
    );
```

Or it could be done using the algorithm adaptor `it_each`:

```
s = "Hello there!";
i = it_each(s, find())(function(c)
      c == "t"
    );
```

You'll notice the occurrence of `)(`.  This ends the algorithm or adaptor call
and start the next call which takes a function to test each an element.  Also,
observe that when the `birlei` parameter is omitted, a `function(birl, end_i)`
is returned, which in this case is `find()`.  The adaptor needs this function
signature to be passed to it so that it can apply the algorithm.

These 2 basic patterns are used everywhere in this library, and though it might
look weird at first, you'll find that it becomes natural quite quickly.

### Iterators:

The algorithms are index, not element centric, which means that a physical
container (i.e. list) is *not* needed.  A virtual container (i.e. function) is
all that is required.  The indices act as iterators as one might find in C++.

The `birl` parameter (formally `begin_i_range_or_list`, but it became too much
to type) for each of these algorithms state either:

1. Starting index (number)
   - Implies that a second `end_i` parameter will indicate the inclusive end
     index (number).  This conforms to how ranges in OpenSCAD work.
2. Indices (range)
   - Will go through each item in the range and use them as indices to pass
     to the algorithm.  `end_i` is ignored.
3. Indices (list)
   - Will go through each element in the list and use them as indices to pass
     to the algorithm.  `end_i` is ignored.

### Algorithms

There are 4 basic algorithms (`reduce`, `reduce_air`, `filter` and `map`) which
most other algorithms can be built from.  For optimisation purposes,
`reduce_air` adds the ability to Allow an Incomplete Reduction (hence the `_air`
suffix) over the range and filter adds a hybrid filter/map feature.

A few others (`find`, `find_upper`, `find_lower`) could have been implemented
with `reduce_air` but have been optimised with their own implementations.

The `find*` and `reduce*` algorithms rely on recursive descent, but conform to
TCO (Tail Call Optimisation) so don't have a maximum depth.  The `filter` and
`map` algorithms use list comprehension so also have no limit to their range
size.


#### `reduce(init, birl, end_i)`
   - Reduce (a.k.a. fold) a range of indices to some final result.
   - Pass just `init` to get a `function(birl, end_i)`.
   - This can be thought of as the equivalent to a for_each loop.
#### `reduce_air(init, birl, end_i)`
   - Reduce a range of indices to some final result.
   - Pass just `init` to get a `function(birl, end_i)`.
   - Reduce operation Allows for Incomplete Reduction, which means that it
     can abort before iterating over the entire range.
   - This can be thought of as the equivalent to a for loop.
#### `filter(birl, end_i)`
   - Create a list of indices or objects where some predicate is true.
#### `map(birl, end_i)`
   - Create a list of values/objects based on a range of indices.
#### `find(birl, end_i)`
   - Look for the first index in a range where a predicate returns true.
#### `find_lower(birl, end_i)`
   - Like C++ lower_bound: returns the first index i for which a spaceship
     predicate >= 0, or undef if none are found.
#### `find_upper(birl, end_i)`
   - Like C++ upper_bound: returns the first index i for which a spaceship
     predicate > 0, or undef if none are found.

### Algorithm Signatures

All of the algorithms have a compatible signature that have a `birlei` (one or
two parameters, a `birl` and optional `end_i`).  When you call the algorithm
without the `birlei` parameter, it returns a function that takes only a `birlei`
parameter.  This is used with the [Algorithms Adaptor](#algorithm-adaptors),
potentially simplifying your code.  When it's passed a `birlei`, it returns a
function that requires a PPMRRAIR function.  That function that is then called
by the algorithm on each index that the `birlei` refers to.

### PPMRRAIR functions

Named after the 4 function types: Predicate, Predicate/Map, Reduction and
Reduction that Allows for Incomplete Reduction, these functions are passed to
the algorithms where the algorithms then call them iteratively over each
`birlei` element:


#### `*Predicate (`function (i) : result`)*`
   - A binary predicate is used by `find`, `filter` and `map`.  It has 2
     results, truthy or falsely.
   - A trinary predicate is used with `find_lower` and `find_upper`.  It has 3
     results: less than 0, equal to 0 and greater than 0.  This is akin to the
     spaceship operator in c++20.
#### `Predicate/Map (function (i, v) : any)`
   - Optionally used by `filter`.
   - If v is not passed then it has a falsy value (`undef`) indicating that the
     function is to act like a binary predicate.  Otherwise, if passed a true
     value, then it the function usually returns the element at that index,
     though can return anything which is to be placed in the resulting list.
   - This 2 parameter function is a performance and memory allocation
     optimisation, allowing `filter` to do a `map` in the same step.
#### `Reduction (function (i, acc) : acc)`
   > **NOTE:**
   >
   > `acc` *IS THE SECOND PARAMETER* which is different from most languages.
   > This is to keep it consistent with the rest of the PPMRRAIR functions and
   > this library in general.  You have been warned.
   </p>

   - Used by `reduce`.
   - Takes in the index and the previous accumulated object and returns the
     new accumulated object.
   - This is roughly equivalent to a for_each loop in C++.
#### `Reduction, Allow Incomplete Reduction (function (i, acc) : [cont, acc])`
   <p style="margin-left: 3em; text-indent: -3em;">
   <b>NOTE</b>: <code>acc</code> <i>IS THE SECOND PARAMETER</i> which is
                different from most languages.  This is to keep it consistent
                with the rest of the PPMRRAIR functions and this library in
                general.  You have been warned.
   </p>

   - Used by `reduce_air`.
   - Takes in the index and the previous accumulated object and returns a
     list `[ cont, new_acc ]`, where `cont` states if to continue looping if not
     finished iterating over the `birlei`.
   - This is roughly equivalent to a for loop in C++.

**See also** [Algorithm Adaptors](#algorithm-adaptors).

## indexable

### Purpose

Treats all indexable objects similarly.  As a group, they are referred to as
`slr`s (string, list or range). Any function that can take a indexable reference
and a `birlei` can have the `birlei` partially or completely omitted (assumes
start and end indices of indexable elements) or can use negative indices to
specify backward indexing from the end for either `begin_i` or `end_i`
positions.

### Slices

A slice is an object similar to a range, but it's not a realised indexable
object until it is paired with an slr.

### Optimisations

Because an index needs to be checked if it's negative and then adjusted based on
the `birlei` type, and since checking that type can be "expensive" (there are up
to 3 checks that need to be done).  Also, getting elements and indices require
functions that may need to call functions to do their work.  All of this can add
up over many iterations.

Also, there in the introduction of a `slice` type which is a specification of
relative slr ranging.

To reduce this overhead, and to allow `slice`s to work over the entire indexable
library, an slr_cache object is used once and can be used many times in sub
calls.


### Algorithm Adaptors

The PPMRRAIR functions usually passed an integer to it's first parameter,
referring to the current index.  For convenience, there are adaptor functions
which allow referencing a slr's (string, list or range) structure/element
values.
  - `it_each`: passes slr element.
  - `it_enum`: passes [index, slr element].
  - `it_idxs`: passes index.
Using these adaptors will allow use the length of the slr as reference if the
`birlei` is partially or fully omitted.  Negative values are also allowed to
reference indices starting from the end of the slr, going backwards.  These
values are converted to positive values prior to processing.

Without adapter usage:
```
a = [1,2,3,4,5]
even_indices = filter(fwd_i(a))(function(i) a[i] % 2);
even_values  = filter(fwd_i(a))(function(i, v) v ? a[i] : a[i] % 2);
```


#### `it_each(slr, algo_fn, birl=0, end_i = -1, is_norm, slr_te)`

Usage:
```
a = [1,2,3,4,5]
even_indices = it_each(a, filter())(function(e) e % 2); // e for element
even_values  = it_each(a, filter())(function(e, v) v ? e : e % 2);
```


#### `it_idxs(slr, algo_fn, birl = 0, end_i = -1, is_norm, slr_te)`

Usage:
```
a = [1,2,3,4,5]
even_indices = it_enum(a, filter())(function(p) p[0] % 2); // p for pair
even_values  = it_enum(a, filter())(function(p, v) v ? p[1] : p[0] % 2);
```


#### `it_enum(slr, algo_fn, birl = 0, end_i = -1, is_norm, slr_te)`

Usage:
```
a = [1,2,3,4,5]
even_indices = it_idxs(a, filter())(function(i) a[i] % 2); // i for index
even_values  = it_idxs(a, filter())(function(i, v) v ? a[i] : a[i] % 2);
```


### Treat All Indexables the Same


#### `idx(slr, i)`

Gets the index.  If `i` is positive, returns no change, but if negative then
return a positive index equivalent to `len(slr) - i` or in the case of a range,
`range_len(slr) - i`.  If `i <= -slr_len || slr_len <= i`, then the result
will still be out of bounds.

**NOTE:**  Considering changing this to `idx` instead.


#### `el(slr, i)`

Gets the *`idx(slr, i)`th* element from the slr.

**NOTE:**  Considering changing this to `el` instead.


#### `idxs(slr, birl = 0, end_i = -1, is_norm = NORM(), slr_te)`

Gets a list of indices as specified by the `birlei`.

**NOTE:**  Considering changing this to `idxs` instead.


#### `els(slr, birl = 0, end_i = -1, is_norm = NORM(), slr_te)`

Gets the elements from the `slr` using the indices specified by the `birlei`.
If the `slr` is a string, it remains a string.  If it's a range, then it's
converted to a list.  A list stays as a list.

**NOTE:**  Considering changing this to `els` instead.


#### `next_in(slr, i, inc = 1, wrap_to_0 = false)`

Goes to the next index in the `slr`.  If `i + inc > slr_len`, then if
`wrap_to_0` is `true`, then the result is `0`.  If `false` then wraps modulo
`slr_len`.

`inc` must be positive.


#### `prev_in(sl, i, dec = 1, wrap_to_last = false)`

Goes to the previous index in the `slr`.  If `i - dec < 0`, then if
`wrap_to_last` is `true`, then the result is `idx(slr, -1)`.  If `false` then
wraps to positive modulo `slr_len`.

`dec` must be positive.

Example:
```
assert(prev_in([1,2,3,4], 0, 2) == 2)
assert(prev_in([1,2,3,4], 0, 6) == 2)
```


#### `fwd_i(slr, start_offset = 0, end_offset = 0)`

Returns a range that iterates forward over the `slr`. `start_offset` is usually
greater or equal to `0` and `end_offset` is usually less or equal to `0`.

If you pass something other than that, then it's assumed you know what you are
doing as doing so will give indices that wouldn't be valid for the given `slr`.

YOU'VE BEEN WARNED!


#### `rev_i(slr, start_offset = 0, end_offset = 0)`

Returns a range that iterates forward over the `slr`. `start_offset` is usually
less or equal to `0` and `end_offset` is usually greater or equal to `0`.

If you pass something other than that, then it's assumed you know what you are
doing as doing so will give indices that wouldn't be valid for the given `slr`.

YOU'VE BEEN WARNED!


#### `slr_len(slr)`

Returns the length of the `slr`.  I.e. the number of times it would have been
iterated over in a `for` loop.


#### `slice(slr, begin_i, end_i)`

Generates a slice of a string, list or range, maintaining its type, unlike
[els()](#elsslr-birl--0-end_i--el_idxslr--1) which would convert a range into
a list.

### Treat Strings and Lists the Same


#### `insert(sl, i, es)`

Inserts the elements (list) into the `sl` (string or list) at position i (where
`0 <= i <= len(sl)`).


#### `remove(sl, begin_i, end_i)`

Removes a consecutive number of elements between `begin_i` -  `end_i` inclusive,
from `sl`.


#### `remove_each(sl, birl = 0, end_i = idx(sl, -1))`

Removes each element that is referenced in the `birlei`.


#### `replace(a, a_begin_i, a_end_i, b, b_birl = 0, b_end_i = idx(b, -1))`

Replaces elements in `a` (sl) between `a_begin_i` - `a_end_i` inclusive, with
each element referenced in `b`'s `birlei`.


#### `replace_each(a, a_birl = 0, a_end_i = idx(a, -1))(b, b_birl = 0, b_end_i = idx(b, -1))`

Replaces each element in `a` as indexed by `a`'s `birlei` with each element in
`b` as indexed by `b`'s `birlei`.

- **NOTE** This is curried between the `a` and `b` parts.
- **NOTE** Both `birlei`s must be the same length.


#### `swap(sl, begin_i1, end_i1, begin_i2, end_i2)`

Swaps contiguous ranges `begin_i1` - `end_i1` with `begin_i2` - `end_i2` from
`sl` leaving the rest untouched.


#### `rotate_sl(sl, i)`

Swaps elements in `sl` from `[ i : idx(sl, -1) ]` with `[ 0, i - 1 ]`.

### Treat List and String as a Stack


#### `push(sl, es)`

Pushes elements `es` (string | list) onto end of `sl`, returning the new `sl`.


#### `pop(sl, i)`

Removes `i` elements from the end of `sl`, returning the new `sl`.


#### `head(sl)`

Gets the element from the end of `sl`.


#### `head_multi(sl, i)`

Gets `i` elements from the end of `sl`.

### Treat List and String as Queue (unshift / shift)


#### `unshift(sl, es)`

Unshifts (adds) elements `es` into the beginning of `sl`.


#### `shift(sl, i=1)`

Shifts (removes) `i` elements from the beginning of `sl`.


#### `tail(sl)`

Gets the element at the beginning of `sl`.


#### `tail_multi(sl, i)`

Gets `i` elements at the beginning of `sl`.

## range

### Purpose

A range is a structure that can be iterated over, like one can do with a list.
However, unlike in python, it doesn't have the ability to be dereferenced or
interrogate it for it's length.  Also, there is a feature which prevents a
preventing having values starting after the result without generating a warning.
As such, this library is to help with those deficiencies.

### Treat Range More Like a First Class Indexable Object


#### `range(begin_i, end_i)` or `range(begin_i, step, end_i)`

Creates a range object but when `begin_i > end_i` don't generate a warning.
Create an empty list instead.  Do the same if `begin_i < end_i` with step being
negative.


#### `is_range(o)`

Tests to see if object `o` is a range object or not.


#### `range_len(r)`

Gets the length of the range `r`.


#### `range_el(r, i)`

Gets an element from the range `r` at index `i`.


#### `range_idx(r, i)`

Gets the index.  If `i` is positive, returns no change, but if negative then
return a positive index equivalent to `range_len(r) - i`.  If
`i <= -slr_len || slr_len <= i`, then the result will still be out of bounds.

## types

### Purpose

Sometimes it is useful to give a type a numeric value.  Also, some types can
only be determined by doing several tests to see what it's not like with a
range.  How about printing out what the type is without having to write your
function, or minimize a type making it easier to read.  This library has it all.

### Type Introspection


#### `type_enum(o, distinguish_float_from_int = false)`

Assigns an object `o` a numeric value.  Optionally can distinguish a `float` from
an `int` (kinda).  Basically checks if there is any fractional part.  So `0.0` is
still `0` and will be though of as an `int`, not a `float`.

##### `UNKNOWN`
> Enum for unknown type

##### `UNDEF`
> Enum for undef type

##### `BOOL`
> Enum for boolean type

##### `FUNC`
> Enum for function type

##### `NUM`
> Enum for number type

##### `INT`
> Enum for integer type

##### `FLOAT`
> Enum for floating point type

##### `NAN`
> Enum for NaN

##### `RANGE`
> Enum for range type

##### `STR`
> Enum for string type

##### `LIST`
> Enum for list type


#### `is_indexable_te(type_enum)`

Test to see if the type given by
[`type_enum()`](#type_enumo-distinguish_float_from_int--false) is a type which
can be indexed, such as a string, list or range.


#### `is_indexable_non_range_te(type_enum)`

DEPRECATED!

Test to see if the type given by
[`type_enum()`](#type_enumo-distinguish_float_from_int--false) is a type which
can be indexed but isn't a range.

#### `is_int(o)`

Checks to see if `o` is a number that doesn't have a fractional part.


#### `is_float(o)`

Checks to see if `o` is a number that does have a fractional part.


#### `is_nan(n)`

Checks to see if `o` doesn't equal itself.


#### `slr_etto_str(i)`

Converts a type enum to a string representation.


#### `type(o, distinguish_float_from_int = false)`

Gets the type of `o` as a string.


#### `type_structure(o)`

Creates a string that states the structure of a type.  If there are repeated
parts, then don't repeat them, just say that they do.


#### `type_value(o)`

Creates a string that outputs the type and value.

## function

### Purpose

Sometimes it's useful to know something basic about the function in hand so that
the code knows what it can and can't do.  This library fills that need.

### Function Introspection


#### `param_count(fn)`

Count the number of parameters that `fn` can take.


#### `apply_to_fn(fn, p)`

Calls function `fn` as if the elements in list `p` are used as parameters.  Can
take up to 16 parameters at this time.  Overkill?

## test

### Purpose

Used to generate code for using TDD methodology.  Tries to report useful error
messages with an optional user configurable message useful.

### Test Your Code!


#### `test_eq(expected, got, msg="")`

Tests if `expected` is equal to `got`.


#### `test_approx_eq(expected, got, epsilon, msg="")`

Tests if `expected` is approx equal to `got` within epsilon.


#### `test_ne(not_expected, got, msg="")`

Tests if `not_expected` is not equal to `got`.


#### `test_lt(lhs, rhs, msg="")`

Tests if `lhs < rhs`.


#### `test_le(lhs, rhs, msg="")`

Tests if `lhs ≤ rhs`.


#### `test_gt(lhs, rhs, msg="")`

Tests if `lhs > rhs`.


#### `test_ge(lhs, rhs, msg="")`

Tests if `lhs ≥ rhs`.


#### `test_truthy(val, msg="")`

Tests if `val` is a truthy value


#### `test_falsy(val, msg="")`

Tests if `val` is a falsy value

## transform

### Purpose

This library is for doing transformations on a point or set of points.

### Homogenisation

When doing certain matrix transformations, adding an additional dimension may be
required.  A homogeneous point can only be multiplied by a homogeneous
transformation matrix.


#### `homogenise(pts, n=4)`

Make pts homogenous.  If a point's dimension is less than n-1, then zeros are
appended before adding a 1 to the end.


#### `dehomogenise(pts, n=3)`

Remove homogenous dimension.  If a point's dimension - 1 is greater than n,
then the extra dimensions are truncated.  All coordinates are divided by
the homogeneous dimension.


#### `homogenise_transform(A, n=4)`

Takes a non-homogeneous transformation matrix and convert it into a
homogeneous one.


### Matrix Math

This deals with all the matrix maths.


#### `transpose(A)`

Transpose of a vector or matrix.

- Row vector [x,y,z] → column vector [[x],[y],[z]]
- Column vector [[x],[y],[z]] → row vector [x,y,z]
- Matrix (list of equal-length rows) → transposed matrix


#### `invert(A, eps = 1e-12)`

Inverts a square matrix using Gauss-Jordan elimination with
partial pivoting.


#### `row_reduction(aug, k, n, eps)`

Performs Gauss-Jordan row reduction with partial pivoting on an
augmented matrix.


#### `identity(n)`

Creates an n×n identity matrix.


#### `augment(A, B)`

Horizontally concatenates two matrices with the same row count.


### Matrix Math Helpers


#### `_right_half(aug, n)`

Extracts the right half (columns n..2n-1) of an n×(2n) augmented matrix.


#### `_swap_rows(M, i, j)`

Returns a copy of matrix M with rows i and j swapped.


#### `_argmax_abs_col(aug, col, start)`

Finds the row index r ∈ [start..n-1] that maximizes |aug[r][col]|.
Ties resolve to the first occurrence.


#### `_is_rect_matrix(M)`

Tests whether M is a rectangular list-of-lists with consistent row length.
Returns a boolean.


#### `_is_square_matrix(M)`

Tests whether M is a square matrix (rectangular and rows == columns).
Returns a boolean.


#### `_all_numeric(M)`

Tests whether all entries of M are numeric.  Returns a boolean.


### Main Transformation Matrix Generators

Functions that generate transformation matrices which parallel's the modules of
the same name.


#### `rotate(a, b=undef)`

Rotate matrix that parallel's module rotate.

**NOTE:** Arguably, I think this should be the only rotate function that should
          be exposed.


#### `translate(v)`

Translation matrix that parallel's module translate.

**NOTE:** Generated matrix is homogeneous.


#### `scale(v)`

Scale matrix that parallel's module scale.


### Transformation Matrix Generator Helpers

Functions that generate transformation matrices.  These deal with rotate, broken
down into smaller parts of what rotate can do.


#### `rot_x(a)`

Builds a 3×3 rotation matrix for a rotation about the X axis.

The matrix is intended for post-multiplying 3D row vectors:
new_p = old_p * rot_x(a).


#### `rot_y(a)`

Builds a 3×3 rotation matrix for a rotation about the Y axis.

The matrix is intended for post-multiplying 3D row vectors:
new_p = old_p * rot_y(a).


#### `rot_z(a)`

Builds a 3×3 rotation matrix for a rotation about the Z axis.

The matrix is intended for post-multiplying 3D row vectors:
new_p = old_p * rot_z(a).


#### `rot_axis(angle, axis)`

Builds a 3×3 rotation matrix for an arbitrary axis-angle rotation.

The axis is normalised internally and the matrix is intended for
post-multiplying 3D row vectors: new_p = old_p * rot_axis(angle, axis).


### Transformation Helpers


#### `transform(pts, matrix_or_fn)`

Transforms a set of points with a matrix, or function that takes a point.


#### `offset_angle(ref_vec, vec, delta_angle_deg)`

This will move vec so that the angle between ref_vec and vec will increase by
delta_angle_deg.


#### `reorient(start_line_seg, end_line_seg, scale_to_vectors)`

Create a homogeneous transform that maps one segment/frame to another.



## helpers

### Purpose

Miscellaneous helper functions.


### Conversions

Conversion functions.


#### `r2d(radians)`

Convert radians to degrees.


#### `d2r(degrees)`

Convert degrees to radians.


### Circular / Spherical Calculations

#### `arc_len(A, B, R=undef)`

Calculates the arc length between vectors A and B for a circle/sphere of
radius R.  If A and B are the same magnitude, R can be omitted.


#### `arc_len_angle(arc_len, radius)`

Given the length of an arc and the radius of a circle/sphere that it's
traversing, returns the angle traversed in degrees.

`arc_len` and `radius` have the same units.


#### `arc_len_for_shift(R, m, a, b = 0)`

Given a `circle R = sqrt(x^2 + y^2)` and a line `y = m*x + (b + a)`,
compute the arc-length difference `Δs` along the circle between the
intersection of the original line `y = m*x + b` and the shifted line
`y = m*x + (b + a)`. Only the right-side `(x >= 0)` intersection is tracked.


#### `shift_for_arc_len(R, m, delta_s, b = 0)`

Given a circle `R = sqrt(x^2 + y^2)` and line `y = m*x + b`, compute the
vertical (y-axis) shift values a that would produce a specified arc-length
difference `Δs` between the original intersection and the shifted line
`y = m*x + (b + a)`, tracking only the right-side `(x >= 0)` intersection.

### Miscellaneous

#### `not(not_fn)`

Wrap a lambda so that it negates its return value.


#### `clamp(v, lo, hi)`

Clamps a value between [lo, hi].


#### `vector_info(a, b)`

Computes direction, length, unit vector and normal to unit vector, and puts
them into an list.  List can be indexed with the following constant functions.
Functions are used because variables are not exported.

#### `VI_VECTOR()` → `2D-point`
> Index of direction of ab.

#### `VI_LENGTH()` → `number`
> Index of length of ab.

#### `VI_DIR()` → `2D-point`
> Index of unit ab vector.

#### `VI_NORMAL()` → `2D-point`
> Index of normal unit vector of ab.


#### `equal(v1, v2, epsilon = 1e-6)`

Checks the equality of two items.  If v1 and v2 are lists of the same length,
then check the equality of each element.  If each are numbers, then check to
see if they are both equal to each other within an error of epsilon.  All
other types are done using the == operator.


#### `function_equal()`

Hoists function into variable namespace to be able to be passed as a lambda.


#### `default(v, d)`

If v is undefined, then return the default value d.


#### `INCOMPLETE(x=undef)`

Used to mark code as incomplete.

#### `fl(f, l)`

File line function to output something that looks like a file line to be able
to jump to the file/line in VSCode easier.

To make it easier in a file, create the following variable in that file:

    _fl = function(l) fl("openscad-script-name.scad", l);

As a variable, it won't get exported when imported using `use<>`.  Then use
`_fl` in your file.  E.g.

    echo(str("Here's your problem", _fl(3)));

Output:

    ECHO: "Here's your problem in file openscad-script-name.scad, line 3
    "



To update a file's line numbers, you can use this one (long) line shell script:

    f="openscad-script-name.scad" && \
      b=$(basename -- "$f" .scad) && \
      awk '{ gsub(/_fl\([0-9]+\)/, "_fl(" NR ")"); print }' "$f" > "$b.tmp" && \
      mv "$b.tmp" "$f" && \
      echo "Update to $f succeeded" || \
      echo "Failed to update $f"

#### `_assert(truth, msg = "")`

Asserts that truth is true, where msg could be a lambda taking 0 parameters.
This can be placed within an expression by adding after it a value within
parentheses.

This is a work around to keep expensive operations from executing when
generating a message.

Example:
```
a = 5 * 
    _assert(dependent > 0, function() some_expensive_msg_generator())
    (3)
// a now equals 15
```

#### `interpolated_values(p0, p1, number_of_values)`

Gets a list of `number_of_values` between `p0` and `p1`.


### Modules

#### `arrow(l, t=1, c, a)`

Create an arrow pointing up in the positive z direction.  Primarily used for
debugging.

#### `module axis(l, t=1)`

Create 3 arrows aligning to x, y and z axis coloured red, green and blue
respectively.


## csearch

### Purpose

A bit more comprehensive search function.

#### `csearch(haystack, needle, birl=0, end_i=undef, equal = function(a, b) a == b)`

Searches for a contiguous set of elements `needle` in `haystack` in the `birlei`
specified.  Similar to built-in `search()` function, but allows specifying
the index range to search and exposes `equal()` operator to allow for non-exact
matches.


## skin

### Purpose

The built in extrude module isn't powerful or flexible enough so this library
was made.  It creates a skin by making layers of polygons with the same number
of vertices and then skins them by putting faces between layers.


### Design

This requires keeping track of a bunch of data, which was put into a list.  To
distinguish this list from others, a header was added.

Each element in the list has a symbol name index:

#### `SKIN_ID()` → string
> This id is located always at index 0.

#### `SKIN_PTS_IN_LAYER()` → `list[point]`
> Index for points in layer

#### `SKIN_LAYERS()` → `number`
> Index for # of point layers - 1

#### `SKIN_PTS()` → `number`
> Index for the list of points

#### `SKIN_DEBUG_AXES()` → `...`
> Index for debug axes

#### `SKIN_COMMENT()` → `string`
> Index for the comment if any

#### `SKIN_OPERATION()` → `string`
> Index for the operation ([op, apply_to_next_count])

#### `SKIN_WALL_DIAG()` → `list[bool]`
> Index for wall diagonal info


### Main API

#### `is_skin(obj)`

Checks to see if object is a skin object


#### `skin_new(pt_count_per_layer, layers, pts3d, comment, operation, wall_diagonal, debug_axes)`

Create a new skin object.


#### `skin_extrude(pts_fn, birl, end_i, comment, operation, wall_diagonal, debug_axes)`

Generates an extruded point list from a number range, range or list of
indices.


#### `skin_create_faces(obj)`

Generates face layer_i to skin a layered structure, including:
  - bottom cap (layer 0)
  - top cap (layer = layers)
  - side wall faces between adjacent layers

Assumes that points are stored in a flat array, with `pts_in_layer`
points per layer, and layers stored consecutively. Points within each
layer must be ordered clockwise when looking into the object.


#### `skin_transform(obj_or_objs, matrix_or_fn)`

Performs a transformation on the points stored in the skin object.


#### `module skin_to_polyhedron(obj_or_objs) `

Takes the skin object and make it into a polyhedron.  If obj is a list, will
assume all are skin objects and attempt to skin them all.


#### `skin_add_layer_if(obj, add_layers_fn)`

Adds a number of interpolated layers between layers based how many
add_layers_fn(i) returns.


### API Incomplete

#### `interpolate(v0, v1, v)`

Interpolates value between v0 and v1?


#### `skin_limit(obj, extract_order_value_fn, begin, end)`

INCOMPLETE!
Truncates the beginning, end or both of the extrusion.


#### `skin_max_layer_distance_fn(obj, max_diff, diff_fn = function(p0, p1) p1.x - p0.x)`

Returns a function that can be used with skin_add_layer_if() to ensure that
the distance between layers don't exceed some length.


### Debug Helpers

#### `skin_to_string(obj, only_first_and_last_layers = true, precision = 4)`

Converts a skin object to a human readable string.


#### `skin_verify(obj, disp_all_pts = false)`

For debugging, returns a string reporting the stats of a skin object.

Asserts if the object's number of points doesn't correspond to the equation:

  `(layers - 1) * pts_in_layer`


### Layer Helpers

#### `layer_pt(pts_in_layer, pt_i, layer)`

Computes the linear index of a point in a layered point array.

This allows to more easily visualise what points are being referenced,
relative to different layers.

Assumes that points are stored consecutively per layer, and layers are
stacked consecutively in memory.


#### `layer_pts(pts_in_layer, pt_offset_and_layer_list)`

Computes a list of linear layer_i for multiple points in a layered point
array.

This allows to more easily visualise what points are being referenced,
relative to different layers.

Assumes points are stored consecutively per layer, with each layer laid out
sequentially.


#### `layer_side_faces(pts_in_layer, layers = 1, wall_diagonal = [0, 1])`

Helper to generate side wall faces between consecutive layers.

Assumes the points are arranged in a flat list, with each layer's points
stored contiguously, and layers stored in sequence. Points within each
layer must be ordered **clockwise when looking into the object**.

Each wall segment is formed from two triangles connecting corresponding
points between adjacent layers.


### Experimental Code For End Capping

#### `triangulate_planar_polygon(pts3d)`

Triangulates a simple, planar, CW-wound polygon in 3D space.
Projects the polygon to the XY plane and applies convex-only ear clipping.


#### `triangulate_loop(pts, idxs, acc)`

Recursively performs convex-only ear clipping. TODO: INCOMPLETE


#### `find_ear(pts, idxs)`

Finds and returns the first convex "ear" from a list of point layer_i in a polygon.

Assumes:
- Points are in clockwise order when looking into the polygon.
- The polygon lies in the XY plane.

Returns a list [iA, iB, iC, i], where A-B-C form a convex ear and `i` is the index
into the idxs list of the middle point `B`. Returns `undef` if no ear is found.

#### `rotation_matrix(from, to)`

Returns a rotation matrix to align `from` to `to` (both 3D).
Uses Rodrigues' rotation formula.


#### `VERTEX_CONVEX()` → 
> vertex is convex

#### `VERTEX_CONCAVE()` → 
> vertex is concave

#### `VERTEX_COLINEAR()` → 
> vertex is colinear


#### `_cap_ears(pt_is, create_ears_fn, _ears = undef, _i = 0, _faces = [])`

Caps the end of a face by making all ears into faces until none left.

Parameters staring with _ will not be set by the external caller.


#### `_cap_ears(pt_is, convexity_fn, _i = 0, _faces = [])`

Caps the end of a face by making all ears into faces until none left.

Parameters staring with _ will not be set by the external caller.


#### `proj_pt(pt, dim_i)`

Project point to axis that is not `dim_i`.  E.g. `dim_i == 0` implies
project to YZ axis or stated another way, project along `dim_i`.


#### `proj_pts(pts, dim_i)`

Project all points to axis that is not `dim_i`.  E.g. `dim_i == 0` implies
project to YZ axis or stated another way, project along `dim_i`.


#### `proj_to_what_norm(pts, dim_i = 0, last_n = [0,0,0], last_n_len = 0, last_i = -1)`

Determine which projection give the largest normal vector.


#### `flip_faces(faces)`

Creates a list of faces that has their normal pointing the opposite direction
of the faces passed in.


#### `cap_layers(pts_in_layer, pts3d, layers = 1)`

Generates triangulated faces to cap the first and last point layers.

Assumes `pts3d` is a flat list of points arranged in contiguous layers,
each containing `pts_in_layer` points. There must be `layers + 1` total
point layers. The polygon formed by each cap must be planar and ordered
clockwise when looking into the object.

Cap faces are generated by applying triangulate_planar_polygon()
to each cap independently. The first cap uses points from layer 0,
and the last cap uses points from the final layer.


#### `module skin_show_debug_axes(obj, styles = [["red", 1, .1], ["green"], ["blue"]])`

UNTESTED!
Shows the debug axes to verify where you think things should be.


## sas_cutter


### TL;DR
Due to how OpenSCAD works where `include<>` is not guarded to only include a
file once and `use<>` does guard but doesn't evaluate and export top level
assignments, and due to no simple way to get the function without the library
user having to write an intermediate functions, I've generated intermediate
functions to help the library user for most public facing library functions
that I feel need it. These functions are defined as `function_<name>()`
which is similar to the suggestion I gave in issue
https://github.com/openscad/openscad/issues/6182 which would look like
`function <name>`, though if implemented, may reduce the need for an
intermediate call.

## birlei

### Purpose

This is the core of the library's algorithm set.  It evolved from having two
indices,
`begin_i` and `end_i` so that functions could be made to recursively iterate
over them.  However, it didn't contain a step, but there was already an
object that worked for list comprehension and it worked the same way as lists
would.

However, to actually use a range or list recursively, they would have to be
indexable in a similar way, so the [range](#range) library was made.
`begin_i` would be used to count to `end_i` over the length of the object,
dereferencing each element as needed.

Keeping this in the user facing API was done because just counting from N to
M is very common, and without dereferencing a list or range it's marginally
faster.

#### **birlei_to_begin_i_end_i**
`function birlei_to_begin_i_end_i(algo_fn, ppmrrair_fn, birl, end_i)`

**Overloads:**

    birlei_to_begin_i_end_i(algo_fn, ppmrrair_fn, begin_i, end_i) : any
    birlei_to_begin_i_end_i(algo_fn, ppmrrair_fn, range_is) : any
    birlei_to_begin_i_end_i(algo_fn, ppmrrair_fn, list_is) : any

Helper which calls `algo_fn` but remaps signature `function(fn, birl, end_i)`
to signature `function(fn, begin_i, end_i, map_back_fn)`.

<details><summary>parameters and return info</summary>

##### `algo_fn` (`function (fn, begin_i, end_i, map_back_fn) : any`)
Function with `(fn, begin_i, end_i, map_back_fn)` signature to call, where:
  - `fn` (`number`)
    ppmrrair function to call.
  - `begin_i` (`number`)
    Starting index to operate on.
  - `end_i` (`number | undef`)
    Ending index to operate on.
  - `map_back_fn` (`function(i) : (number | undef)`)
    If returning an index, pass the index retrieved by algorithm
    to get actual index as it may have been remapped with a range or list.
    `i` can be a number or undef



##### `ppmrrair_fn` (`function (i) : any | function (i, o) : any`)
- Takes index or element and possibly a second param and returns a value.


##### `birl` (`number | range | list`)
- If number, start index to check
- If range, indices to check
- If list, indices to check


##### `begin_i` (`number`)
- Start index to check.


##### `end_i` (`number | undef`)
- If `birl` is a number, then end index to check.  end_i could be less than
  birl if there's nothing to iterate over, but would have to be handled by
  algo_fn.  Ignored If `birl` is not a number.


##### `range_is` (`range`)
- Range of indices to check.


##### `list_is` (`list`)
- List of indices to check.


##### Returns (`any`)

Result of `algo_fn()`.

</details><hr/>

#### **birlei_to_indices**
`function birlei_to_indices(birl, end_i)`

Helper to convert birlei parameters to an lr to traverse.

<details><summary>parameters and return info</summary>

##### `birl` (`number | range | list`)
- If number, start index to check
- If range, indices to check
- If list, indices to check


##### `end_i` (`number | undef`)
- If `birl` is a number, end index to check.  If end_i is less than birl,
  then returns an empty list.


##### Returns (`list | range`)

Returns a list or range describing the indices to traverse.

</details><hr/>


## base_algos

### Purpose

The purpose of this library is to provide the minimum number of abstracted
composable algorithms to be able to make coding easier, both when reading and
writing.  They are quite fast, and although you could prolly make faster hand
rolled implementations, IMHO this makes it easier to read and rationalise as
to intent.  Also, the pattern used is repeated everywhere, making it easier
to learn how to use.

### FYI: Functions and Currying are Abound!

There is a lot of currying and passing of functions in this library.  (Mmmmmm
curry!)  No, not that type of curry.  Currying relates to having a function
return a function and using that function immediately.  For instance.  Say I
want to find the first instance of the letter "t" in a string.  Using this
library, the following could be done:

```
s = "Hello there!";
i = find(fwd_i(s))(function(i)
      s[i] == "t"
    );
```

Or it could be done using the algorithm adaptor `it_each` (See
[Algorithm Adaptors](#algorithm-adaptors)):

```
s = "Hello there!";
i = it_each(s, find())(function(c)
      c == "t"
    );
```

You'll notice the occurrence of `)(`.  This ends the algorithm or adaptor
call and start the next call which takes a function to test each element.
Also, observe that when the algorithm's `birlei` parameter is omitted, a
`function(birl, end_i)` is returned, which in this case is `find()`.  The
adaptor needs this function signature to be passed to it so that it can apply
the algorithm while passing the element to the `PPMRRAIR` function.

These 2 basic patterns are used everywhere in the library set, and though it
might look odd at first, you'll find that it becomes natural quite quickly.

### Iterators:

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

### Algorithms

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

> TTA:
>
> Should reduce_air's `init` param be `[ start, init ]` instead?  This would
> allow it to do nothing without the need for a special ternary check
> preceding it.
>
> A: I've yet not seen a good reason to do this.

### Algorithm Signatures

All of the algorithms have a compatible signature that have a `birlei` (one
or two parameters, a `birl` and optional `end_i`).  When you call the
algorithm without the `birlei` parameter, it returns a function that takes
only a `birlei` parameter.  This is used with the
[Algorithms Adaptor](#algorithm-adaptors), potentially simplifying your code.
When it's passed a `birlei`, it returns a function that requires a PPMRRAIR
function.  That function that is then called by the algorithm on each index
that the `birlei` refers to.

### PPMRRAIR functions

Named after the 4 function types: `P`redicate, `P`redicate/`M`ap, `R`eduction
and `R`eduction that `A`llows for `I`ncomplete `R`eduction, these functions
are passed to the algorithms where the algorithms then call them iteratively
over each `birlei` element:

#### **Predicate** (`function (i) : result`)

- A binary predicate is used by `find`, `filter` and `map`.  It has 2
  results, truthy or falsely.
- A trinary predicate is used with `find_lower` and `find_upper`.  It has 3
  results: less than 0, equal to 0 and greater than 0.  This is akin to the
  spaceship operator in c++20.

#### **Predicate/Map** (`function (i, v) : any`)

- Optionally used by `filter`.
- If v is not passed then it has a falsy value (`undef`) indicating that the
  function is to act like a binary predicate.  Otherwise, if passed a true
  value, then it the function usually returns the element at that index,
  though can return anything which is to be placed in the resulting list.
- This 2 parameter function is a performance and memory allocation
  optimisation, allowing `filter` to do a `map` in the same step.

#### **Reduction** (`function (i, acc) : acc`)

> NOTE:
>
> `acc` **is the second parameter** which is different from most languages.
> This is to keep it consistent with the rest of the `PPMRRAIR` functions
> and this library in general.  You have been warned.

- Used by `reduce`.
- Takes in the index and the previous accumulated object and returns the
  new accumulated object.
- This is roughly equivalent to a for_each loop in C++.

#### **Reduction, Allow Incomplete Reduction** (`function (i, acc) : [cont, acc]`)

> NOTE:
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

#### **find_lower**
`function find_lower(birl, end_i)`

**Overloads:**

    find_lower(begin_i, end_i)    (spaceship_fn) : (number | undef)
    find_lower(range_is)          (spaceship_fn) : (number | undef)
    find_lower(list_is)           (spaceship_fn) : (number | undef)
    find_lower() (begin_i, end_i) (spaceship_fn) : (number | undef)
    find_lower() (range_is)       (spaceship_fn) : (number | undef)
    find_lower() (list_is)        (spaceship_fn) : (number | undef)

Like C++'s `lower_bound`: returns the first index `i` for which
`spaceship_fn(i) >= 0`.

> **NOTE:**
>
> The specified `birlei` of indices must be such that `spaceship_fn(i)`
> is monotonically nondecreasing over the searched indices; or the results
> are UB.

<details><summary>parameters and return info</summary>

##### `spaceship_fn` (`function(i) : number`)
This is a trinary predicate where if the element `i` is:
- *less than* the searched value, then it would return a value *less than*
  `0`.
- *equal* to the searched value, then it would return a value *equal* to
  `0`.
- *greater than* the searched value, then it would return a value *greater
  than* `0`.


##### `birl` (`number | range | list`)
- If `number`, start index to iterate over
- If `range`, indices to iterate over
- If `list`, indices to iterate over


##### `begin_i` (`number`)
- Start index to iterate over.


##### `end_i` (`number | undef`)
- If `birl` is a number, then this is the end index to iterate over.
  - If `end_i < birl` then `spaceship_fn` is never called, making this
    function return `undef`.


##### `range_is` (`range`)
- Range of indices to iterate over.


##### `list_is` (`list`)
- List of indices to iterate over.


##### Returns (`number | undef`)

First index where `spaceship_fn(i) ≥ 0`.  If none are found, returns
`undef`.

> **NOTE:**
>
> The reason for returning `undef` rather than `end_i+1`, is because `birl`
> could be a noncontiguous `range` or `list` of indices.

</details><hr/>

#### **find_upper**
`function find_upper(birl, end_i)`

**Overloads:**

    find_upper(begin_i, end_i)    (spaceship_fn) : (number | undef)
    find_upper(range_is)          (spaceship_fn) : (number | undef)
    find_upper(list_is)           (spaceship_fn) : (number | undef)
    find_upper() (begin_i, end_i) (spaceship_fn) : (number | undef)
    find_upper() (range_is)       (spaceship_fn) : (number | undef)
    find_upper() (list_is)        (spaceship_fn) : (number | undef)

Like C++'s `upper_bound`: returns the first index `i` for which
`spaceship_fn(i) > 0`.

> **NOTE:**
>
> The specified `birlei` of indices must be such that `spaceship_fn(i)`
> is monotonically nondecreasing over the searched indices; or the results
> are UB.

<details><summary>parameters and return info</summary>

##### `spaceship_fn` (`function(i) : number`)
This is a trinary predicate where if the element `i` is:
- *less than* the searched value, then it would return a value *less than*
  `0`.
- *equal* to the searched value, then it would return a value *equal* to
  `0`.
- *greater than* the searched value, then it would return a value *greater
  than* `0`.


##### `birl` (`number | range | list`)
- If `number`, start index to iterate over
- If `range`, indices to iterate over
- If `list`, indices to iterate over


##### `begin_i` (`number`)
- Start index to iterate over.


##### `end_i` (`number | undef`)
- If `birl` is a number, then this is the end index to iterate over.
  - If `end_i < birl` then `spaceship_fn` is never called, making this
    function return `undef`.


##### `range_is` (`range`)
- Range of indices to iterate over.


##### `list_is` (`list`)
- List of indices to iterate over.


##### Returns (`number | undef`)

First index where `spaceship_fn(i) > 0`.  If none are found, returns
`undef`.

> **NOTE:**
>
> The reason for returning `undef` rather than `end_i+1`, is because `birl`
> could be a noncontiguous `range` or `list` of indices.

</details><hr/>

#### **find**
`function find(birl, end_i)`

**Overloads:**

    find(begin_i, end_i)    (pred_fn) : (number | undef)
    find(range_is)          (pred_fn) : (number | undef)
    find(list_is)           (pred_fn) : (number | undef)
    find() (begin_i, end_i) (pred_fn) : (number | undef)
    find() (range_is)       (pred_fn) : (number | undef)
    find() (list_is)        (pred_fn) : (number | undef)

Returns the first index that results in `pred_fn(i)` returning a truthy
result.

<details><summary>parameters and return info</summary>

##### `pred_fn` (`function(i) : bool`)
Where `i` is an index, if returns a truthy value, will stop searching and
return `i`.


##### `birl` (`number | range | list`)
- If `number`, start index to iterate over
- If `range`, indices to iterate over
- If `list`, indices to iterate over


##### `begin_i` (`number`)
- Start index to iterate over.


##### `end_i` (`number | undef`)
- If `birl` is a number, then this is the end index to iterate over.
  - If `end_i < birl` then `pred_fn` is never called, making this function
    return `undef`.


##### `range_is` (`range`)
- Range of indices to iterate over.


##### `list_is` (`list`)
- List of indices to iterate over.


##### Returns (`number | undef`)

If a call to pred_fn(i) returns truthy, will return i.  Otherwise
will return undef.

</details><hr/>

#### **reduce**
`function reduce(init, birl, end_i)`

**Overloads:**

    reduce(init, begin_i, end_i)  (op_fn) : init_result
    reduce(init, range_is)        (op_fn) : init_result
    reduce(init, list_is)         (op_fn) : init_result
    reduce(init) (begin_i, end_i) (op_fn) : init_result
    reduce(init) (range_is)       (op_fn) : init_result
    reduce(init) (list_is)        (op_fn) : init_result

Reduces (a.k.a. folds) a set of indices to produce some value/object based on
the indices.

<details><summary>parameters and return info</summary>

##### `init` (`any`)
This is the initial value that is passed to the first iteration of `op_fn`
as the accumulator.


##### `birl` (`number | range | list`)
- If `number`, start index to iterate over
- If `range`, indices to iterate over
- If `list`, indices to iterate over


##### `begin_i` (`number`)
- Start index to iterate over.


##### `end_i` (`number | undef`)
- If `birl` is a number, end index to iterate over.
  - If `end_i < birl` then `op_fn` is never called, making this function
    return `init`.


##### `range_is` (`range`)
- Range of indices to iterate over.


##### `list_is` (`list`)
- List of indices to iterate over.


##### `op_fn` (`function(i, acc) : any`)
Reduction callback, where `i` is the index and `acc` is the accumulator.
Returns new accumulator value.

> **NOTE:**
>
> `acc` **is the second parameter** which is different from most languages.
> This is to keep it consistent with the rest of the `PPMRRAIR` functions
> and this library in general.  You have been warned.



##### Returns (`any`)

Final value of accumulator.

</details><hr/>

#### **reduce_air**
`function reduce_air(init, birl, end_i)`

**Overloads:**

    reduce_air(init, begin_i, end_i)  (op_fn) : [cont, init_result]
    reduce_air(init, range_is)        (op_fn) : [cont, init_result]
    reduce_air(init, list_is)         (op_fn) : [cont, init_result]
    reduce_air(init) (begin_i, end_i) (op_fn) : [cont, init_result]
    reduce_air(init) (range_is)       (op_fn) : [cont, init_result]
    reduce_air(init) (list_is)        (op_fn) : [cont, init_result]

Reduces (a.k.a. folds) a set of indices to produce some value/object based on
the indices.  This Reduction Allows for Incomplete Reduction.

<details><summary>parameters and return info</summary>

##### `init` (`any`)
This is the initial value that is passed to the first iteration of `op_fn`
as the accumulator.


##### `birl` (`number | range | list`)
- If `number`, start index to iterate over
- If `range`, indices to iterate over
- If `list`, indices to iterate over


##### `end_i` (`number | undef`)
- If birl is a number, end index to iterate over.  If end_i < birl then
  op_fn is never called, making this function return `[true, init]`.


##### `op_fn` (`function(i, acc) : list`)
Reduction callback, where `i` is the index and `acc` is the accumulator.
Returns a list where element `0` is `true` if to continue to next iteration
or `false` if to stop.  Element `1` is the new accumulator value.

> **NOTE:**
>
> `acc` **is the second parameter** which is different from most languages.
> This is to keep it consistent with the rest of the `PPMRRAIR` functions
> and this library in general.  You have been warned.


##### Returns (`list`)

- Index 0 is if final call to `op_fn()` said to continue. `true` if not
  called.
- Index 1 is the final value of accumulator.

</details><hr/>

#### **filter**
`function filter(birl, end_i)`

**Overloads:**

    filter(begin_i, end_i)    (ppm_fn) : list
    filter(range_is)          (ppm_fn) : list
    filter(list_is)           (ppm_fn) : list
    filter() (begin_i, end_i) (ppm_fn) : list
    filter() (range_is)       (ppm_fn) : list
    filter() (list_is)        (ppm_fn) : list

Filter function.

<details><summary>parameters and return info</summary>

##### `ppm_fn` (`function(i) : bool | function(i, v) : any`)
- If this takes 1 parameter, then if it return a truthy value, add the
  index to the list.
- If this takes 2 parameters, then if passed only 1 parameter needs to call
  with a truthy as the second parameter and adds the returned value to the
  list.


##### `birl` (`number | range | list`)
- If `number`, start index to iterate over
- If `range`, indices to iterate over
- If `list`, indices to iterate over


##### `end_i` (`number | undef`)
- If birl is a number, end index to iterate over.  If end_i is less than birl,
  then ppm_fn() is never called, so filter will return an empty
  list.


##### Returns (`list`)

Returns a list of all indices or elements where ppm_fn returned
a truthy value.

</details><hr/>

#### **map**
`function map(birl, end_i)`

**Overloads:**

    map(begin_i, end_i)    (map_fn) : list
    map(range_is)          (map_fn) : list
    map(list_is)           (map_fn) : list
    map() (begin_i, end_i) (map_fn) : list
    map() (range_is)       (map_fn) : list
    map() (list_is)        (map_fn) : list

Map values to indices or list elements, producing an list that has as many
elements as indices provided.

<details><summary>parameters and return info</summary>

##### `map_fn` (`function (i) : any`)
Function to take an index and return the remapped value/object.


##### `birl` (`number | range | list`)
- If `number`, start index to iterate over
- If `range`, indices to iterate over
- If `list`, indices to iterate over


##### `end_i` (`number | undef`)
- If birl is a number, end index to iterate over.  If end_i is less than birl,
  then map_fn() is never called, so map will return an empty list.


##### Returns (`list`)

A new mapped list.

</details><hr/>


## indexable

### Purpose

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

> NOTE:
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


### Slices

A `slice` is an object similar to a `range`, but it's not a realised
indexable object until it is paired with an `slr`.

#### **is_slice**
`function is_slice(o)`

Check if object is a `slice` object.

<details><summary>parameters and return info</summary>

##### `o` (`any`)
Object to check.


##### Returns (`bool`)

`true` if object is a slice, `false` otherwise.

</details><hr/>

#### **slice**
`function slice(begin_i, step_or_end_i, end_i_)`

**Overloads:**

    slice(begin_i, end_i)
    slice(begin_i, step, end_i)

Slice is an unresolved range that works with an indexable.  It itself is
**not indexable**.  Use [`slice_to_range`](#slice_to_range) to convert to an
indexable range.

> **NOTE:**
>
> Due to ranges using inclusive values, and slices adhering to that same
> paradigm, a slice cannot refer to an empty range unless `step` precludes
> `begin_i` from getting to `end_i` or the referred to `slr` has a length of
> `0`.

> **TTA:**
>
> Built in ranges are `[ start : stop ]` or `[ start : step : stop ]`. I
> personally find this convention annoying and prefer python's convention of
> `range(start, stop + 1)` or `range(start, stop+1, step)`, having `step` at
> the end.  As builder of this library, I'm aware of my end users, so would
> like to know how they stand on this before I release this library into the
> wild.

<details><summary>parameters and return info</summary>

##### `begin_i` (`number`)
The first index of the slice.  If negative, then counts backward from end
of slr being referred to.


##### `step_or_end_i` (`number`)
- If `end_i_` not defined, then refers to the lat index of the sequence.
  - If negative, then counts backward from end of `slr` being referred to.
- If `end_i_` is defined, then refers to the step count used to go between
  `begin_i` and `end_i_`.


##### `end_i_` (`number | undef`)
If defined, then the last index of the slice.  If negative, then counts
backward from end of slr being referred to.


##### `step` (`number`)
The stride to go from one index to the next.


##### `end_i` (`number`)
Refers to the lat index of the sequence, if the step allows.
- If negative, then counts backward from end of `slr` being referred to.


##### Returns (`slice`)

Returns a slice object.

</details><hr/>

#### **slice_to_range**
`function slice_to_range(slice, slr, _slr_len)`

**Overloads:**

    slice_to_range(slice, slr)
    slice_to_range(slice, slr, _slr_len)

Converts a slice to a range when given a particular `slr`.

<details><summary>parameters and return info</summary>

##### `slice` (`slice`)
The slice being converted.


##### `slr` (`string | list | range`)
The `slr` used as reference.


##### `_slr_len` (`number | undef`)
Cached length of `slr`.  Will calculate it if `undef`.

> **NOTE:**
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!


##### Returns (`range | list`)

A range that corresponds to what the slice is to do given an `slr`.
If the slice is completely before or after the slr, returns [].

</details><hr/>


### Algorithm Adaptors

The `PPMRRAIR` functions usually are passed an integer as it's first
parameter, referring to the current index.  For convenience, there are
adaptor functions which allow referencing a `slr`'s element values.
  - [`it_each`](#it_each): passes slr element.
  - [`it_enum`](#it_enum): passes [index, slr element].
  - [`it_idxs`](#it_idxs): passes index.

Using these adaptors allows the use the length of the `slr` as reference if
the `birlsei` is partially or fully omitted.

#### **it_each**
`function it_each(slr, algo_fn, birls=0, end_i=undef)`

**Overloads:**

    it_each(slr, algo_fn, begin_i, end_i) (ppmrrair_fn) : any
    it_each(slr, algo_fn, range_is)       (ppmrrair_fn) : any
    it_each(slr, algo_fn, list_is)        (ppmrrair_fn) : any
    it_each(slr, algo_fn, slice_is)       (ppmrrair_fn) : any

This convenience function will execute function `algo_fn` as if it were used
on a collection, remapping the first parameter being passed to `ppmrrair_fn`
so that it receives the *element* rather than the *index*.  Uses the `slr` as
a reference so that `birlsei` can be partially or fully omitted.  The
`birlsei` is then normalised to a `birlei` and forwarded to `algo_fn`.

**Example:**

Normal usage:
```
a = [1,2,3,4,5]
even_indices = filter(fwd_i(a))(function(i) a[i] % 2);
even_values  = filter(fwd_i(a))(function(i, v) v ? a[i] : a[i] % 2);
```
vs `it_each()` usage:
```
a = [1,2,3,4,5]
even_indices = it_each(a, filter())(function(e) e % 2);
even_values  = it_each(a, filter())(function(e, v) v ? e : e % 2);
```

<details><summary>parameters and return info</summary>

##### `slr` (`string | list | range`)
This is the list to take element data from.


##### `algo_fn` (`function (fn, birl, end_i)`)
This is the operation function that is called. E.g. find(), filter(), etc.


##### `birls` (`number | range | list | slice`) *(Default: `0`)*
- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, will convert to an appropriate range using the `slr` length
  for reference.


##### `end_i` (`number | undef`) *(Default: `idx(slr, -1)`)*
- If `birls` is a number, then
  - If `end_i` is `undef`, then
    - `end_i` becomes `idx(slr, -1)`.
  - If `end_i < birls`, then
    - `birlsei`'s length is `0`, so nothing to iterate over.
  - Else
    - `end_i` is the last index to iterate over.


##### `range_is` (`range`)
- Range of indices to iterate over.


##### `list_is` (`list`)
- List of indices to iterate over.


##### `slice_is` (`slice`)
- Slice to convert to range to iterate over.


##### Returns (`any`)

The return value of the `algo_fn()` call.

</details><hr/>

#### **it_idxs**
`function it_idxs(slr, algo_fn, birls=0, end_i=undef)`

**Overloads:**

    it_idxs(slr, algo_fn, begin_i, end_i) (ppmrrair_fn) : any
    it_idxs(slr, algo_fn, range_is)       (ppmrrair_fn) : any
    it_idxs(slr, algo_fn, list_is)        (ppmrrair_fn) : any
    it_idxs(slr, algo_fn, slice_is)       (ppmrrair_fn) : any

This convenience function will execute function `algo_fn` as if it were used
on a collection, `ppmrrair_fn` will still receive the *index*.  Uses the
`slr` as a reference so that `birlsei` can be partially or fully omitted.
The `birlsei` is then normalised to a `birlei` and forwarded to `algo_fn`.

**Example:**

Normal usage:
```
a = [1,2,3,4,5]
even_indices = filter(fwd_i(a))(function(i) a[i] % 2);
even_values  = filter(fwd_i(a))(function(i, v) v ? a[i] : a[i] % 2);
```
vs `it_idxs()` usage:
```
a = [1,2,3,4,5]
even_indices = it_idxs(a, filter())(function(i) a[i] % 2);
even_values  = it_idxs(a, filter())(function(i, v) v ? a[i] : a[i] % 2);
```

<details><summary>parameters and return info</summary>

##### `slr` (`string | list | range`)
This is the list to take element data from.


##### `algo_fn` (`function (fn, birl, end_i)`)
This is the operation function that is called. E.g. find(), filter(), etc.


##### `birls` (`number | range | list | slice`) *(Default: `0`)*
- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, will convert to an appropriate range using the `slr` length
  for reference.


##### `end_i` (`number | undef`) *(Default: `idx(slr, -1)`)*
- If `birls` is a number, then
  - If `end_i` is `undef`, then
    - `end_i` becomes `idx(slr, -1)`.
  - If `end_i < birls`, then
    - `birlsei`'s length is `0`, so nothing to iterate over.
  - Else
    - `end_i` is the last index to iterate over.


##### `range_is` (`range`)
- Range of indices to iterate over.


##### `list_is` (`list`)
- List of indices to iterate over.


##### `slice_is` (`slice`)
- Slice to convert to range to iterate over.


##### Returns (`any`)

The return value of the `algo_fn()` call.

</details><hr/>

#### **it_enum**
`function it_enum(slr, algo_fn, birls=0, end_i=undef)`

**Overloads:**

    it_enum(slr, algo_fn, begin_i, end_i) (ppmrrair_fn) : any
    it_enum(slr, algo_fn, range_is)       (ppmrrair_fn) : any
    it_enum(slr, algo_fn, list_is)        (ppmrrair_fn) : any
    it_enum(slr, algo_fn, slice_is)       (ppmrrair_fn) : any

This convenience function will execute function `algo_fn` as if it were used
on a collection, remapping the first parameter being passed to `ppmrrair_fn`
so that it receives *[index, element]* rather than the *index*.  Uses the
`slr` as a reference so that `birlsei` can be partially or fully omitted.
The `birlsei` is then normalised to a `birlei` and forwarded to `algo_fn`.

**Example:**

Normal usage:
```
a = [1,2,3,4,5]
even_indices = filter(fwd_i(a))(function(i) a[i] % 2);
even_values  = filter(fwd_i(a))(function(i, v) v ? a[i] : a[i] % 2);
```
vs `it_enum()` usage:
```
a = [1,2,3,4,5]
even_indices = it_enum(a, filter())(function(p) p[0] % 2);
even_values  = it_enum(a, filter())(function(p, v) v ? p[1] : p[0] % 2);
```

<details><summary>parameters and return info</summary>

##### `slr` (`string | list | range`)
This is the list to take element data from.


##### `algo_fn` (`function (fn, birl, end_i)`)
This is the operation function that is called. E.g. find(), filter(), etc.


##### `birls` (`number | range | list | slice`) *(Default: `0`)*
- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, will convert to an appropriate range using the `slr` length
  for reference.


##### `end_i` (`number | undef`) *(Default: `idx(slr, -1)`)*
- If `birls` is a number, then
  - If `end_i` is `undef`, then
    - `end_i` becomes `idx(slr, -1)`.
  - If `end_i < birls`, then
    - `birlsei`'s length is `0`, so nothing to iterate over.
  - Else
    - `end_i` is the last index to iterate over.


##### `range_is` (`range`)
- Range of indices to iterate over.


##### `list_is` (`list`)
- List of indices to iterate over.


##### `slice_is` (`slice`)
- Slice to convert to range to iterate over.


##### Returns (`any`)

The return value of the `algo_fn()` call.

</details><hr/>


### Treat All Indexables the Same
#### **slr_len**
`function slr_len(slr)`

Will return the number of elements the string, list or range contains.

<details><summary>parameters and return info</summary>

##### `slr` (`string | list | range`)
The `slr` to count how many elements it would iterate over.


##### Returns (`number`)

The number of elements the `slr` contains.

</details><hr/>

#### **idx**
`function idx(slr, i, _slr_len)`

If `i` is positive then returns `i`, otherwise add the slr's length to it so
as to count backwards from the end of the slr.

> **NOTE:**
>
> If not `-slr_len(slr) ≤ i < slr_len(slr)`, then using the returned value to
> dereference the `slr` is **UB**.

<details><summary>parameters and return info</summary>

##### `slr` (`string | list | range`)
The `slr` to get the index for.


##### `i` (`number`)
The index of the element.  If value is negative, then goes backward from
end of slr, where -1 represents the last indexable index.


##### `_slr_len` (`number | undef`)
Cached length of `slr`.  Will calculate it if `undef`.

> **NOTE:**
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!


##### Returns (`number`)

The positive index.

</details><hr/>

#### **el**
`function el(slr, i)`

Dereference `slr` at index `i`, allowing for negative indices to go backward
from end.

> **NOTE:**
>
> It is **UB** to dereference at an index that is not in the `slr`.

<details><summary>parameters and return info</summary>

##### `slr` (`string | list | range`)
The `slr` to get the element from.


##### `i` (`number`)
The index of the element.  If value is negative, then goes backward from
end of the `slr`.


##### Returns (`any`)

The element at the index specified.

</details><hr/>

#### **el_pos_idx**
`function el_pos_idx(slr, i)`

Dereference `slr` at index `i`, allowing only positive indices.

> **NOTE:**
>
> It is **UB** to dereference at an index that is not in the `slr`.

<details><summary>parameters and return info</summary>

##### `slr` (`string | list | range`)
The `slr` to get the element from.


##### `i` (`number`)
The number iterations to have been done to get the return value.
Must be positive `(i >= 0)`.


##### Returns (`any`)

The element at the index specified.

</details><hr/>

#### **els**
`function els(slr, birls = 0, end_i = undef)`

**Overloads:**

    els(slr, begin_i, end_i) : (string | list | range)
    els(slr, list_is)        : (string | list | range)
    els(slr, range_is)       : (string | list | range)
    els(slr, slice_is)       : (string | list | range)

Gets a substring, sub-range or sub-elements of a string, list or range.

> **NOTE:**
>
> To expand a range to a list, use `[ each range_to_expand ]`.

<details><summary>parameters and return info</summary>

##### `slr` (`string | list | range`)
The `slr` to get the elements from.


##### `birls` (`number | range | list | slice`) *(Default: `0`)*
- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, will convert to an appropriate range using the `slr` length
  for reference.


##### `end_i` (`number | undef`) *(Default: `idx(slr, -1)`)*
- If `birls` is a number, then
  - If `end_i` is `undef`, then
    - `end_i` becomes `idx(slr, -1)`.
  - If `end_i < birls`, then
    - `birlsei`'s length is `0`, so nothing to iterate over.
  - Else
    - `end_i` is the last index to iterate over.


##### `range_is` (`range`)
- Range of indices to iterate over.


##### `list_is` (`list`)
- List of indices to iterate over.


##### `slice_is` (`slice`)
- Slice to convert to range to iterate over.


##### Returns (`string | list | range`)

The elements at the indices specified or the substring.

</details><hr/>

#### **range_els**
`function range_els(r, birls=0, end_i=undef)`

**Overloads:**

    range_els(slr, begin_i, end_i) : (range | list)
    range_els(slr, list_is)        : (range | list)
    range_els(slr, range_is)       : (range | list)
    range_els(slr, slice_is)       : (range | list)

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

<details><summary>parameters and return info</summary>

##### `r` (`range`)
The r to get the elements from.


##### `birls` (`number | range | list | slice`) *(Default: `0`)*
- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, will convert to an appropriate range using the `r` length for
  reference.


##### `end_i` (`number | undef`) *(Default: `idx(r, -1)`)*
- If `birls` is a number, then
  - If `end_i` is `undef`, then
    - `end_i` becomes `idx(r, -1)`.
  - If `end_i < birls`, then
    - `birlsei`'s length is `0`, so nothing to iterate over.
  - Else
    - `end_i` is the last index to iterate over.


##### `range_is` (`range`)
- Range of indices to iterate over.


##### `list_is` (`list`)
- List of indices to iterate over.


##### `slice_is` (`slice`)
- Slice to convert to range to iterate over.


##### Returns (`range | list`)

The elements at the indices specified or the substring.

</details><hr/>


### Getting/Traversing Indices
#### **idxs**
`function idxs(slr, birls=0, end_i=undef)`

**Overloads:**

    idxs(slr, begin_i, end_i) : list[number]
    idxs(slr, list_is)        : list[number]
    idxs(slr, range_is)       : list[number]
    idxs(slr, slice_is)       : list[number]

Gets the indices from a `birlsei` as a list.

<details><summary>parameters and return info</summary>

##### `slr` (`string | list | range`)
The `slr` to get the indices from.


##### `birls` (`number | range | list | slice`) *(Default: `0`)*
- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, will convert to an appropriate range using the `slr` length
  for reference.


##### `end_i` (`number | undef`) *(Default: `idx(slr, -1)`)*
- If `birls` is a number, then
  - If `end_i` is `undef`, then
    - `end_i` becomes `idx(slr, -1)`.
  - If `end_i < birls`, then
    - `birlsei`'s length is `0`, so nothing to iterate over.
  - Else
    - `end_i` is the last index to iterate over.


##### `range_is` (`range`)
- Range of indices to iterate over.


##### `list_is` (`list`)
- List of indices to iterate over.


##### `slice_is` (`slice`)
- Slice to convert to range to iterate over.


##### Returns (`list[number]`)

The indices the `birlsei` would iterate over.

</details><hr/>

#### **fwd_i**
`function fwd_i(slr, start_offset = 0, end_offset = 0, _slr_len)`

Return a range representing indices to iterate over a list forwards.

> **NOTE:**
>
> Dev is responsible for ensuring that when using start_offset / end_offset,
> that they don't go out of bounds, or if they do, the underlying PPMRRAIR
> function will handle it gracefully.

<details><summary>parameters and return info</summary>

##### `slr` (`string | list | range`)
slr to iterate over


##### `start_offset` (`number`) *(Default: `0`)*
Offset to start the starting point from.
- Should prolly be positive to not give an undefined index.


##### `end_offset` (`number`) *(Default: `0`)*
Offset to end the ending point to.
- Should prolly be negative to not give an undefined index.


##### `_slr_len` (`number | undef`)
Cached length of `slr`.  Will calculate it if `undef`.

> **NOTE:**
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!


##### Returns (`range`)

An ascending range that goes from `start_offset` to idx(slr, -1) +
end_offset.

</details><hr/>

#### **rev_i**
`function rev_i(slr, start_offset = 0, end_offset = 0, _slr_len)`

Return a range representing indices to iterate over slr backwards.

> **NOTE:**
>
> Dev is responsible for ensuring that when using start_offset / end_offset,
> that they don't go out of bounds, or if they do, the underlying PPMRRAIR
> function will handle it gracefully.

<details><summary>parameters and return info</summary>

##### `slr` (`string | list | range`)
slr to iterate over


##### `start_offset` (`number`) *(Default: `0`)*
Offset to start the starting point from.
- Should prolly be negative to not give an undefined index.


##### `end_offset` (`number`) *(Default: `0`)*
Offset to end the ending point to.
- Should prolly be positive to not give an undefined index.


##### `_slr_len` (`number | undef`)
Cached length of `slr`.  Will calculate it if `undef`.

> **NOTE:**
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!


##### Returns (`range`)

A descending range that goes from idx(slr, -1) + start_offset to
end_offset.

</details><hr/>

#### **next_in**
`function next_in(slr, i, inc=1, wrap_to_0 = false, _slr_len)`

Gets the next index, wrapping if goes to or beyond slr_len(slr).

<details><summary>parameters and return info</summary>

##### `slr` (`string | list | range`)
slr used for knowing when to wrap.


##### `i` (`number`)
Index to start from.  Assumed: `0 <= i < slr_len(slr)`.


##### `inc` (`number`) *(Default: `1`)*
Count to increase i by.


##### `wrap_to_0` (`bool`) *(Default: `false`)*
If true, then when i+inc >= slr_len(slr), result is 0.  Otherwise, it wraps
to modulo slr_len(slr).


##### `_slr_len` (`number | undef`)
Cached length of `slr`.  Will calculate it if `undef`.

> **NOTE:**
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!


##### Returns (`number`)

Next element index in list.

</details><hr/>

#### **prev_in**
`function prev_in(slr, i, dec=1, wrap_to_last = false, _slr_len)`

Gets the prev index, wrapping if goes negative.

<details><summary>parameters and return info</summary>

##### `slr` (`string | list | range`)
slr used for knowing when to wrap.


##### `i` (`number`)
Index to start from.  Assumed: `0 <= i < slr_len(slr)`.


##### `dec` (`number`) *(Default: `1`)*
Count to decrease i by.


##### `wrap_to_last` (`bool`) *(Default: `false`)*
If true, then when i-dec < 0, result is idx(slr, -1).  Otherwise, it wraps
to modulo slr_len(slr).


##### `_slr_len` (`number | undef`)
Cached length of `slr`.  Will calculate it if `undef`.

> **NOTE:**
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!


##### Returns (`number`)

Previous element index in list.

</details><hr/>


### Functions to Manipulate Strings and Lists
#### **push**
`function push(sl, es)`

Push elements onto the head (which is after the last element) of the `sl`.

<details><summary>parameters and return info</summary>

##### `sl` (`string | list`)
sl to add to.


##### `es` (`string | list | range`)
- if string, then
  - a string of characters to append to string or
  - list of characters to append to list.
- if list, then a list of elements to append to list.
- if range, then a range of elements to append to list.


##### Returns (`string | list`)

The updated string or list.

</details><hr/>

#### **pop**
`function pop(sl, count=1, _sl_len)`

Pops 0 or more elements off the head (which are the last elements) of the
`sl`.

> **NOTE:**
>
> It is **UB** to pop off more elements than are available.

<details><summary>parameters and return info</summary>

##### `sl` (`string | list`)
sl to remove from.


##### `count` (`number`) *(Default: `1`)*
Number of elements to pop off end of list.


##### `_sl_len` (`number | undef`)
If a number, then use that cached value instead of calculating `len(sl)`.

> **NOTE:**
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!


##### Returns (`string | list`)

The updated sl.

</details><hr/>

#### **unshift**
`function unshift(sl, es)`

Unshift elements onto the tail (which are before the beginning) of the `sl`.

<details><summary>parameters and return info</summary>

##### `sl` (`string | list`)
List to add to.


##### `es` (`string | list | range`)
- if string, then
  - a string of characters to prepend to string or
  - list of characters to prepend to list.
- if list, then a list of elements to prepend to list.
- if range, then a range of elements to prepend to list.


##### Returns (`string | list`)

The updated sl.

</details><hr/>

#### **shift**
`function shift(sl, count=1, _sl_len)`

Shift elements off of the tail (which are at the beginning) of the `sl`.

> **NOTE:**
>
> It is **UB** to shift off more elements than are available.

<details><summary>parameters and return info</summary>

##### `sl` (`string | list`)
sl to remove from.


##### `count` (`number`) *(Default: `1`)*
Number of elements to shift off beginning of list.


##### `_sl_len` (`number | undef`)
If a number, then use that cached value instead of calculating `len(sl)`.

> **NOTE:**
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!


##### Returns (`string | list`)

The updated sl.

</details><hr/>

#### **insert**
`function insert(sl, i, es, es_birls=0, es_end_i=undef)`

**Overloads:**

    insert(sl, i, es, es_begin_i, es_end_i) : (string | list)
    insert(sl, i, es, es_list_is)           : (string | list)
    insert(sl, i, es, es_range_is)          : (string | list)
    insert(sl, i, es, es_slice_is)          : (string | list)

Insert specified elements in `es` into `sl` starting at index `i`.

<details><summary>parameters and return info</summary>

##### `sl` (`string | list`)
String or list to insert into.


##### `i` (`number`)
Index to insert into.
- `0` to insert at beginning of list (like unshift)
- `len(sl)` to insert at end of list (like push)
- Negative values will insert starting from the end.
  - `-1` will insert between the second last element and the last element.
  - `-len(sl)` will insert at the beginning of list (like unshift)
  - **UB** if `i < -len(sl) or len(sl) < i`.


##### `es` (`string | list | range`)
Elements to insert.


##### `es_birls` (`number | range | list | slice`) *(Default: `0`)*
- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, will convert to an appropriate range using the `es` length for
  reference.


##### `es_end_i` (`number | undef`) *(Default: `idx(es, -1)`)*
- If `es_birls` is a number, then
  - If `es_end_i` is `undef`, then
    - `es_end_i` becomes `idx(es, -1)`.
  - If `es_end_i < es_birls`, then
    - `birlsei`'s length is `0`, so nothing to iterate over.
  - Else
    - `es_end_i` is the last index to iterate over.


##### Returns (`string | list`)

The updated sl.

</details><hr/>

#### **remove**
`function remove(sl, begin_i, end_i, _sl_len)`

Removes a contiguous set of elements from a sl.

> **NOTE:**
>
> `begin_i` and `end_i` accept negative values (`-1` is last element). Both
> are first converted to their non-negative equivalents by adding `len(sl)`.
> If the converted `end_i < begin_i`, nothing is removed. Otherwise the
> inclusive range `[begin_i..end_i]` is removed.
>
> Unless `end_i < begin_i`, it is **UB** if `begin_i` or `end_i` don't
> resolve to an index in the sl.

<details><summary>parameters and return info</summary>

##### `sl` (`string | list`)
List to remove elements from.


##### `begin_i` (`number`)
The first index to remove. Can be negative to represent counting from end.


##### `end_i` (`number`)
The last index to remove. Can be negative to represent counting from end.


##### `_sl_len` (`number | undef`)
If a number, then use that cached value instead of calculating `len(sl)`.

> **NOTE:**
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!


##### Returns (`string | list`)

The updated sl.

</details><hr/>

#### **remove_adjacent_dups**
`function remove_adjacent_dups(sl, wrap = false, _sl_len)`

**Overloads:**

    remove_adjacent_dups(sl, wrap, _sl_len) (equal_fn) : (string | list)

Removes the same consecutive values, where same is defined by `equal_fn`.

<details><summary>parameters and return info</summary>

##### `sl` (`string | list`)
List to remove duplicate consecutive elements from.


##### `wrap` (`bool`) *(Default: `false`)*
If true, then will consider the first and last element consecutive.


##### `equal_fn` (`function(prev_el, current_el) : bool`)
Function to denote equality.


##### `_sl_len` (`number | undef`)
If a number, then use that cached value instead of calculating `len(sl)`.

> **NOTE:**
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!


##### Returns (`string | list`)

String or list that has the consecutive duplicates removed.

</details><hr/>

#### **remove_each**
`function remove_each(sl, birls = 0, end_i = undef)`

**Overloads:**

    remove_each(sl, begin_i, es_end_i) : (string | list)
    remove_each(sl, list_is)           : (string | list)
    remove_each(sl, range_is)          : (string | list)
    remove_each(sl, slice_is)          : (string | list)

Removes each element indexed in the `birlsei`.

> **NOTE:**
>
> **UB** if resulting `birlei` is not strictly increasing.

<details><summary>parameters and return info</summary>

##### `sl` (`string | list`)
List to remove elements from.


##### `birls` (`number | range | list | slice`) *(Default: `0`)*
- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, will convert to an appropriate range using the `sl` length
  for reference.


##### `end_i` (`number | undef`) *(Default: `idx(sl, -1)`)*
- If `birls` is a number, then
  - If `end_i` is `undef`, then
    - `end_i` becomes `idx(sl, -1)`.
  - If `end_i < birls`, then
    - `birlsei`'s length is `0`, so nothing to iterate over.
  - Else
    - `end_i` is the last index to iterate over.


##### `range_is` (`range`)
- Range of indices to iterate over.


##### `list_is` (`list`)
- List of indices to iterate over.


##### `slice_is` (`slice`)
- Slice to convert to range to iterate over.


##### Returns (`string | list`)

The updated sl.

</details><hr/>

#### **replace**
`function replace(a, a_begin_i, a_end_i, b, b_birls=0, b_end_i=undef)`

**Overloads:**

    replace(a, a_begin_i, a_end_i, b, b_begin_i, b_end_i) : (string | list)
    replace(a, a_begin_i, a_end_i, b, b_list_is)          : (string | list)
    replace(a, a_begin_i, a_end_i, b, b_range_is)         : (string | list)
    replace(a, a_begin_i, a_end_i, b, b_slice_is)         : (string | list)

Replaces contiguous index set [`a_begin_i`, `a_end_i`] from list `a` with
`birlsei` index set of list `b`.

<details><summary>parameters and return info</summary>

##### `a` (`string | list`)
List to have elements replaced.


##### `a_begin_i` (`number`)
The starting index of a to replace.


##### `a_end_i` (`number`)
The ending index of a to replace.


##### `b` (`string | list | range`)
List to draw elements from to replace the a element range with.


##### `b_birls` (`number | range | list | slice`) *(Default: `0`)*
- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, will convert to an appropriate range using the `b` length for
  reference.


##### `b_end_i` (`number | undef`) *(Default: `idx(b, -1)`)*
- If `b_birls` is a number, then
  - If `b_end_i` is `undef`, then
    - `b_end_i` becomes `idx(b, -1)`.
  - If `b_end_i < b_birls`, then
    - `birlsei`'s length is `0`, so nothing to iterate over.
  - Else
    - `b_end_i` is the last index to iterate over.


##### Returns (`string | list`)

This is the updated list of elements.

</details><hr/>

#### **replace_each**
`function replace_each(a, a_birls=0, a_end_i=undef)`

**Overloads:**

    replace_each(a, a_begin_i, a_end_i) (b, b_begin_i, b_end_i) : (string | list)
    replace_each(a, a_begin_i, a_end_i) (b, b_list_is)          : (string | list)
    replace_each(a, a_begin_i, a_end_i) (b, b_range_is)         : (string | list)
    replace_each(a, a_begin_i, a_end_i) (b, b_slice_is)         : (string | list)
    replace_each(a, a_list_is)          (b, b_begin_i, b_end_i) : (string | list)
    replace_each(a, a_list_is)          (b, b_list_is)          : (string | list)
    replace_each(a, a_list_is)          (b, b_range_is)         : (string | list)
    replace_each(a, a_list_is)          (b, b_slice_is)         : (string | list)
    replace_each(a, a_range_is)         (b, b_begin_i, b_end_i) : (string | list)
    replace_each(a, a_range_is)         (b, b_list_is)          : (string | list)
    replace_each(a, a_range_is)         (b, b_range_is)         : (string | list)
    replace_each(a, a_range_is)         (b, b_slice_is)         : (string | list)
    replace_each(a, a_slice_is)         (b, b_begin_i, b_end_i) : (string | list)
    replace_each(a, a_slice_is)         (b, b_list_is)          : (string | list)
    replace_each(a, a_slice_is)         (b, b_range_is)         : (string | list)
    replace_each(a, a_slice_is)         (b, b_slice_is)         : (string | list)

Replaces each element specified by `a_birls, a_end_i` with each element
specified by `b_birls, b_end_i`.

> **NOTE:**
>
> `a_birlsei` must be strictly increasing.

> **NOTE:**
>
> Both `birlsei`s MUST iterate over the same number of elements.

<details><summary>parameters and return info</summary>

##### `a` (`string | list`)
sl to have elements replaced.


##### `a_birls` (`number | range | list | slice`) *(Default: `0`)*
- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, will convert to an appropriate range using the `a` length for
  reference.


##### `a_end_i` (`number | undef`) *(Default: `idx(a, -1)`)*
- If `a_birls` is a number, then
  - If `a_end_i` is `undef`, then
    - `a_end_i` becomes `idx(a, -1)`.
  - If `a_end_i < a_birls`, then
    - `birlsei`'s length is `0`, so nothing to iterate over.
  - Else
    - `a_end_i` is the last index to iterate over.


##### `b` (`string | list | range`)
sl to have elements replaced.


##### `b_birls` (`number | range | list | slice`) *(Default: `0`)*
- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, will convert to an appropriate range using the `b` length for
  reference.


##### `b_end_i` (`number | undef`) *(Default: `idx(b, -1)`)*
- If `b_birls` is a number, then
  - If `b_end_i` is `undef`, then
    - `b_end_i` becomes `idx(b, -1)`.
  - If `b_end_i < b_birls`, then
    - `birlsei`'s length is `0`, so nothing to iterate over.
  - Else
    - `b_end_i` is the last index to iterate over.


##### Returns (`string | list`)

This is the updated list of elements.

</details><hr/>

#### **swap**
`function swap(sl, begin_i1, end_i1, begin_i2, end_i2)`

Swap the elements between [begin_i1 : end_i1] and [begin_i2 : end_i2].
Range must be nondecreasing or there will not be any elements in that
range.  Negative values are normalised to positive by adding `len(sl)` to
them.

<details><summary>parameters and return info</summary>

##### `sl` (`string | list`)
List to swap elements in.


##### `begin_i1` (`number`)
Starting index of group 1.


##### `end_i1` (`number`)
Ending index of group 1.


##### `begin_i2` (`number`)
Starting index of group 2.


##### `end_i2` (`number`)
Ending index of group 2.


##### Returns (`string | list`)

List with ranges swapped.

</details><hr/>

#### **rotate_left**
`function rotate_left(sl, i, _sl_len)`

Does a left rotation of the elements in the `sl` so that the elements are
reordered as if indices were `[i : len(sl)-1]` followed by `[0 : i - 1]`.

<details><summary>parameters and return info</summary>

##### `sl` (`string | list`)
This is the list to rotate.


##### `i` (`number`)
- Number of elements to rotate left.
- If negative, rotates right.


##### `_sl_len` (`number | undef`)
If a number, then use that cached value instead of calculating `len(sl)`.

> **NOTE:**
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!


##### Returns (`string | list`)

Returns the rotated list.

</details><hr/>

#### **rotate_right**
`function rotate_right(sl, i, _sl_len)`

Does a right rotation of the elements in the `sl` so that the elements are
reordered as if indices were `[len(sl)-i : len(sl)-1]` followed by
`[0 : len(sl)-i - 1]`.

<details><summary>parameters and return info</summary>

##### `sl` (`string | list`)
This is the list to rotate.


##### `i` (`number`)
- Number of elements to rotate right.
- If negative, rotates left.


##### `_sl_len` (`number | undef`)
If a number, then use that cached value instead of calculating `len(sl)`.

> **NOTE:**
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!


##### Returns (`string | list`)

Returns the rotated list.

</details><hr/>

#### **head**
`function head(sl, _sl_len)`

Gets the element at the head (which is the last element) of the `sl`.

<details><summary>parameters and return info</summary>

##### `sl` (`string | list`)
List to get from.


##### `_sl_len` (`number | undef`)
If a number, then use that cached value instead of calculating `len(sl)`.

> **NOTE:**
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!


##### Returns (`any`)

Object at the head of the list.

</details><hr/>

#### **head_multi**
`function head_multi(sl, i, _sl_len)`

Gets the elements at the head (which are the last elements) of the `sl`.

<details><summary>parameters and return info</summary>

##### `sl` (`string | list`)
List to get from.


##### `i` (`number`)
Number of elements to retrieve from the head.


##### `_sl_len` (`number | undef`)
If a number, then use that cached value instead of calculating `len(sl)`.

> **NOTE:**
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!


##### Returns (`string | list`)

Objects at the head of the list.

</details><hr/>

#### **tail**
`function tail(sl)`

Gets the element at the tail (which is the first element) of the `sl`.

<details><summary>parameters and return info</summary>

##### `sl` (`string | list`)
List to get from.


##### Returns (`any`)

Object at the tail of the list.

</details><hr/>

#### **tail_multi**
`function tail_multi(sl, i)`

Gets the elements at the tail (which are the first elements) of the `sl`.

<details><summary>parameters and return info</summary>

##### `sl` (`string | list`)
List to get from.


##### `i` (`number`)
Number of elements to retrieve from the tail.


##### Returns (`string | list`)

Objects at the tail of the list.

</details><hr/>

#### **osearch**
`function osearch(haystack, birls=0, end_i=undef)`

**Overloads:**

    osearch(haystack, begin_i, end_i) (needle, n_begin_i, n_end_i) (equal_fn) : (undef | number)
    osearch(haystack, begin_i, end_i) (needle, n_list_is)          (equal_fn) : (undef | number)
    osearch(haystack, begin_i, end_i) (needle, n_range_is)         (equal_fn) : (undef | number)
    osearch(haystack, begin_i, end_i) (needle, n_slice_is)         (equal_fn) : (undef | number)
    osearch(haystack, list_is)        (needle, n_begin_i, n_end_i) (equal_fn) : (undef | number)
    osearch(haystack, list_is)        (needle, n_list_is)          (equal_fn) : (undef | number)
    osearch(haystack, list_is)        (needle, n_range_is)         (equal_fn) : (undef | number)
    osearch(haystack, list_is)        (needle, n_slice_is)         (equal_fn) : (undef | number)
    osearch(haystack, range_is)       (needle, n_begin_i, n_end_i) (equal_fn) : (undef | number)
    osearch(haystack, range_is)       (needle, n_list_is)          (equal_fn) : (undef | number)
    osearch(haystack, range_is)       (needle, n_range_is)         (equal_fn) : (undef | number)
    osearch(haystack, range_is)       (needle, n_slice_is)         (equal_fn) : (undef | number)
    osearch(haystack, slice_is)       (needle, n_begin_i, n_end_i) (equal_fn) : (undef | number)
    osearch(haystack, slice_is)       (needle, n_list_is)          (equal_fn) : (undef | number)
    osearch(haystack, slice_is)       (needle, n_range_is)         (equal_fn) : (undef | number)
    osearch(haystack, slice_is)       (needle, n_slice_is)         (equal_fn) : (undef | number)

Searches for an ordered set of elements specified in needle that occurs as an
ordered set of elements in haystack.  Similar to built-in search() function,
but allows specifying an index range to search and exposes the equal()
operator to allow for non-exact matches.

<details><summary>parameters and return info</summary>

##### `haystack` (`string | list`)
String or list of consecutive items to search through.


##### `birls` (`number | range | list | slice`) *(Default: `0`)*
- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, will convert to an appropriate range using the `haystack`
  length for reference.


##### `end_i` (`number | undef`) *(Default: `idx(haystack, -1)`)*
- If `birls` is a number, then
  - If `end_i` is `undef`, then
    - `end_i` becomes `idx(haystack, -1)`.
  - If `end_i < birls`, then
    - `birlsei`'s length is `0`, so nothing to iterate over.
  - Else
    - `end_i` is the last index to iterate over.


##### `range_is` (`range`)
- Range of indices to iterate over.


##### `list_is` (`list`)
- List of indices to iterate over.


##### `slice_is` (`slice`)
- Slice to convert to range to iterate over.


##### `needle` (`string | list`)
String or list of consecutive items being searched for.


##### `n_birls` (`number | range | list | slice`) *(Default: `0`)*
- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, will convert to an appropriate range using the `needle`
  length for reference.


##### `n_end_i` (`number | undef`) *(Default: `idx(needle, -1)`)*
- If `n_birls` is a number, then
  - If `n_end_i` is `undef`, then
    - `n_end_i` becomes `idx(needle, -1)`.
  - If `n_end_i < n_birls`, then
    - `n_`birlsei``'s length is `0`, so nothing to iterate over.
  - Else
    - `n_end_i` is the last index to iterate over.


##### `n_range_is` (`range`)
- Range of indices to iterate over.


##### `n_list_is` (`list`)
- List of indices to iterate over.


##### `n_slice_is` (`slice`)
- Slice to convert to range to iterate over.


##### `equal_fn` (`function(haystack_el, needle_el) : equality_result`)
Function that defines how to perform equality.  For a less strict equality
check, try [`function_equal`](#function_equal).


##### Returns (`number | undef`)

The index where needle was found or undef if wasn't found.

</details><hr/>

#### **csearch**
`function csearch(haystack, birls=0, end_i=undef)`

**Overloads:**

    csearch(haystack, begin_i, end_i) (needle, n_begin_i, n_end_i) (equal_fn) : (undef | number)
    csearch(haystack, begin_i, end_i) (needle, n_list_is)          (equal_fn) : (undef | number)
    csearch(haystack, begin_i, end_i) (needle, n_range_is)         (equal_fn) : (undef | number)
    csearch(haystack, begin_i, end_i) (needle, n_slice_is)         (equal_fn) : (undef | number)
    csearch(haystack, list_is)        (needle, n_begin_i, n_end_i) (equal_fn) : (undef | number)
    csearch(haystack, list_is)        (needle, n_list_is)          (equal_fn) : (undef | number)
    csearch(haystack, list_is)        (needle, n_range_is)         (equal_fn) : (undef | number)
    csearch(haystack, list_is)        (needle, n_slice_is)         (equal_fn) : (undef | number)
    csearch(haystack, range_is)       (needle, n_begin_i, n_end_i) (equal_fn) : (undef | number)
    csearch(haystack, range_is)       (needle, n_list_is)          (equal_fn) : (undef | number)
    csearch(haystack, range_is)       (needle, n_range_is)         (equal_fn) : (undef | number)
    csearch(haystack, range_is)       (needle, n_slice_is)         (equal_fn) : (undef | number)
    csearch(haystack, slice_is)       (needle, n_begin_i, n_end_i) (equal_fn) : (undef | number)
    csearch(haystack, slice_is)       (needle, n_list_is)          (equal_fn) : (undef | number)
    csearch(haystack, slice_is)       (needle, n_range_is)         (equal_fn) : (undef | number)
    csearch(haystack, slice_is)       (needle, n_slice_is)         (equal_fn) : (undef | number)

Searches haystack for contiguous set of elements that starts from an ordered
set of indices that match an ordered set of elements specified in needle.
Similar to built-in search() function, but allows specifying an index range
to search and exposes the equal() operator to allow for non-exact matches.

<details><summary>parameters and return info</summary>

##### `haystack` (`string | list`)
String or list of consecutive items to search through.


##### `birls` (`number | range | list | slice`) *(Default: `0`)*
- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, will convert to an appropriate range using the `haystack`
  length for reference.


##### `end_i` (`number | undef`) *(Default: `idx(haystack, -1)`)*
- If `birls` is a number, then
  - If `end_i` is `undef`, then
    - `end_i` becomes `idx(haystack, -1)`.
  - If `end_i < birls`, then
    - `birlsei`'s length is `0`, so nothing to iterate over.
  - Else
    - `end_i` is the last index to iterate over.


##### `range_is` (`range`)
- Range of indices to iterate over.


##### `list_is` (`list`)
- List of indices to iterate over.


##### `slice_is` (`slice`)
- Slice to convert to range to iterate over.


##### `needle` (`string | list`)
String or list of consecutive items being searched for.


##### `n_birls` (`number | range | list | slice`) *(Default: `0`)*
- If `number`, start index to iterate over.
- If `range`, indices to iterate over.
- If `list`, indices to iterate over.
- If `slice`, will convert to an appropriate range using the `needle`
  length for reference.


##### `n_end_i` (`number | undef`) *(Default: `idx(needle, -1)`)*
- If `n_birls` is a number, then
  - If `n_end_i` is `undef`, then
    - `n_end_i` becomes `idx(needle, -1)`.
  - If `n_end_i < n_birls`, then
    - `n_`birlsei``'s length is `0`, so nothing to iterate over.
  - Else
    - `n_end_i` is the last index to iterate over.


##### `n_range_is` (`range`)
- Range of indices to iterate over.


##### `n_list_is` (`list`)
- List of indices to iterate over.


##### `n_slice_is` (`slice`)
- Slice to convert to range to iterate over.


##### `equal_fn` (`function(haystack_el, needle_el) : equality_result`)
Function that defines how to perform equality.  For a less strict equality
check, try [`function_equal`](#function_equal).


##### Returns (`number | undef`)

The index where needle was found or undef if wasn't found.

</details><hr/>


## range

### Purpose

A range is a structure that can be iterated over, like one can do with a
list.  However, unlike in python, it doesn't have the ability to index an
element in the range or interrogate it for it's length.  Also, there is a
feature which prevents having unreachable end values given an initial start
and step value without generating a warning.  This library is to help with
those deficiencies.

> NOTE:
>
> Ranges in OpenSCAD are closed ranges.  This means that if the step allows,
> the specified end value will be part of the iteration.  E.g. `range(1, 5)`
> will iterate on `1`, `2`, `3`, `4` *and* `5`, opposed to half open ranges
> like that used in python, where `range(1, 5)` would iterate on `1`, `2`,
> `3`, and `4`.

#### **is_range**
`function is_range(o)`

Tests if the object is a range object.

<details><summary>parameters and return info</summary>

##### `o` (`any`)
Object to test.


##### Returns (`bool`)

Returns `true` if object is a range, otherwise `false`.

</details><hr/>

#### **range**
`function range(count_or_begin_i, step_or_end_i, end_i_)`

**Overloads:**

    range(count)
    range(begin_i, end_i)
    range(begin_i, step, end_i)

Creates a range object.

> **NOTE:**
>
> Will **not** generate a warning if step results in no elements in range,
> unlike `[ begin_i : end_i ]` or `[ begin_i : step : end_i ]`.  Instead,
> generates an empty list.

> **TTA:**
>
> Built in ranges are `[ start : stop ]` or `[ start : step : stop ]`. I
> personally find this convention annoying and prefer python's convention of
> `range(start, stop + 1)` or `range(start, stop+1, step)`, having `step` at
> the end.  As builder of this library, I'm aware of my end users, so would
> like to know how they stand on this before I release this library into the
> wild.

<details><summary>parameters and return info</summary>

##### `count_or_begin_i` (`number`)
- If `step_i_end_i` is `undef`, the number of indices to count, from `0` to
  `count_or_begin_i-1`.
  - If `≤ 0` then returns an empty list.
- Else the beginning index.


##### `step_or_end_i` (`number | undef`)
- If `end_i_` is `undef`, then this is the end index.
- Else this is the step.


##### `end_i_` (`number | undef`)
- If a number, then this is the ending index.


##### `count` (`number`)
The number of indices to count.  Starts at `0`.
- If `≤ 0` then returns an empty list.


##### `begin_i` (`number`)
The beginning index.


##### `step` (`number`)
Step value when iterating from `begin_i` to `end_i`.  Cannot be `0`.


##### `end_i` (`number`)
Last value to attempt to reach.  If `step` allows, this value is included
in the range.


##### Returns (`range | list`)

This is the range to iterate over.  If `step < 0 and begin_i < end_i or
step > 0 and begin_i > end_i or count <= 0`, then returns an empty list.

</details><hr/>

#### **range_len**
`function range_len(r)`

Will return the number of elements the range will return.

> **NOTE:**
>
> Assumes range was created with [`range`](#range-1), so that the elements
> must be valid. E.g. `[ -B : +S : -E ]` will never occur as it would have
> been converted to `[]`.

<details><summary>parameters and return info</summary>

##### `range` (`range`)
The range to count how many indices it will iterate over.


##### Returns (`number`)

The number of indices the range contains.

</details><hr/>

#### **range_el**
`function range_el(r, i, _r_len)`

Will return the element that would have been returned if left to iterate `i`
times.

> **NOTE:**
>
> It is **UB** to dereference at an index that is not in the range.

<details><summary>parameters and return info</summary>

##### `range` (`range`)
The range to get index from if left to iterate `i` times.


##### `i` (`number`)
The number iterations to have been done to get the return value.
If negative then start counting from end to beginning.


##### `_r_len` (`number | undef`)
Cached length of `r`.  Will calculate it if `undef`.

> **NOTE:**
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!


##### Returns (`number`)

The index to have retrieved if iterated over `i` times.

</details><hr/>

#### **range_el_pos_idx**
`function range_el_pos_idx(r, i)`

Dereference range at index `i`, allowing only positive indices.

> **NOTE:**
>
> It is **UB** to dereference at an index that is not in the range.

<details><summary>parameters and return info</summary>

##### `range` (`range`)
The range to get index from if left to iterate `i` times.


##### `i` (`number`)
The number iterations to have been done to get the return value.
Must be positive `(i >= 0)`.


##### Returns (`number`)

The index to have retrieved if iterated over `i` times.

</details><hr/>

#### **range_idx**
`function range_idx(r, i, _r_len)`

Gets the index for an range.  Allows for negative values to reference
elements starting from the end going backwards.

<details><summary>parameters and return info</summary>

##### `r` (`list`)
The range to get the index for.


##### `i` (`number`)
The index of the element.  If value is negative, then goes backward from
end of range.


##### `_r_len` (`number | undef`)
Cached length of `r`.  Will calculate it if `undef`.

> **NOTE:**
>
> This is a private parameter and it may disappear at any time in the
> future.  Use at your own peril!


##### Returns (`number`)

The positive index.

</details><hr/>


## types

### Purpose

This library allows representing types as enumerated values, strings or
minimal strings for complex types.


### Tests
#### **is_indexable_te**
`function is_indexable_te(type_enum)`

States if a te (type_enum) represents an indexable type, either directly with
`sl[index]` or indirectly with `range_el(r, index)`.

<details><summary>parameters and return info</summary>

##### `type_enum` (`number`)
Enum for type (See [type_enum](#type_enum))


##### Returns (`bool`)

Returns `true` if indexable, `false` otherwise.

</details><hr/>

#### **is_int**
`function is_int(o)`

States if object is an integer (has no fractional part).

<details><summary>parameters and return info</summary>

##### `o` (`any`)
Object to query.


##### Returns (`bool`)

Returns `true` if integer, `false` otherwise.

</details><hr/>

#### **is_float**
`function is_float(o)`

States if object is a float (has a fractional part).

<details><summary>parameters and return info</summary>

##### `o` (`any`)
Object to query.


##### Returns (`bool`)

Returns `true` if float, `false` otherwise.

</details><hr/>

#### **is_nan**
`function is_nan(n)`

States if object is a NaN object.

<details><summary>parameters and return info</summary>

##### `o` (`any`)
Object to query.


##### Returns (`bool`)

Returns `true` if NaN, `false` otherwise.

</details><hr/>


### Type Introspection
#### **type_enum**
`function type_enum(o, distinguish_float_from_int = false)`

Function to get the type of an object as an enum.

<details><summary>parameters and return info</summary>

##### `o` (`any`)
The object to get the type from.


##### `distinguish_float_from_int` (`bool`)
Flag to indicate if to distinguish floats from integers rather than
grouping them together as numbers.


##### Returns (`number`)

The number corresponding to the type enum.

</details><hr/>

#### **type_enum_to_str**
`function type_enum_to_str(i)`

Convert the type enum to a string.

<details><summary>parameters and return info</summary>

##### `i` (`number`)
Type enum to convert.


##### Returns (`string`)

The string corresponding to the type enum.  If type enum is not recognised,
return "*INVALID TYPE*".

</details><hr/>

#### **type**
`function type(o, distinguish_float_from_int = false)`

Gets a string representation of the type of `o`.

<details><summary>parameters and return info</summary>

##### `o` (`any`)
Object to query.


##### Returns (`bool`)

Returns string representation of `o`'s type.

</details><hr/>

#### **type_structure**
`function type_structure(o)`

Attempts to simplify the type structure of object o recursively.

- If o is a list
  - if all elements in that list contain the same type structure,
    - simplify the list by only showing that structure once and append to it
      how many times it is repeated.
  - else if not the same, then recursively simplify each element.
- else it's some other type, so will just output the type of the object.

<details><summary>parameters and return info</summary>

##### `o` (`any`)
Gets the simplified type structure of o.


##### Returns (`string`)

This string is a representation of the type structure of o.

</details><hr/>

#### **type_value**
`function type_value(o)`

Gives a string that outputs the type_structure and value of object passed in.

<details><summary>parameters and return info</summary>

##### `o` (`any`)
The object to list information about.


##### Returns (`string`)

Give info for `o` as string.

</details><hr/>


## function

### Purpose

Sometimes it's useful to know something basic about the function in hand so
that the code knows what it can and can't do.  This library fills that need.

### Function Introspection


### Purpose

Sometimes it's useful to know something basic about the function in hand so that
the code knows what it can and can't do.  This library fills that need.

#### **param_count**
`function param_count(fn)`

Counts the number of parameters that can be passed to the function fn.

<details><summary>parameters and return info</summary>

##### `fn` (`function(...) : any`)


##### Returns (`number`)

The number of parameters that the function can take.

</details><hr/>

#### **param_count_direct_recursion_demo**
`function param_count_direct_recursion_demo(fn)`

Counts the number of parameters that can be passed to the function fn.

THIS IS A DEMO of how this would look if using direct recursion.
#### **apply_to_fn**
`function apply_to_fn(fn, p)`

Applies each element in an list to a function's parameter list.

TODO: apply_to_fn has allocation overhead, where as apply_to_fn2 has lookup
      overhead.  NEED TO BENCHMARK to determine which to keep.

<details><summary>parameters and return info</summary>

##### `fn` (`function(...) : any`)
A lambda that takes between 0 and 15 parameters.


##### `p` (`list`)
A list of elements to apply to the function fn.  Must have the same or
fewer elements than `fn` can take and must be less than 15 elements.


##### Returns (`any`)

The return value of fn().

</details><hr/>

#### **apply_to_fn2**
`function apply_to_fn2(fn, p)`

Applies each element in an list to a function's parameter list.

TODO: apply_to_fn has allocation overhead, where as apply_to_fn2 has lookup
      overhead.  NEED TO BENCHMARK to determine which to keep.

<details><summary>parameters and return info</summary>

##### `fn` (`function(...) : any`)
A lambda that takes between 0 and 15 parameters.


##### `p` (`list`)
A list of elements to apply to the function fn.  Must have the same or
fewer elements than `fn` can take and must be less than 15 elements.


##### Returns (`any`)

The return value of fn().

</details><hr/>


## test

### Purpose

Used to generate code for using TDD methodology.  Tries to report useful
error messages with an optional user configurable message.

### Test Your Code!

#### **test_eq**
`module test_eq(expected, got, msg="")`


#### **test_approx_eq**
`module test_approx_eq(expected, got, epsilon, msg="")`


#### **test_ne**
`module test_ne(not_expected, got, msg="")`


#### **test_lt**
`module test_lt(lhs, rhs, msg="")`


#### **test_le**
`module test_le(lhs, rhs, msg="")`


#### **test_gt**
`module test_gt(lhs, rhs, msg="")`


#### **test_ge**
`module test_ge(lhs, rhs, msg="")`


#### **test_truthy**
`module test_truthy(val, msg="")`


#### **test_falsy**
`module test_falsy(val, msg="")`



## transform

### Purpose

This library is for matrix math for a verity of things.


### Generate Matrices for Vector Transforms
#### **transpose**
`function transpose(A)`

Transpose of a matrix.

- Matrix (list of equal-length rows) → transposed matrix

> **NOTE:**
>
> There is no need to transpose a vector to a column vector.  When OpenSCAD
> sees M * V or V * M, the vector V is automatically treated as a column or
> row vector as appropriate.

<details><summary>parameters and return info</summary>

##### `A` (`matrix`)
The matrix to transpose.


##### Returns (`matrix`)

The transpose of matrix A.

</details><hr/>

#### **homogenise**
`function homogenise(pts, n=4)`

Convert points to homogeneous coordinates.

Each point is padded with zeros up to dimension n-1, then a trailing 1 is
appended.

<details><summary>parameters and return info</summary>

##### `pts` (`list[list[number]]`)
List of points.  Each point must have dimension < n.


##### `n` (`number`)
Target homogeneous dimension.  Must be greater than the dimension of every
point in pts.


##### Returns (`list[list[number]]`)

List of n-dimensional points with homogeneous coordinate 1 at index n-1.

</details><hr/>

#### **dehomogenise**
`function dehomogenise(pts, n=3)`

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

##### `pts` (`list[list[number]]`)
List of homogeneous points.


##### `n` (`number`) *(Default: `3`)*
Number of Euclidean coordinates to return per point.


</details><hr/>

#### **homogenise_transform**
`function homogenise_transform(A, n=4)`

Embed a non-homogeneous square transform into a larger homogeneous matrix.

Returns a **homogeneous column-vector** matrix H (n×n).  A is placed in the
top-left block.

Use:
- If H is used as a transform matrix, apply it like any other homogeneous
  column-vector matrix:
  - Single point p: treat p as homogeneous when multiplying.
  - Point list Ps: use transform(Ps, transpose(H)).

<details><summary>parameters and return info</summary>

##### `A` (`matrix`)
Square M×M transform matrix.


##### `n` (`number`)
Target homogeneous dimension.  Must satisfy M < n.


##### Returns (`matrix`)

Homogeneous matrix H (n×n) with A in the top-left block and identity
elsewhere.

</details><hr/>

#### **rot_x**
`function rot_x(a)`

Rotation matrix about the X axis.

Returns a **non-homogeneous column-vector** rotation matrix M (3×3).

Use:
- Single point p (3-vector):  p' = M * p
- Point list Ps:              Ps' = Ps * transpose(M)

<details><summary>parameters and return info</summary>

##### `a` (`number`)
Rotation angle in degrees.


##### Returns (`matrix 3x3`)

Column-vector rotation matrix M.

</details><hr/>

#### **rot_y**
`function rot_y(a)`

Rotation matrix about the X axis.

Returns a **non-homogeneous column-vector** rotation matrix M (3×3).

Use:
- Single point p (3-vector):  p' = M * p
- Point list Ps:              Ps' = Ps * transpose(M)

<details><summary>parameters and return info</summary>

##### `a` (`number`)
Rotation angle in degrees.


##### Returns (`matrix 3x3`)

Column-vector rotation matrix M.

</details><hr/>

#### **rot_z**
`function rot_z(a)`

Rotation matrix about the Y axis.

Returns a **non-homogeneous column-vector** rotation matrix M (3×3).

Use:
- Single point p (3-vector):  p' = M * p
- Point list Ps:              Ps' = Ps * transpose(M)

<details><summary>parameters and return info</summary>

##### `a` (`number`)
Rotation angle in degrees.


##### Returns (`matrix 3x3`)

Column-vector rotation matrix M.

</details><hr/>

#### **rot_axis**
`function rot_axis(angle, axis)`

Rotation matrix about an arbitrary axis.

Returns a **non-homogeneous column-vector** rotation matrix M (3×3).

Use:
- Single point p (3-vector):  p' = M * p
- Point list Ps:              Ps' = Ps * transpose(M)

<details><summary>parameters and return info</summary>

##### `angle` (`number`)
Rotation angle in degrees.


##### `axis` (`list[number]`)
Rotation axis vector (must be non-zero).


##### Returns (`matrix 3x3`)

Column-vector rotation matrix M.

</details><hr/>

#### **rotate**
`function rotate(a, b=undef)`

Rotation matrix that parallels OpenSCAD's rotate() module.

Returns a **non-homogeneous column-vector** rotation matrix M (3×3).

Use:
- Single point p (3-vector):  p' = M * p
- Point list Ps:              Ps' = Ps * transpose(M)

<details><summary>parameters and return info</summary>

##### `a` (`number | list[number]`)
- If number and b is undef: rotate CCW around Z.
- If number and b is a 3-vector: rotate CCW around axis b.
- If 3-vector [rx,ry,rz]: apply rotations about X then Y then Z (degrees).
  (b is ignored.)


##### `b` (`undef | list[number]`)
Axis vector when a is a number.  If undef, axis is Z.


##### Returns (`matrix 3x3`)

Column-vector rotation matrix M.

</details><hr/>

#### **translate**
`function translate(v)`

Translation matrix that parallels OpenSCAD's translate() module.

Returns a **homogeneous column-vector** translation matrix T (4×4).

Use:
- Single 3D point p: treat p as [x,y,z,1] (homogeneous) when multiplying.
- Point list Ps (3D): use transform(Ps, transpose(T)).  (Preferred.)

<details><summary>parameters and return info</summary>

##### `v` (`list[number]`)
Translation vector.


##### Returns (`matrix 4x4`)

Homogeneous column-vector translation matrix T.

</details><hr/>

#### **scale**
`function scale(v)`

Scale matrix that parallels OpenSCAD's scale() module.

Returns a **non-homogeneous column-vector** scaling matrix S (3×3).

Use:
- Single point p (3-vector):  p' = S * p
- Point list Ps:              Ps' = Ps * transpose(S)

<details><summary>parameters and return info</summary>

##### `v` (`list[number]`)
Per-axis scale factors.


##### Returns (`matrix 3x3`)

Column-vector scaling matrix S.

</details><hr/>

#### **transform**
`function transform(pts, matrix_or_fn)`

Transform a list of points using either a matrix or a point-mapping function.

Points in pts are treated as **row vectors** (each point is a 1×d row).

- If matrix_or_fn is a matrix, this function computes: pts * matrix_or_fn.
  Therefore, if you have a column-vector matrix M intended for M * p, pass
  transpose(M) here.

- If matrix_or_fn is a homogeneous matrix (e.g.  4×4 for 3D points), this
  function homogenises pts, multiplies, then dehomogenises back to the
  original point dimension.

<details><summary>parameters and return info</summary>

##### `pts` (`list[list[number]]`)
List of points (rows).  All points must have the same dimension.


##### `matrix_or_fn` (`matrix | function(pt) : list[number]`)
Either:
- a matrix in row-vector orientation (typically transpose(M)), or
- a function that maps a single point to a transformed point.


##### Returns (`list[list[number]]`)

Transformed points.

</details><hr/>

#### **reorient**
`function reorient(start_line_seg, end_line_seg, scale_to_vectors = false)`

Returns a homogeneous column-vector transform matrix T (4×4) that maps one
line segment to another.

Use:
- Single 3D point p: treat p as [x,y,z,1] (homogeneous) when multiplying.
- Point list Ps (3D): use transform(Ps, transpose(T)).  (Preferred.)

<details><summary>parameters and return info</summary>

##### `start_line_seg` (`list[list[number], list[number]]`)
The source line segment: [P0, P1].


##### `end_line_seg` (`list[list[number], list[number]]`)
The target line segment: [Q0, Q1].


##### `scale_to_vectors` (`bool`) *(Default: `false`)*
Only affects the 2-point overload.  If true, also apply uniform scaling by
|Q1-Q0|/|P1-P0|.


##### Returns (`matrix 4x4`)

Homogeneous column-vector transform matrix T.

</details><hr/>


### Matrix Math
#### **invert**
`function invert(A, eps = 1e-12)`

Invert a square matrix using Gauss-Jordan elimination with partial pivoting.

<details><summary>parameters and return info</summary>

##### `A` (`matrix`)
Non-empty square numeric matrix (list of equal-length lists).


##### `eps` (`number`) *(Default: 1e-12)*
Pivot tolerance.  Must be > 0.


##### Returns (`matrix`)

The inverse matrix A^{-1}.


</details><hr/>

#### **row_reduction**
`function row_reduction(aug, k, n, eps)`

Performs Gauss-Jordan row reduction with partial pivoting on an augmented
matrix.

<details><summary>parameters and return info</summary>

##### `aug` (`matrix`)
Augmented matrix of shape n×(2n), typically [A | I].


##### `k` (`number`)
Current column index (0-based).  External callers pass 0.


##### `n` (`number`)
Matrix order.  Must equal the row count of aug.


##### `eps` (`number`)
Pivot tolerance.  Must be > 0.


##### Returns (`matrix`)

The reduced augmented matrix.  For a nonsingular A this is [I | A^{-1}].


</details><hr/>

#### **identity**
`function identity(n)`

Creates an n×n identity matrix.

<details><summary>parameters and return info</summary>

##### `n` (`number`)
Matrix order.  Must be > 0.


##### Returns (`matrix`)

The identity matrix of order n.

</details><hr/>

#### **augment**
`function augment(A, B)`

Horizontally concatenates two matrices with the same row count.

<details><summary>parameters and return info</summary>

##### `A` (`matrix`)
Left matrix with r rows.


##### `B` (`matrix`)
Right matrix with r rows.


##### Returns (`matrix`)

The augmented matrix [A | B].


</details><hr/>


## helpers

### Purpose

Miscellaneous helper functions.


### Conversion functions
#### **r2d**
`function r2d(radians)`

Convert radians to degrees.

<details><summary>parameters and return info</summary>

##### `radians` (`number`)
radians to convert.


##### Returns (`number`)

Equivalent degrees.

</details><hr/>

#### **d2r**
`function d2r(degrees)`

Convert degrees to radians.

<details><summary>parameters and return info</summary>

##### `degrees` (`number`)
degrees to convert.


##### Returns (`number`)

Equivalent radians.

</details><hr/>


### Circular / Spherical Calculations
#### **arc_len**
`function arc_len(A, B, R=undef)`

Calculates the arc length between vectors A and B for a circle/sphere of
radius R.  If A and B are the same magnitude, R can be omitted.

<details><summary>parameters and return info</summary>

##### `A` (`list`)
First vector.


##### `B` (`list`)
Second vector.


##### `R` (`undef | number`)
Radius to use to measure the length along a sphere's great arc.
- If undef then will use the magnitude of A. Asserts if magnitude of B is
  not the same.
- If R=1, then the result is equivalent to the arc angle in radians.
- If R=180/PI, then the result is equivalent to the arc angle in degrees.


##### Returns (`number`)

The length of the great arc between the two vectors for a sphere of radius
R.

</details><hr/>

#### **arc_len_angle**
`function arc_len_angle(arc_len, radius)`

Given the length of an arc and the radius of a circle/sphere that it's
traversing, returns the angle traversed in degrees.

`arc_len` and `radius` have the same units.

<details><summary>parameters and return info</summary>

##### `arc_len` (`number`)
Arc length along the circle.


##### `radius` (`number`)
Circle radius (must be non-zero).


##### Returns (`number`)

Angle in degrees. Sign follows arc_len.

</details><hr/>

#### **arc_len_for_shift**
`function arc_len_for_shift(R, m, a, b = 0)`

Given a `circle R = sqrt(x^2 + y^2)` and a line `y = m*x + (b + a)`,
compute the arc-length difference `Δs` along the circle between the
intersection of the original line `y = m*x + b` and the shifted line
`y = m*x + (b + a)`. Only the right-side `(x >= 0)` intersection is tracked.

<details><summary>parameters and return info</summary>

##### `R` (`number`)
circle radius


##### `m` (`number`)
slope (dy/dx)


##### `a` (`number`)
vertical shift of the line relative to b


##### `b` (`number`)
original y-intercept (default 0)


##### Returns (`number`)

Δs (nonnegative) or undef if the right-side intersection does not exist
before or after the shift.

</details><hr/>

#### **shift_for_arc_len**
`function shift_for_arc_len(R, m, delta_s, b = 0)`

Given a circle `R = sqrt(x^2 + y^2)` and line `y = m*x + b`, compute the
vertical (y-axis) shift values a that would produce a specified arc-length
difference `Δs` between the original intersection and the shifted line
`y = m*x + (b + a)`, tracking only the right-side `(x >= 0)` intersection.

<details><summary>parameters and return info</summary>

##### `R` (`number`)
circle radius


##### `m` (`number`)
slope (dy/dx)


##### `delta_s` (`number`)
desired arc length difference


##### `b` (`number`)
original y-intercept (default 0)


##### Returns (`[a_up_or_undef, a_down_or_undef]`)

a_up ≥ 0, a_down ≤ 0.

</details><hr/>


### Miscellaneous
#### **not**
`function not(not_fn)`

Wrap a lambda so that it negates its return value.

<details><summary>parameters and return info</summary>

##### `not_fn` (`function (p) : any`)
The function to invert the boolean's (or equivalent truthy/falsy) value.


##### Returns (`function (p) : bool`)

Return the lambda that will invert a lambda's truth value.

</details><hr/>

#### **clamp**
`function clamp(v, lo, hi)`

Clamps a value between [lo, hi].

<details><summary>parameters and return info</summary>

##### `v` (`number`)
Value to clamp.


##### `lo` (`number`)
Lowest value v should take.


##### `hi` (`number`)
Highest value v should take.


##### Returns (`number`)

Value v that is clamped between [lo, hi].

</details><hr/>

#### **vector_info**
`function vector_info(a, b)`

Computes direction, length, unit vector and normal to unit vector, and puts
them into an list.

Add `include <helpers_consts>` to use the appropriate constants.

<details><summary>parameters and return info</summary>

##### `a` (`Point`)
Starting point of vector


##### `b` (`Point`)
Ending point of vector


##### Returns (`Array[Point]`)

result[VI_VECTOR] = direction of ab
result[VI_LENGTH] = length of ab
result[VI_DIR   ] = unit ab vector
result[VI_NORMAL] = normal unit vector of ab

</details><hr/>

#### **equal**
`function equal(v1, v2, epsilon = 1e-6)`

Checks the equality of two items.  If v1 and v2 are lists of the same length,
then check the equality of each element.  If each are numbers, then check to
see if they are both equal to each other within an error of epsilon.  All
other types are done using the == operator.

<details><summary>parameters and return info</summary>

##### `v1` (`any`)
First item to compare against.


##### `v2` (`any`)
Second item to compare against.


##### `epsilon` (`number`)
The max error tolerated for a number.


##### Returns (`bool`)

True if the objects are equal within tolerance.  False otherwise.

</details><hr/>

#### **function_equal**
`function function_equal()`


#### **default**
`function default(v, d)`

If v is undefined, then return the default value d.

<details><summary>parameters and return info</summary>

##### `v` (`any`)
The value to test if defined.


##### `d` (`any`)
The result to give if v is undefined.


##### Returns (`any`)

If v is defined, then return v, else d.

</details><hr/>

#### **INCOMPLETE**
`function INCOMPLETE(x=undef)`

Used to mark code as incomplete.
#### **offset_angle**
`function offset_angle(ref_vec, vec, delta_angle_deg)`

Rotate vec so that the angle between ref_vec and vec increases by
delta_angle_deg.

Uses rotate(delta_angle_deg, cross(ref_vec, vec)) and applies it to vec.

<details><summary>parameters and return info</summary>

##### `ref_vec` (`list[number]`)
Reference vector.  Must have norm(ref_vec) > 0.


##### `vec` (`list[number]`)
Vector to rotate.  Must have norm(vec) > 0 and must not be (anti)parallel to
ref_vec.


##### `delta_angle_deg` (`number`)
Angle increase in degrees.


##### Returns (`list[number]`)

The rotated vector.

</details><hr/>

#### **arrow**
`module arrow(l, t=1, c, a)`

Create an arrow pointing up in the positive z direction.  Primarily used for
debugging.

<details><summary>parameters</summary>

##### `l` (`number`)
Length of arrow.


##### `t` (`number`)
Thickness of arrowhead shaft.


##### `c` (`list | string | undef`)
Same as color() module's first parameter. [r, g, b], [r, g, b, a],
"color_name", "#hex_value".  If not defined, no colour is applied.


##### `a` (`number`)
Same as color() module's optional second parameter.  Alpha value between
[0, 1].

</details><hr/>

#### **axis**
`module axis(l, t=1)`

Create 3 arrows aligning to x, y and z axis coloured red, green and blue
respectively.

<details><summary>parameters</summary>

##### `l` (`number`)
Length of arrow.


##### `t` (`number`)
Thickness of arrowhead shaft.

</details><hr/>

#### **fl**
`function fl(f, l)`

File line function to output something that looks like a file line to be able
to jump to the file/line in VSCode easier.

To make it easier in a file, create the following variable in that file:

    _fl = function(l) fl("<this-file-name>", l);

As a variable, it won't get exported.  Use that in your file.

<details><summary>parameters and return info</summary>

##### `f` (`string`)
Name of file.


##### `l` (`number`)
Line number in file.


##### Returns (`string`)

Returns a string which will allow you to ctrl-click on the string text from
the terminal window.

</details><hr/>

#### **interpolated_values**
`function interpolated_values(p0, p1, number_of_values)`

Gets a list of `number_of_values` between `p0` and `p1`.

If `p0` and `p1` must be the same shape and must comprise of values that have
+, - and / operations defined for them.

## skin

### Purpose

The built in extrude module isn't powerful or flexible enough so this library
was made.  It creates a skin by making layers of polygons with the same
number of vertices and then skins them by putting faces between layers.


### Design

This requires keeping track of a bunch of data, which was put into a list.

#### **skin_to_string**
`function skin_to_string(obj, only_first_and_last_layers = true, precision = 4)`

Converts a skin object to a human readable string.

<details><summary>parameters and return info</summary>

##### `obj` (`skin`)
This is the skin object to view.


##### `only_first_and_last_layers` (`bool`)
Show only the first and last layers if true, otherwise all layers.


##### `precision` (`number`)
The number of decimal places to show the layers.


##### Returns (`string`)

The string representation of the skin object.

</details><hr/>

#### **layer_pt**
`function layer_pt(pts_in_layer, pt_i, layer)`

Computes the linear index of a point in a layered point array.

This allows to more easily visualise what points are being referenced,
relative to different layers.

Assumes that points are stored consecutively per layer, and layers are
stacked consecutively in memory.

<details><summary>parameters and return info</summary>

##### `pts_in_layer` (`integer`)
Number of points in each layer.


##### `pt_i` (`integer`)
Index of the point (0-based).  If > pts_in_layer, then wraps back to 0.


##### `layer` (`integer`)
Index of the layer (0-based).


##### Returns (`integer`)

The linear index of the specified point.

</details><hr/>

#### **layer_pts**
`function layer_pts(pts_in_layer, pt_offset_and_layer_list)`

Computes a list of linear layer_i for multiple points in a layered point
array.

This allows to more easily visualise what points are being referenced,
relative to different layers.

Assumes points are stored consecutively per layer, with each layer laid out
sequentially.

<details><summary>parameters and return info</summary>

##### `pts_in_layer` (`integer`)
Number of points per layer.


##### `pt_offset_and_layer_list` (`list of [pt_offset, layer]`)
List of (point index, layer index) pairs.


##### Returns (`list of integer`)

A list of linear layer_i corresponding to the given points.

</details><hr/>

#### **layer_side_faces**
`function layer_side_faces(pts_in_layer, layers = 1, wall_diagonal = [0, 1])`

Helper to generate side wall faces between consecutive layers.

Assumes the points are arranged in a flat list, with each layer's points
stored contiguously, and layers stored in sequence. Points within each
layer must be ordered **clockwise when looking into the object**.

Each wall segment is formed from two triangles connecting corresponding
points between adjacent layers.

<details><summary>parameters and return info</summary>

##### `pts_in_layer` (`integer`)
Number of points per layer.


##### `layers` (`integer`)
Number of vertical wall segments to generate (requires one more point
layer).


##### `wall_diagonal` (`list[bool]`)
This is used to allow changing the diagonal of neighbouring square polygons
on a layer.

E.g.
  - [1] will have all diagonals go one way.
  - [1,0] will alternate.
  - [0,1] will alternate the opposite way to [1,0].
  - [0,0,1] will have it go one way for 2 consecutive squares, and then the
    other way, and then repeat.


##### Returns (`list of [int, int, int]`)
:
A list of triangle layer_i forming the side walls.

</details><hr/>

#### **filter_out_degenerate_triangles**
`function filter_out_degenerate_triangles(pts3d, triangles)`

Not Documented<hr/>

#### **is_skin**
`function is_skin(obj)`

Checks to see if object is a skin object
#### **skin_new**
`function skin_new(pt_count_per_layer, layers, pts3d, comment, operation, wall_diagonal, debug_axes)`

Create a new skin object.

<details><summary>parameters and return info</summary>

##### `pt_count_per_layer` (`integer`)
number of points per layer (must be ≥ 3)


##### `layers` (`integer`)
Number of wall segments (requires `layers + 1` total point layers).


##### `pts3d` (`list of [x, y, z]`)
The full list of points arranged in stacked layers.


##### `comment` (`string`)
Usually a string, this is just a comment for reading and debugging purposes.


##### `operation` (`string`)
This is used by skin_to_polyhedron() when passing a list of SKIN objects.
If a SKIN object has an operation attached, then that SKIN object will have
the operation specified applied to the next element in the list which can
be an object or list of objects.


##### `wall_diagonal` (`list[bool]`)
This is used to allow changing the diagonal of neighbouring square polygons
on a layer.

E.g.
  - [1] will have all diagonals go one way.
  - [1,0] will alternate.
  - [0,1] will alternate the opposite way to [1,0].
  - [0,0,1] will have it go one way for 2 consecutive squares, and then the
    other way, and then repeat.


##### `debug_axes` (`list[list[Point3D]]`)
This is a list of point groups.  The first element in the point group is
the reference point.  Everything after that is a point relative to that
reference point.  When debugging, call skin_show_debug_axis().  INCOMPLETE
and UNTESTED.


##### Returns (`skin object`)


</details><hr/>

#### **skin_extrude**
`function skin_extrude(birl, end_i, comment, operation, wall_diagonal, debug_axes)`

**Overloads:**

    skin_extrude(birl, end_i, comment, operation, wall_diagonal, debug_axes) (pts_fn) : skin

Generates an extruded point list from a number range, range or list of
indices.

<details><summary>parameters and return info</summary>

##### `birl` (`number | range | list`)
- If number, start index to check
- If range, indices to check
- If list, indices to check


##### `end_i` (`number | undef`)
- If birl is a number, then end index to check.  end_i
  could be less than birl if there's nothing to iterate
  over.


##### `comment` (`string`)
Usually a string, this is just a comment for reading and debugging purposes.


##### `operation` (`string`)
This is used by skin_to_polyhedron() when passing a list of SKIN objects.
If a SKIN object has an operation attached, then that SKIN object will have
the operation specified applied to the next element in the list which can
be an object or list of objects.


##### `wall_diagonal` (`list[bool]`)
This is used to allow changing the diagonal of neighbouring square polygons
on a layer.

E.g.
  - [1] will have all diagonals go one way.
  - [1,0] will alternate.
  - [0,1] will alternate the opposite way to [1,0].
  - [0,0,1] will have it go one way for 2 consecutive squares, and then the
    other way, and then repeat.


##### `pts_fn` (`function(i) list_of_points`)
Function that returns a list of points for layer i.  It's fine to have
duplicate points in list as degenerate triangles will be filtered when
calling skin_to_polyhedron.

> **NOTE:**
>
> Points **MUST** wind in clockwise order when looking into object from
> starting layer towards next layer.
>
> Non-coplanar points on a layer may result in UB. Especially on end caps.


##### Returns (`skin object`)


</details><hr/>

#### **skin_create_faces**
`function skin_create_faces(skin)`

Generates face layer_i to skin a layered structure, including:
  - bottom cap (layer 0)
  - top cap (layer = layers)
  - side wall faces between adjacent layers

Assumes that points are stored in a flat array, with `pts_in_layer`
points per layer, and layers stored consecutively. Points within each
layer must be ordered clockwise when looking into the object.

<details><summary>parameters and return info</summary>

##### `skin` (`skin`)
The skin object generating the faces from.


##### Returns (`list of [int, int, int]`)
:
A list of triangle face definitions.

</details><hr/>

#### **skin_transform**
`function skin_transform(obj_or_objs, matrix_or_fn)`

Performs a transformation on the points stored in the skin object.

<details><summary>parameters and return info</summary>

##### `obj` (`skin object`)
The skin object where the points are coming from to transform.


##### `matrix_or_fn` (`list[list[number]] | function(pt) : pt`)
The matrix or function to do the transformation with.  If the
transformation is homogenous, then will convert the points to a homogeneous
basis, perform the transformation and then remove the basis.


##### Returns (`skin object`)
:
A new skin object with the points transformed.

</details><hr/>

#### **skin_to_polyhedron**
`module skin_to_polyhedron(obj_or_objs)`

Takes the skin object and make it into a polyhedron.  If obj is a list, will
assume all are skin objects and attempt to skin them all.

<details><summary>parameters and return info</summary>

##### `obj_or_objs` (`skin object | list<skin object>`)
The skin object or list of skin objects to make into a polyhedron.


##### Returns (`skin object`)
:
A new skin object with the points transformed.

</details><hr/>

#### **skin_add_layer_if**
`function skin_add_layer_if(obj, add_layers_fn)`

Adds a number of interpolated layers between layers based how many
add_layers_fn(i) returns.

<details><summary>parameters and return info</summary>

##### `obj` (`SKIN object`)
Object to add to.


##### `add_layers_fn` (`function(i) : number_of_layers_to_add`)
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


##### Returns (`SKIN object`)

Updated SKIN object.

</details><hr/>

#### **skin_add_point_in_layer**
`function skin_add_point_in_layer(obj, add_pts_after_pt_numbers)`

Not Documented<hr/>

#### **skin_show_debug_axes**
`module skin_show_debug_axes(obj, styles = [["red", 1, .1], ["green"], ["blue"]])`

UNTESTED!
Shows the debug axes to verify where you think things should be.

<details><summary>parameters</summary>

##### `obj` (`SKIN object`)
Object to show debug axes for.


##### `styles` (`list<list<color, alpha, thickness>>`)
Contains a list of styles that are reused when the number of points in a
debug group exceeds the the number of styles.

If a style doesn't contain a colour, alpha or thickness (set as undef),
will go backwards to find one that does and uses that.

</details><hr/>

#### **interpolate**
`function interpolate(v0, v1, v)`

Interpolates value between v0 and v1?
#### **skin_limit**
`function skin_limit(obj, extract_order_value_fn, begin, end)`

INCOMPLETE!
Truncates the beginning, end or both of the extrusion.

<details><summary>parameters and return info</summary>

##### `obj` (`skin object`)
Object to remove values before in points.  Value extracted from points MUST
BE monotonically nondecreasing over the points list.


##### `extract_order_value_fn` (`function(pt) : extracted_value`)
This take in a point and returns some value.  This is to allow selection of
a particular axis or length for a given point to compare against value.


##### `begin` (`number`) *(Default: `extract_order_value_fn(el(obj[SKIN_PTS],  0))`)*
The value to compare against the extracted value from a point.


##### `end` (`number`) *(Default: `extract_order_value_fn(el(obj[SKIN_PTS], -1))`)*
The value to compare against the extracted value from a point.


##### Returns (`skin object`)

Updated skin object with all of the points before value removed.  If
extracted value is not EXACTLY value, then will linearly interpolated to
cup off EXACTLY at value.

</details><hr/>

#### **skin_verify**
`function skin_verify(obj, disp_all_pts = false)`

For debugging, returns a string reporting the stats of a skin object.

Asserts if the object's number of points doesn't correspond to the equation:

  `(layers + 1) * pts_in_layer`

<details><summary>parameters and return info</summary>

##### `obj` (`SKIN object`)
Object to verify.


##### `disp_all_pts` (`bool`)
- If false, only returns the first and last points in the list.
- If true, returns all points, with each layer of points on a separate line.


##### Returns (`string`)

A prettified/simplified view of points in the object.

</details><hr/>

#### **skin_max_layer_distance_fn**
`function skin_max_layer_distance_fn(obj, max_diff, diff_fn = function(p0, p1) p1.x - p0.x)`

Returns a function that can be used with skin_add_layer_if() to ensure that
the distance between layers don't exceed some length.

<details><summary>parameters and return info</summary>

##### `obj` (`SKIN object`)


##### `max_diff` (`number`)
Maximum distance before adding another layer to reduce the distance below
max_diff.


##### `diff_fn` (`function(p0, p1) : distance_between_layers`) *(Default: checks x distances)*
Callback that gives the distance between layers, where `p0` is the first
point of the current layer and `p1` is the first point of the next layer.
Will return a value that states the distance between layers.


##### Returns (`function(i) : number_of_layers_to_add`)

Function that can be used with skin_add_layer_if().

</details><hr/>

#### **skin_max_pt_distance_fn**
`function skin_max_pt_distance_fn(obj, max_diff)`

Not Documented<hr/>

#### **skin_example1**
`module skin_example1()`

Not Documented<hr/>

#### **skin_example2**
`module skin_example2()`

Not Documented<hr/>

#### **skin_example3**
`module skin_example3()`

Not Documented<hr/>

#### **sas_cutter**
`function sas_cutter(a, b, y_thickness, z_thickness,
  lat_wave_segs, lat_wave_cycles, wave_amp,
  long_wave_segs = 4, long_wave_cycles = 0.5,
  cutedge_long_overflow = 1e-4, cutedge_lat_overflow = 1, xy_phase_offset = 90)`

Self aligning seam cutter aligned along edge a → b, with sinusoidal cutface.

<details><summary>parameters and return info</summary>

##### `a` (`Point2D`)
Starting point.


##### `b` (`Point2D`)
Ending point.


##### `y_thickness` (`float`)
Thickness along y-axis of cutter from cutface to handle.


##### `z_thickness` (`float`)
Hight of cutting tool (z-axis).


##### `lat_wave_segs` (`int`)
Number of segments to break up the wave into.


##### `lat_wave_cycles` (`number`)
Number of complete wave_cycles to apply along cutting edge.


##### `wave_amp` (`float`)
Amplitude of the wave on cutting edge (peek to peek).


##### `long_wave_segs` (`int`)
Number of segments to break up the wave into.


##### `long_wave_cycles` (`number`)
Number of complete wave_cycles to apply perpendicular to the cutting edge.


##### `cutedge_long_overflow` (`number`)
Widens the cutter by this amount
     expanding from the centre.


##### `cutedge_lat_overflow` (`number`)
Lengthens the cutter by this amount (rounded to the next segment length)
expanding from the centre.


##### Returns (`SKIN object`)


</details><hr/>

#### **sas2_cutter**
`function sas2_cutter(a, b, y_thickness, z_thickness,
  lat_wall_percent, lat_wave_cycles, wave_amp,
  ignored1 = undef, ignored2 = undef,
  // long_wave_segs = 4, long_wave_cycles = 0.5,
  cutedge_long_overflow = 1e-4, cutedge_lat_overflow = 1, x_phase_offset = 0, comment)`

Self aligning seam cutter 2 aligned along edge a → b, with sinusoidal cutface.

Similar to sas, but uses overlapping tabs instead of bumps that fit into
indentations.

TODO: a and b parameters are misleading.  They are only used for the length.
      Need to fix.

<details><summary>parameters and return info</summary>

##### `a` (`Point2D`)
Starting point.


##### `b` (`Point2D`)
Ending point.


##### `y_thickness` (`float`)
Rhickness of cutter along y-axis from lowest part of cutface to handle.


##### `z_thickness` (`float`)
hight of cutting tool (z-axis).


##### `lat_wall_percent` (`float`)
     When transitioning from the each half cycle to the next point, and a
     point to each half cycle, this is % of a 1/4 cycle traveled along the
     latitude direction.  A value of 0 is a results in a "square wave".  A
     value of 1 would result in a "sawtooth wave".

     E.g.          latitude travel   Square wave           Sawtooth wave
           ___     |↔|__              ___     ___                 
          /   \    |/   \            |   |   |   |           /\  /\
          |    \___/     \___/|      |   |___|   |___       |  \/  \/|
          |___________________|      |_______________|      |________|


##### `lat_wave_cycles` (`number`)
number of complete wave_cycles to apply along cutting edge.


##### `wave_amp` (`float`)
amplitude of the wave on cutting edge (peek to peek).


##### `long_wave_segs` (`int`)
number of segments to break up the wave into.


##### `long_wave_cycles` (`number`)
number of complete wave_cycles to apply perpendicular to the cutting edge.


##### `cutedge_long_overflow` (`number`)
widens the cutter by this amount
     expanding from the centre.


##### `cutedge_lat_overflow` (`number`)
lengthens the cutter by this amount
     (rounded to the next segment length) expanding from the centre.


##### `x_phase_offset` (`number`)
     The starting phase of the a point.  Value must be ∈ [0, 360).


##### Returns (`SKIN object`)


</details><hr/>

#### **scs_cutter**
`function scs_cutter(a, b, y_thickness, z_thickness,
  lat_wave_segs, lat_wave_cycles, wave_amp,
  long_wave_segs = 4, long_wave_cycles = 0.5,
  cutedge_long_overflow = 1e-4, cutedge_lat_overflow = 1, xy_phase_offset = 90)`

Self connecting seam cutter aligned along edge a → b, with sinusoidal cutface.
INCOMPLETE!

<details><summary>parameters</summary>

##### `a` (`Point2D`)
starting point.


##### `b` (`Point2D`)
ending point.


##### `y_thickness` (`float`)
y_thickness of cutter from cutface to handle.


##### `z_thickness` (`float`)
hight of cutting tool (z-axis).


##### `lat_wave_segs` (`int`)
number of segments to break up the wave into.


##### `lat_wave_cycles` (`number`)
number of complete wave_cycles to apply
     along cutting edge.


##### `wave_amp` (`float`)
amplitude of the wave on cutting edge (peek to peek).


##### `long_wave_segs` (`int`)
number of segments to break up the wave into.


##### `long_wave_cycles` (`number`)
number of complete wave_cycles to apply
     perpendicular to the cutting edge.


##### `cutedge_long_overflow` (`number`)
widens the cutter by this amount
     expanding from the centre.


##### `cutedge_lat_overflow` (`number`)
lengthens the cutter by this amount
     (rounded to the next segment length) expanding from the centre.

</details><hr/>

