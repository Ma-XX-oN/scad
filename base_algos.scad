/**
 * # Base Algorithms
 *
 * Don't include this file.  Use the `use<>` idiom.
 *
 * ## Purpose:
 *
 * The purpose of this library is to provide the minimum number of abstracted
 * composable algorithms to be able to make coding easier.
 *
 * This file contains the 4 basic algorithms (find, reduce, filter and map)
 * which most other algorithms can be built from.  For optimisation purposes,
 * reduce_air adds the ability to do an incomplete reduction over the range and
 * filter adds a hybrid filter/map feature.  There are also binary search
 * algorithms find_lower and find_upper.  So, it actually becomes 7 basic
 * algorithms:
 *
 * 1. find
 *    - Look for the first index in a range where a predicate returns true.
 * 2. find_lower
 *    - Like C++ lower_bound: returns the first index i for which
 *      a spaceship predicate >= 0, or undef if none are found.
 * 3. find_upper
 *    - Like C++ upper_bound: returns the first index i for which
 *      a spaceship predicate > 0, or undef if none are found.
 * 4. reduce
 *    - Reduce a range of indices to a some final result.
 *    - This is equivalent to a for_each loop.
 * 5. reduce_air
 *    - Reduce a range of indices to a some final result.
 *    - Reduce operation Allows for Incomplete Reduction, which means that it
 *      can abort before iterating over the entire range.
 *    - This is equivalent to a for loop.
 * 6. filter
 *    - Create a list of indices or objects where some predicate is true.
 * 7. map
 *    - Create a list of values/objects based on a range of indices.
 *
 * ## Iterators:
 *
 * These algorithms are index, not element centric, which means that a physical
 * container (i.e. list) is not needed.  A virtual container (i.e. function) is
 * all that is required.  The indices act as iterators as one might find in C++.
 *
 * The birl (formally begin_i_range_or_list) parameter of each of these function
 * state either:
 *
 * 1. Starting index (number)
 *    - Implies that end_i will indicate the inclusive end index (number).  This
 *      conforms to how ranges in OpenSCAD work.
 * 2. Indices (range)
 *    - Will go through each item in the range and use them as indices to pass
 *      to the algorithm.  end_i is ignored.
 * 3. Indices (list)
 *    - Will go through each element in the list and use them as indices to pass
 *      to the algorithm.  end_i is ignored.
 *
 * ## PPMRRAIR functions
 *
 * Named after the 4 function types: Predicate, Predicate/Map, Reduction and
 * Reduction that Allows for Incomplete Reduction, these functions are passed to
 * the algorithms:
 *
 * 1. Predicate (function (i) : result)
 *    - A binary predicate is used by find, filter and map.  It has 2 results,
 *      true or false.  
 *    - A spaceship predicate is used with find_lower and find_upper.  It has 3
 *      results, less than 0, equal to 0 and greater than 0.  
 * 2. Predicate/Map (function (i, v) : any)
 *    - Optionally used by filter.
 *    - If v is not passed, then it acts like a binary predicate.  Otherwise, if
 *      passed a true value, usually returns the element at that index, but can
 *      map to something else.
 *    - This 2 parameter function is a performance and memory allocation
 *      optimisation, allowing filter to do a map in the same step.
 * 3. Reduction (function (i, acc) : acc)
 *    NOTE: acc IS THE SECOND PARAMETER which is different from most languages.
 *          This is to keep it consistent with the rest of the PPMRRAIR
 *          functions and this library in general.  You have been warned.
 *    - Used by reduce.
 *    - Takes in the index and the previous accumulated object and returns the
 *      new accumulated object.
 *    - This is equivalent to a for_each loop.
 * 4. Reduction, Allow Incomplete Reduction (function (i, acc) : [cont, acc])
 *    - Used by reduce_air.
 *    - Takes in the index and the previous accumulated object and returns a
 *      list [ cont, new_acc ].
 *    - This is equivalent to a for loop.
 *
 * ## Helpers functions:
 *
 * 1. it_fwd_i(array, begin_offset = 0, end_offset = 0)
 *    - Returns a range object.
 *    - begin_offset is usually POSITIVE and end_offset usually NEGATIVE. If
 *      they are not usual values, then OUT OF BOUND CONDITIONS will occur and
 *      it is up to the dev to deal with it.
 * 2. it_rev_i(array, begin_offset = 0, end_offset = 0)
 *    - Returns a range object.
 *    - begin_offset is usually NEGATIVE and end_offset usually POSITIVE. If
 *      they are not usual values, then OUT OF BOUND CONDITIONS will occur and
 *      it is up to the dev to deal with it.
 * 3. el_idx(array, index)
 *    - Gets the index for an array.  If negative, start from the end and go
 *      backwards.
 * 4. el(array, index)
 *    - Gets the element from an array.  If negative, start from the end and go
 *      backwards.
 * 5. not(fn)
 *    - Returns a lambda that will take one parameter and return the negation of
 *      what the original function would give if passed that one parameter.
 * 6. apply_to_fn(fn, parameters_as_array)
 *    - Applies the parameters_as_array to the function fn, so that each element
 *      becomes a parameter.
 * 7. in_array(array, algo_fn, ppmrrair_fn, birl = 0, end_i = el_idx(array, -1))
 *    - Adaptor function to iterate over the array and pass elements rather than
 *      indices to the PPMRRAIR function.  This can make the usage intent
 *      clearer, and if the index range is omitted, can use the array's length
 *      as the default reference.
 * 8. fn_reduce(init) and fn_reduce_air(init)
 *    - Used to return a function that can be passed to in_array.
 * 9. function_<algo_name>()
 *    - Used to return a lambda of the algorithm.  Primarily used to be passed
 *      to in_array, though function_reduce*() functions will not be compatible
 *      as the init parameter will also be included in the signature.
 *
 * ## Secondary algorithms:
 *
 * 1. param_count(fn)
 *    - Returns the number of parameters that the lambda takes.
 *
 * The find and reduce algorithms rely on recursive descent, but they also
 * conform to TCO (Tail Call Optimisation) so don't have a maximum depth.  The
 * filter and map algorithms use list comprehension so also have no limit to
 * it's range size.
 *
 * Due to how OpenSCAD works where include<> is not guarded to only include a
 * file once and use<> does guard but doesn't evaluate and export top level
 * assignments, and due to no simple way to get the function without the library
 * user having to write an intermediate function, I've generated intermediate
 * functions to help the library user for most public facing library functions
 * that I feel need it. These functions are defined as `function_<fn_name>()`
 * which is similar to the suggestion I gave in issue
 * https://github.com/openscad/openscad/issues/6182 which would look like
 * `function <fn_name>`, though may reduce the need for an intermediate call
 * level.
 */

