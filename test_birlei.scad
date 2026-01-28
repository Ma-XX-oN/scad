use <test>
use <birlei>
use <indexable>
use <helpers>

_fl = function(l) fl("test_birlei.scad", l);

module test_birlei_to_indices() {
  range_is = [ each birlei_to_indices(1, 4) ];
  test_eq([1 : 1 : 4], birlei_to_indices(1, 4), _fl(10));
  test_eq([1, 2, 3, 4], range_is, _fl(11));
}

test_birlei_to_indices();
