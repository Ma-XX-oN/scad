use <test>
use <range>

module tests_range_is_range() {
  // Currently, library does not construct a dedicated "range object"
  // in OpenSCAD; these tests only cover negatives.
  test_falsy(is_range(123));
  test_falsy(is_range("abc"));
  test_falsy(is_range([0, 1, 2]));
}

module tests_range_construction() {
  // 2-argument form: [begin : end]
  test_eq([0:1:3], range(0, 3));
  test_eq([0:3], range(0, 3));
  test_eq([], range(3, 0));

  // 3-argument form: [begin : step : end]
  test_eq([0:2:4], range(0, 2, 4));
  test_eq([], range(4, 2, 0));
  test_eq([0:5:3], range(0, 5, 3));
}

module tests_range_len_and_idx_value() {
  // From existing inline tests.
  test_eq(4, range_len([0:3:10]));
  test_eq(4, range_len([10:-3:0]));
  test_eq(3, range_len([0:5:10]));

  r = [1:10];  // standard range list
  test_eq(10, range_len(r));

  // range_idx: positive and negative indexing.
  test_eq(0, range_idx(r, 0));
  test_eq(9, range_idx(r, 9));
  test_eq(undef, range_idx(r, -1));
  test_eq(undef, range_idx(r, -2));

  // range_el over a list.
  test_eq(1,  range_el(r, 0));
  test_eq(10, range_el(r, 9));
}

module tests_range_slice() {
  test_eq([2, 3]
    , slice([1, 2, 3, 4], 1, 2));
  test_eq([2, 3, 4]
    , slice([1, 2, 3, 4], 1, 3));
  test_eq([3, 4]
    , slice([1, 2, 3, 4], -2, -1));
}

module tests_slice() {
  test_eq([2,3], slice([1,2,3], 1, 2));
}

module tests_range_fns(el) {
  test_eq(4, slr_len([0:3:10]));
  test_eq(4, slr_len([10:-3:0]));
  test_eq(3, slr_len([0:5:10]));
  // assert(is_undef(slr_len([0:-1:10]))); // These work, but generate warnings.
  // assert(is_undef(slr_len([10:1:0])));  // These work, but generate warnings.
  let(r=[1:10]) test_eq(10, slr_len(r));
  let(r=[1:10]) test_eq(1, el(r, 0));
  let(r=[1:10]) test_eq(2, el(r, 1));
  let(r=[1:10]) test_eq(3, el(r, 2));
  let(r=[1:10]) test_eq(4, el(r, 3));
  let(r=[1:10]) test_eq(5, el(r, 4));
  let(r=[1:10]) test_eq(6, el(r, 5));
  let(r=[1:10]) test_eq(7, el(r, 6));
  let(r=[1:10]) test_eq(8, el(r, 7));
  let(r=[1:10]) test_eq(9, el(r, 8));
  let(r=[1:10]) test_eq(10, el(r, 9));

  let(r=[1:2:10]) test_eq(5, slr_len(r));
  let(r=[1:2:10]) test_eq(1, el(r, 0));
  let(r=[1:2:10]) test_eq(3, el(r, 1));
  let(r=[1:2:10]) test_eq(5, el(r, 2));
  let(r=[1:2:10]) test_eq(7, el(r, 3));
  let(r=[1:2:10]) test_eq(9, el(r, 4));

  let(r=[10:-2:1]) test_eq(5, slr_len(r));
  let(r=[10:-2:1]) test_eq(10, el(r, 0));
  let(r=[10:-2:1]) test_eq(8, el(r, 1));
  let(r=[10:-2:1]) test_eq(6, el(r, 2));
  let(r=[10:-2:1]) test_eq(4, el(r, 3));
  let(r=[10:-2:1]) test_eq(2, el(r, 4));
}

module tests_range_existing() {
  // Call existing test modules from range.scad so they still run
  // even if you later strip the auto-calls inside that file.
  tests_range_fns(function(r, i) range_el(r, i));
  tests_range_fns(function(lr, i) el(lr, i));
  tests_slice();
}

module tests_range_all() {
  tests_range_is_range();
  tests_range_construction();
  tests_range_len_and_idx_value();
  tests_range_slice();
  tests_range_existing();
}

tests_range_all();