use <list.scad>
use <types.scad>
use <range.scad>
use <test.scad>

////////////////////////////////////////////////////////////////////////////////
// Find and Reduce
////////////////////////////////////////////////////////////////////////////////

/**
 * Negate a lambda's return value
 *
 * @param not_fn (function (p) : any)
 *   The function to invert the boolean's (or equivalent truthy/falsy) value.
 *
 * @returns (function (p) : bool)
 *   Return the lambda that will invert a lambda's truth value.
 */
function not(not_fn) =
  // echo("NOT: ", not_fn)
  assert(is_function(not_fn))
  function(p) !not_fn(p)
;

/**
 * Return a range representing indices to iterate over array forwards.
 *
 * NOTE:  Dev is responsible for ensuring that when using start_offset /
 *        end_offset, that they don't go out of bounds, or if they do, the
 *        underlying PPMRRAIR function will handle it gracefully.
 *
 * @param array (list)
 *   List to iterate over
 * @param start_offset (number)
 *   Offset to start the starting point from.  (Default: 0)
 * @param end_offset (number)
 *   Offset to end the ending point to.  (Default: 0) Should be negative to not
 *   go to the end of array.  Positive would go past the end of the array.
 *
 * @returns (range)
 *   An ascending range that goes from start_offset to el_idx(array, -1) +
 *   end_offset.
 */
function it_fwd_i(array, start_offset = 0, end_offset = 0, debug) =
  let ( end_i = (debug?echo("it_fwd_i", array, end_offset)0:0) + el_idx(array, -1, debug) + end_offset )
  start_offset <= end_i
  ? [ start_offset : end_i ]
  : []
;

/**
 * Return a range representing indices to iterate over array backwards.
 *
 * NOTE:  Dev is responsible for ensuring that when using start_offset /
 *        end_offset, that they don't go out of bounds, or if they do, the
 *        underlying PPMRRAIR function will handle it gracefully.
 *
 * @param array (list)
 *   List to iterate over
 * @param start_offset (number)
 *   Offset to start the starting point from.  (Default: 0)  Should be negative
 *   to not start from the end of array.  Positive would start past the end of
 *   the array.
 * @param end_offset (number)
 *   Offset to end the ending point to.  (Default: 0)
 *
 * @returns (range)
 *   A descending range that goes from el_idx(array, -1) + start_offset to
 *   end_offset.
 */
function it_rev_i(array, start_offset = 0, end_offset = 0) =
  let ( begin_i = el_idx(array, -1) + start_offset )
  begin_i <= end_offset
  ? [ begin_i : -1 : end_offset ]
  : []
;

assert(
  let(
    a=[1,2,3,4,5],
    fn=function(i) a[i]%2==0
  )
  find(fn, it_fwd_i(a)) == 1
);

/**
 * @overload birlei_to_begin_i_end_i(it_fn, it_helper_test_fn, begin_i, end_i)
 * @overload birlei_to_begin_i_end_i(it_fn, it_helper_test_fn, range_is)
 * @overload birlei_to_begin_i_end_i(it_fn, it_helper_test_fn, list_is)
 *
 * Helper which calls it_fn but remaps signature function(fn, birl, end_i) to
 * signature function(fn, begin_i, end_i).
 *
 * @param it_fn (function (fn, begin_i, end_i, map_back_fn) : any)
 *   Function with (fn, begin_i, end_i, map_back_fn) signature to call.
 *     @param fn (number)
 *       ppmrrair function to call.
 *     @param begin_i (number)
 *       Starting index to operate on.
 *     @param end_i (number)
 *       Ending index to operate on.
 *     @param map_back_fn (function(i) : number | undef)
 *       If returning an index, pass the index retrieved by algorithm
 *       to get actual index as it may have been remapped with a range or list.
 *       i can be a number or undef
 *
 * @param it_helper_test_fn (function (number i) : bool)
 *   - Takes index for some index searchable and returns boolean.
 * @param birl (number | range | list)
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param begin_i (number)
 *   - Start index to check.
 * @param end_i (number)
 *   - If birl is a number, then end index to check.  end_i could be less than
 *     birl if there's nothing to iterate over, but would have to be handled by
 *     it_fn.  Ignored if birl is not a number.
 * @param range_is (range)
 *   - Range of indices to check.
 * @param list_is (list)
 *   - List of indices to check.
 *
 * @returns result of it_fn().
 */
function birlei_to_begin_i_end_i(it_fn, it_helper_test_fn, birl, end_i) =
  assert(is_function(it_fn),
    str("it_fn should be function. Got ", it_fn, " instead."))
  assert(is_function(it_helper_test_fn),
    str("it_helper_test_fn should be function. Got {", it_helper_test_fn, "} instead."))
  is_num(birl)
  ? assert(is_num(end_i), str("end_i (", end_i, ") must be a number."))
    it_fn(it_helper_test_fn, birl, end_i, function(i) i)
  : let ( pc = param_count(it_helper_test_fn) )
    is_list(birl)
    ? let (
        result_i = it_fn(
          pc == 1
          ? function(i) it_helper_test_fn(birl[i])
          : function(i, o) it_helper_test_fn(birl[i], o),
          0, el_idx(birl, -1), function(i) i == undef ? undef : birl[i])
      )
      result_i
    : // birl must be a range
      assert(is_range(birl),
        str("birl (", birl, ") must be a range."))
      birl[1] == 1
      ? // If step is 1, no need to use range which reduces indirection.
        it_fn(it_helper_test_fn, birl[0], birl[2], function(i) i == undef ? undef : i)
      : let (
          rc = range_len(birl),
          end2_i = is_undef(rc) ? -1 : rc - 1,
          result_i = it_fn(
            pc == 1
            ? function(i) it_helper_test_fn(range_value(birl, i))
            : function(i, o) it_helper_test_fn(range_value(birl, i), o),
            0, end2_i, function(i) i == undef ? undef : range_value(birl, i))
        )
        result_i
;

