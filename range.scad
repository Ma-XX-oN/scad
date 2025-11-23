use <list.scad>
/**
 * Tests if the object is a range object.
 *
 * @param o (any)
 *   Object to test.
 *
 * @return (bool)
 *   Returns if object is a range.
 */
function is_range(o) =
  !is_list(o) && !is_string(o) && is_num(o[0])
;

/**
 * @overload range(begin_i, end_i)
 * @overload range(begin_i, step, end_i)
 *
 * Creates a range object.  Will NOT generate a warning if step results in no
 * elements in range, unlike [ begin_i : end_i ] or [ begin_i : step : end_i ].
 *
 * @param begin_i (number)
 *   The beginning index.
 * @param step (number)
 *   step value when iterating from begin_i to end_i.  Cannot be 0.
 * @param end_i (number)
 *   If a number, then this is the ending index.
 *
 * @returns (range | list)
 *   This is the range to iterate over.  If step < 0 and begin_i < end_i or step
 *   > 0 and end_i < begin_i, then returns an empty list.
 */
function range(begin_i, step_or_end_i, end_i) =
  is_undef(end_i)  // are only 2 params defined?
  ? begin_i <= step_or_end_i
    ? [ begin_i : step_or_end_i ]
    : []
  : step_or_end_i > 0 // 3 params defined.  Increasing or decreasing?
    ? begin_i <= end_i
      ? [ begin_i : step_or_end_i : end_i ]
      : []
    : assert(step_or_end_i != 0, "Range cannot have a step of 0.")
      end_i <= begin_i
      ? [ end_i : step_or_end_i : begin_i ]
      : []
;

/**
 * Will return the number of elements the range will return.
 *
 * @param range (range | list)
 *   The range to count how many indices it will iterate over.  If a list,
 *   assumes it is a list of 0 or more numbers.
 *
 * @returns (number)
 *   The number of indices the range contains.
 */
function range_len(rl) =
  let (
    count =
      assert(is_list(rl) || is_num(rl[0]) && is_num(rl[1]) && is_num(rl[2]),
             str("Not a valid rl (", rl, ")."))
      assert(rl[1] != 0, "range step cannot be 0")
      is_list(rl)
      ? len(rl)
      : floor((rl[2] - rl[0]) / rl[1]) + 1
  )
  count < 0
  ? undef
  : count
;

/**
 * Will return the index that would have been returned if left to iterate i
 * times.
 *
 * @param range (range | list)
 *   The range to get index from if left to iterate i times.
 * @param i (number)
 *   The number iterations to have been done to get the return value.
 *
 * @returns (number)
 *   The index to have retrieved if iterated over i times.
 */
function range_value(rl, i) =
  let (
    l = range_len(rl),
    offset = i < 0 ? l : 0,
    ii = i + offset
  )
  assert(ii < l, str("i (", i, ") exceeds the length for the range ", l, "."))
  assert(ii >= 0,
    str("i (", i, ") negative value exceeds the length of the range ", l, "."))
  is_list(rl)
  ? rl[ii]
  : rl[0] + rl[1] * ii
;

/**
 * Gets the index for an array.  Allows for negative values to reference
 * elements starting from the end going backwards.
 *
 * @param a (list)
 *   The array to get the index for.
 * @param i (number)
 *   The index of the element.  If value is negative, then goes backward from
 *   end of array.
 *
 * @returns (number)
 *   The positive index.
 */
function range_idx(rl, i) =
  i >= 0
  ? i
  : range_len(rl)+i
;

module tests_range_fns() {
  assert(range_len([0:3:10]) == 4);
  assert(range_len([10:-3:0]) == 4);
  assert(range_len([0:5:10]) == 3);
  // assert(is_undef(range_len([0:-1:10]))); // These work, but generate warnings.
  // assert(is_undef(range_len([10:1:0])));  // These work, but generate warnings.
  let(r=[1:10]) assert(range_len(r) == 10);
  let(r=[1:10]) assert(range_value(r, 0) == 1);
  let(r=[1:10]) assert(range_value(r, 1) == 2);
  let(r=[1:10]) assert(range_value(r, 2) == 3);
  let(r=[1:10]) assert(range_value(r, 3) == 4);
  let(r=[1:10]) assert(range_value(r, 4) == 5);
  let(r=[1:10]) assert(range_value(r, 5) == 6);
  let(r=[1:10]) assert(range_value(r, 6) == 7);
  let(r=[1:10]) assert(range_value(r, 7) == 8);
  let(r=[1:10]) assert(range_value(r, 8) == 9);
  let(r=[1:10]) assert(range_value(r, 9) == 10);

  let(r=[1:2:10]) assert(range_len(r) == 5);
  let(r=[1:2:10]) assert(range_value(r, 0) == 1);
  let(r=[1:2:10]) assert(range_value(r, 1) == 3);
  let(r=[1:2:10]) assert(range_value(r, 2) == 5);
  let(r=[1:2:10]) assert(range_value(r, 3) == 7);
  let(r=[1:2:10]) assert(range_value(r, 4) == 9);

  let(r=[10:-2:1]) assert(range_len(r) == 5);
  let(r=[10:-2:1]) assert(range_value(r, 0) == 10);
  let(r=[10:-2:1]) assert(range_value(r, 1) == 8);
  let(r=[10:-2:1]) assert(range_value(r, 2) == 6);
  let(r=[10:-2:1]) assert(range_value(r, 3) == 4);
  let(r=[10:-2:1]) assert(range_value(r, 4) == 2);
}
tests_range_fns();

/**
 * Creates a subset of the rl object.
 *
 * @param rl (range | list)
 *   Starting range/list object to slice.
 * @param begin_i (number)
 *   The first index of the slice.
 * @param end_i (number)
 *   The last index of the slice.  If < begin_i, then will return an empty list.
 *
 * @return (range | list)
 *   Returns a portion of the original rl object.  If < begin_i, then will
 *   return an empty list.
 */
function slice(rl, begin_i, end_i) =
  let (
    b_i = range_idx(rl, begin_i),
    e_i = range_idx(rl, end_i)
  )
  is_list(rl)
  ? extract(rl, b_i, e_i)
  : range(range_value(rl, b_i), rl[1], range_value(rl, e_i))
;

module tests_slice() {
  assert(slice([1,2,3], 1, 2) == [2,3]);
  echo(slice([1,2,3], 1, 4) == [2,3]);
}
tests_slice();
