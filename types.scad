use <base_algorithms.scad>

function UNKNOWN() = 0;
function UNDEF()   = 1;
function BOOL()    = 2;
function NUM()     = 3;
function STR()     = 4;
function LIST()    = 5;
function FUNC()    = 6;
function RANGE()   = 7;

function TYPE_NAMES() = [
    "*UNKNOWN*"
  , "undef"    
  , "bool"     
  , "num"      
  , "str"      
  , "list"     
  , "func"     
  , "range"
];

function enum_type(o) =
  is_string(o)   ? STR()    :
  is_list(o)     ? LIST()   :
  is_num(o[0])   ? RANGE()  :
  is_function(o) ? FUNC()   :
  is_num(o)      ? NUM()    :
  is_bool(o)     ? BOOL()   :
  is_undef(o)    ? UNDEF()  :
                   UNKNOWN();

function enum_type_to_str(i) =
  0 <= i && i < len(TYPE_NAMES())
  ? TYPE_NAMES()[i]
  : "*INVALID TYPE*"
;

function type(o) =
  enum_type_to_str(enum_type(o));
;

// types(o, md, d) {
//   if md == d:
//     if is_list(o):
//       // Need to check if all elements are of the same type
//       if len(o) == 0:
//         // No elements, so all elements are the same
//         // Output "EMTPY LIST()"
//       else if len(o) == 1:
//         // One element, so all elements are the same
//         // output [ types(o[1]) ]
//       else:
//         // Verify all elements are the same
//         // Once verified, output [ types(o[1]) ]
//     else:
//       // Output type of o
//   else: // not at max depth
//     if is_list(o):
//       // output [ for (e = o) types(e, md, d+1) ]
//     else:
//       // output type(o)
// }
function types(o, max_depth = 999, depth = 0) =
  max_depth == depth
  ? is_list(o)
    ? len(o) == 0
      ? [ "(0 elements)" ]
      : len(o) == 1
        ? [ str(types(o[0]), "... (1 element)") ]
        : let (
            init = types(o[0]),
            _ = [
              for (i = [1:len(o)-1])
                assert(init == types(o[i]), str("Types not same at depth ", depth,
                ". Ref: ", init, " Array[", i, "]: ", types(o[i])))
            ]
          ) [ str(types(o[1]), "... (", len(o), " elements)") ]
    : type(o)
  : is_list(o)
    ? [ for (e = o) types(e, depth+1, max_depth) ]
    : type(o)
;

function gen_type(o) =
  let (
    et = enum_type(o)
  )
  et == LIST()
  ? [ for (e = o) gen_type(e) ]
  : et
;

function simplified_type(o, gt_ = undef) =
  let (
    gt = is_undef(gt_)
    ? gen_type(o)
    : gt_,
    t = is_list(gt)
      ? let (
          len_gt = len(gt)
        )
        len_gt == 0
        ? "[ (0 elements) ]"
        : len_gt == 1
          ? concat( simplified_type(o[0], gt[0]), [ " (1 element)" ] )
          : all_find(function(i) gt[0] == gt[i], 1, len_gt-1)
            ? concat( simplified_type(o[0], gt[0]), [ str("... (", len_gt, " elements) ]") ] )
            : [ for (i = it_fwd(gt)) simplified_type(o[i], gt[i]) ]
      : enum_type(o)
  )
  t
;
echo("simplified_type 1", simplified_type("hi"));
echo("simplified_type 2", simplified_type(["hi", ""]));
// _ = assert(!"TESTING", str("TYPES: ", types([1, [[[1, 3], ""], [[3, 3], ""]], "2"], 1)));