/**
 * @overload find_lower(it_fn, it_helper_test_fn, begin_i, end_i)
 * @overload find_lower(it_fn, it_helper_test_fn, range_is)
 * @overload find_lower(it_fn, it_helper_test_fn, list_is)
 *
 * Like C++ lower_bound: returns the first index i for which spaceship_fn(i) >=
 * 0.
 *
 * NOTE: The specified range or list of indices must be such that
 *       spaceship_fn(i) is monotonically nondecreasing over the searched
 *       indices; otherwise results are undefined.
 *
 * @param spaceship_fn (function(i) : number)
 *   This is a trinary predicate where if the element i is less than the
 *   searched value, then it would return a value < 0.  If the element i is
 *   equal to the searched value, then it should be equal to 0.  Otherwise it
 *   should be > 0.
 * @param birl (number | range | list)
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param begin_i (number)
 *   - Start index to check.
 * @param end_i (number)
 *   - If birl is a number, end index to check.  If end_i < birl then
 *     spaceship_fn is never called, making this function return undef.
 * @param range_is (range)
 *   - Range of indices to check.
 * @param list_is (list)
 *   - List of indices to check.
 *
 * @returns (number | undef)
 *   First index where spaceship_fn(i) >= 0.  If none are found, returns undef.
 *
 *   NOTE: The reason for returning undef rather than end_i+1, is because birl
 *         could be a noncontiguous range or list of indices.
 */
function find_lower(spaceship_fn, birl, end_i) =
  let (
    _find_binary = function(_spaceship_fn, begin_i, end_i)
      begin_i == end_i
        ? begin_i
        : let (
            mid_i = floor((begin_i + end_i) / 2),
            result = _spaceship_fn(mid_i)
          )
          result >= 0
            ? _find_binary(_spaceship_fn, begin_i,   mid_i)  // first-true lies at/before mid_i
            : _find_binary(_spaceship_fn, mid_i + 1, end_i)  // still false at mid_i -> go right

  )
  birlei_to_begin_i_end_i(
    function(_spaceship_fn, begin_i, end_i, map_back_fn)
      end_i < begin_i || _spaceship_fn(end_i) < 0
      ? undef
      : map_back_fn(_find_binary(_spaceship_fn, begin_i, end_i)),
    spaceship_fn, birl, end_i)
;

function function_find_lower() =
  function(spaceship_fn, birl, end_i)
    find_lower(spaceship_fn, birl, end_i)
;

/**
 * Give a compatible function signature that can be used in in_array or allows
 * the spaceship_fn to be placed after the birl/end_i parameters for clarity.
 *
 * @param init (any)
 *   This is the initial value that will be passed to reduce.
 * @param birl (number | range | list | undef)
 *   - If undef, then returns function(spaceship_fn, birl, end_i) : any,
 *     otherwise returns function(spaceship_fn) : any.  This allows for
 *     placing the range at the top of the function call to make code easier to
 *     read.
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If birl is a number, end index to check.  If end_i < birl then
 *     spaceship_fn is never called, making this function return init.
 *
 * @returns (function(spaceship_fn, birl, end_i) : any |
 *           function(spaceship_fn) : any)
 *   Function to pass to in_array, or to allow placing the PPMRAIR function
 *   after the birl/end_i for easier reading.
 */
function fn_find_lower(birl=undef, end_i=undef) =
  birl == undef
  ? function(spaceship_fn, birl, end_i) find_lower(spaceship_fn, birl, end_i)
  : function(spaceship_fn)              find_lower(spaceship_fn, birl, end_i)
;

let (v = 0) test_eq(v, echo(str("Searching for ", v)) in_array([0,1,2,3,4], function_find_lower(), function(e) e-v));
let (v = 1) test_eq(v, echo(str("Searching for ", v)) in_array([0,1,2,3,4], function_find_lower(), function(e) e-v));
let (v = 2) test_eq(v, echo(str("Searching for ", v)) in_array([0,1,2,3,4], function_find_lower(), function(e) e-v));
let (v = 3) test_eq(v, echo(str("Searching for ", v)) in_array([0,1,2,3,4], function_find_lower(), function(e) e-v));
let (v = 4) test_eq(v, echo(str("Searching for ", v)) in_array([0,1,2,3,4], function_find_lower(), function(e) e-v));
let (v = 5) test_eq(undef, echo(str("Searching for ", v)) in_array([0,1,2,3,4], function_find_lower(), function(e) e-v));
let (v = 7) test_eq(v, echo(str("Searching for ", v)) in_array([0,1,2,3,4,5,6,7], function_find_lower(), function(e) e-v));
let (v = 2) test_eq(2, echo(str("Searching for ", v)) in_array([0,1,2,2,4], function_find_lower(), function(e) e-v));
let (v = 2) test_eq(2, echo(str("Searching for ", v)) in_array([0,1,2,2,2], function_find_lower(), function(e) e-v));
let (v = 2) test_eq(1, echo(str("Searching for ", v)) in_array([0,2,2,2,2], function_find_lower(), function(e) e-v));
let (v = 3) test_eq(undef, echo(str("Searching for ", v)) in_array([0,2,2,2,2], function_find_lower(), function(e) e-v));

/**
 * @overload find_lower(it_fn, it_helper_test_fn, begin_i, end_i)
 * @overload find_lower(it_fn, it_helper_test_fn, range_is)
 * @overload find_lower(it_fn, it_helper_test_fn, list_is)
 *
 * Like C++ upper_bound: returns the first index i for which spaceship_fn(i) >
 * 0.
 *
 * NOTE: The specified range or list of indices must be such that
 *       spaceship_fn(i) is monotonically nondecreasing over the searched
 *       indices; otherwise results are undefined.
 *
 * @param spaceship_fn (function(i) : number)
 *   This is a trinary predicate where if the element i is less than the
 *   searched value, then it would return a value < 0.  If the element i is
 *   equal to the searched value, then it should be equal to 0.  Otherwise it
 *   should be > 0.
 * @param birl (number | range | list)
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param begin_i (number)
 *   - Start index to check.
 * @param end_i (number)
 *   - If birl is a number, end index to check.  If end_i < birl then
 *     spaceship_fn is never called, making this function return undef.
 * @param range_is (range)
 *   - Range of indices to check.
 * @param list_is (list)
 *   - List of indices to check.
 *
 * @returns (number | undef)
 *   First index where spaceship_fn(i) > 0.  If none are found, returns undef.
 *
 *   NOTE: The reason for returning undef rather than end_i+1, is because birl
 *         could be a noncontiguous range or list of indices.
 */
