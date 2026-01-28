use <test>
use <helpers>

_fl = function(l) fl("test_helpers.scad", l);

module test_helpers_angle_conversion() {
  // Radians to degrees: PI radians = 180 degrees
  test_approx_eq(180, r2d(PI), 1e-6, _fl(8));

  // Common angles
  test_approx_eq(90, r2d(PI / 2), 1e-6, _fl(11));
  test_approx_eq(45, r2d(PI / 4), 1e-6, _fl(12));
  test_approx_eq(0, r2d(0), 1e-6, _fl(13));

  // Degrees to radians: 180 degrees = PI radians
  test_approx_eq(PI, d2r(180), 1e-6, _fl(16));

  // Common angles
  test_approx_eq(PI / 2, d2r(90), 1e-6, _fl(19));
  test_approx_eq(PI / 4, d2r(45), 1e-6, _fl(20));
  test_approx_eq(0, d2r(0), 1e-6, _fl(21));

  // Round trip conversion
  test_approx_eq(45, r2d(d2r(45)), 1e-6, _fl(24));
  test_approx_eq(PI / 3, d2r(r2d(PI / 3)), 1e-6, _fl(25));
}

module test_helpers_clamp() {
  // Clamp below lower bound
  test_eq(10, clamp(5, 10, 20), _fl(30));

  // Clamp above upper bound
  test_eq(20, clamp(25, 10, 20), _fl(33));

  // Within bounds
  test_eq(15, clamp(15, 10, 20), _fl(36));

  // At bounds
  test_eq(10, clamp(10, 10, 20), _fl(39));
  test_eq(20, clamp(20, 10, 20), _fl(40));

  // Negative values
  test_eq(-10, clamp(-15, -10, 10), _fl(43));
  test_eq(10, clamp(15, -10, 10), _fl(44));
}

module test_helpers_equal() {
  // Exact equality
  test_truthy(equal(1.0, 1.0), _fl(49));
  test_truthy(equal([1, 2, 3], [1, 2, 3]), _fl(50));

  // Approximate equality with default epsilon
  test_truthy(equal(1.0, 1.0 + 1e-7), _fl(53));
  test_truthy(equal(1.0, 1.0 - 1e-7), _fl(54));

  // Outside default epsilon
  test_falsy(equal(1.0, 1.1), _fl(57));

  // Custom epsilon
  test_truthy(equal(1.0, 1.01, 0.02), _fl(60));
  test_falsy(equal(1.0, 1.01, 0.001), _fl(61));

  // Lists with approximate equality
  test_truthy(equal([1.0, 2.0], [1.0 + 1e-7, 2.0 - 1e-7]), _fl(64));
}

module test_helpers_default() {
  // Return value if not undef
  test_eq(42, default(42, 100), _fl(69));
  test_eq("hello", default("hello", "world"), _fl(70));

  // Return default if value is undef
  test_eq(100, default(undef, 100), _fl(73));
  test_eq("world", default(undef, "world"), _fl(74));

  // Return value if falsy but not undef (0, "", false)
  test_eq(0, default(0, 100), _fl(77));
  test_eq("", default("", "world"), _fl(78));
  test_eq(false, default(false, true), _fl(79));
}

module test_helpers_not() {
  // Negate predicate
  gt_fn = function(x) x > 5;
  le_fn = not(gt_fn);

  test_falsy(le_fn(10), _fl(87));  // not(10 > 5) = false
  test_truthy(le_fn(3), _fl(88));  // not(3 > 5) = true
  test_truthy(le_fn(5), _fl(89));  // not(5 > 5) = true
}

module test_helpers_arc_len() {
  // Arc length with radius - arc_len uses cross() which requires 3D vectors
  A = [1, 0, 0];
  B = [0, 1, 0];
  // 90 degree angle between vectors on unit circle
  arc = arc_len(A, B, R=1);
  test_gt(arc, 0, _fl(98));

  // Different points (3D vectors)
  A2 = [2, 0, 0];
  B2 = [0, 2, 0];
  arc2 = arc_len(A2, B2);
  test_gt(arc2, 0, _fl(104));
}

module test_helpers_arc_len_angle() {
  // Arc length to angle conversion
  // Arc length on unit circle
  angle = arc_len_angle(PI / 2, 1);  // pi/2 radians on circle of radius 1
  test_approx_eq(90, angle, 1e-6, _fl(111));

  // Full circle
  angle_full = arc_len_angle(2 * PI, 1);
  test_approx_eq(360, angle_full, 1e-6, _fl(115));

  // Half circle
  angle_half = arc_len_angle(PI, 1);
  test_approx_eq(180, angle_half, 1e-6, _fl(119));
}

