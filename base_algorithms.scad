/**
 * Base Algorithms
 *
 * This file contains the 4 basic algorithms which most other algorithms can be
 * built from.  They are:
 *
 * 1. find - look for the first time in a range where a predicate returns true.
 * 2. reduce - reduce a range of indices to a some final result.
 * 3. filter - create a list of indices or objects where some predicate is true.
 * 4. map - create a list of values/objects based on a range of indices.
 *
 * These algorithms are index, not element centric, which means that a physical
 * container (i.e. list) is not needed.  A virtual container (i.e. function) is
 * all that is required.  The indices act as iterators as one might find in C++.
 *
 * The functions that the dev can provide to the algorithms are:
 *
 * 1. predicate (function (i) : bool)
 *    - Used by find and filter.
 *    - Is only passed the index to test against.
 * 2. dereference (function (i, v) : any)
 *    - Optionally used by filter.
 *    - If v is not passed, then it acts like a predicate.  Otherwise, it's
 *      passed a true value, which usually results in the element at that index.
 * 3. reduce (function (i, acc) : any)
 *    - Used by reduce
 *    - Takes in the index and the previous accumulated object and returns the
 *      new accumulated object.
 *
 * There is an adaptor function (in_array) which will allow those functions to
 * take in an element rather than an index.  This can make the usage intent
 * clearer, and if the index range is omitted, can use the array's length as a
 * default reference.
 *
 * For the find and reduce algorithms, they rely on recursive decent.

 * This has some similarities to how the C++ STL separates iterators from
 * algorithms by reusing a common interface, namely a predicate or operation
 * lambda, and a begin and end index, or a range or list of indices.  The
 * indices act as iterators and the functions act as predicates, dereferencers
 * or operators.  Note that dereferencing doesn't necessarily mean that there is
 * an underlying list container.  It could just as easily be a function
 * container which has a O(1) memory footprint.
 *
 * All predicate or operation lambdas take an index, but can be made to take an
 * element by using the `in_array()` helper.  This will cause the predicate or
 * operation lambda to accept the element rather than the index, which might
 * help with showing intent.  No performance testing has been done to see if
 * there is any execution degradation.
 *
 * find and reduce were implemented using a logarithmic/linear hybrid recursion
 * model to reduce stack depth and maximise performance.  filter and map use
 * list comprehension.
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

use <types.scad>
use <range.scad>

////////////////////////////////////////////////////////////////////////////////
// Find and Reduce
////////////////////////////////////////////////////////////////////////////////

function true_fn(i) = true;
function function_true_fn() =
  function(i) true
;

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
 *        underlying predicate / operator / dereference operator will handle it
 *        gracefully.
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
 *   A range that goes from 0 + start_offset to len(array) + end_offset - 1.
 */
function it_fwd(array, start_offset = 0, end_offset = 0) =
  [start_offset : len(array) + end_offset - 1];

/**
 * Return a range representing indices to iterate over array backwards.
 *
 * NOTE:  Dev is responsible for ensuring that when using start_offset /
 *        end_offset, that they don't go out of bounds, or if they do, the
 *        underlying predicate / operator / dereference operator will handle it
 *        gracefully.
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
 *   A range that goes from 0 to len(array) - 1.
 */
function it_back(array, start_offset = 0, end_offset = 0) =
  [len(array) + start_offset - 1 : -1 : end_offset];

echo(let(a=[1,2,3,4,5], fn=function(i) a[i]%2==0)
  str("find: ", find(fn, it_fwd(a)))
);

use_arrays_for_tests = true;

/**
 * This is the max linear recursive decent depth.  Any higher will result in a
 * logarithmic recursive decent, which is slightly more computationally
 * intensive, but is much nicer to the stack depth.
 */
function linear_threshold() = 1024;

