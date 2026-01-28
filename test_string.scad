use <test>
use <string>
use <types>
use <helpers>
include <types_consts>
include <string_consts>

_fl = function(l) fl("test_string.scad", l);

module test_string_align_left_right() {
  // align_left / align_right semantics from implementation.
  test_eq("ab___", align_left("ab", 5, "_"), _fl(12));
  test_eq("___ab", align_right("ab", 5, "_"), _fl(13));

  // If width == len(s), result must be unchanged.
  test_eq("abc", align_left("abc", 3, "_"), _fl(16));
  test_eq("abc", align_right("abc", 3, "_"), _fl(17));
}

module test_string_repeat_and_sign_consts() {
  test_eq("",       repeat("x", 0), _fl(21));
  test_eq("x",      repeat("x", 1), _fl(22));
  test_eq("xxx",    repeat("x", 3), _fl(23));
  test_eq("ababab", repeat("ab", 3), _fl(24));

  // SHOW_SIGN_* values are used as indices in _sign_str.
  test_eq(0, SHOW_SIGN_NEG, _fl(27));
  test_eq(1, SHOW_SIGN_POS_NEG, _fl(28));
  test_eq(2, SHOW_SIGN_SPC_NEG, _fl(29));

  // _sign_str behaviour.
  test_eq("-", _sign_str(-1, SHOW_SIGN_NEG), _fl(32));
  test_eq("",  _sign_str( 1, SHOW_SIGN_NEG), _fl(33));
  test_eq("+", _sign_str( 1, SHOW_SIGN_POS_NEG), _fl(34));
  test_eq(" ", _sign_str( 0, SHOW_SIGN_SPC_NEG), _fl(35));
}

module test_string_float_to_string() {
  inf = 1/0;
  nan = inf - inf;

  // These are the exact test cases already present in string.scad.
  test_eq("+1.300000"
    , float_to_string(1.3, show_sign = SHOW_SIGN_POS_NEG), _fl(44));
  test_eq("+1.3000  "
    , float_to_string(1.3
      , show_sign = SHOW_SIGN_POS_NEG
      , precision = 4
      , min_width = 9), _fl(49));
  test_eq("  +1.3000"
    , float_to_string(1.3
      , show_sign       = SHOW_SIGN_POS_NEG
      , left_justified  = false
      , precision       = 4
      , min_width       = 9), _fl(55));
  test_eq(" 0.000000"
    , float_to_string(0
      , show_sign = SHOW_SIGN_SPC_NEG), _fl(58));
  test_eq("+inf"
    , float_to_string(inf
      , show_sign = SHOW_SIGN_POS_NEG), _fl(61));
  test_eq("-inf"
    , float_to_string(-inf
      , show_sign = SHOW_SIGN_POS_NEG), _fl(64));
  test_eq("NaN   "
    , float_to_string(nan
      , show_sign = SHOW_SIGN_POS_NEG
      , min_width = 6), _fl(68));
  test_eq("   NaN"
    , float_to_string(nan
      , show_sign      = SHOW_SIGN_POS_NEG
      , min_width      = 6
      , left_justified = false), _fl(73));
}

module test_string_obj_to_string() {
  // Default obj_to_string must delegate to str().
  test_eq("123", obj_to_string(123), _fl(78));
  test_eq("\"hello\"", obj_to_string("hello"), _fl(79));
  test_eq("hello", obj_to_string("hello", quote_strings=false), _fl(80));
  test_eq("[1, 2]"
    , obj_to_string([1, 2]), _fl(82));

  // Custom fmt_fn that only recognises lists.
  fmt_lists_only =
    function(obj)
      is_list(obj) ? "LIST" : undef;

  test_eq("LIST"
    , obj_to_string([1, 2], fmt_lists_only), _fl(90));
  test_eq("42"
    , obj_to_string(42, fmt_lists_only), _fl(92));
  test_eq("\"hi\""
    , obj_to_string("hi", fmt_lists_only), _fl(94));

  // Strings not recognised by fmt_fn must be quoted.
  fmt_none =
    function(obj) undef;

  test_eq("\"hi\""
    , obj_to_string("hi", fmt_none), _fl(101));
  test_eq("3"
    , obj_to_string(3, fmt_none), _fl(103));
}

module test_string() {
  test_string_align_left_right();
  test_string_repeat_and_sign_consts();
  test_string_float_to_string();
  test_string_obj_to_string();
}

test_string();