function find_upper(spaceship_fn, birl, end_i) =
  let (
    _find_binary = function(_spaceship_fn, begin_i, end_i)
      begin_i == end_i
        ? begin_i
        : let (
            mid_i = floor((begin_i + end_i) / 2),
            result = _spaceship_fn(mid_i)
          )
          (result > 0
            ? _find_binary(_spaceship_fn, begin_i,   mid_i)  // first-true (>0) at/before mid_i
            : _find_binary(_spaceship_fn, mid_i + 1, end_i)  // still <= 0 at mid_i -> go right
          )
  )
  birlei_to_begin_i_end_i(
    function(_spaceship_fn, begin_i, end_i, map_back_fn)
      end_i < begin_i || _spaceship_fn(end_i) <= 0
      ? undef
      : map_back_fn(_find_binary(_spaceship_fn, begin_i, end_i)),
    spaceship_fn, birl, end_i)
;

function function_find_upper() =
  function(spaceship_fn, birl, end_i)
    find_upper(spaceship_fn, birl, end_i)
;

/**
 * Give a compatible function signature that can be used in in_array or allows
 * the spaceship_fn to be placed after the birl/end_i parameters for clarity.
 *
 * @param init (any)
 *   This is the initial value that will be passed to reduce.
 * @param birl (number | range | list | undef)
 *   - If undef, then returns function(spaceship_fn, birl, end_i) : any,
 *     otherwise returns function(spaceship_fn) : any.  This allows for
 *     placing the range at the top of the function call to make code easier to
 *     read.
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If birl is a number, end index to check.  If end_i < birl then
 *     spaceship_fn is never called, making this function return init.
 *
 * @returns (function(spaceship_fn, birl, end_i) : any |
 *           function(spaceship_fn) : any)
 *   Function to pass to in_array, or to allow placing the PPMRAIR function
 *   after the birl/end_i for easier reading.
 */
function fn_find_upper(birl=undef, end_i=undef) =
  birl == undef
  ? function(spaceship_fn, birl, end_i) find_upper(spaceship_fn, birl, end_i)
  : function(spaceship_fn)              find_upper(spaceship_fn, birl, end_i)
;

let (v = 0) test_eq(v+1, echo(str("Searching for ", v)) in_array([0,1,2,3,4], function_find_upper(), function(e) e-v));
let (v = 1) test_eq(v+1, echo(str("Searching for ", v)) in_array([0,1,2,3,4], function_find_upper(), function(e) e-v));
let (v = 2) test_eq(v+1, echo(str("Searching for ", v)) in_array([0,1,2,3,4], function_find_upper(), function(e) e-v));
let (v = 3) test_eq(v+1, echo(str("Searching for ", v)) in_array([0,1,2,3,4], function_find_upper(), function(e) e-v));
let (v = 4) test_eq(undef, echo(str("Searching for ", v)) in_array([0,1,2,3,4], function_find_upper(), function(e) e-v));
let (v = 7) test_eq(undef, echo(str("Searching for ", v)) in_array([0,1,2,3,4,5,6,7], function_find_upper(), function(e) e-v));
let (v = 5) test_eq(undef, echo(str("Searching for ", v)) in_array([0,1,2,3,4], function_find_upper(), function(e) e-v));
let (v = 2) test_eq(4, echo(str("Searching for ", v)) in_array([0,1,2,2,4], function_find_upper(), function(e) e-v));
let (v = 2) test_eq(undef, echo(str("Searching for ", v)) in_array([0,1,2,2,2], function_find_upper(), function(e) e-v));
let (v = 2) test_eq(undef, echo(str("Searching for ", v)) in_array([0,2,2,2,2], function_find_upper(), function(e) e-v));

/**
 * @overload find(it_fn, it_helper_test_fn, begin_i, end_i)
 * @overload find(it_fn, it_helper_test_fn, range_is)
 * @overload find(it_fn, it_helper_test_fn, list_is)
 *
 * Returns the first index that results in find_pred_fn(i) returning a truthy
 * result.
 *
 * @param find_pred_fn (function(i) : bool)
 *   Where i is an index, if returns a truthy value, will stop searching and
 *   return i.
 * @param birl (number | range | list)
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param begin_i (number)
 *   - Start index to check.
 * @param end_i (number)
 *   - If birl is a number, end index to check.  If end_i < birl then
 *     find_pred_fn is never called, making this function return undef.
 * @param range_is (range)
 *   - Range of indices to check.
 * @param list_is (list)
 *   - List of indices to check.
 *
 * @returns (number)
 *   If a call to find_pred_fn(i) returns truthy, will return i.  Otherwise
 *   will return undef.
 */
function find(find_pred_fn, birl, end_i) =
  let (
    // recursion depth is O(N)
    _find_linear = function(_find_pred_fn, begin_i, end_i)
      begin_i <= end_i
      ? // echo("find_helper linear: ", begin_i, _find_pred_fn)
        _find_pred_fn(begin_i)
        ? begin_i
        : _find_linear(_find_pred_fn, begin_i + 1, end_i)
      : undef
  )
  birlei_to_begin_i_end_i(
    function(_find_pred_fn, begin_i, end_i, map_back_fn)
      end_i < begin_i
      ? undef
      : map_back_fn(_find_linear(_find_pred_fn, begin_i, end_i)),
    find_pred_fn, birl, end_i)
;

function function_find() =
  function(find_pred_fn, birl, end_i)
    find(find_pred_fn, birl, end_i)
;

/**
 * Give a compatible function signature that can be used in in_array or allows
 * the find_pred_fn to be placed after the birl/end_i parameters for clarity.
 *
 * @param init (any)
 *   This is the initial value that will be passed to reduce.
 * @param birl (number | range | list | undef)
 *   - If undef, then returns function(find_pred_fn, birl, end_i) : any,
 *     otherwise returns function(find_pred_fn) : any.  This allows for placing
 *     the range at the top of the function call to make code easier to read.
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If birl is a number, end index to check.  If end_i < birl then
 *     find_pred_fn is never called, making this function return init.
 *
 * @returns (function(find_pred_fn, birl, end_i) : any |
 *           function(find_pred_fn) : any)
 *   Function to pass to in_array, or to allow placing the PPMRAIR function
 *   after the birl/end_i for easier reading.
 */
