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

 1. [ranges](#file-range)
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
