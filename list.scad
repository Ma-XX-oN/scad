use <base_algos.scad>
use <range.scad>
use <types.scad>
use <helpers.scad>
use <test.scad>

/**
 * Gets the element of an array.  Allows for negative values to reference
 * elements starting from the end going backwards.
 *
 * @param a (list | string)
 *   The array to get the element from.
 * @param i (number)
 *   The index of the element.  If value is negative, then goes backward from
 *   end of array.
 *
 * @returns (any)
 *   The element at the index specified.
 */
function el(a, i) =
  a[el_idx(a, i)]
;

/**
 * Gets the index for an array.  Allows for negative values to reference
 * elements starting from the end going backwards.
 *
 * @param a (list | string)
 *   The array to get the index for.
 * @param i (number)
 *   The index of the element.  If value is negative, then goes backward from
 *   end of array.
 *
 * @returns (number)
 *   The positive index.
 */
function el_idx(a, i, debug) =
  (debug?echo("el_idx", a, i)0:0)+
  i >= 0
  ? i
  : len(a)+i
;

/**
 * Push an element onto the head of the list.
 *
 * @param a (list)
 *   List to add to.
 * @param es (list)
 *   List of elements to append to the list.  When adding one element, it must
 *   be wrapped in a list.
 *
 * @returns (list)
 *   The updated list.
 */
function push(a, es) =
  assert(is_list(a), "OOPS!")
  concat(a, es)
;

/**
 * Pops one or more elements off the head of the list.
 *
 * @param a (list)
 *   List to remove from.
 * @param i (number)
 *   Number of elements to pop off end of list.
 *
 * @returns (list)
 *   The updated list.
 */
function pop(a, i=1) =
  assert(is_list(a))
  assert(len(a) >= i)
  map(function(i) a[i], 0, len(a)-i-1)
;

/**
 * Unshift elements onto the tail of the list.
 *
 * @param a (list)
 *   List to add to.
 * @param es (list)
 *   List of elements to prepend to the list.  When adding one element, it must
 *   be wrapped in a list.
 *
 * @returns (list)
 *   The updated list.
 */
function unshift(a, es) =
  assert(is_list(a))
  concat(es, a)
;

/**
 * Shift elements off of the tail of the list.
 *
 * @param a (list)
 *   List to add to.
 * @param i (number)
 *   Number of elements to shift off beginning of list.
 *
 * @returns (list)
 *   The updated list.
 */
function shift(a, i=1) =
  assert(is_list(a))
  assert(len(a) >= i)
  map(function(i) a[i], i, len(a)-1)
;

/**
 * Insert elements es in list a starting at index i.
 *
 * @param a (list)
 *   List to insert into.
 * @param i (number)
 *   Index to insert into.
 *   - 0 to insert at beginning of list (like unshift)
 *   - len(a) to insert at end of list (like push)
 *   - Negative values will insert starting from the end.
 *     - -1 will insert between the second last element and the last element.
 *     - -len(a) will insert at the beginning of list (like unshift)
 *     - if less than -len(a), then will wrap.  E.g. -len(a)-1 is equivalent to
 *       -1.
 *
 * @returns (list)
 *   The updated list.
 */
function insert(a, i, es, debug) =
  assert(is_list(a))
  assert(i <= len(a), "Can only insert between indices [0, len(a)].")
  i < 0
  ? insert(a, len(a)-i-1, es)
  : i == len(a)
    ? push(a, es)
    : [
        for (j = [0 : i-1])
          a[j]
        ,
        each es
        ,
        debug ? echo("insert: ", a, i)[] : [],
        for (j = it_fwd_i(a, i, debug=debug))
          a[j]
      ]
;

// TODO: Benchmark this against insert()
function insert2(a, i, es) =
  assert(is_list(a))
  assert(i <= len(a), "Can only insert between indices [0, len(a)].")
  i < 0
  ? insert(a, len(a)-i-1, es)
  : i == len(a)
    ? push(a, es)
    : concat(
        map(function(i) a[i], 0, i-1),
        es,
        map(function(i) a[i], i, len(a)-1)
      )
;

/**
 * Removes a contagious set of elements from a list.
 *
 * @param a (list)
 *   List to remove elements from.
 * @param begin_i (number)
 *   The first index to remove.
 * @param end_i (number)
 *   The last index to remove.  If < begin_i, no elements are removed.
 *
 * @returns (list)
 *   The updated list.
 */
function remove(a, begin_i, end_i) =
  assert(is_list(a))
  [
    for (i = range(0, begin_i-1))
      a[i]
    ,
    for (i = range(end_i+1, len(a)-1))
      a[i]
  ]
;