function fn_find(birl=undef, end_i=undef) =
  birl == undef
  ? function(find_pred_fn, birl, end_i) find(find_pred_fn, birl, end_i)
  : function(find_pred_fn)              find(find_pred_fn, birl, end_i)
;

/**
 * Reduces (a.k.a. folds) a set of indices to produce some value/object based on
 * the indices.
 *
 * @param reduce_op_fn (function(i, acc) : any)
 *   NOTE: acc IS THE SECOND PARAMETER which is different from most languages.
 *         This is to keep it consistent with the rest of the PPMRRAIR
 *         functions and this library in general.  You have been warned.
 *
 *   @param i (number)
 *     Index
 *   @param acc (any)
 *     The accumulator
 *
 *   @returns (any)
 *     New value of accumulator.
 *
 * @param birl (number | range | list)
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If birl is a number, end index to check.  If end_i < birl then
 *     reduce_op_fn is never called, making this function return init.
 *
 * @returns (any)
 *   Final value of accumulator.
 */
function reduce(reduce_op_fn, init, birl, end_i) =
  // echo(str("reduce:\n  ", reduce_op_fn, "\n  ", type_value(init), "\n  ", birl, ", ", end_i ))
  let (
    _reduce_linear = function(reduce_op_fn, acc, begin_i, end_i)
      end_i > begin_i
      ?
        assert(param_count(reduce_op_fn) == 2, reduce_op_fn)
        assert(param_count(_reduce_linear) == 4)
        let( result = reduce_op_fn(begin_i, acc) )
        _reduce_linear(reduce_op_fn, result, begin_i + 1, end_i)
      : reduce_op_fn(begin_i, acc)
  )
  birlei_to_begin_i_end_i(
    function (reduce_op_fn, begin_i, end_i, map_back_fn)
      assert(param_count(reduce_op_fn) == 2, reduce_op_fn)
      end_i < begin_i
      ? init
      : _reduce_linear(reduce_op_fn, init, begin_i, end_i),
    reduce_op_fn, birl, end_i)
;

function function_reduce() =
  function(reduce_op_fn, init, birl, end_i)
    reduce(reduce_op_fn, init, birl, end_i)
;

/**
 * Give a compatible function signature that can be used in in_array by setting
 * the initial value of init or allows the reduce_op_fn to be placed after the
 * birl/end_i parameters for clarity.
 *
 * @param init (any)
 *   This is the initial value that will be passed to reduce.
 * @param birl (number | range | list | undef)
 *   - If undef, then returns function(reduce_op_fn, birl, end_i) : any,
 *     otherwise returns function(reduce_op_fn) : any.  This allows for placing
 *     the range at the top of the function call to make code easier to read.
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If birl is a number, end index to check.  If end_i < birl then
 *     reduce_op_fn is never called, making this function return init.
 *
 * @returns (function(reduce_op_fn, birl, end_i) : any |
 *           function(reduce_op_fn) : any)
 *   Function to pass to in_array, or to allow placing the PPMRAIR function
 *   after the birl/end_i for easier reading.
 *
 *   NOTE: reduce_op_fn expects that acc IS THE SECOND PARAMETER which is
 *         different from most languages.
 *         This is to keep it consistent with the rest of the PPMRRAIR
 *         functions and this library in general.  You have been warned.
 */
function fn_reduce(init, birl=undef, end_i=undef) =
  birl == undef
  ? function(reduce_op_fn, birl, end_i) reduce(reduce_op_fn, init, birl, end_i)
  : function(reduce_op_fn)              reduce(reduce_op_fn, init, birl, end_i)
;

/**
 * Reduces (a.k.a. folds) a set of indices to produce some value/object based on
 * the indices.  This Reduction Allows for Incomplete Reduction.
 *
 * @param reduce_op_fn (function(i, acc) : any)
 *   NOTE: acc IS THE SECOND PARAMETER which is different from most languages.
 *         This is to keep it consistent with the rest of the PPMRRAIR
 *         functions and this library in general.  You have been warned.
 *
 *   @param i (number)
 *     Index
 *   @param acc (any)
 *     The accumulator
 *
 *   @returns (list)
 *     - Index 0 is a boolean. truthy indicates to iterate to the next index.
 *       Falsy stops iterating and returns this list.
 *     - Index 1 is the new value of accumulator.
 *
 * @param birl (number | range | list)
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If birl is a number, end index to check.  If end_i < birl then
 *     reduce_op_fn is never called, making this function return init.
 *
 * @returns (list)
 *   Index 0 is a boolean. truthy indicates the entire range was processed.
 *   Index 1 is the final value of accumulator.
 */
function reduce_air(reduce_op_fn, init, birl, end_i) =
  // echo(str("reduce:\n  ", reduce_op_fn, "\n  ", init, "\n  ", birl, ", ", end_i ))
  let (
    _reduce_linear = function(reduce_op_fn, acc, begin_i, end_i)
      end_i > begin_i
      ? let (result = reduce_op_fn(begin_i, acc))
        result[0]
        ? _reduce_linear(reduce_op_fn, result[1], begin_i + 1, end_i)
        : result
      : reduce_op_fn(begin_i, acc)
  )
  birlei_to_begin_i_end_i(
    function (reduce_op_fn, begin_i, end_i, map_back_fn)
      end_i < begin_i
      ? init
      : _reduce_linear(reduce_op_fn, init, begin_i, end_i),
    reduce_op_fn, birl, end_i)
;

function function_reduce_air() =
  function(reduce_op_fn, init, birl, end_i)
    reduce_air(reduce_op_fn, init, birl, end_i)
;

/**
 * Give a compatible function signature that can be used in in_array by setting
 * the initial value of init.
 *
 * @param init (any)
 *   This is the initial value that will be passed to reduce_air.
 * @param birl (number | range | list | undef)
 *   - If undef, then returns function(reduce_op_fn, birl, end_i) : any,
 *     otherwise returns function(reduce_op_fn) : any.  This allows for placing
 *     the range at the top of the function call to make code easier to read.
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If birl is a number, end index to check.  If end_i < birl then
 *     reduce_op_fn is never called, making this function return init.
 *
 * @returns (function(reduce_op_fn, birl, end_i) : any)
 *   Function to pass to in_array, or to allow placing the PPMRAIR function
 *   after the birl/end_i for easier reading.
 *
 *   NOTE: reduce_op_fn expects that acc IS THE SECOND PARAMETER which is
 *         different from most languages.
 *         This is to keep it consistent with the rest of the PPMRRAIR
 *         functions and this library in general.  You have been warned.
 */
