use <test>
use <base_algos>
use <function>
use <indexable>
use <helpers>

_fl = function(l) fl("test_function.scad", l);

module test_base_algos_apply_to_fn() {
  // Re-use your existing exhaustive tests for apply_to_fn.
  test_apply_to_fn();

  // Also check apply_to_fn2 round-trips the same way for simple case.
  fn2 = function(p0, p1, p2)
    [p0, p1, p2];

  arr = [1, 2, 3];
  r = apply_to_fn2(fn2, arr);
  test_eq(arr, r, _fl(19));
}

module test_apply_to_fn() {
  fn = function(p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15)
    let (arr =
      it_each(
        [p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15],
        filter())(
          function(e, v) v ? e : !is_undef(e)
        )
    )
    // echo(arr)
    arr
  ;

  arr = function(is)
    let (
      a = map(0, is-1)(function(i) i)
    )
    // echo("arr", a)
    a
  ;

  let(a = arr(0) , r = apply_to_fn(fn, a)) test_eq(a, r, _fl(43));
  let(a = arr(1) , r = apply_to_fn(fn, a)) test_eq(a, r, _fl(44));
  let(a = arr(2) , r = apply_to_fn(fn, a)) test_eq(a, r, _fl(45));
  let(a = arr(3) , r = apply_to_fn(fn, a)) test_eq(a, r, _fl(46));
  let(a = arr(4) , r = apply_to_fn(fn, a)) test_eq(a, r, _fl(47));
  let(a = arr(5) , r = apply_to_fn(fn, a)) test_eq(a, r, _fl(48));
  let(a = arr(6) , r = apply_to_fn(fn, a)) test_eq(a, r, _fl(49));
  let(a = arr(7) , r = apply_to_fn(fn, a)) test_eq(a, r, _fl(50));
  let(a = arr(8) , r = apply_to_fn(fn, a)) test_eq(a, r, _fl(51));
  let(a = arr(9) , r = apply_to_fn(fn, a)) test_eq(a, r, _fl(52));
  let(a = arr(10), r = apply_to_fn(fn, a)) test_eq(a, r, _fl(53));
  let(a = arr(11), r = apply_to_fn(fn, a)) test_eq(a, r, _fl(54));
  let(a = arr(12), r = apply_to_fn(fn, a)) test_eq(a, r, _fl(55));
  let(a = arr(13), r = apply_to_fn(fn, a)) test_eq(a, r, _fl(56));
  let(a = arr(14), r = apply_to_fn(fn, a)) test_eq(a, r, _fl(57));
  let(a = arr(15), r = apply_to_fn(fn, a)) test_eq(a, r, _fl(58));
  // x = apply_to_fn(function(q,w)1, [3,3,3]);
}

test_apply_to_fn();
test_base_algos_apply_to_fn();