// TODO:  Benchmark this against remove()
function remove2(a, begin_i, end_i) =
  assert(is_list(a))
  concat(
    map(function(i) a[i], 0,       begin_i-1),
    map(function(i) a[i], end_i+1, len(a)-1)
  )
;

/**
 * Replaces consecutive index set [a_begin_i, a_end_i] for list a with birl
 * index set of list b.
 *
 * @param a (list)
 *   List to have elements replaced.
 * @param a_begin_i (number)
 *   The starting index of a to replace.  Must be < len(a).
 * @param a_end_i (number)
 *   The ending index of a to replace. Must be >= 0.
 * @param b (list)
 *   List to draw elements from to replace the a element range with.
 * @param b_birl (number | range | list)
 *   - If number, start index to draw elements from (Default: 0)
 *   - If range, indices to draw elements from
 *   - If list, indices to draw elements from
 * @param b_end_i (number)
 *   - If b_birl is a number, then end index to draw elements from.  b_end_i
 *     could be less than b_birl if there's nothing to iterate over. (Default:
 *     len(b)-1)
 *
 * @returns (list)
 *   This is the updated list of elements.
 */
function replace(a, a_begin_i, a_end_i, b, b_birl=0, b_end_i=undef) =
  assert(is_list(a))
  assert(a_begin_i < len(a))
  assert(a_end_i >= 0)
  [
    for (i = range(0, a_begin_i-1))
      a[i]
    ,
    each in_array(b, function_map(), function(e) e, b_birl, b_end_i)
    ,
    for (i = range(a_end_i+1, len(a)-1))
      a[i]
  ]
;

function replace_each(a, a_birl, a_end_i, b, b_birl=0, b_end_i=undef) =
  let (
    a_rl = birlei_to_indices(a_birl, a_end_i),
    b_rl = birlei_to_indices(b_birl, b_end_i),
    end_i = range_len(a_rl)-1
  )
  assert(range_len(a_rl) == range_len(b_rl), 
    str("a and b ranges must be the same length.  Lengths are: ", range_len(a_rl),
      ", ", range_len(b_rl), " respectively."))
  fn_reduce(
    extract(a, 0, range_value(a_rl, 0)-1),
    0, end_i)
  (
    function(i, acc)
      concat(
        acc,
        b[range_value(b_rl, range_value(b_rl, i))],
        i != end_i
        ? extract(a, range_value(a_rl, i)+1, range_value(a_rl, i+1)-1)
        : extract(a, range_value(a_rl, i)+1)
      )
  )
;

/**
 * Gets the element at the head (end) of the list.
 *
 * @param a (list)
 *   List to get from.
 *
 * @returns (any)
 *   Object at the head of the list.
 */
function head(a) =
  assert(len(a) >= 1)
  a[len(a)-1]
;

/**
 * Gets the elements at the head (end) of the list.
 *
 * @param a (list)
 *   List to get from.
 * @param i (number)
 *   Number of elements to retrieve from the head.
 *
 * @returns (any)
 *   Object at the head of the list.
 */
function head_multi(a, i) =
  assert(len(a) >= i)
  map(function(i) a[i], len(a)-i, len(a)-1)
;

/**
 * Gets the element at the tail (beginning) of the list.
 *
 * @param a (list)
 *   List to get from.
 *
 * @returns (any)
 *   Object at the tail of the list.
 */
function tail(a) =
  assert(len(a) >= 1)
  a[0]
;

/**
 * Gets the elements at the tail (beginning) of the list.
 *
 * @param a (list)
 *   List to get from.
 * @param i (number)
 *   Number of elements to retrieve from the tail.
 *
 * @returns (any)
 *   Object at the tail of the list.
 */
function tail_multi(a, i) =
  assert(len(a) >= i)
  map(function(i) a[i], 0, i-1)
;

/**
 * Extracts a set of elements from list a.
 *
 * @param a (list)
 *   List to extract from.
 * @param birl (number | range | list)
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If birl is a number, end index to check.  If end_i is less than birl,
 *     then returns an empty list.
 *
 * @returns (list)
 *   A list of elements to have extracted.
 */
function extract(a, birl, end_i) =
  echo("extract", a, birl, end_i)
  in_array(a, function_map(), function(e) e, birl, end_i)
;

module tests_lists() {
  echo("RUNNING TESTS!");

  s0 = push([], [1]);
  s1 = push(s0, [2]);
  test_eq([1,2],        s1);
  test_eq(2,            head(s1));
  test_eq([2],          head_multi(s1,1));
  test_eq([1,2],        head_multi(s1,2));
  test_eq(1,            tail(s1));

  s2 = unshift(s1, [0]);
  test_eq(0,            tail(s2));
  test_eq([0, 1],       tail_multi(s2,2));

