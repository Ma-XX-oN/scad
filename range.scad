function is_range(o) = !is_list(o) && !is_string(o) && is_num(o[0]);

function range_count(range) =
  let (
    count =
      assert(is_num(range[0]) && is_num(range[1]) && is_num(range[2]),
             str("Not a valid range (", range, ")."))
      assert(range[1] != 0, "range step cannot be 0")
      floor((range[2] - range[0]) / range[1]) + 1
  )
  count < 0
  ? undef
  : count
;

function range_value(range, i) =
  assert(i < range_count(range), str("i (", i, ") exceeds range index ", range))
  assert(0 <= i, str("i (", i, ") cannot be negative"))
  range[0] + range[1] * i
;

module tests_range_fns() {
  assert(range_count([0:3:10]) == 4);
  assert(range_count([10:-3:0]) == 4);
  assert(range_count([0:5:10]) == 3);
  // assert(is_undef(range_count([0:-1:10]))); // These work, but generate warnings.
  // assert(is_undef(range_count([10:1:0])));  // These work, but generate warnings.
  let(r=[1:10]) assert(range_count(r) == 10);
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
  
  let(r=[1:2:10]) assert(range_count(r) == 5);
  let(r=[1:2:10]) assert(range_value(r, 0) == 1);
  let(r=[1:2:10]) assert(range_value(r, 1) == 3);
  let(r=[1:2:10]) assert(range_value(r, 2) == 5);
  let(r=[1:2:10]) assert(range_value(r, 3) == 7);
  let(r=[1:2:10]) assert(range_value(r, 4) == 9);

  let(r=[10:-2:1]) assert(range_count(r) == 5);
  let(r=[10:-2:1]) assert(range_value(r, 0) == 10);
  let(r=[10:-2:1]) assert(range_value(r, 1) == 8);
  let(r=[10:-2:1]) assert(range_value(r, 2) == 6);
  let(r=[10:-2:1]) assert(range_value(r, 3) == 4);
  let(r=[10:-2:1]) assert(range_value(r, 4) == 2);
}
tests_range_fns();