/**
 * Helper which calls it_fn but remaps signature function(fn,
 * begin_i_range_or_list, end_i) to signature function(fn, begin_i, end_i).
 *
 * @param it_fn (function (fn, begin_i, end_i) : any)
 *   - Function with (fn, begin_i, end_i) signature to call.
 * @param it_helper_test_fn (function (number i) : bool)
 *   - Takes index for some index searchable and returns boolean.
 * @param begin_i_range_or_list (number | range | list)
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If begin_i_range_or_list is a number, then end index to check.  end_i
 *     could be less than begin_i_range_or_list if there's nothing to iterate
 *     over.
 *
 * @returns result of it_fn().
 */
function _to_begin_i_end_i(it_fn, it_helper_test_fn, begin_i_range_or_list, end_i) =
  assert(is_function(it_fn),
    str("it_fn should be function. Got ", it_fn, " instead."))
  assert(is_function(it_helper_test_fn),
    str("it_helper_test_fn should be function. Got ", it_helper_test_fn, " instead."))
  is_num(begin_i_range_or_list)
  ? assert(is_num(end_i), str("end_i (", end_i, ") must be a number."))
    it_fn(it_helper_test_fn, begin_i_range_or_list, end_i)
  : is_list(begin_i_range_or_list)
    ? it_fn(function(i) it_helper_test_fn(begin_i_range_or_list[i]), 0, len(begin_i_range_or_list)-1)
    : // begin_i_range_or_list must be a range
      assert(is_range(begin_i_range_or_list),
        str("begin_i_range_or_list (", begin_i_range_or_list, ") must be a range."))
      begin_i_range_or_list[1] == 1
      ? // If step is 1, no need to use range and installing function compensators.
        it_fn(it_helper_test_fn, begin_i_range_or_list[0], begin_i_range_or_list[2])
      : let (
          rc = range_count(begin_i_range_or_list),
          end2_i = is_undef(rc) ? -1 : rc - 1
        )
        it_fn(function(i) it_helper_test_fn(range_value(begin_i_range_or_list, i)), 0, end2_i)
;

/**
 * Returns the first index that results in find_pred_fn(i) returning a truthy
 * result.
 *
 * @param find_pred_fn (function(i) : bool)
 *   Where i is an index, if returns a truthy value, will stop searching and
 *   return i.
 * @param begin_i_range_or_list (number | range | list)
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If begin_i_range_or_list is a number, end index to check.  If end_i < 0
 *     then find_pred_fn is never called.  Therefore, this function returns
 *     undef.
 * @param linear_threshold (number)
 *   If the number of items to iterate over exceeds this value, then a
 *   logarithmic recursive decent will occur, rather than a linear one.  This is
 *   to prevent blowing the stack up.  (Default: linear_threshold())
 *
 * @returns (number)
 *   If a call to find_pred_fn(i) returns truthy, will return i.  Otherwise
 *   will return undef.
 */
