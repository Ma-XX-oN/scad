use <test>
use <base_algos>
use <list>

module tests_base_algos_find_and_filter() {
  a = [1, 2, 3, 4, 5];

  // find: exact match
  idx3 = find(function(i) a[i] == 3, 0, len(a) - 1);
  test_eq(2, idx3);

  // find_lower / find_upper on sorted data.
  sorted = [1, 3, 5, 7, 9];
  // First element >= 4 -> index of 5 -> 2
  test_eq(2, find_lower(function(i) sorted[i] - 4, 0, len(sorted)-1));
  // First element > 5 -> index of 7 -> 3
  test_eq(3, find_upper(function(i) sorted[i] - 5, 0, len(sorted)-1));

  // filter and map
  evens = filter(function(i, v) v ? a[i] : a[i] % 2 == 0, 0, len(a)-1);
  mapped = map(function(i) a[i]*2, 0, len(a)-1);
  test_eq([1, 3, 5], evens);     // indices 1, 3, 5 => values 2,4,6
  test_eq([2, 4, 6, 8, 10], mapped);
}

module tests_base_algos_reduce_and_reduce_air() {
  a = [1, 2, 3, 4];

  sum = reduce(
    function(i, acc) acc + a[i],
    0, 0, len(a)-1);
  test_eq(10, sum);

  // reduce_air used as standard reduce (cont always true).
  r = reduce_air(
    function(i, acc)
      [true, acc + a[i]],
    0, 0, len(a)-1);
  test_eq(10, r);
}

module tests_base_algos_in_array_and_param_count() {
  a = [10, 20, 30];

  // param_count
  fn0 = function() 0;
  fn2 = function(x, y) x + y;
  test_eq(0, param_count(fn0));
  test_eq(2, param_count(fn2));

  // in_array as a generic traversal: collect the elements.
  collected = in_array(
    a,
    fn_reduce([]),
    function(e, acc) concat(acc, [e]),
    0, len(a)-1);
  test_eq(a, collected);
}

module tests_base_algos_birlei_helpers() {
  // birl as begin index; end_i explicit.
  bi = 1;
  tuple = birlei_to_begin_i_end_i(bi, len([0,1,2,3]));
  // begin_i should be 1 and end_i unchanged.
  test_eq([1, len([0,1,2,3])], tuple);

  irange = birlei_to_indices(1, 4);
  test_eq([1, 2, 3, 4], irange);
}

module tests_base_algos_apply_to_fn() {
  // Re-use your existing exhaustive tests for apply_to_fn.
  tests_apply_to_fn();

  // Also check apply_to_fn2 round-trips the same way for simple case.
  fn2 = function(p0, p1, p2)
    [p0, p1, p2];

  arr = [1, 2, 3];
  r = apply_to_fn2(fn2, arr);
  test_eq(arr, r);
}

module tests_base_algos() {
  tests_base_algos_find_and_filter();
  tests_base_algos_reduce_and_reduce_air();
  tests_base_algos_in_array_and_param_count();
  tests_base_algos_birlei_helpers();
  tests_base_algos_apply_to_fn();
}

tests_base_algos();