  s3 = insert(s2, 2, [3], 1);
  test_eq([0, 1, 3, 2], s3);
  test_eq([1, 3, 2],    shift(s3));
  test_eq([3, 2],       shift(s3, 2));
  test_eq([0, 1, 3],    pop(s3));
  test_eq([0, 1],       pop(s3, 2));
  test_eq([0, 2],       remove(s3, 1, 2));
  test_eq([0, 3, 2],    remove(s3, 1, 1));
  test_eq([0, 1, 3, 2], remove(s3, 1, 0));

  echo("TESTS SUCCEEDED!");
}

/**
 * Takes a 1D list and outputs it as a string with only row_length elements on
 * each row. E.g.
 * ```
 * [
 *    a, b, c,
 *    d, e, f
 * ]
 * ```
 *
 * If the row_length doesn't evenly divide into the length of the list, it will
 * be padded with undef at the end.
 *
 * @param list (list)
 *   A list to prettify.
 * @param row_length (number)
 *   The number of elements to show per line (Default: len(list))
 * @param fmt_el_fn (function(i, e, indent) : formatted_element)
 *   Format element function.  (Default: fmt_list_fn())
 *
 *   @param i (number)
 *     Index of the element.
 *   @param e (any)
 *     Element at index i.
 *   @param indent (string)
 *     The characters to put at the beginning of the line.
 *
 *   @returns (string)
 *     String displaying the element.
 * @param indent (string)
 *   The character to put at the beginning of each line.
 * @param indent_first_line (bool)
 *   States if to indent the first line.
 * @param new_indent (string)
 *   The indent string to add when adding a new indent level.
 * @param only_first_and_last (bool)
 *   States if to output only first and last row (true) or all rows (false).
 *
 * @return (string)
 *   Prettified list.
 */
function list_to_string(list, row_length, fmt_el_fn = fmt_list_fn(),
  indent = "", indent_first_line = false, new_indent = "  ", only_first_and_last = false
) =
  let (
    output_row_fn = function(i, acc, row_length = row_length, new_indent = new_indent)
      fn_reduce(
        str(acc, indent, new_indent, fmt_el_fn(i, list[i], indent)),
        i+1, i+row_length-1)
      (
        function(i, acc)
          str(acc, ", ", fmt_el_fn(i, list[i], indent))
      )
  )
  row_length == 0
  ?
    let (result = output_row_fn(0, "", len(list), ""))
    str(
      "[",
      result,
      "]"
    )
  :
  only_first_and_last
  ? str(
      indent_first_line ? indent : "",
      output_row_fn(0, "[\n"),
      len(list) > row_length
      ? str(
          len(list) > row_length * 2
          ? str(",\n", new_indent, indent, "...\n")
          : ",\n",
          output_row_fn((round(len(list)/row_length)-1)*row_length, "")
        )
      : "",
      "\n",
      indent,
      "]"
    )
  : str(
      indent_first_line ? indent : "",
      fn_reduce(
        output_row_fn(0, "[\n"),
        range(row_length, row_length, len(list)-1))
      (
        function(i, acc)
          output_row_fn(i, str(acc, ",\n"))
      ),
      "\n",
      indent,
      "]"
    )
;

function fmt_list_fn(precision=6, show_sign=SHOW_SIGN_SPC_NEG()) =
  function(i, e, indent)
    is_list(e)
    ? list_to_string(e, len(e), fmt_list_fn(), str("  ", indent))
    : is_num(e)
      ? float_to_string(e, precision=precision, show_sign=show_sign)
      : e
;

function fmt_coord_fn(precision=6, show_sign=SHOW_SIGN_SPC_NEG()) =
  function(i, e, indent)
    is_num(e)
    ? float_to_string(e, precision=precision, show_sign=show_sign)
    : str("*UNEXPECTED* ", e)
;

/**
 * Passed to list_to_string, this will format elements as if they are
 * coordinates.  Values are shown so that they all have the same number of
 * characters.
 */
function fmt_pt_fn(precision=6, show_sign=SHOW_SIGN_SPC_NEG()) =
  function(i, e, indent)
    is_list(e)
    ? list_to_string(e, 0, fmt_coord_fn(precision, show_sign))
    : str("*UNEXPECTED* ", e)
;

let(a = [1, 2, [3, 4, 5, 6, 7], 8])
echo(
  list_to_string(a, 1,
    function(i, e, indent)
      is_list(e)
      ? list_to_string(e, 2, indent = str(indent, "  "))
      : e
  )
);

let(a = [1,2,3,2,3,4])
echo(
  list_to_string(a, 2, only_first_and_last=1)
);