function find(find_pred_fn, begin_i_range_or_list, end_i, linear_threshold = linear_threshold()) =
  let (
    // recursion depth is O(N)
    _find_linear = function(_find_pred_fn, begin_i, end_i)
      begin_i <= end_i
      ? // echo("find_helper linear: ", begin_i, _find_pred_fn)
        _find_pred_fn(begin_i)
        ? begin_i
        : _find_linear(_find_pred_fn, begin_i + 1, end_i)
      : undef
  ,
    _find_logarithmic = function(_find_pred_fn, begin_i, end_i)
      // Recursion depth is O(ln(N))
      // 0, 3  (b_i = 0, e_i = 3, m_i = (0 + 3)//2 = 1, e_i - b_i = 3) check (0, 1) and check (2, 3)
      // 0, 2  (b_i = 0, e_i = 2, m_i = (0 + 2)//2 = 1, e_i - b_i = 2) check (0, 1) and check (2, 2)
      // 0, 1  (b_i = 0, e_i = 1, m_i = (0 + 1)//2 = 0, e_i - b_i = 1) test (0) and test(1)
      // 0     (b_i = 0, e_i = 0, m_i = (0 + 0)//2 = 0, e_i - b_i = 0) test (0)
      let (index_diff = end_i - begin_i)
      index_diff < linear_threshold
      ? _find_linear(_find_pred_fn, begin_i, end_i)
      : index_diff == 0 // 1 item
        ? // echo("find_helper 1", begin_i)
          _find_pred_fn(begin_i)
          ? begin_i
          : undef
        : index_diff == 1 // 2 items
          ? // echo("find_helper 2", begin_i)
            _find_pred_fn(begin_i)
            ? begin_i
            : // echo("find_helper 3", end_i)
              _find_pred_fn(end_i)
              ? end_i
              : undef
          : let ( // 3+ items
              middle_i = floor((begin_i + end_i) / 2),
              result = _find_logarithmic(_find_pred_fn, begin_i, middle_i)
            )
            is_undef(result)
              ? _find_logarithmic(_find_pred_fn, middle_i + 1, end_i)
              : result
  )
  _to_begin_i_end_i(
    function(_find_pred_fn, begin_i, end_i)
      end_i < begin_i
      ? undef
      : _find_logarithmic(_find_pred_fn, begin_i, end_i),
    find_pred_fn, begin_i_range_or_list, end_i)
;

function function_find() =
  function(find_pred_fn, begin_i_range_or_list, end_i, linear_threshold = linear_threshold())
    find(find_pred_fn, begin_i_range_or_list, end_i, linear_threshold)
;

/**
 * Reduces (a.k.a. folds) a set of indices to produce some value/object based on
 * the indices.
 *
 * @param reduce_op_fn (function(i, acc) : any)
 *   @param i (number)
 *     Index
 *   @param acc (any)
 *     The accumulator
 *
 *   @returns (any)
 *     New value of accumulator.
 *
 * @param begin_i_range_or_list (number | range | list)
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If begin_i_range_or_list is a number, end index to check.  If end_i < 0
 *     then reduce_op_fn is never called.  Therefore, this function returns
 *     init.
 * @param linear_threshold (number)
 *   If the number of items to iterate over exceeds this value, then a
 *   logarithmic recursive decent will occur, rather than a linear one.  This is
 *   to prevent blowing the stack up.  (Default: linear_threshold())
 *
 * @returns (any)
 *   Final value of accumulator.
 */
function reduce(reduce_op_fn, init, begin_i_range_or_list, end_i, linear_threshold = linear_threshold()) =
  // echo(str("reduce:\n  ", reduce_op_fn, "\n  ", init, "\n  ", begin_i_range_or_list, ", ", end_i ))
  let (
    _reduce_linear = function(reduce_op_fn, acc, begin_i, end_i)
      end_i > begin_i
      ? _reduce_linear(reduce_op_fn, reduce_op_fn(begin_i, acc), begin_i + 1, end_i)
      : reduce_op_fn(begin_i, acc)
    ,
    _reduce_logarithmic = function(reduce_op_fn, acc, begin_i, end_i)
      let (i_diff = end_i - begin_i)
      i_diff < linear_threshold
      ? _reduce_linear(reduce_op_fn, acc, begin_i, end_i)
      : i_diff == 0 // 1 element
        ? reduce_op_fn(begin_i, acc)
        : i_diff == 1 // 2 elements
          ? let ( result = reduce_op_fn(begin_i, acc) )
            reduce_op_fn(end_i, result)
          : // more than 2 elements
            let (
              middle_i = floor((begin_i + end_i) / 2),
              result = _reduce_logarithmic(reduce_op_fn, acc, begin_i, middle_i)
            )
            _reduce_logarithmic(reduce_op_fn, result, middle_i+1, end_i)
  )
  _to_begin_i_end_i(
    function (reduce_op_fn, begin_i, end_i)
      end_i < begin_i
      ? init
      : _reduce_logarithmic(reduce_op_fn, init, begin_i, end_i),
    reduce_op_fn, begin_i_range_or_list, end_i)