function fn_reduce_air(init, birl, end_i) =
  birl == undef
  ? function(reduce_op_fn, birl, end_i) reduce_air(reduce_op_fn, init, birl, end_i)
  : function(reduce_op_fn)              reduce_air(reduce_op_fn, init, birl, end_i)
;

/**
 * This convenience function will execute function in_array_algo_fn as if it were
 * used on a collection, remapping the first parameter being passed to
 * in_array_ppmrrair_fn so that it retrieves the element rather than the index.
 *
 * @example
 *
 * Normal usage:
 * ```
 * even_indices = let(a=[1,2,3,4,5]) filter(function(i) a[i] % 2);
 * even_values  = let(a=[1,2,3,4,5]) filter(function(i, v) v ? a[i] : a[i] % 2);
 * ```
 * vs in_array() usage:
 * ```
 * even_indices = in_array([1,2,3,4,5], function_filter(), function(e) e % 2);
 * even_values  = in_array([1,2,3,4,5], function_filter(), function(e, v) v ? e : e % 2);
 * ```
 *
 * NOTE: If `in_array_algo_fn` takes more than the standard 3 parameters, then
 *       it must bind the extra parameters so that only the 3 standard
 *       parameters are required.
 *
 * @param arr (list | string)
 *   This is the list to take element data from.
 * @param in_array_algo_fn (function (fn, birl, end_i))
 *   This is the operation function that is called. E.g. find(), filter(), etc.
 * @param in_array_ppmrrair_fn (function(i) : any | function(i, v) : any)
 *   This is forwarded to in_array_algo_fn.  Function can take 1 or 2 parameters
 *   based on what `in_array_algo_fn()` requires.
 * @param birl (number | range | list)
 *   This is forwarded to in_array_algo_fn. If a negative number, will count
 *   from the end of the array. (Default: 0).
 * @param end_i (undef | number)
 *   This is forwarded to in_array_algo_fn. If a negative number, will count
 *   from the end of the array. (Default: el_idx(arr, -1)).
 * @parma use_el_param (bool)
 *   States if the first parameter in the in_array_ppmrrair_fn will be sent the
 *   array element (Default: true) or the index (false).
 *
 * @returns (any)
 *   The return value of the in_array_algo_fn() call.
 */
function in_array(arr, in_array_algo_fn, in_array_ppmrrair_fn, birl=0, end_i=undef, use_el_param = true) =
  // echo(str("in_array:\n  in_array_algo_fn: ", in_array_algo_fn, "\n  arr: ", arr, "\n  in_array_ppmrrair_fn: ", in_array_ppmrrair_fn))
  // echo(str("in_array: birl= ", birl, " end_i= ", end_i))
  let (
    pc = param_count(in_array_ppmrrair_fn),
    b_i = is_num(birl) ? el_idx(arr, birl) : birl,
    e_i = is_undef(end_i) ? el_idx(arr, -1) : el_idx(arr, end_i)
  )
  assert(is_list(arr) || is_string(arr), str("arr (", type(arr), ") must be a list or a string"))
  pc == 1
  ? in_array_algo_fn(
    use_el_param
    ? function(i) in_array_ppmrrair_fn(arr[i])
    : in_array_ppmrrair_fn,
    b_i, e_i)
  : assert(pc == 2, str("parameter count (", pc, ") must be 1 or 2."))
    // forward 2nd parameter unmodified.
    in_array_algo_fn(
      use_el_param
      ? function(i, o) in_array_ppmrrair_fn(arr[i], o)
      : in_array_ppmrrair_fn,
      b_i, e_i)
;

/**
 * Allows the in_array_ppmrrair_fn to be placed after the other parameters for
 * clarity.
 *
 * @param arr (list | string)
 *   This is the list to take element data from.
 * @param in_array_algo_fn (function (fn, birl, end_i))
 *   This is the operation function that is called. E.g. find(), filter(), etc.
 * @param in_array_ppmrrair_fn (function(i) : any | function(i, v) : any)
 *   This is forwarded to in_array_algo_fn.  Function can take 1 or 2 parameters
 *   based on what `in_array_algo_fn()` requires.
 * @param birl (number | range | list)
 *   This is forwarded to in_array_algo_fn. If a negative number, will count
 *   from the end of the array. (Default: 0).
 * @param end_i (undef | number)
 *   This is forwarded to in_array_algo_fn. If a negative number, will count
 *   from the end of the array. (Default: el_idx(arr, -1)).
 * @parma use_el_param (bool)
 *   States if the first parameter in the in_array_ppmrrair_fn will be sent the
 *   array element (Default: true) or the index (false).
 *
 * @returns (function(find_pred_fn, birl, end_i) : any |
 *           function(find_pred_fn) : any)
 *   Function to pass to in_array, or to allow placing the PPMRAIR function
 *   after the birl/end_i for easier reading.
 */
function fn_in_array(arr, in_array_algo_fn, birl=0, end_i=undef, use_el_param = true) =
  function(in_array_ppmrrair_fn)
    in_array(arr, in_array_algo_fn, in_array_ppmrrair_fn, birl, end_i, use_el_param)
;

/**
 * Counts the number of parameters that can be passed to the function fn.
 *
 * @param fn (function(...) : any)
 *
 * @returns (number)
 *   The number of parameters that the function can take.
 */
