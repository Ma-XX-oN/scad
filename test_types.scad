use <test>
use <types>
use <helpers>
include <types_consts>

_fl = function(l) fl("test_types.scad", l);

module test_types_constants_and_names() {
  // type_enum_to_str converts type enum constants to strings.
  test_eq("*UNKNOWN*", type_enum_to_str(UNKNOWN), _fl(10));
  test_eq("undef"    , type_enum_to_str(UNDEF), _fl(11));
  test_eq("bool"     , type_enum_to_str(BOOL), _fl(12));
  test_eq("str"      , type_enum_to_str(STR), _fl(13));
  test_eq("list"     , type_enum_to_str(LIST), _fl(14));
  test_eq("range"    , type_enum_to_str(RANGE), _fl(15));
  test_eq("func"     , type_enum_to_str(FUNC), _fl(16));
  test_eq("num"      , type_enum_to_str(NUM), _fl(17));
  test_eq("int"      , type_enum_to_str(INT), _fl(18));
  test_eq("float"    , type_enum_to_str(FLOAT), _fl(19));
  test_eq("NaN"      , type_enum_to_str(NAN), _fl(20));

  // Out of range type index.
  test_eq("*INVALID TYPE*", type_enum_to_str(-1), _fl(23));
  test_eq("*INVALID TYPE*", type_enum_to_str(100), _fl(24));
}

module test_types_type_enum_basic() {
  nan = (1/0) - (1/0);

  test_eq(UNDEF, type_enum(undef), _fl(30));
  test_eq(BOOL , type_enum(true), _fl(31));
  test_eq(BOOL , type_enum(false), _fl(32));
  test_eq(STR  , type_enum("hi"), _fl(33));
  test_eq(LIST , type_enum([1, 2, 3]), _fl(34));

  // Numeric without int/float distinction.
  test_eq(NUM, type_enum(5), _fl(37));
  test_eq(NUM, type_enum(5.5), _fl(38));

  // With int/float distinction.
  test_eq(INT  , type_enum(5, true), _fl(41));
  test_eq(FLOAT, type_enum(5.5, true), _fl(42));

  // NaN path.
  test_eq(NAN, type_enum(nan), _fl(45));
}

module test_types_predicates() {
  nan = (1/0) - (1/0);

  test_truthy(is_int(5), _fl(51));
  test_falsy (is_int(5.5), _fl(52));
  test_falsy (is_int("5"), _fl(53));

  test_truthy(is_float(5.5), _fl(55));
  test_falsy (is_float(5), _fl(56));
  test_falsy (is_float("5"), _fl(57));

  test_truthy(is_nan(nan), _fl(59));
  test_falsy (is_nan(0), _fl(60));
  test_falsy (is_nan(1/0), _fl(61));
}

module test_types_type_and_type_structure() {
  // For non-lists, type_structure should collapse to type().
  test_eq(type(5),          type_structure(5), _fl(66));
  test_eq(type(5.5),        type_structure(5.5), _fl(67));
  test_eq(type("hello"),    type_structure("hello"), _fl(68));
  test_eq(type(true),       type_structure(true), _fl(69));
  test_eq(type(undef),      type_structure(undef), _fl(70));

  // With distinguish_float_from_int flag.
  test_eq("int",   type(5, true), _fl(73));
  test_eq("float", type(5.5, true), _fl(74));
}

module test_types_type_value() {
  // type_value wraps type_structure in a fixed format.
  v = 42;
  ts = type_structure(v);
  expected = str("value(", ts, "): {", v, "}");
  test_eq(expected, type_value(v), _fl(82));

  lst = [1, 2, 3];
  ts2 = type_structure(lst);
  expected2 = str("value(", ts2, "): {", lst, "}");
  test_eq(expected2, type_value(lst), _fl(87));
}

module test_types_is_indexable_te() {
  // Indexable types: RANGE, LIST, STR
  test_truthy(is_indexable_te(RANGE), _fl(92));
  test_truthy(is_indexable_te(LIST), _fl(93));
  test_truthy(is_indexable_te(STR), _fl(94));

  // Non-indexable types
  test_falsy(is_indexable_te(UNKNOWN), _fl(97));
  test_falsy(is_indexable_te(UNDEF), _fl(98));
  test_falsy(is_indexable_te(BOOL), _fl(99));
  test_falsy(is_indexable_te(NUM), _fl(100));
  test_falsy(is_indexable_te(FUNC), _fl(101));
}

module test_types() {
  test_types_constants_and_names();
  test_types_type_enum_basic();
  test_types_predicates();
  test_types_type_and_type_structure();
  test_types_type_value();
  test_types_is_indexable_te();
}

test_types();
