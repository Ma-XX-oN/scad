use <test>
use <list>
use <range>
use <base_algos>

module tests_list_el_and_el_idx() {
  a = [10, 20, 30, 40];
  test_eq(10, el(a, 0));
  test_eq(40, el(a, -1));
  test_eq(30, el(a, -2));

  test_eq(0, el_idx(a, 0));
  test_eq(3, el_idx(a, -1));
}

module tests_list_push_pop_shift_unshift_head_tail() {
  a0 = [];
  a1 = push(a0, [1]);
  a2 = push(a1, [2]);
  test_eq([1, 2], a2);

  test_eq(2, head(a2));
  test_eq([2], head_multi(a2, 1));
  test_eq([1, 2], head_multi(a2, 2));

  tail1 = tail(a2);
  test_eq(1, tail1);

  tail2 = tail_multi([1, 2, 3, 4], 2);
  test_eq([1, 2], tail2);

  s0 = [1, 2];
  s1 = shift(s0);
  test_eq([2], s1);

  u0 = [];
  u1 = unshift(u0, [1]);
  u2 = unshift(u1, [0]);
  test_eq([0, 1], u2);
}

module tests_list_insert_remove_replace() {
  a = [1, 3];
  a_ins = insert(a, 1, [2]);
  test_eq([1, 2, 3], a_ins);

  a_rem = remove([1, 2, 3], 1, 1);
  test_eq([1, 3], a_rem);

  a_rep = replace([1, 2, 3], 1, 1, [20]);
  test_eq([1, 20, 3], a_rep);

  a_rep_each = replace_each([1, 2, 3, 4], range(1, 2, 3), undef, [20, 40]);
  test_eq([1, 20, 3, 40], a_rep_each);
}

module tests_list_any_all() {
  a = [1, 2, 3, 4];

  test_eq(2, fn_in_list(a, fn_find())(function(e) e == 3));
  test_eq(undef, fn_in_list(a, fn_find())(function(e) e == 5));

  test_eq([2, 4], fn_in_list(a, fn_filter())(function(e, v) v ? e : e % 2 == 0));
  test_eq([1, 2, 3, 4], fn_in_list(a, fn_filter())(function(e, v) v ? e : e > 0));
  test_eq(0, fn_in_list(a, fn_find())(function(e) e > 0));

  // function_* wrappers for higher-order use.
  idxs = fn_in_list(a, fn_reduce([]), 1)(
    function(e, idxs) e % 2 == 0 ? concat(idxs, e) : idxs
  );
  test_eq([2, 4], idxs);
}

module tests_list_existing() {
  // Call your original comprehensive tests.
  tests_lists();
  tests_any_all("unit");
}

module tests_list() {
  tests_list_el_and_el_idx();
  tests_list_push_pop_shift_unshift_head_tail();
  tests_list_insert_remove_replace();
  tests_list_any_all();
  tests_list_existing();
}

tests_list();
