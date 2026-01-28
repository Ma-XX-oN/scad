use <test>
use <indexable>
use <range>
use <base_algos>
use <helpers>

_fl = function(l) fl("test_list.scad", l);

module test_list_el_and_el_idx() {
  a = [10, 20, 30, 40];
  test_eq(10, el(a, 0), _fl(11));
  test_eq(40, el(a, -1), _fl(12));
  test_eq(30, el(a, -2), _fl(13));

  test_eq(0, idx(a, 0), _fl(15));
  test_eq(3, idx(a, -1), _fl(16));

  // Edge cases
  test_eq(10, el(a, 0), _fl(19));  // First element
  test_eq(40, el(a, 3), _fl(20));  // Last element by positive index
}

module test_list_push_pop_shift_unshift_head_tail() {
  a0 = [];
  a1 = push(a0, [1]);
  a2 = push(a1, [2]);
  test_eq([1, 2], a2, _fl(27));

  test_eq(2, head(a2), _fl(29));
  test_eq([2], head_multi(a2, 1), _fl(30));
  test_eq([1, 2], head_multi(a2, 2), _fl(31));

  tail1 = tail(a2);
  test_eq(1, tail1, _fl(34));

  tail2 = tail_multi([1, 2, 3, 4], 2);
  test_eq([1, 2], tail2, _fl(37));

  s0 = [1, 2];
  s1 = shift(s0);
  test_eq([2], s1, _fl(41));

  u0 = [];
  u1 = unshift(u0, [1]);
  u2 = unshift(u1, [0]);
  test_eq([0, 1], u2, _fl(46));

  // Edge cases
  // Push single vs multiple
  test_eq([5], push([], [5]), _fl(50));
  test_eq([1, 2, 3], push([1, 2], [3]), _fl(51));

  // Shift with count
  test_eq([3, 4], shift([1, 2, 3, 4], 2), _fl(54));

  // Pop with count
  test_eq([1, 2], pop([1, 2, 3, 4], 2), _fl(57));
}

module test_list_insert_remove_replace() {
  a = [1, 3];
  a_ins = insert(a, 1, [2]);
  test_eq([1, 2, 3], a_ins, _fl(63));

  a_rem = remove([1, 2, 3], 1, 1);
  test_eq([1, 3], a_rem, _fl(66));

  a_rep = replace([1, 2, 3], 1, 1, [20]);
  test_eq([1, 20, 3], a_rep, _fl(69));

  a_rep_each = replace_each([11, 12, 13, 14], range(1, 2, 3))([20, 40], 0, 1);
  test_eq([11, 20, 13, 40], a_rep_each, _fl(72));

  // Edge cases
  // Insert at beginning
  test_eq([99, 1, 2, 3], insert([1, 2, 3], 0, [99]), _fl(76));

  // Insert at end
  test_eq([1, 2, 3, 99], insert([1, 2, 3], 3, [99]), _fl(79));

  // Remove from beginning
  test_eq([2, 3], remove([1, 2, 3], 0, 0), _fl(82));

  // Remove from end
  test_eq([1, 2], remove([1, 2, 3], 2, 2), _fl(85));
}

module test_list_edge_cases() {
  // Empty list operations (pop/shift on empty list not supported - they assert)
  test_eq([], push([], []), _fl(90));
  // test_eq([], pop([]), _fl(91));  // Not supported: can't pop from empty
  // test_eq([], shift([]), _fl(92)); // Not supported: can't shift from empty
  test_eq([], unshift([], []), _fl(93));

  // Single element
  test_eq([], pop([1]), _fl(96));
  test_eq([], shift([1]), _fl(97));
  test_eq(1, head([1]), _fl(98));
  test_eq(1, tail([1]), _fl(99));

  // Multiple push/pop cycle (use let for sequential assignments in OpenSCAD)
  let(
    a0 = [],
    a1 = push(a0, [1]),
    a2 = push(a1, [2]),
    a3 = push(a2, [3])
  ) {
    test_eq([1, 2, 3], a3, _fl(106));
    let(a4 = pop(a3))
      test_eq([1, 2], a4, _fl(108));
  }

  // Negative indices for insert/remove
  // Remove with negative indices (implementation dependent)
  test_eq([1, 3], remove([1, 2, 3], 1, 1), _fl(112));
}

module test_list() {
  test_list_el_and_el_idx();
  test_list_push_pop_shift_unshift_head_tail();
  test_list_insert_remove_replace();
  test_list_edge_cases();
}

test_list();
