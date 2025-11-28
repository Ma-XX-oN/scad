use <test>
use <string>
use <types>

module tests_string_align_left_right() {
  // align_left / align_right semantics from implementation.
  test_eq("ab___", align_left("ab", 5, "_"));
  test_eq("___ab", align_right("ab", 5, "_"));

  // If width == len(s), result must be unchanged.
  test_eq("abc", align_left("abc", 3, "_"));
  test_eq("abc", align_right("abc", 3, "_"));
}

module tests_string_repeat_and_sign_consts() {
  test_eq("",       repeat("x", 0));
  test_eq("x",      repeat("x", 1));
  test_eq("xxx",    repeat("x", 3));
  test_eq("ababab", repeat("ab", 3));

  // SHOW_SIGN_* values are used as indices in _sign_str.
  test_eq(0, SHOW_SIGN_NEG());
  test_eq(1, SHOW_SIGN_POS_NEG());
  test_eq(2, SHOW_SIGN_SPC_NEG());

  // _sign_str behaviour.
  test_eq("-", _sign_str(-1, SHOW_SIGN_NEG()));
  test_eq("",  _sign_str( 1, SHOW_SIGN_NEG()));
  test_eq("+", _sign_str( 1, SHOW_SIGN_POS_NEG()));
  test_eq(" ", _sign_str( 0, SHOW_SIGN_SPC_NEG()));
}

module tests_string_float_to_string() {
  inf = 1/0;
  nan = inf - inf;

  // These are the exact test cases already present in string.scad.
  test_eq("+1.300000"
    , float_to_string(1.3, show_sign = SHOW_SIGN_POS_NEG()));
  test_eq("+1.3000  "
    , float_to_string(1.3
      , show_sign = SHOW_SIGN_POS_NEG()
      , precision = 4
      , min_width = 9));
  test_eq("  +1.3000"
    , float_to_string(1.3
      , show_sign       = SHOW_SIGN_POS_NEG()
      , left_justified  = false
      , precision       = 4
      , min_width       = 9));
  test_eq(" 0.000000"
    , float_to_string(0
      , show_sign = SHOW_SIGN_SPC_NEG()));
  test_eq("+inf"
    , float_to_string(inf
      , show_sign = SHOW_SIGN_POS_NEG()));
  test_eq("-inf"
    , float_to_string(-inf
      , show_sign = SHOW_SIGN_POS_NEG()));
  test_eq("NaN   "
    , float_to_string(nan
      , show_sign = SHOW_SIGN_POS_NEG()
      , min_width = 6));
  test_eq("   NaN"
    , float_to_string(nan
      , show_sign      = SHOW_SIGN_POS_NEG()
      , min_width      = 6
      , left_justified = false));
}

module tests_string_obj_to_string() {
  // Default obj_to_string must delegate to str().
  test_eq("123", obj_to_string(123));
  test_eq("\"hello\"", obj_to_string("hello"));
  test_eq("hello", obj_to_string("hello", quote_strings=false));
  test_eq("[1, 2]"
    , obj_to_string([1, 2]));

  // Custom fmt_fn that only recognises lists.
  fmt_lists_only =
    function(obj)
      is_list(obj) ? "LIST" : undef;

  test_eq("LIST"
    , obj_to_string([1, 2], fmt_lists_only));
  test_eq("42"
    , obj_to_string(42, fmt_lists_only));
  test_eq("\"hi\""
    , obj_to_string("hi", fmt_lists_only));

  // Strings not recognised by fmt_fn must be quoted.
  fmt_none =
    function(obj) undef;

  test_eq("\"hi\""
    , obj_to_string("hi", fmt_none));
  test_eq("3"
    , obj_to_string(3, fmt_none));
}

module tests_string() {
  tests_string_align_left_right();
  tests_string_repeat_and_sign_consts();
  tests_string_float_to_string();
  tests_string_obj_to_string();
}

tests_string();
