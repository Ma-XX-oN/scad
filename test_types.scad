use <test>
use <types>
include <types_consts>

module tests_types_constants_and_names() {
  // Basic enum values must map into TYPE_NAMES correctly.
  test_eq("*UNKNOWN*", TYPE_NAMES()[UNKNOWN]);
  test_eq("undef"    , TYPE_NAMES()[UNDEF]);
  test_eq("bool"     , TYPE_NAMES()[BOOL]);
  test_eq("str"      , TYPE_NAMES()[STR]);
  test_eq("list"     , TYPE_NAMES()[LIST]);
  test_eq("range"    , TYPE_NAMES()[RANGE]);
  test_eq("func"     , TYPE_NAMES()[FUNC]);
  test_eq("num"      , TYPE_NAMES()[NUM]);
  test_eq("int"      , TYPE_NAMES()[INT]);
  test_eq("float"    , TYPE_NAMES()[FLOAT]);
  test_eq("NaN"      , TYPE_NAMES()[NAN]);

  // type_enum_to_str must agree with TYPE_NAMES.
  test_eq("*UNKNOWN*", type_enum_to_str(UNKNOWN));
  test_eq("undef"    , type_enum_to_str(UNDEF));
  test_eq("bool"     , type_enum_to_str(BOOL));
  test_eq("str"      , type_enum_to_str(STR));
  test_eq("list"     , type_enum_to_str(LIST));
  test_eq("range"    , type_enum_to_str(RANGE));
  test_eq("func"     , type_enum_to_str(FUNC));
  test_eq("num"      , type_enum_to_str(NUM));
  test_eq("int"      , type_enum_to_str(INT));
  test_eq("float"    , type_enum_to_str(FLOAT));
  test_eq("NaN"      , type_enum_to_str(NAN));

  // Out of range type index.
  test_eq("*INVALID TYPE*", type_enum_to_str(-1));
  test_eq("*INVALID TYPE*", type_enum_to_str(len(TYPE_NAMES())));
}

module tests_types_type_enum_basic() {
  nan = (1/0) - (1/0);

  test_eq(UNDEF, type_enum(undef));
  test_eq(BOOL , type_enum(true));
  test_eq(BOOL , type_enum(false));
  test_eq(STR  , type_enum("hi"));
  test_eq(LIST , type_enum([1, 2, 3]));

  // Numeric without int/float distinction.
  test_eq(NUM, type_enum(5));
  test_eq(NUM, type_enum(5.5));

  // With int/float distinction.
  test_eq(INT  , type_enum(5, true));
  test_eq(FLOAT, type_enum(5.5, true));

  // NaN path.
  test_eq(NAN, type_enum(nan));
}

module tests_types_predicates() {
  nan = (1/0) - (1/0);

  test_truthy(is_int(5));
  test_falsy (is_int(5.5));
  test_falsy (is_int("5"));

  test_truthy(is_float(5.5));
  test_falsy (is_float(5));
  test_falsy (is_float("5"));

  test_truthy(is_nan(nan));
  test_falsy (is_nan(0));
  test_falsy (is_nan(1/0));
}

module tests_types_type_and_type_structure() {
  // For non-lists, type_structure should collapse to type().
  test_eq(type(5),          type_structure(5));
  test_eq(type(5.5),        type_structure(5.5));
  test_eq(type("hello"),    type_structure("hello"));
  test_eq(type(true),       type_structure(true));
  test_eq(type(undef),      type_structure(undef));

  // With distinguish_float_from_int flag.
  test_eq("int",   type(5, true));
  test_eq("float", type(5.5, true));
}

module tests_types_type_value() {
  // type_value wraps type_structure in a fixed format.
  v = 42;
  ts = type_structure(v);
  expected = str("value(", ts, "): {", v, "}");
  test_eq(expected, type_value(v));

  lst = [1, 2, 3];
  ts2 = type_structure(lst);
  expected2 = str("value(", ts2, "): {", lst, "}");
  test_eq(expected2, type_value(lst));
}

module tests_types() {
  tests_types_constants_and_names();
  tests_types_type_enum_basic();
  tests_types_predicates();
  tests_types_type_and_type_structure();
  tests_types_type_value();
}

tests_types();