;

function function_reduce() =
  function(reduce_op_fn, init, begin_i_range_or_list, end_i, linear_threshold = linear_threshold())
    reduce(reduce_op_fn, init, begin_i_range_or_list, end_i, linear_threshold)
;

/**
 * This convenience function will execute function in_array_op_fn as if it were
 * used on a collection, remapping the first parameter being passed to
 * in_array_fn so that it retrieves the element rather than the index.
 *
 * This function isn't really necessary, but may make intention clearer.  It is
 * possible that this may reduce performance as this adds another layer of call
 * indirection to the in_array_fn.
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
 * NOTE: If `in_array_op_fn` takes more than the standard 3 parameters, then it
 *       must bind the extra parameters so only the 3 standard parameters are
 *       required.
 *
 * @param arr (list)
 *   This is the list to take element data from.
 * @param in_array_op_fn (function (fn, begin_i_range_or_list, end_i))
 *   This is the operation function that is called. E.g. find(), filter(), etc.
 * @param in_array_fn (function(fn, begin_i_range_or_list, end_i) : any)
 *   This is forwarded to in_array_op_fn.  `fn` can take 1 or 2 parameters based
 *   on what `in_array_op_fn()` requires.
 * @param begin_i_range_or_list (number | range | list)
 *   This is forwarded to in_array_op_fn (default: 0).
 * @param end_i (undef | number)
 *   This is forwarded to in_array_op_fn (default: len(arr)-1).
 *
 * @returns (any)
 *   The return value of the in_array_op_fn() call.
 */
function in_array(arr, in_array_op_fn, in_array_fn, begin_i_range_or_list=0, end_i=undef) =
  // echo(str("in_array:\n  in_array_op_fn: ", in_array_op_fn, "\n  arr: ", arr, "\n  in_array_fn: ", in_array_fn))
  let (
    pc = param_count(in_array_fn),
    b_i = begin_i_range_or_list,
    e_i = is_undef(end_i) ? len(arr)-1 : end_i
  )
  assert(is_list(arr))
  pc == 1
  ? in_array_op_fn(function(i) in_array_fn(arr[i]), b_i, e_i)
  : assert(pc == 2, str("parameter count (", pc, ") must be 1 or 2."))
    // forward 2nd parameter unmodified.
    in_array_op_fn(function(i, o) in_array_fn(arr[i], o), b_i, e_i)
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
    close_i =
      assert(fn_str[param_begin_i-1] == "(", str("lambda parameters expected to start at ", param_begin_i))
      find(function(i) fn_str[i] == ")", param_begin_i, len(fn_str)-1),
    // Alternate way to get parameter boundary, but it relies on param_count, so can't use it.
    // params = in_array(fn_str, filter(), function(e) e == ")", param_begin_i),
    comma_count = reduce(function(i, acc) fn_str[i] == "," ? acc + 1 : acc, 0, param_begin_i, close_i-1),
    nonws_count = reduce(function(i, acc) fn_str[i] != " " ? acc + 1 : acc, 0, param_begin_i, close_i-1)
  )
  comma_count == 0
    ? nonws_count
      ? 1
      : 0
    : assert(!is_undef(comma_count)) comma_count + 1
;

assert(param_count(function() 1) == 0);
assert(param_count(function( s) 1) == 1);
assert(param_count(function(d,e) 1) == 2);

assert(reduce(function (i, a) echo(i) [1,2,3,4,5][i] + a, 0, 0, 4) == 15);
assert(in_array(
    [1,2,3,4,5],
    function(fn, ib, ie) reduce(fn, 0, ib, ie),
    function(e, a) e + a
  ) == 15
);

