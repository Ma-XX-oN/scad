use <base_algos.scad>
use <any_all_none.scad>
use <list.scad>

/** Enum for unknown type */
function UNKNOWN() = 0;
/** Enum for undef type */
function UNDEF()   = 1;
/** Enum for boolean type */
function BOOL()    = 2;
/** Enum for string type */
function STR()     = 3;
/** Enum for list type */
function LIST()    = 4;
/** Enum for range type */
function RANGE()   = 5;
/** Enum for function type */
function FUNC()    = 6;
/** Enum for number type */
function NUM()     = 7;
/** Enum for integer type */
function INT()     = 8;
/** Enum for floating point type */
function FLOAT()   = 9;
/** Enum for NaN */
function NAN()     = 10;

/**
 * The names of the types indexed by the type enums.
 */
function TYPE_NAMES() = [
    "*UNKNOWN*" //  0
  , "undef"     //  1
  , "bool"      //  2
  , "str"       //  3
  , "list"      //  4
  , "range"     //  5
  , "func"      //  6
  , "num"       //  7
  , "int"       //  8
  , "float"     //  9
  , "NaN"       // 10
];


/**
 * Function to get the type of an object as an enum.
 *
 * @param o (any)
 *   The object to get the type from.
 *
 * @returns (number)
 *   The number corresponding to the type enum.
 */
function enum_type(o, distinguish_float_from_int = false) =
  is_string(o)   ? STR()    :
  is_list(o)     ? LIST()   :
  is_num(o[0])   ? RANGE()  :
  is_function(o) ? FUNC()   :
  is_num(o)      ? distinguish_float_from_int
                 ? floor(o) == o
                   ? INT()
                   : FLOAT()
                 : NUM()    :
  is_bool(o)     ? BOOL()   :
  is_undef(o)    ? UNDEF()  :
  is_nan(o)      ? NAN()    :
                   UNKNOWN();

function is_int(o) =
  is_num(o) && floor(o) == o
;

function is_float(o) =
  is_num(o) && floor(o) != o
;

function is_nan(n) =
  n != n
;

/**
 * Convert the type enum to a string.
 *
 * @param (number)
 *   Type enum to convert.
 *
 * @returns (string)
 *   The string corresponding to the type enum.  If type enum is not recognised,
 *   return "*INVALID TYPE*".
 */
function enum_type_to_str(i) =
  assert(is_num(i))
  0 <= i && i < len(TYPE_NAMES())
  ? TYPE_NAMES()[i]
  : "*INVALID TYPE*"
;

function type(o, distinguish_float_from_int = false) =
  enum_type_to_str(enum_type(o, distinguish_float_from_int));
;

function csv_strings_not_quoted(a) =
  is_list(a)
  ? len(a) > 0
    ? in_array(a, fn_reduce(str(a[0])), function(e, acc) str(acc, ", ", e), 1)
    : ""
  : a
;
echo(csv_strings_not_quoted(["hello", "there", "out", "there"]));

/**
 * Attempts to simplify the type structure of object o recursively.
 *
 * - If o is a list
 *   - if all elements in that list contain the same type structure,
 *     - simplify the list by only showing that structure once and append to it
 *       how many times it is repeated.
 *   - else if not the same, then recursively simplify each element.
 * - else it's some other type, so will just output the type of the object.
 *
 * @param o (any)
 *   Gets the simplified type structure of o.
 *
 * @returns (string)
 *   This string is a representation of the type structure of o.
 */
function type_structure(o) =
  let (
    gen_type_structure = // Generate detailed structure
      function(o)
        let (
          et = enum_type(o)
        )
        et == LIST()
        ? // in_array(o, function_map(), function(e) gen_type_structure(e))
          [ for (e = o) gen_type_structure(e) ] // same as above but is most likely more performant.
        : et
    ,
    simplify = // Simplifies the detailed type structure
      function(type_structure)
        is_list(type_structure)
          ? let (
              len_gt = len(type_structure)
            )
            len_gt == 0
            ? [ " (0 elements) " ]
            : let (
                sub_types = simplify(type_structure[0])
              )
              len_gt == 1
              ? concat( [ sub_types ], [ " (1 element)" ] )
              : all_find(function(i) type_structure[0] == type_structure[i], 1, len_gt-1)
                ? concat(
                    [ sub_types ],
                    [ str(" ... (", len_gt, " elements)") ]
                  )
                : // let (z =[ for (i = it_fwd_i(type_structure)) echo("i", i, type_structure[i], simplify(type_structure[i])) simplify(type_structure[i]) ] ) echo("z", z) z
                  in_array(type_structure, function_map(), function(e) simplify(e))
          : type_structure
    ,
    indent = function(spaces, s = "")
      assert(is_num(spaces))
      assert(spaces >= 0)
      1 ? "" :
      spaces == 0
      ? s
      : indent(spaces - 1, str(s, " "))
    ,
    result_to_str = // Convert the simplified structure to a string
      function(simplified_type_structure, depth = 0)
        is_list(simplified_type_structure)
        ? assert(len(simplified_type_structure) != 0,
            "All lists should have at least one element")
          let ( last = el(simplified_type_structure, -1) )
          is_string(last)
          ? // List end in string stating number of repeats
            str(
              indent(depth),
              "[ ",
              len(simplified_type_structure) > 1
              ? let (first = result_to_str(simplified_type_structure[0], depth+1))
                in_array(simplified_type_structure, fn_reduce(first),
                  function(e, acc) str(acc, ", ", indent(depth+1), result_to_str(e, depth+1)),
                  1, el_idx(simplified_type_structure, -2))
              : "",
              last,
              indent(depth),
              " ]"
            )
          : // List doesn't end in a string.
            let ( first = result_to_str(simplified_type_structure[0], depth+1) )
            str(
              "[ ",
              in_array(simplified_type_structure, fn_reduce(first),
                function(e, acc) str(acc, ", ", indent(depth+1), result_to_str(e)),
                1),
              " ]"
            )
        : // not a list.  Must be a type enum.
          assert(is_num(simplified_type_structure),
            str("Must be a number, but found: ", simplified_type_structure))
          enum_type_to_str(simplified_type_structure)
    ,
    type_structure = gen_type_structure(o),
    result = simplify(type_structure)
  )
  // result
  result_to_str(result)
;

function type_value(o) =
  str("value(", type_structure(o), "): {", o, "}")
;

echo(concat("hello", [1]));
echo(concat(["hello"], [1]));
echo("type_structure 1", type_structure("hi"));
echo("type_structure 2", type_structure(["hi", 1]));
echo("type_structure 3", type_structure(["hi", []]));
echo("type_structure 4", type_structure(["hi", ""]));