function param_count(fn) =
  let (
    fn_str = assert(is_function(fn)) str(fn),
    param_begin_i = 9,
    // close_i =
    //   find(function(i) fn_str[i] == ")", param_begin_i, el_idx(fn_str, -1))
    params =
      assert(fn_str[param_begin_i-1] == "(", str("lambda parameters expected to start at ", param_begin_i))
      reduce_air(
        // This function does 6 separate tests per character to check if at a
        // parameter or not. 5 of which are against the character.
        // Could use search to get index of interested characters and a dispatch
        // table to call appropriate code so that I could limit tests to just 2
        // or 3 I think.
        // TODO: Should do some benchmarking to see if it's worth the effort.
        function(i, acc)
          let (
            c = fn_str[i],
            params      = acc[0],
            escaping    = acc[1],
            quoting     = acc[2],
            nwscf       = acc[3], // non-whitespace character found
            paren_depth = acc[4]
          )
          quoting
          ? escaping
            ? [1, [params, !escaping, quoting, nwscf, paren_depth]]          // escaping this char, so no longer escaping
            : c == "\\"
              ? [1, [params, !escaping, quoting, nwscf, paren_depth]]        // escape next char
              : c == "\""
                ? [1, [params, escaping, !quoting, nwscf, paren_depth]]      // next chars are not quoted
                : [1, acc]                                                   // no state change
          : c == "\""
            ? [1, [params, escaping, !quoting, nwscf, paren_depth]]          // next chars are quoted
            : c == ")"
              ? // reduce paren depth. finished searching if new paren_depth == 0
                [paren_depth-1, [params, escaping, quoting, nwscf, paren_depth-1]]
              : c == "("
                ? [1, [params, escaping, quoting, nwscf, paren_depth+1]]     // increment paren depth
                : paren_depth == 1
                  ? c == ","
                    ? [1, [params+1, escaping, quoting, false, paren_depth]] // increment param count only if at main param def level
                    : c != " " && c != "\n" && c != "\t" && c != "\r"
                      ? // found what should be a param name. If no params yet, add a parameter to the count.
                        [1, [params == 0 && !nwscf ? 1 : params, escaping, quoting, true, paren_depth]]
                      : [1, acc]                                             // no state change
                  : [1, acc]                                                 // no state change
        ,
        [0, 0, 0, 0, 1], param_begin_i, len(fn_str)-1)[1][0]
  )
  params
;

test_eq(0, param_count(function() 1));
test_eq(1, param_count(function( s) 1));
test_eq(2, param_count(function(d,e) 1));

test_eq(15, reduce(function (i, a) echo(i) [1,2,3,4,5][i] + a, 0, 0, 4));
assert(in_array(
    [1,2,3,4,5],
    function(fn, ib, ie) reduce(fn, 0, ib, ie),
    function(e, a) e + a
  ) == 15
);

/**
 * Applies each element in an array to a function's parameter list.
 *
 * TODO: apply_to_fn has allocation overhead, where as apply_to_fn2 has lookup
 *       overhead.  NEED TO BENCHMARK to determine which to keep.
 *
 * @param fn (function(...) : any)
 *   A lambda that takes between 0 and 15 parameters.
 * @param p (list)
 *   A list of elements to apply to the function fn.  Must have the same or
 *   fewer elements than `fn` can take and must be less than 15 elements.
 *
 * @returns (any)
 *   The return value of fn().
 */
function apply_to_fn(fn, p) =
  let (
    fn_pc = param_count(fn),
    passed_pc = len(p),
    dispatch_table = [
      function() fn(),
      function() fn(p[0]),
      function() fn(p[0], p[1]),
      function() fn(p[0], p[1], p[2]),
      function() fn(p[0], p[1], p[2], p[3]),
      function() fn(p[0], p[1], p[2], p[3], p[4]),
      function() fn(p[0], p[1], p[2], p[3], p[4], p[5]),
      function() fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6]),
      function() fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7]),
      function() fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8]),
      function() fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9]),
      function() fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10]),
      function() fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11]),
      function() fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12]),
      function() fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13]),
      function() fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14])
    ]
  )
  assert(is_function(fn))
  assert(is_list(p))
  assert(
    fn_pc >= passed_pc,
    str("Too many array elements (", passed_pc,
        ") for the number of parameters available (", fn_pc, ")."))
  assert(passed_pc < len(dispatch_table), "Can't apply more than 15 parameters.")
  dispatch_table[passed_pc]()
;

function apply_to_fn2(fn, p) =
  let (
    fn_pc = param_count(fn),
    passed_pc = len(p)
  )
  assert(is_function(fn))
  assert(is_list(p))
  assert(
    fn_pc >= passed_pc,
    str("Too many array elements (", passed_pc,
        ") for the number of parameters available (", fn_pc, ")."))
  assert(passed_pc < 16, "Can't apply more than 15 parameters.")
  //                     1 1 1 1 1 1
  // 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
  //                 <
  //         <               <
  //     <       <       <       <
  //   <   <   <   <   <   <   <   <
  passed_pc < 8
  ? passed_pc < 4
    ? passed_pc < 2
      ? passed_pc < 1
        ? fn()
        : fn(p[0])
      : passed_pc < 3
        ? fn(p[0], p[1])
        : fn(p[0], p[1], p[2])
    : passed_pc < 6
      ? passed_pc < 5
        ? fn(p[0], p[1], p[2], p[3])
        : fn(p[0], p[1], p[2], p[3], p[4])
      : passed_pc < 7
        ? fn(p[0], p[1], p[2], p[3], p[4], p[5])
        : fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6])
  : passed_pc < 12
    ? passed_pc < 10
      ? passed_pc < 9
        ? fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7])
        : fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8])
      : passed_pc < 11
        ? fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9])
        : fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10])
    : passed_pc < 14
      ? passed_pc < 13
        ? fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11])
        : fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12])
      : passed_pc < 15
        ? fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13])
        : fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14])
;

module tests_apply_to_fn() {
  fn = function(p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15)
    let (arr =
      in_array(
        [p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15],
        function_filter(), function(e, v) v ? e : !is_undef(e))
    )
    // echo(arr)
    arr
  ;

  arr = function(is)
    let (
      a = map(function(i) i, 0, is-1)
    )
    // echo("arr", a)
    a
  ;

  let(a = arr(0) , r = apply_to_fn(fn, a)) test_eq(a, r);
  let(a = arr(1) , r = apply_to_fn(fn, a)) test_eq(a, r);
  let(a = arr(2) , r = apply_to_fn(fn, a)) test_eq(a, r);
  let(a = arr(3) , r = apply_to_fn(fn, a)) test_eq(a, r);
  let(a = arr(4) , r = apply_to_fn(fn, a)) test_eq(a, r);
  let(a = arr(5) , r = apply_to_fn(fn, a)) test_eq(a, r);
  let(a = arr(6) , r = apply_to_fn(fn, a)) test_eq(a, r);
  let(a = arr(7) , r = apply_to_fn(fn, a)) test_eq(a, r);
  let(a = arr(8) , r = apply_to_fn(fn, a)) test_eq(a, r);
  let(a = arr(9) , r = apply_to_fn(fn, a)) test_eq(a, r);
  let(a = arr(10), r = apply_to_fn(fn, a)) test_eq(a, r);
  let(a = arr(11), r = apply_to_fn(fn, a)) test_eq(a, r);
  let(a = arr(12), r = apply_to_fn(fn, a)) test_eq(a, r);
  let(a = arr(13), r = apply_to_fn(fn, a)) test_eq(a, r);
  let(a = arr(14), r = apply_to_fn(fn, a)) test_eq(a, r);
  let(a = arr(15), r = apply_to_fn(fn, a)) test_eq(a, r);
  // x = apply_to_fn(function(q,w)1, [3,3,3]);
}
tests_apply_to_fn();

