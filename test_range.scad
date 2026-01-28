use <test>
use <range>
use <indexable>
use <helpers>

_fl = function(l) fl("test_range.scad", l);

module test_range_is_range() {
  // These tests only verify non-range values return false.
  // Positive cases (actual ranges) are not tested here.
  test_falsy(is_range(123), _fl(11));
  test_falsy(is_range("abc"), _fl(12));
  test_falsy(is_range([0, 1, 2]), _fl(13));
}

module test_range_construction() {
  // 2-argument form: [begin : end]
  test_eq([0:1:3], range(0, 3), _fl(18));
  test_eq([0:3], range(0, 3), _fl(19));
  test_eq([], range(3, 0), _fl(20));

  // 3-argument form: [begin : step : end]
  test_eq([0:2:4], range(0, 2, 4), _fl(23));
  test_eq([], range(4, 2, 0), _fl(24));
  test_eq([0:5:3], range(0, 5, 3), _fl(25));
}

module test_range_len_and_idx_value() {
  // From existing inline tests.
  test_eq(4, range_len([0:3:10]), _fl(30));
  test_eq(4, range_len([10:-3:0]), _fl(31));
  test_eq(3, range_len([0:5:10]), _fl(32));

  r = [1:10];  // standard range list
  test_eq(10, range_len(r), _fl(35));

  // range_idx: positive and negative indexing.
  test_eq(0, range_idx(r, 0), _fl(38));
  test_eq(9, range_idx(r, 9), _fl(39));
  test_eq(9, range_idx(r, -1), _fl(40));
  test_eq(8, range_idx(r, -2), _fl(41));

  // range_el over a list.
  test_eq(1,  range_el(r, 0), _fl(44));
  test_eq(10, range_el(r, 9), _fl(45));
}

module test_range_slice() {
  // els(slr, begin_i, end_i) extracts elements from begin to end
  test_eq([2, 3], els([1, 2, 3, 4], 1, 2), _fl(50));
  test_eq([2, 3, 4], els([1, 2, 3, 4], 1, 3), _fl(51));
  test_eq([3, 4], els([1, 2, 3, 4], slice(-2, -1)), _fl(52));
}

module test_slice_object() {
  // slice() creates a slice object that can be used with els()
  s = slice(1, 2);  // slice from index 1 to 2
  test_eq([2, 3], els([1, 2, 3, 4], s), _fl(58));
}

module test_range_fns(el_fn) {
  test_eq(4, slr_len([0:3:10]), _fl(62));
  test_eq(4, slr_len([10:-3:0]), _fl(63));
  test_eq(3, slr_len([0:5:10]), _fl(64));
  // assert(is_undef(slr_len([0:-1:10]))); // These work, but generate warnings.
  // assert(is_undef(slr_len([10:1:0])));  // These work, but generate warnings.
  let(r=[1:10]) test_eq(10, slr_len(r), _fl(67));
  let(r=[1:10]) test_eq(1, el_fn(r, 0), _fl(68));
  let(r=[1:10]) test_eq(2, el_fn(r, 1), _fl(69));
  let(r=[1:10]) test_eq(3, el_fn(r, 2), _fl(70));
  let(r=[1:10]) test_eq(4, el_fn(r, 3), _fl(71));
  let(r=[1:10]) test_eq(5, el_fn(r, 4), _fl(72));
  let(r=[1:10]) test_eq(6, el_fn(r, 5), _fl(73));
  let(r=[1:10]) test_eq(7, el_fn(r, 6), _fl(74));
  let(r=[1:10]) test_eq(8, el_fn(r, 7), _fl(75));
  let(r=[1:10]) test_eq(9, el_fn(r, 8), _fl(76));
  let(r=[1:10]) test_eq(10, el_fn(r, 9), _fl(77));

  let(r=[1:2:10]) test_eq(5, slr_len(r), _fl(79));
  let(r=[1:2:10]) test_eq(1, el_fn(r, 0), _fl(80));
  let(r=[1:2:10]) test_eq(3, el_fn(r, 1), _fl(81));
  let(r=[1:2:10]) test_eq(5, el_fn(r, 2), _fl(82));
  let(r=[1:2:10]) test_eq(7, el_fn(r, 3), _fl(83));
  let(r=[1:2:10]) test_eq(9, el_fn(r, 4), _fl(84));

  let(r=[10:-2:1]) test_eq(5, slr_len(r), _fl(86));
  let(r=[10:-2:1]) test_eq(10, el_fn(r, 0), _fl(87));
  let(r=[10:-2:1]) test_eq(8, el_fn(r, 1), _fl(88));
  let(r=[10:-2:1]) test_eq(6, el_fn(r, 2), _fl(89));
  let(r=[10:-2:1]) test_eq(4, el_fn(r, 3), _fl(90));
  let(r=[10:-2:1]) test_eq(2, el_fn(r, 4), _fl(91));
}

module test_range_existing() {
  // Call existing test modules from range.scad so they still run
  // even if you later strip the auto-calls inside that file.
  test_range_fns(function(r, i) range_el(r, i));
  test_range_fns(function(lr, i) el(lr, i));
  test_slice_object();
}

module test_range_all() {
  test_range_is_range();
  test_range_construction();
  test_range_len_and_idx_value();
  test_range_slice();
  test_range_existing();
}

test_range_all();