/**
 * Applies each element in an array to a function's parameter list.
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
    pc_ = param_count(fn),
    pc = len(p)
  )
  assert(is_function(fn))
  assert(is_list(p))
  assert(
    pc_ >= pc,
    str("Too many array elements (", pc,
        ") for the number of parameters available (", pc_, ")."))
  assert(pc < 16, "Can't apply more than 15 parameters.")
  //                     1 1 1 1 1 1
  // 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5
  //                 <
  //         <               <        
  //     <       <       <       <    
  //   <   <   <   <   <   <   <   <  
  pc < 8
  ? pc < 4
    ? pc < 2
      ? pc < 1
        ? fn()
        : fn(p[0])
      : pc < 3
        ? fn(p[0], p[1])
        : fn(p[0], p[1], p[2])
    : pc < 6
      ? pc < 5
        ? fn(p[0], p[1], p[2], p[3])
        : fn(p[0], p[1], p[2], p[3], p[4])
      : pc < 7
        ? fn(p[0], p[1], p[2], p[3], p[4], p[5])
        : fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6])
  : pc < 12
    ? pc < 10
      ? pc < 9
        ? fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7])
        : fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8])
      : pc < 11
        ? fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9])
        : fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10])
    : pc < 14
      ? pc < 13
        ? fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11])
        : fn(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12])
      : pc < 15
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

  let(a = arr(0) , r = apply_to_fn(fn, a)) assert(r == a, str(r, " ≠ ", a));
  let(a = arr(1) , r = apply_to_fn(fn, a)) assert(r == a, str(r, " ≠ ", a));
  let(a = arr(2) , r = apply_to_fn(fn, a)) assert(r == a, str(r, " ≠ ", a));
  let(a = arr(3) , r = apply_to_fn(fn, a)) assert(r == a, str(r, " ≠ ", a));
  let(a = arr(4) , r = apply_to_fn(fn, a)) assert(r == a, str(r, " ≠ ", a));
  let(a = arr(5) , r = apply_to_fn(fn, a)) assert(r == a, str(r, " ≠ ", a));
  let(a = arr(6) , r = apply_to_fn(fn, a)) assert(r == a, str(r, " ≠ ", a));
  let(a = arr(7) , r = apply_to_fn(fn, a)) assert(r == a, str(r, " ≠ ", a));
  let(a = arr(8) , r = apply_to_fn(fn, a)) assert(r == a, str(r, " ≠ ", a));
  let(a = arr(9) , r = apply_to_fn(fn, a)) assert(r == a, str(r, " ≠ ", a));
  let(a = arr(10), r = apply_to_fn(fn, a)) assert(r == a, str(r, " ≠ ", a));
  let(a = arr(11), r = apply_to_fn(fn, a)) assert(r == a, str(r, " ≠ ", a));
  let(a = arr(12), r = apply_to_fn(fn, a)) assert(r == a, str(r, " ≠ ", a));
  let(a = arr(13), r = apply_to_fn(fn, a)) assert(r == a, str(r, " ≠ ", a));
  let(a = arr(14), r = apply_to_fn(fn, a)) assert(r == a, str(r, " ≠ ", a));
  let(a = arr(15), r = apply_to_fn(fn, a)) assert(r == a, str(r, " ≠ ", a));
  // x = apply_to_fn(function(q,w)1, [3,3,3]);
}
tests_apply_to_fn();

echo(
  str("find_in_array: ", [1,2,3,4,5], "\n", function_find(), "\n", function(e) e%3==0)
);

/**
 * Will determine if any of the calls to any_fn(i) will result in a truthy
 * result.
 *
 * NOTE: This uses find to determine the any state which has a memory footprint
 *       of O(1), but may take longer than any_filter() if the matching item
 *       is way down the end of a long list due to call stack and iteration
 *       overhead.  On the plus side, this will terminate early if it finds a
 *       truthy result near the beginning of a list.
 *
 * @param any_fn (function(i) : bool)
 *   Where i is an index, if returns a truthy, will stop searching and return
 *   true.
 * @param begin_i_range_or_list (number | range | list)
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If begin_i_range_or_list is a number, end index to check.  If end_i < 0
 *     then reduce_op_fn is never called.  Therefore, this function returns
 *     false.
 *
 * @returns (bool)
 *   If any any_fn(i) calls returns truthy, then returns true, otherwise
 *   false.
 */
