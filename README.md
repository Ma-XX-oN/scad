# Algorithms

Don't include these files.  Use the `use<>` idiom.

There are several files in this library.

1. base_algos
   - The base algorithms which most of the rest of the library uses.
2. birlei
   - Refers to the two parameters that keep popping up in this library.
   - `birl` refers to Begin Index, Range or List.  `ei` (a.k.a. `end_i`) refers
     to End Index.  Together, they give a range of number values, usually used
     as indices to dereference elements from indexable objects like strings,
     lists, or ranges.
   - When birlei are two numbers, `birl` **must be <=** `end_i` or nothing is
     iterated over.  There is no warning.  This is by design.
2. range
   - Wraps OpenSCAD ranges `[start:stop]`/`[start:step:stop]`, adds extra
     functionality and remove warnings from null ranges.  Ranges are considered
     indexable using `range_el`.
3. list
   - Adds some functions to manipulate a list as a stack / queue, use
     negative indices to get the indices/elements at the end, insert /
     remove / replace elements, any / all tests and format to a
     string.
4. types
   - Allows for classifying object types that are beyond the standard
     `is_num`, `is_string`, `is_list`, `is_undef`, `is_function`, `is_bool` by
     adding `is_int`, `is_float`, `is_range` and `is_nan`.  `is_range` is
     defined in range library.
   - Gets an enum for an object type.
   - Gets a minimal string representing the type of an object.
5. test
   - Testing modules for TDD.
6. helpers
   - Point transform functions, equivalent function, and other miscellaneous
     functions.
7. csearch
   - Searches for a contagious series of elements. 
8. skin
   - Helper in generating a polyhedron using slices.
9. sas_cutter
   - Creates a skin which is used as a cutting tool help to align two
     separate parts together.

## base_algos

### Purpose:

The purpose of this library is to provide the minimum number of abstracted
composable algorithms to be able to make coding easier.  Both when reading and
writing.

This file contains the 4 basic algorithms (`reduce`, `reduce_air`, `filter` and
`map`) which most other algorithms can be built from.  For optimisation
purposes, `reduce_air` adds the ability to Allow an Incomplete Reduction (hence
the `_air` suffix) over the range and filter adds a hybrid filter/map feature.

A few others (`find`, `find_upper`, `find_lower`) could have been implemented
with `reduce_air` but have been optimised with their own implementations.

The `find*` and `reduce` algorithms rely on recursive descent, but conform to
TCO (Tail Call Optimisation) so don't have a maximum depth.  The `filter` and
`map` algorithms use list comprehension so also have no limit to their range
size.

1. `reduce`
   - Reduce (aka fold) a range of indices to a some final result.
   - This is equivalent to a for_each loop.
2. `reduce_air`
   - Reduce a range of indices to a some final result.
   - Reduce operation Allows for Incomplete Reduction, which means that it
     can abort before iterating over the entire range.
   - This is equivalent to a for loop.
3. `filter`
   - Create a list of indices or objects where some predicate is true.
4. `map`
   - Create a list of values/objects based on a range of indices.
5. `find`
   - Look for the first index in a range where a predicate returns true.
6. `find_lower`
   - Like C++ lower_bound: returns the first index i for which a spaceship
     predicate >= 0, or undef if none are found.
7. `find_upper`
   - Like C++ upper_bound: returns the first index i for which a spaceship
     predicate > 0, or undef if none are found.

### Algorithm Signatures

All of the algorithms have a compatible signature that consists of a PPMRRAIR
function and one or two parameters (`birl` and optional `end_i`) to state what
indices are going to be iterated over.  Together, I refer to them as birlei

If the PPMRRAIR function is wanted at
the end, use the fn_* adaptors.  These adaptors can return a function that takes
a PPMRRAIR, making the call look reminiscent of a scoped block.

### Adaptors

The PPMRRAIR function usually takes an integer as it's first parameter,
referring to the current index.  For convenience, there are adaptor functions
which allow referencing an array's structure/value.
  - `in_list`: passes array element.
  - `enum_list`: passes [index, element].
  - `ref_list`: passes index.
Using these adaptors will also use the length of the array as reference if the
birlei is partially or fully omitted.

### PPMRRAIR functions

Named after the 4 function types: Predicate, Predicate/Map, Reduction and
Reduction that Allows for Incomplete Reduction, these functions are passed to
the algorithms:

#### 1. Predicate (function (i) : result)
   - A binary predicate is used by `find`, `filter` and `map`.  It has 2
     results, true or false.
   - A trinary predicate is used with `find_lower` and `find_upper`.  It has 3
     results: less than 0, equal to 0 and greater than 0.  This is akin to the
     spaceship operator in c++20.
#### 2. Predicate/Map (function (i, v) : any)
   - Optionally used by `filter`.
   - If v is not passed, then it acts like a binary predicate.  Otherwise, if
     passed a true value, usually returns the element at that index, but can
     map to something else.
   - This 2 parameter function is a performance and memory allocation
     optimisation, allowing `filter` to do a `map` in the same step.
#### 3. Reduction (function (i, acc) : acc)
   <p style="margin-left: 3em; text-indent: -3em;">
   <b>NOTE</b>: <code>acc</code> <i>IS THE SECOND PARAMETER</i> which is
                different from most languages.  This is to keep it consistent
                with the rest of the PPMRRAIR functions and this library in
                general.  You have been warned.
   </p>

   - Used by `reduce`.
   - Takes in the index and the previous accumulated object and returns the
     new accumulated object.
   - This is roughly equivalent to a for_each loop in C++.