module test_helpers_vector_info() {
  // vector_info returns [VI_VECTOR, VI_LENGTH, VI_DIR, VI_NORMAL]
  A = [0, 0, 0];
  B = [3, 4, 0];
  info = vector_info(A, B);

  test_eq([3, 4, 0], info[0], _fl(128));                    // VI_VECTOR
  test_eq(5, info[1], _fl(129));                             // VI_LENGTH
  test_approx_eq([0.6, 0.8, 0], info[2], 1e-6, _fl(130));   // VI_DIR

  // Another example
  A2 = [1, 0, 0];
  B2 = [2, 0, 0];
  info2 = vector_info(A2, B2);
  test_eq([1, 0, 0], info2[0], _fl(136));  // VI_VECTOR
  test_eq(1, info2[1], _fl(137));          // VI_LENGTH
}

module test_helpers_fl() {
  // fl returns a string like " in file <f>, line <l>\n"
  ref = fl("test_helpers.scad", 42);
  test_eq(" in file test_helpers.scad, line 42\n", ref, _fl(143));
}

module test_helpers_function_equal() {
  fn_eq = function_equal();
  test_truthy(fn_eq(1.0, 1.0), _fl(148));
  test_truthy(fn_eq([1, 2], [1, 2]), _fl(149));
  test_falsy(fn_eq(1.0, 2.0), _fl(150));
  test_truthy(fn_eq(1.0, 1.0 + 1e-7), _fl(151));
}

module test_helpers_assert() {
  // Assert with truthy value returns identity function
  id_fn = Assert(true, "should not fire");
  test_eq(42, id_fn(42), _fl(157));
  test_eq("hi", id_fn("hi"), _fl(158));

  // Assert with truthy value and function msg
  id_fn2 = Assert(1, function() "should not fire");
  test_eq(99, id_fn2(99), _fl(162));
}

module test_helpers_interpolated_values() {
  // 1 value between 1 and 2 => midpoint
  test_approx_eq([1.5], interpolated_values(1, 2, 1), 1e-6, _fl(167));

  // 3 values between 1 and 2
  result = interpolated_values(1, 2, 3);
  test_approx_eq([1.25, 1.5, 1.75], result, 1e-6, _fl(171));

  // Works with vectors
  result_v = interpolated_values([0, 0], [4, 8], 1);
  test_approx_eq([[2, 4]], result_v, 1e-6, _fl(175));
}

module test_helpers_arc_len_for_shift() {
  // Shift of 0 should give arc length of 0
  test_approx_eq(0, arc_len_for_shift(10, 0, 0), 1e-6, _fl(180));

  // Known geometry: unit circle, horizontal line y = a
  // Base line y = 0 intersects at (1,0). Shift by a moves line to y = a.
  ds = arc_len_for_shift(1, 0, 0.5);
  test_gt(ds, 0, _fl(185));
}

module test_helpers_shift_for_arc_len() {
  // Zero arc length should give shifts of [0, 0] (or close)
  result = shift_for_arc_len(1, 0, 0);
  test_approx_eq(0, result[0], 1e-6, _fl(191));
  test_approx_eq(0, result[1], 1e-6, _fl(192));

  // Round-trip: shift_for_arc_len then arc_len_for_shift
  R = 10;
  m = 0;
  target_ds = 1.0;
  shifts = shift_for_arc_len(R, m, target_ds);
  // a_up should produce the target arc length
  a_up = shifts[0];
  test_truthy(!is_undef(a_up), _fl(201));
  recovered_ds = arc_len_for_shift(R, m, a_up);
  test_approx_eq(target_ds, recovered_ds, 1e-6, _fl(203));
}

module test_helpers_offset_angle() {
  // Rotate [1,0,0] by 90 degrees around cross([0,0,1], [1,0,0]) = [0,1,0]
  // offset_angle(ref_vec, vec, delta_angle_deg)
  ref = [0, 0, 1];
  vec = [1, 0, 0];
  result = offset_angle(ref, vec, 10);
  // Result should still have the same magnitude
  test_approx_eq(norm(vec), norm(result), 1e-6, _fl(213));
  // Angle between ref and result should be arc_len(ref, result, R=1) different
  test_gt(norm(result), 0, _fl(215));
}

module test_helpers_all() {
  test_helpers_angle_conversion();
  test_helpers_clamp();
  test_helpers_equal();
  test_helpers_default();
  test_helpers_not();
  test_helpers_arc_len();
  test_helpers_arc_len_angle();
  test_helpers_vector_info();
  test_helpers_fl();
  test_helpers_function_equal();
  test_helpers_assert();
  test_helpers_interpolated_values();
  test_helpers_arc_len_for_shift();
  test_helpers_shift_for_arc_len();
  test_helpers_offset_angle();
}

test_helpers_all();