function any_find(any_fn, begin_i_range_or_list, end_i) =
  assert(is_function(any_fn),
    str("any_fn should be function. Got ", any_fn, " instead."))
  !is_undef(find(any_fn, begin_i_range_or_list, end_i))
;

function function_any_find() =
  function(any_fn, begin_i_range_or_list, end_i)
    any_find(any_fn, begin_i_range_or_list, end_i)
;

/**
 * Will determine if all of the calls to all_fn(i) will result in a truthy
 * result.
 *
 * NOTE: This uses find to determine the any state which has a memory footprint
 *       of O(1), but may take longer than all_filter() if a non-matching
 *       item is way down the end of a long list due to call stack and iteration
 *       overhead.  On the plus side, this will terminate early if it finds a
 *       falsy result near the beginning of a list.
 *
 * @param all_fn (function(i) : bool)
 *   Where i is an index, if returns a falsy, will stop searching and return
 *   false.
 * @param begin_i_range_or_list (number | range | list)
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If begin_i_range_or_list is a number, end index to check.  If end_i < 0
 *     then reduce_op_fn is never called.  Therefore, this function returns
 *     true.
 *
 * @returns (bool)
 *   If any any_fn(i) calls returns truthy, then returns true, otherwise
 *   false.
 */
function all_find(all_fn, begin_i_range_or_list, end_i) =
  assert(is_function(all_fn),
    str("all_fn should be function. Got ", all_fn, " instead."))
  !any_find(not(all_fn), begin_i_range_or_list, end_i)
  // is_undef(find(not(all_fn), begin_i_range_or_list, end_i));
;

function function_all_find() =
  function(all_fn, begin_i_range_or_list, end_i)
    all_find(all_fn, begin_i_range_or_list, end_i)
;

module tests_any_all(test_group) {
  if (test_group) {
    assert(let(a=[1,2,3,4,5])  any_find(function(i) a[i]==3, it_fwd(a)));
    assert(let(a=[1,2,3,4,5]) !any_find(function(i) a[i]==6, it_fwd(a)));
    assert(let(a=[1,2,3,4,5])  all_find(function(i) a[i]>0 , it_fwd(a)));
    assert(let(a=[1,2,3,4,5]) !all_find(function(i) a[i]!=3, it_fwd(a)));
    assert( in_array([1,2,3,4,5], function_any_find(), function(e) e==3));
    assert(!in_array([1,2,3,4,5], function_any_find(), function(e) e==6));
    assert( in_array([1,2,3,4,5], function_all_find(), function(e) e!=0));
    assert(!in_array([1,2,3,4,5], function_all_find(), function(e) e!=3));
  } else {
    assert( [for (e=[1,2,3,4,5]) if (e==3) 1 ]);
    assert(![for (e=[1,2,3,4,5]) if (e==6) 1 ]);
    assert(![for (e=[1,2,3,4,5]) if (e<=0) 1 ]);
    assert( [for (e=[1,2,3,4,5]) if (e==3) 1 ]);
    assert( [for (e=[1,2,3,4,5]) if (e==3) 1 ]);
    assert(![for (e=[1,2,3,4,5]) if (e==6) 1 ]);
    assert(![for (e=[1,2,3,4,5]) if (e<=0) 1 ]);
    assert( [for (e=[1,2,3,4,5]) if (e==3) 1 ]);
  }
}

tests_any_all(1);

/**
 * Searches for needle in haystack in the range specified.
 *
 * @param haystack (string | list)
 *   String or list of consecutive items to search through.
 * @param needle (string | list)
 *   String or list of consecutive items being searched for.
 * @param begin_i_range_or_list (number | range | list)
 *   - If number, start index to check (Default: 0)
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If begin_i_range_or_list is a number, end index to check. If end_i is
 *     less than or equal to begin_i_range_or_list, nothing is searched.
 *     (Default: len(haystack)-1)
 *
 * @returns (number | undef)
 *   The index where needle was found or undef if wasn't found.
 */