#### 4. Reduction, Allow Incomplete Reduction (function (i, acc) : [cont, acc])
   <p style="margin-left: 3em; text-indent: -3em;">
   <b>NOTE</b>: <code>acc</code> <i>IS THE SECOND PARAMETER</i> which is
                different from most languages.  This is to keep it consistent
                with the rest of the PPMRRAIR functions and this library in
                general.  You have been warned.
   </p>

   - Used by `reduce_air`.
   - Takes in the index and the previous accumulated object and returns a
     list [ cont, new_acc ].
   - This is roughly equivalent to a for loop in C++.

### Iterators:

These algorithms are index, not element centric, which means that a physical
container (i.e. list) is not needed.  A virtual container (i.e. function) is
all that is required.  The indices act as iterators as one might find in C++.

The `birl` (formally `begin_i_range_or_list`) parameter for each of these
algorithms state either:

1. Starting index (number)
   - Implies that `end_i` will indicate the inclusive end index (number).  This
     conforms to how ranges in OpenSCAD work.
2. Indices (range)
   - Will go through each item in the range and use them as indices to pass
     to the algorithm.  `end_i` is ignored.
3. Indices (list)
   - Will go through each element in the list and use them as indices to pass
     to the algorithm.  `end_i` is ignored.

### Helpers functions:

#### 1. `not(fn)`
   - Returns a lambda that will take one parameter and return the negation of
     what the original function would give if passed that one parameter.
#### 2. `param_count(fn)`
   - Returns the number of parameters that the lambda takes.
   - See `param_count_direct_recursion_demo` to see how it would look if using
     direct recursion.
#### 3. `in_list(array, algo_fn, ppmrrair_fn, birl = 0, end_i = el_idx(array, -1))`
   - Adaptor function to iterate over the array and pass a list element rather
     than an index to the PPMRRAIR function.  This can make the usage intent
     clearer and coding easier.  birlei can be partially or fully omitted
     resulting in referencing the array's length.
#### 4. `enum_list(array, algo_fn, ppmrrair_fn, birl = 0, end_i = el_idx(array, -1))`
   - Adaptor function to iterate over the array and pass [index, element] rather
     than an index to the PPMRRAIR function.  This can make the usage intent
     clearer and coding easier.  birlei can be partially or fully omitted
     resulting in referencing the array's length.
#### 5. `ref_list(array, algo_fn, ppmrrair_fn, birl = 0, end_i = el_idx(array, -1))`
   - Adaptor function to iterate over the array but still passes an index to the
     PPMRRAIR function.  This can make the usage intent clearer and coding
     easier.  birlei can be partially or fully omitted resulting in referencing
     the array's length.
#### 6. `fn_*_list(arr, birl = 0, end_i = len(arr)-1)`
   - Used to have the PPMRRAIR at the end.
#### 7. `fn_reduce*(init, birl = undef, end_i = undef)`
   - Used to return a function that can be passed to *_list or if birl/end_i
     are added, then they are used to allow placing the PPMRRAIR at the end.
#### 8. `fn_*<algo_name>*(birl = undef, end_i = undef)`
   - Used to return a function that can be passed to *_list or if birl/end_i
     are added, then they are used to allow placing the PPMRRAIR at the end.
#### 9. `function_<name>()`
   - Used to return a lambda of the algorithm.  Primarily used to be passed
     to *_list, though `function_reduce*` functions will not be compatible
     as the init parameter will also be included in the signature.  Want to add
     an enhancement to the language to make this unnecessary.

     See https://github.com/openscad/openscad/issues/6182.

### Secondary algorithms:

#### 1. `apply_to_fn(fn, parameters_as_list)`
   - Applies the parameters_as_list to the function fn, so that each element
     becomes a parameter.

### TL;DR
Due to how OpenSCAD works where `include<>` is not guarded to only include a
file once and `use<>` does guard but doesn't evaluate and export top level
assignments, and due to no simple way to get the function without the library
user having to write an intermediate functions, I've generated intermediate
functions to help the library user for most public facing library functions
that I feel need it. These functions are defined as `function_<fn_name>()`
which is similar to the suggestion I gave in issue
https://github.com/openscad/openscad/issues/6182 which would look like
`function <fn_name>`, though if implemented, may reduce the need for an
intermediate call.

## list

Functions related to list and list management.

#### 1. `it_fwd_i(array, begin_offset = 0, end_offset = 0, debug = false)`
   - Returns a range object.
   - begin_offset is usually POSITIVE and end_offset usually NEGATIVE. If
     they are not usual values, then OUT OF BOUND CONDITIONS will occur and
     it is up to the dev to deal with it.
#### 2. `it_rev_i(array, begin_offset = 0, end_offset = 0, debug = false)`
   - Returns a range object.
   - begin_offset is usually NEGATIVE and end_offset usually POSITIVE. If
     they are not usual values, then OUT OF BOUND CONDITIONS will occur and
     it is up to the dev to deal with it.
#### 3. `el_idx(array, index, debug = false)`
   - Gets the index for an array.  If negative, start from the end and go
     backwards.
#### 4. `el(array, index)`
   - Gets the element from an array.  If negative, start from the end and go
     backwards.
