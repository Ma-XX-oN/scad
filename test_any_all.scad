use <test>
use <any_all>
use <indexable>
use <base_algos>
use <helpers>

_fl = function(l) fl("test_any_all.scad", l);

module test_any_all(test_group) {
  if (test_group) {
    test_truthy(let(a=[1,2,3,4,5])  any(fwd_i(a))(function(i) a[i]==3), _fl(11));
    test_truthy(let(a=[1,2,3,4,5]) !any(fwd_i(a))(function(i) a[i]==6), _fl(12));
    test_truthy(let(a=[1,2,3,4,5])  all(fwd_i(a))(function(i) a[i]>0 ), _fl(13));
    test_truthy(let(a=[1,2,3,4,5]) !all(fwd_i(a))(function(i) a[i]!=3), _fl(14));
    test_truthy( it_each([1,2,3,4,5], any())(function(e) e==3), _fl(15));
    test_truthy(!it_each([1,2,3,4,5], any())(function(e) e==6), _fl(16));
    test_truthy( it_each([1,2,3,4,5], all())(function(e) e!=0), _fl(17));
    test_truthy(!it_each([1,2,3,4,5], all())(function(e) e!=3), _fl(18));
  } else {
    test_truthy( [for (e=[1,2,3,4,5]) if (e==3) 1 ], _fl(20));
    test_truthy(![for (e=[1,2,3,4,5]) if (e==6) 1 ], _fl(21));
    test_truthy(![for (e=[1,2,3,4,5]) if (e<=0) 1 ], _fl(22));
    test_truthy( [for (e=[1,2,3,4,5]) if (e==3) 1 ], _fl(23));
    test_truthy( [for (e=[1,2,3,4,5]) if (e==3) 1 ], _fl(24));
    test_truthy(![for (e=[1,2,3,4,5]) if (e==6) 1 ], _fl(25));
    test_truthy(![for (e=[1,2,3,4,5]) if (e<=0) 1 ], _fl(26));
    test_truthy( [for (e=[1,2,3,4,5]) if (e==3) 1 ], _fl(27));
  }
}

module test_any_all_edge_cases() {
  // Empty list - any should return false
  test_falsy(it_each([], any())(function(e) true), _fl(33));

  // Empty list - all should return true (vacuous truth)
  test_truthy(it_each([], all())(function(e) false), _fl(36));

  // Single element - any
  test_truthy(it_each([5], any())(function(e) e == 5), _fl(39));
  test_falsy(it_each([5], any())(function(e) e == 3), _fl(40));

  // Single element - all
  test_truthy(it_each([5], all())(function(e) e == 5), _fl(43));
  test_falsy(it_each([5], all())(function(e) e != 5), _fl(44));

  // All true
  test_truthy(it_each([1, 2, 3], all())(function(e) e > 0), _fl(47));

  // All false
  test_falsy(it_each([1, 2, 3], all())(function(e) e > 10), _fl(50));

  // Mixed with false predicate
  test_falsy(it_each([1, 2, 3, 4, 5], all())(function(e) e < 4), _fl(53));

  // With undefined/null-like values
  test_falsy(it_each([1, 0, 2], all())(function(e) e != 0), _fl(56));
  test_truthy(it_each([1, 2, 3], all())(function(e) e != 0), _fl(57));
}

module test_list_any_all() {
  a = [1, 2, 3, 4];

  test_eq(2, it_each(a, find())(function(e) e == 3), _fl(63));
  test_eq(undef, it_each(a, find())(function(e) e == 5), _fl(64));

  test_eq([2, 4], it_each(a, filter())(function(e, v) v ? e : e % 2 == 0), _fl(66));
  test_eq([1, 2, 3, 4], it_each(a, filter())(function(e, v) v ? e : e > 0), _fl(67));
  test_eq(0, it_each(a, find())(function(e) e > 0), _fl(68));

  // function_* wrappers for higher-order use.
  idxs = it_each(a, reduce([]), 1)(
    function(e, idxs) e % 2 == 0 ? concat(idxs, e) : idxs
  );
  test_eq([2, 4], idxs, _fl(74));
}

module test_list_existing() {
  test_any_all("unit");
}

test_any_all(1);
test_list_any_all();
test_list_existing();
test_any_all_edge_cases();