function substr(haystack, needle, begin_i_range_or_list=0, end_i=undef) =
  len(needle) > len(haystack)
  ? undef
  : let(
      t = enum_type(begin_i_range_or_list),
      n_len = len(needle),
      h_len = len(haystack),
      b_i = 
        t == NUM()
        ? begin_i_range_or_list
        : t == LIST()
          ? // If list then filter out start indices that would extend past the
            // end of the haystack.
            filter(function(i) begin_i_range_or_list[i] + n_len < h_len, it_fwd(begin_i_range_or_list))
          : assert(t == RANGE(),
              str("begin_i_range_or_list (", enum_type_to_str(t), "(", t, ")) must be a number, list or range."))
            begin_i_range_or_list[1] > 0
            ? [ begin_i_range_or_list[0] : begin_i_range_or_list[1] : min(begin_i_range_or_list[2], h_len-n_len) ]
            : [ min(begin_i_range_or_list[0], h_len-n_len) : begin_i_range_or_list[1] : begin_i_range_or_list[2] ],
      e_i =
        t == NUM()
        ? is_undef(end_i)
          ? h_len-n_len
          : min(end_i, h_len-n_len)
        : undef
    )
    find(
      function(i)
        all_find(
          function(j)
            let (h_i = j, n_i = j - i)
            haystack[h_i] == needle[n_i],
          i,
          i + len(needle) - 1),
      b_i, e_i)
;

module tests_substr() {
  echo("substr begin")
  echo("substr end: ",
  let(
    s = "hello there out there.",
    i = substr(s, "there"),
    i2 = substr(s, "there", i + 1)
    ) [i, i2],
    let (
      s = "hello there out there."
    ) filter(function(i) !is_undef(substr(s, "there", i, i)), it_fwd(s))
  );
}

////////////////////////////////////////////////////////////////////////////////
// Map and Filter
////////////////////////////////////////////////////////////////////////////////
/**
 * Helper to get the indices to traverse.
 *
 * @param begin_i_range_or_list (number | range | list)
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If begin_i_range_or_list is a number, end index to check.  If end_i is
 *     less than begin_i_range_or_list, then returns an empty list.
 *
 * @returns (list | range)
 *   Returns a list or range describing the indices to traverse.
 */
function _to_indices(begin_i_range_or_list, end_i) =
  is_num(begin_i_range_or_list)
  ? assert(is_num(end_i), str("end_i (", end_i, ") must be a number."))
    end_i < begin_i_range_or_list
    ? []
    : [ begin_i_range_or_list : end_i ]
  : begin_i_range_or_list 
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
 * @param begin_i_range_or_list (number | range | list)
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If begin_i_range_or_list is a number, end index to check.  If end_i is
 *     less than begin_i_range_or_list, then filter_pred_fn() is never called,
 *     so filter will return an empty list.
 *
 * @returns (list)
 *   Returns a list of all indices or elements where filter_pred_fn returned
 *   a truthy value.
 */
function filter(filter_pred_fn, begin_i_range_or_list, end_i) =
  let (
    indices = _to_indices(begin_i_range_or_list, end_i),
    return_indices = param_count(filter_pred_fn)
  )
  assert(return_indices == 1 || return_indices == 2)
  return_indices == 1
  ? [
    for (i = indices) if (filter_pred_fn(i)) i
  ]
  : [
    for (i = indices) if (filter_pred_fn(i)) filter_pred_fn(i, true)
  ]
;

function function_filter() =
  function(filter_pred_fn, begin_i_range_or_list, end_i)
    filter(filter_pred_fn, begin_i_range_or_list, end_i)
;