echo(
  str("find_in_array: ", [1,2,3,4,5], "\n", function_find(), "\n", function(e) e%3==0)
);

////////////////////////////////////////////////////////////////////////////////
// Map and Filter
////////////////////////////////////////////////////////////////////////////////
/**
 * Helper to convert birlei parameters to indices to traverse.
 *
 * @param birl (number | range | list)
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If birl is a number, end index to check.  If end_i is less than birl,
 *     then returns an empty list.
 *
 * @returns (list | range)
 *   Returns a list or range describing the indices to traverse.
 */
function birlei_to_indices(birl, end_i) =
  // echo("_to_idices:", birl, end_i)
  is_num(birl)
  ? assert(is_num(end_i), str("end_i (", end_i, ") must be a number."))
    // echo("made range: ", range(birl, end_i))
    range(birl, end_i)
  : // echo("birl: ", birl)
    birl
;

function birlei_verify(valid_min, valid_max, birl, end_i) =
  let (
    rl = birlei_to_indices(birl, end_i),
    _min = is_list(rl)
      ? fn_in_array(rl, fn_reduce(rl[0]), slice(rl, 1))(
        function(i, acc)
          min(i, acc)
      )
      : rl[1] > 0
        ? range_value(rl, 0)
        : range_value(rl, -1),
    _max = is_list(rl)
      ? fn_in_array(rl, fn_reduce(rl[0]), slice(rl, 1))(
        function(i, acc)
          max(i, acc)
      )
      : rl[1] > 0
        ? range_value(rl, -1)
        : range_value(rl, 0)
  )
  assert(valid_min <= _min && _max < valid_max, str("birlei (", [birl, end_i],
    ") out of range (", [ valid_min, valid_max ], ")"))
  true
;

/**
 * Filter function.
 *
 * @param filter_pred_fn (function(i) : bool | function(i, v) : bool)
 *   - If this takes 1 parameter, then if it return a truthy value, add the
 *     index to the list.
 *   - If this takes 2 parameters, then if when passing only 1 parameter it
 *     returns a truthy value, then add the return value of the function when
 *     called with an additional true parameter to the list.
 *   - If when called, returns a falsy value, then don't add anything to the
 *     list.
 * @param birl (number | range | list)
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If birl is a number, end index to check.  If end_i is less than birl,
 *     then filter_pred_fn() is never called, so filter will return an empty
 *     list.
 *
 * @returns (list)
 *   Returns a list of all indices or elements where filter_pred_fn returned
 *   a truthy value.
 */
function filter(filter_pred_fn, birl, end_i) =
  let (
    indices = birlei_to_indices(birl, end_i),
    pc = param_count(filter_pred_fn)
  )
  assert(pc == 1 || pc == 2, str("filter_pred_fn must be a function with 1 or 2 params, not ", pc, "."))
  pc == 1
  ? [
    for (i = indices) if (filter_pred_fn(i)) i
  ]
  : [
    for (i = indices) if (filter_pred_fn(i)) filter_pred_fn(i, true)
  ]
;

function function_filter() =
  function(filter_pred_fn, birl, end_i)
    filter(filter_pred_fn, birl, end_i)
;

/**
 * Give a compatible function signature that can be used in in_array or allows
 * the filter_pred_fn to be placed after the birl/end_i parameters for clarity.
 *
 * @param init (any)
 *   This is the initial value that will be passed to reduce.
 * @param birl (number | range | list | undef)
 *   - If undef, then returns function(filter_pred_fn, birl, end_i) : any,
 *     otherwise returns function(filter_pred_fn) : any.  This allows for
 *     placing the range at the top of the function call to make code easier to
 *     read.
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If birl is a number, end index to check.  If end_i < birl then
 *     filter_pred_fn is never called, making this function return init.
 *
 * @returns (function(filter_pred_fn, birl, end_i) : any |
 *           function(filter_pred_fn) : any)
 *   Function to pass to in_array, or to allow placing the PPMRAIR function
 *   after the birl/end_i for easier reading.
 */
function fn_filter(birl=undef, end_i=undef) =
  birl == undef
  ? function(filter_pred_fn, birl, end_i) filter(filter_pred_fn, birl, end_i)
  : function(filter_pred_fn)              filter(filter_pred_fn, birl, end_i)
;

/**
 * Map values to indices or array elements, producing an array that has as many
 * elements as indices provided.
 *
 * @param map_fn (function (i) : any)
 *   Function to take an index and return the remapped value/object.
 * @param birl (number | range | list)
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If birl is a number, end index to check.  If end_i is less than birl,
 *     then map_fn() is never called, so map will return an empty list.
 *
 * @returns (list)
 *   A new mapped list.
 */
function map(map_fn, birl, end_i) =
  let (indices = birlei_to_indices(birl, end_i))
  echo("indices: ", indices)
  [ for (i = indices)
      echo("map", i)
      map_fn(i)
  ]
;

function function_map() =
  function(map_fn, birl, end_i)
    map(map_fn, birl, end_i)
;

/**
 * Give a compatible function signature that can be used in in_array or allows
 * the map_fn to be placed after the birl/end_i parameters for clarity.
 *
 * @param init (any)
 *   This is the initial value that will be passed to reduce.
 * @param birl (number | range | list | undef)
 *   - If undef, then returns function(map_fn, birl, end_i) : any,
 *     otherwise returns function(map_fn) : any.  This allows for
 *     placing the range at the top of the function call to make code easier to
 *     read.
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If birl is a number, end index to check.  If end_i < birl then
 *     map_fn is never called, making this function return init.
 *
 * @returns (function(map_fn, birl, end_i) : any |
 *           function(map_fn) : any)
 *   Function to pass to in_array, or to allow placing the PPMRAIR function
 *   after the birl/end_i for easier reading.
 */
function fn_map(birl=undef, end_i=undef) =
  birl == undef
  ? function(map_fn, birl, end_i) map(map_fn, birl, end_i)
  : function(map_fn)              map(map_fn, birl, end_i)
;
