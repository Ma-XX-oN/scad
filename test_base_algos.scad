use <test>
use <base_algos>
use <indexable>
use <function>

module tests_base_algos_find_and_filter() {
  a = [1, 2, 3, 4, 5];

  // find: exact match
  idx3 = find(0, len(a) - 1)(function(i) a[i] == 3);
  test_eq(2, idx3);

  // find_lower / find_upper on sorted data.
  sorted = [1, 3, 5, 7, 9];
  // First element >= 4 -> index of 5 -> 2
  test_eq(2, find_lower(0, len(sorted)-1)(function(i) sorted[i] - 4));
  // First element > 5 -> index of 7 -> 3
  test_eq(3, find_upper(0, len(sorted)-1)(function(i) sorted[i] - 5));

  // filter and map
  evens = filter(0, len(a)-1)(function(i, v) v ? a[i] : a[i] % 2 == 0);
  mapped = map(0, len(a)-1)(function(i) a[i]*2);
  test_eq([2, 4], evens);     // indices 1, 3, 5 => values 2,4,6
  test_eq([2, 4, 6, 8, 10], mapped);
}

module tests_base_algos_reduce_and_reduce_air() {
  a = [1, 2, 3, 4];

  sum = reduce(0, 0, len(a)-1)(function(i, acc) acc + a[i]);
  test_eq(10, sum);

  // reduce_air used as standard reduce (cont always true).
  r = reduce_air(0, 0, len(a)-1)(
    function(i, acc)
      [true, acc + a[i]]
  )[1];
  test_eq(10, r);
}

module tests_base_algos_slr_each_and_param_count() {
  a = [10, 20, 30];

  // param_count
  fn0 = function() 0;
  fn2 = function(x, y) x + y;
  test_eq(0, param_count(fn0));
  test_eq(2, param_count(fn2));

  // it_each as a generic traversal: collect the elements.
  collected = it_each(a, reduce([]), 0, len(a)-1)(
    function(e, acc) concat(acc, [e])
  );
  test_eq(a, collected);
}

module tests_base_algos() {
  tests_base_algos_find_and_filter();
  tests_base_algos_reduce_and_reduce_air();
  tests_base_algos_slr_each_and_param_count();
}

tests_base_algos();