/**
 * Map values to indices or array elements, producing an array that has as many
 * elements as indices provided.
 *
 * @param map_fn (function (i) : any)
 *   Function to take an index and return the remapped value/object.
 * @param begin_i_range_or_list (number | range | list)
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If begin_i_range_or_list is a number, end index to check.  If end_i is
 *     less than begin_i_range_or_list, then map_fn() is never called,
 *     so map will return an empty list.
 *
 * @returns (list)
 *   A new mapped list.
 */
function map(map_fn, begin_i_range_or_list, end_i) =
  let (indices = _to_indices(begin_i_range_or_list, end_i))
  [ for (i = indices)
      map_fn(i)
  ]
;

function function_map() =
  function(map_fn, begin_i_range_or_list, end_i)
    map(map_fn, begin_i_range_or_list, end_i)
;

/**
 * Determines if any indices or elements passed to any_pred_fn will result in
 * a truthy value.
 *
 * NOTE: This uses filter to determine the any state which has a memory
 *       footprint of O(n), where n is the number of times any_pred_fn(i)
 *       returns true.  However, may take less time than any_find() if a non-
 *       matching item is way down the end of a long list due to no recursion
 *       overhead.  On the minus side, this will have to go through EVERY 
 *       index and WILL NOT terminate early if it finds a falsy result near the
 *       beginning of a list.
 *
 * @param any_pred_fn (function(i) : bool)
 *   - If array is not passed, function will take an index parameter and if it
 *     returns a truthy value, the index is stored in the returned array.
 *   - Otherwise will take the array element at that index and if it returns a
 *     truthy value, the index or the element value is stored depending on
 *     return_indices value.
 * @param begin_i_range_or_list (number | range | list)
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If begin_i_range_or_list is a number, end index to check.  If end_i is
 *     less than begin_i_range_or_list, then any_pred_fn() is never called and
 *     any_filter() returns false.
 *
 * @returns (bool)
 *   True if any of the calls to any_pred_fn with values from indices result in
 *   a truthy value, otherwise false.
 */
function any_filter(any_pred_fn, begin_i_range_or_list, end_i) =
  !!filter(any_pred_fn, begin_i_range_or_list, end_i)
;

function function_any_filter() =
  function(any_pred_fn, begin_i_range_or_list, end_i)
    any_filter(any_pred_fn, begin_i_range_or_list, end_i)
;

/**
 * Determines if all indices or elements passed to all_pred_fn will result in
 * a truthy value.
 *
 * NOTE: This uses filter to determine the any state which has a memory
 *       footprint of O(n), where n is the number of times all_pred_fn(i)
 *       returns false.  However, may take less time than all_find() if a non-
 *       matching item is way down the end of a long list due to no recursion
 *       overhead.  On the minus side, this will have to go through EVERY 
 *       index and WILL NOT terminate early if it finds a falsy result near the
 *       beginning of a list.
 *
 * @param all_pred_fn (function(i) : bool)
 *   - If array is not passed, function will take an index parameter and if it
 *     returns a truthy value, the index is stored in the returned array.
 *   - Otherwise will take the array element at that index and if it returns a
 *     truthy value, the index or the element value is stored depending on
 *     return_indices value.
 * @param begin_i_range_or_list (number | range | list)
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If begin_i_range_or_list is a number, end index to check.  If end_i is
 *     less than begin_i_range_or_list, then any_pred_fn() is never called and
 *     any_filter() returns false.
 *
 * @returns (bool)
 *   True if any of the calls to all_pred_fn with values from indices result in
 *   a truthy value, otherwise false.
 */
function all_filter(all_pred_fn, begin_i_range_or_list, end_i) =
  !any_filter(not(all_pred_fn), begin_i_range_or_list, end_i)
;

function function_all_filter(all_pred_fn, begin_i_range_or_list, end_i) =
  function(all_pred_fn, begin_i_range_or_list, end_i)
    all_filter(all_pred_fn, begin_i_range_or_list, end_i)
;