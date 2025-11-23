use <base_algos.scad>
use <list.scad>
use <helpers.scad>
use <types.scad>
use <range.scad>

/** Header for skin */
function SKIN_ID() = "SKIN";
/** Index for points in layer */
function SKIN_PTS_IN_LAYER() = 1;
/** Index for # of point layers - 1 */
function SKIN_LAYERS() = 2;
/** Index for the list of points */
function SKIN_PTS() = 3;
/** Index for debug axes */
function SKIN_DEBUG_AXES() = 4;
/** Index for the comment if any */
function SKIN_COMMENT() = 5;
/** Index for the operation ([op, apply_to_next_count]) */
function SKIN_OPERATION() = 6;
/** Index for wall diagonal info */
function SKIN_WALL_DIAG() = 7;

function skin_to_string(obj, only_first_and_last_layers = true, precision = 4) =
  let (
    names = [
      "ID", "PTS_IN_LAYER", "LAYERS", "PTS", "DEBUG_AXIS", "COMMENT", "OPERATION", "WALL_DIAG"
    ],
    fmt_el_fn = function(i,e,indent)
      str(names[i], ": ",
        i == SKIN_PTS()
        ? list_to_string(e, obj[SKIN_PTS_IN_LAYER()], indent=str("  ", indent),
            fmt_pt_fn(precision), only_first_and_last_layers)
        : e)
  )
  echo("skin_to_string", type_structure(obj), obj)
  list_to_string(obj, 1, fmt_el_fn)
;

/**
 * Computes the linear index of a point in a layered point array.
 *
 * This allows to more easily visualise what points are being referenced,
 * relative to different layers.
 *
 * Assumes that points are stored consecutively per layer, and layers are
 * stacked consecutively in memory.
 *
 * @param pts_in_layer (integer):
 *   Number of points in each layer.
 * @param pt_i (integer):
 *   Index of the point (0-based).  If > pts_in_layer, then wraps back to 0.
 * @param layer (integer):
 *   Index of the layer (0-based).
 *
 * @returns (integer)
 *   The linear index of the specified point.
 */
function layer_pt(pts_in_layer, pt_i, layer)
  = (pt_i % pts_in_layer) + pts_in_layer * layer
;

/**
 * Computes a list of linear layer_i for multiple points in a layered point
 * array.
 *
 * This allows to more easily visualise what points are being referenced,
 * relative to different layers.
 *
 * Assumes points are stored consecutively per layer, with each layer laid out
 * sequentially.
 *
 * @param pts_in_layer (integer):
 *   Number of points per layer.
 * @param pt_offset_and_layer_list (list of [pt_offset, layer]):
 *   List of (point index, layer index) pairs.
 *
 * @returns (list of integer)
 *   A list of linear layer_i corresponding to the given points.
 */
function layer_pts(pts_in_layer, pt_offset_and_layer_list)
  = [
      for (pt_offset_and_layer = pt_offset_and_layer_list)
        layer_pt(pts_in_layer, pt_offset_and_layer[0], pt_offset_and_layer[1])
    ];

/**
 * Helper to generate side wall faces between consecutive layers.
 *
 * Assumes the points are arranged in a flat list, with each layer's points
 * stored contiguously, and layers stored in sequence. Points within each
 * layer must be ordered **clockwise when looking into the object**.
 *
 * Each wall segment is formed from two triangles connecting corresponding
 * points between adjacent layers.
 *
 * @param pts_in_layer (integer):
 *   Number of points per layer.
 * @param layers (integer):
 *   Number of vertical wall segments to generate (requires one more point
 *   layer).
 * @param wall_diagonal (list<bool>):
 *   This is used to allow changing the diagonal of neighbouring square polygons
 *   on a layer.
 *
 *   E.g.
 *     - [1] will have all diagonals go one way.
 *     - [1,0] will alternate.
 *     - [0,1] will alternate the opposite way to [1,0].
 *     - [0,0,1] will have it go one way for 2 consecutive squares, and then the
 *       other way, and then repeat.
 *
 * @returns (list of [int, int, int]):
 *   A list of triangle layer_i forming the side walls.
 */
function layer_side_faces(pts_in_layer, layers = 1, wall_diagonal = [0, 1])
  = assert(is_list(wall_diagonal))
    [ for (layer = [0: layers-1])
      for (i = [0:pts_in_layer-1]) // i is the point index in the layer
        each let(
          which_diag_index = (i + pts_in_layer * layer) % len(wall_diagonal)
        )
        wall_diagonal[which_diag_index]
        ? [
          layer_pts(pts_in_layer, [[i, layer], [i,   layer+1], [i+1, layer+1]]),
          layer_pts(pts_in_layer, [[i, layer], [i+1, layer+1], [i+1, layer  ]])
        ]
        : [
          layer_pts(pts_in_layer, [[i, layer+1], [i+1, layer+1], [i+1, layer]]),
          layer_pts(pts_in_layer, [[i, layer+1], [i+1, layer  ], [i  , layer]])
        ]
    ];

/**
 * Triangulates a simple, planar, CW-wound polygon in 3D space.
 * Projects the polygon to the XY plane and applies convex-only ear clipping.
 *
 * @param pts3d List of 3D points
 * @return List of triangle layer_i [ [i1, i2, i3], ... ]
 */
function triangulate_planar_polygon(pts3d) =
  let (
    normal = echo("pts3d:", pts3d) cross(pts3d[1] - pts3d[0], pts3d[2] - pts3d[0]),
    zaxis = [0, 0, 1],
    rot = rotation_matrix(normal, zaxis),
    pts2d = echo("rot: ", rot) [for (pt = pts3d) rot * pt],
    idxs = echo("pts2d: ", pts2d) [for (i = [0 : len(pts2d) - 1]) i],
    dummy = echo("idxs: ", idxs)
  )
  triangulate_loop(pts2d, idxs, []);


/**
 * Recursively performs convex-only ear clipping. TODO: INCOMPLETE
 */
function triangulate_loop(pts, idxs, acc) =
  len(idxs) == 3
    ? concat(acc, [[idxs[0], idxs[1], idxs[2]]])
    : let (ear = find_ear(pts, idxs))
        echo("ear:", ear) ear != undef
          ? triangulate_loop(
              pts,
              concat(
                [for (i = [0 : ear[3] - 1]) idxs[i]],
                [for (i = [ear[3] + 1 : len(idxs) - 1]) idxs[i]]
              ),
              concat(acc, [[ear[0], ear[1], ear[2]]])
            )
          : assert(false, "No convex ear found - input may be degenerate");


/**
 * Finds and returns the first convex "ear" from a list of point layer_i in a polygon.
 *
 * Assumes:
 * - Points are in clockwise order when looking into the polygon.
 * - The polygon lies in the XY plane.
 *
 * Returns a list [iA, iB, iC, i], where A-B-C form a convex ear and `i` is the index
 * into the idxs list of the middle point `B`. Returns `undef` if no ear is found.
 */
function find_ear(pts, idxs) =
  let (
    n = len(idxs),
    candidates = [
      for (i = [0 : n - 1])
        let (
          iA = idxs[(i - 1 + n) % n],
          iB = idxs[i],
          iC = idxs[(i + 1) % n],
          A = pts[iA], B = pts[iB], C = pts[iC],
          AB = B - A,
          BC = C - B,
          cross_z = AB[0] * BC[1] - AB[1] * BC[0]
        )
        echo("cross_z:", cross_z) cross_z > 0 ? [iA, iB, iC, i] : undef
    ],
    ears = [for (ear = candidates) if (ear != undef) ear]
  )
  echo("ears find_ear:", ears) len(ears) > 0 ? ears[0] : undef;


/**
 * Returns a rotation matrix to align `from` to `to` (both 3D).
 * Uses Rodrigues' rotation formula.
 */
function rotation_matrix(from, to) =
  let (
    v = cross(from, to),
    c = from * to,
    s = norm(v),
    I = [[1,0,0],[0,1,0],[0,0,1]],
    vx = [
      [    0, -v[2],  v[1]],
      [ v[2],     0, -v[0]],
      [-v[1],  v[0],     0]
    ],
    dummy = echo("from:", from) echo("to:", to) echo("c:", c)
  )
  s == 0
    ? (c > 0 ? I : [[-1,0,0],[0,-1,0],[0,0,1]])
    : I + vx + ((1 - c)/(s * s)) * (vx * vx);

function flip_faces(faces) =
  [ for (face = faces)
      [ face[0], face[2], face[1] ]
  ];

function filter_out_same_consecutive_items(a) =
  a == [] ? [] :
  [ a[0], each for (i=[1:len(a)-1]) if (a[i] != a[i-1]) a[i] ];

// ECHO: [1, 2, 3, 1]

function cap_layers_orig(pts_in_layer, layers = 1) =
  assert(is_num(pts_in_layer), str("pts_in_layer (", pts_in_layer, ") isn't a number") )
  concat(
    [ // Bottom cap (layer 0)
      for (i = [1 : pts_in_layer - 2])
        [0, i, i + 1]
    ],
    [ // Top cap (layer = layers)
      for (i = [1 : pts_in_layer - 2])
        let (
          base = pts_in_layer * layers
        )
        [base, base + i + 1, base + i] // reverse order to preserve orientation
    ]
  );

/**
 * Generates triangulated faces to cap the first and last point layers.
 *
 * Assumes `pts3d` is a flat list of points arranged in contiguous layers,
 * each containing `pts_in_layer` points. There must be `layers + 1` total
 * point layers. The polygon formed by each cap must be planar and ordered
 * clockwise when looking into the object.
 *
 * Cap faces are generated by applying triangulate_planar_polygon()
 * to each cap independently. The first cap uses points from layer 0,
 * and the last cap uses points from the final layer.
 *
 * @param pts_in_layer (int):
 *   Number of points per layer.
 * @param pts3d (list of [x, y, z]):
 *   The full list of points arranged in stacked layers.
 * @param layers (int):
 *   Number of wall layers (so total layers = layers + 1).
 *
 * @returns list of triangle index triplets:
 *   Triangle faces forming the two end caps.
 */
function cap_layers(pts_in_layer, pts3d, layers = 1) =
  1 // Only accepting convex polygons for now.
  ? cap_layers_orig(pts_in_layer, layers)
  : // ChatGPT implementation of ear clipping for end face is faulty.
    concat(
      echo("pts3d cap:", pts3d)
      assert(pts3d != undef, "pts3d must be specified")
      triangulate_planar_polygon(
        [for (i = [0 : pts_in_layer - 1]) pts3d[i]]
      ),
      flip_faces(triangulate_planar_polygon(
        [for (i = [0 : pts_in_layer - 1])
          pts3d[pts_in_layer * layers + i]]
      ))
    );

// Create faces for a particular layer.
//
// TODO: FIX ALGORITHM to perform general end capping by clipping ears around
//       concave points.
function cap_end(obj, layer_i) =
  let (
    // TODO: Need to rotate or project layer so that it's on the xy plane.
    //       When on xy plane, convexity can be determined by checking if z of
    //       cross(p1, p2) is positive or negative.
    //       Projection is cheeper CPU wise, but have to deal with edge case
    //       where layer is perpendicular to xy plane, which will result in z of
    //       cross product equaling 0.
    pts = obj[SKIN_PTS()],
    pts_in_layer = obj[SKIN_PTS_IN_LAYER()],
    _cap_layer = function(layer_pts_is, faces_is)
      let (
        // TODO: Need to clip ears off of polygon, skipping colinear points.
        // TODO: Finally, finish face by making a fan face from a single staring
        //       point.
        remove_i = find(function(i)
          cross(pts[i-1]-pts[i], pts[i+1]-pts[i]))[2] > 0
      )INCOMPLETE
  )
  1
;

function filter_out_degenerate_triangles(pts3d, triangles) =
  in_array(triangles, function_filter(),
    function(tri, v)
      v ? tri :
      let (
        p0 = pts3d[tri[0]], p1 = pts3d[tri[1]], p2 = pts3d[tri[2]]
        , v1 = p0 - p1, v2 = p2 - p1
        // Not a degenerate triangle if all points are different and
        // two vectors are not colinear.  If any 2 or 3 points are same in
        // triangle, then cross product of vectors will act as if colinear.
        // cross(v1, v2) != [0,0,0]
        // !equal(cross(v1, v2), [0,0,0])
        // p0 != p1 && p1 != p2 && p2 != p0
        , result =
          assert(is_list(v1) && len(v1) == 3, type_value(v1))
          assert(is_list(v2) && len(v2) == 3, type_value(v2))
          !equal(cross(v1, v2), [0,0,0])
      )
      result
      // ? result
      // : echo("degenerate found: ", [p0, p1, p2]) result
  )
;

/**
 * Checks to see if object is a skin object
 */
function is_skin(obj) = is_list(obj) && obj[0] == SKIN_ID();

/**
 * Create a new skin object.
 *
 * @param pt_count_per_layer (integer):
 *   number of points per layer (must be ≥ 3) or
 * @param pts3d (list of [x, y, z]):
 *   The full list of points arranged in stacked layers.
 * @param layers (integer):
 *   Number of wall segments (requires `layers + 1` total point layers).
 * @param comment (string)
 *   Usually a string, this is just a comment for reading and debugging purposes.
 * @param operation (string)
 *   This is used by skin_to_polyhedron() when passing a list of SKIN objects.
 *   If a SKIN object has an operation attached, then that SKIN object will have
 *   the operation specified applied to the next element in the list which can
 *   be an object or list of objects.
 * @param wall_diagonal (list<bool>):
 *   This is used to allow changing the diagonal of neighbouring square polygons
 *   on a layer.
 *
 *   E.g.
 *     - [1] will have all diagonals go one way.
 *     - [1,0] will alternate.
 *     - [0,1] will alternate the opposite way to [1,0].
 *     - [0,0,1] will have it go one way for 2 consecutive squares, and then the
 *       other way, and then repeat.
 * @param debug_axes (list<list<points>>)
 *   This is a list of point groups.  The first element in the point group is
 *   the reference point.  Everything after that is a point relative to that
 *   reference point.  When debugging, call skin_
 *
 * @returns (skin object)
 */
function skin_new(pt_count_per_layer, layers, pts3d, comment, operation, wall_diagonal, debug_axes) =
  [ SKIN_ID(), pt_count_per_layer, layers, pts3d, debug_axes, comment, operation, wall_diagonal ]
;

/**
 * Generates an extruded point list from a number range, range or list of
 * indices.
 *
 * @param pts_fn (function(i) list_of_points)
 *   Function that returns a list of points for layer i.  It's fine to have
 *   duplicate points in list as they will be filtered when calling
 *   skin_to_polyhedron.
 * @param birl (number | range | list)
 *   - If number, start index to check
 *   - If range, indices to check
 *   - If list, indices to check
 * @param end_i (number)
 *   - If birl is a number, then end index to check.  end_i
 *     could be less than birl if there's nothing to iterate
 *     over.
 * @param comment (string)
 *   Usually a string, this is just a comment for reading and debugging purposes.
 * @param operation (string)
 *   This is used by skin_to_polyhedron() when passing a list of SKIN objects.
 *   If a SKIN object has an operation attached, then that SKIN object will have
 *   the operation specified applied to the next element in the list which can
 *   be an object or list of objects.
 * @param wall_diagonal (list<bool>):
 *   This is used to allow changing the diagonal of neighbouring square polygons
 *   on a layer.
 *
 *   E.g.
 *     - [1] will have all diagonals go one way.
 *     - [1,0] will alternate.
 *     - [0,1] will alternate the opposite way to [1,0].
 *     - [0,0,1] will have it go one way for 2 consecutive squares, and then the
 *       other way, and then repeat.
 *
 *
 * @returns (skin object)
 */
function skin_extrude(pts_fn, birl, end_i, comment, operation, wall_diagonal, debug_axes) =
  let (
    layer_is = birlei_to_indices(birl, end_i),
    layer_count = is_list(layer_is) ? len(layer_is) : range_len(layer_is),
    // NOTE: this will result in pts_fn being called on index 0 twice.  Once
    //       here, and once in the skin_new() call.
    pt_0 = pts_fn(is_list(layer_is) ? layer_is[0] : range_value(layer_is, 0)),
    pts_in_layer = len(pt_0)
  )
  assert(layer_count > 1, "Need 2 or more layers to make a volume.")
  // - `pts_fn returns` a list of points.
  // - `map` makes that into a list of list of points.
  // - Inside of list initialisation, `each` is used to remove the outer list,
  //   making it a list of points in a list.  Another `each` is used to make
  //   it just a bunch of points in a list.
  skin_new(pts_in_layer, layer_count - 1,
    [ each each map(pts_fn, layer_is) ], comment, operation, wall_diagonal, debug_axes
  )
;

/**
 * Generates face layer_i to skin a layered structure, including:
 *   - bottom cap (layer 0)
 *   - top cap (layer = layers)
 *   - side wall faces between adjacent layers
 *
 * Assumes that points are stored in a flat array, with `pts_in_layer`
 * points per layer, and layers stored consecutively. Points within each
 * layer must be ordered clockwise when looking into the object.
 *
 * @param obj (skin object):
 *   The skin object generating the faces from.
 *
 * @returns (list of [int, int, int]):
 *   A list of triangle face definitions.
 */
function skin_create_faces(obj) =
  assert(is_skin(obj))
  let (
    wall_diagonal = default(obj[SKIN_WALL_DIAG()], [0, 1]),
    pts_in_layer = obj[SKIN_PTS_IN_LAYER()],
    layers = obj[SKIN_LAYERS()],
    pts3d = obj[SKIN_PTS()]
  )
  concat(
    cap_layers(pts_in_layer,
      //echo("pts3d skin: ", pts3d)
      pts3d, layers)
    ,
    filter_out_degenerate_triangles(
      pts3d,
      layer_side_faces(pts_in_layer, layers, wall_diagonal))
  )
;

/**
 * Performs a transformation on the points stored in the skin object.
 *
 * @param obj (skin object):
 *   The skin object where the points are coming from to transform.
 * @param matrix_or_fn (list<list<number>> | function(pt) : pt):
 *   The matrix or function to do the transformation with.  If the
 *   transformation is homogenous, then will convert the points to a homogeneous
 *   basis, perform the transformation and then remove the basis.
 *
 * @returns (skin object):
 *   A new skin object with the points transformed.
 */
function skin_transform(obj_or_objs, matrix_or_fn) =
  is_skin(obj_or_objs)
  ? let (
      pts = obj_or_objs[SKIN_PTS()],
      dbg_pts = obj_or_objs[SKIN_DEBUG_AXES()],
      _ = assert(is_list(pts), str("pts (", pts, ") is not a list\n", obj_or_objs))
    )
    replace(obj_or_objs, SKIN_PTS(), SKIN_DEBUG_AXES(), [
      transform(pts, matrix_or_fn),
      dbg_pts == undef ? undef : transform(dbg_pts, matrix_or_fn)
    ])
  : [ for (obj = obj_or_objs) skin_transform(obj, matrix_or_fn) ]
;

/**
 * Takes the skin object and make it into a polyhedron.  If obj is a list, will
 * assume all are skin objects and attempt to skin them all.
 *
 * @param obj_or_objs (skin object | list<skin object>):
 *   The skin object or list of skin objects to make into a polyhedron.
 *
 * @returns (skin object):
 *   A new skin object with the points transformed.
 */
module skin_to_polyhedron(obj_or_objs) {
  // base case
  if (is_skin(obj_or_objs)) {
    obj = obj_or_objs;
    pts = obj[SKIN_PTS()];
    faces = skin_create_faces(obj);
    polyhedron(pts, faces);
  } else {
    assert(is_list(obj_or_objs),
      str(
        "If obj_or_objs is not a SKIN object, then it must be a list of SKIN objects.",
        "\n", obj_or_objs));
    objs = obj_or_objs;

    // Collect all indices that don't have an operation or is the 0th index.
    // Prevents the need to recurse just to iterate over list of SKIN objects.
    is = filter(function(i)
        // filter out any index that does have an operation in the previous index.
        i == 0 || !is_skin(objs[i-1]) || objs[i-1][SKIN_OPERATION()] == undef,
      0, len(objs)-1);
    for (i = is) {
      obj = objs[i];
      if (is_skin(obj)) {
        op = obj[SKIN_OPERATION()];
        pts = obj[SKIN_PTS()];
        faces = skin_create_faces(obj);
        if (op == undef) {
            polyhedron(pts, faces);
        } else if (op == "difference") {
          difference() {
            polyhedron(pts, faces);
            skin_to_polyhedron(objs[i+1]);
          }
        } else if (op == "union") {
          union() {
            polyhedron(pts, faces);
            skin_to_polyhedron(objs[i+1]);
          }
        } else if (op == "intersection") {
          intersection() {
            polyhedron(pts, faces);
            skin_to_polyhedron(objs[i+1]);
          }
        } else {
          assert(false, str("Unrecognised operator \"", op, "\"."));
        }
      } else {
        skin_to_polyhedron(obj);
      }
    }
  }
}

/**
 * Adds a number of interpolated layers between layers based how many
 * add_layers_fn(i) returns.
 *
 * @param obj (SKIN object)
 *   Object to add to.
 * @param add_layers_fn (function(i) : number_of_layers_to_add)
 *   This function will return the first index of a layer, expecting that the
 *   point it refers to or its brethren on that layer to be compared to the
 *   points on the very next layer.
 *
 *   It is guaranteed that there is a next layer of points to compare with.
 *
 *   @param i (number)
 *     The first index of the layer to be analyzed.
 *
 *   @returns (number)
 *     The number of additional layers to add between the current layer and the
 *     next.  Negative numbers are treated as 0.
 *
 *     E.g.
 *     - 0 or less means add no additional layers.
 *     - 1 means add another layer that is half way in between the current and
 *       next layer.
 *     - 2 means add 2 layers, 1/3 and 2/3 between.
 *     - etc...
 *
 * @returns (SKIN object)
 *   Updated SKIN object.
 */
function skin_add_layer_if(obj, add_layers_fn) =
  let (
    pts = obj[SKIN_PTS()],
    pts_in_layer = obj[SKIN_PTS_IN_LAYER()],

    new_pts =
      fn_reduce(
        tail_multi(pts, pts_in_layer),
        range(pts_in_layer, pts_in_layer, len(pts) - pts_in_layer))
      (
        function(i, acc)
          let (
            prev_i = i - pts_in_layer,
            num_of_layers_to_add = add_layers_fn(prev_i),
            layer_pts = extract(pts, prev_i, i - 1)
          )
          num_of_layers_to_add > 0
          ? [
              each acc,
              each layer_pts,
              // concat doesn't have the ability to take a list of a list of
              // points and make it into a list of points, without creating a
              // function to do so.  This is just easier (and possibly faster).
              each each interpolated_values(
                layer_pts, extract(pts, i, i+pts_in_layer), num_of_layers_to_add)
            ]
          : concat(
              acc,
              layer_pts
            )
      )
    , _ = len(new_pts) != len(pts)
        ? echo(str("Added ", (len(new_pts) - len(pts))/pts_in_layer, " layers",
          obj[SKIN_COMMENT()] == undef ? "" : str(" to ", obj[SKIN_COMMENT()])))
        : undef,

    result = replace(obj, SKIN_LAYERS(), SKIN_PTS(), [ len(new_pts)/pts_in_layer-1, new_pts ]),
    added_layer_count = result[SKIN_LAYERS()] - obj[SKIN_LAYERS()]
  )
  assert(added_layer_count >= 0, str("Lost ", -added_layer_count, " layers."))
  echo("layers", added_layer_count)
  echo(skin_verify(result, true))
  result
;

function skin_add_point_in_layer(obj, add_pts_after_pt_numbers) =
  let (
    pts = obj[SKIN_PTS()],
    pts_in_layer = obj[SKIN_PTS_IN_LAYER()],
    pt_ranges = [ [0], each add_pt_between_pt_numbers ]
  )
  // iterate over each layer
  fn_reduce([], range(0, pts_in_layer, len(pts)-pts_in_layer))(
      function(i0, acc)
        // iterate each point in layer
        fn_reduce(acc, range(1, len(pt_ranges)-1))(
          function(pt_i, acc2)
            let (
              p0_i = i + pt_ranges[pt_i-1][0],
              p1_i = i + pt_ranges[pt_i  ][0], p1 = pts[p1_i],
              p2_i = i + pt_ranges[pt_i  ][0], p2 = pts[p2_i],
              pt_count_to_insert = pt_ranges[pt_i][1]
            )
            concat(
              acc2,
              extract(pts, p0_i, p1_i),
              interpolated_values(p1, p2, pt_count_to_insert)
            )
        )
    )
;

function interpolated_values(p0, p1, number_of_values) =
  let (
    diff = p1 - p0
  )
  fn_map(1, number_of_values)(
    function(i)
      i/(number_of_values+1)*diff + p0
  )
;


/**
 * UNTESTED!
 * Shows the debug axes to verify where you think things should be.
 *
 * @param obj (SKIN object)
 *   Object to show debug axes for.
 * @param styles (list<list<color, alpha, thickness>>)
 *   Contains a list of styles that are reused when the number of points in a
 *   debug group exceeds the the number of styles.
 *
 *   If a style doesn't contain a colour, alpha or thickness (set as undef),
 *   will go backwards to find one that does and uses that.
 */
module skin_show_debug_axes(obj, styles = [["red", 1, .1], ["green"], ["blue"]])
{
  assert(is_skin(obj));
  dbg_pt_grps = obj[SKIN_DEBUG_AXES()];
  assert(dbg_pt_grps != undef, "No debug axes to show.");
  for (pt_grp = debug_pt_grps) {
    ref_pt = pt_grp[0];
    for (pt_i = it_fwd_i(pt_grp, 1)) {
      v = pt_grp[i] - ref_pt;
      angle = arc_len([0, 0, 1], v, 180/PI);
      normal = cross([0, 0, 1], v);
      length = norm(v);
      T = translate(axis_obj[0]) * homogenise_transform(rotate(angle, normal));

      init = styles == undef ? undef : styles[ pt_i % len(styles) ];
      if (init == undef) {

        pred = function(a)
          any_find(function(i) a[i] == undef, 0, 2);

        data = pred(init)
          ? in_array(styles, fn_reduce_air(init),
              function(e, acc)
                [ pred(acc), [ for (i = [0:2]) default(acc[i], e) ] ],
              range(pt_i % len(styles), -1, 0))[1]
          : init;

        colour    = data[0];
        alpha     = data[1];
        thickness = default(data[2], length * 0.1);

        if (color == undef) {
          multmatrix(T)
          axis(length, thickness);
        } else {
          color(colour, alpha)
            multmatrix(T)
            axis(length, thickness);
        }
      } else {
        thickness = length * 0.1;
        multmatrix(T)
          axis(length, thickness);
      }
    }
  }
}

function interpolate(v0, v1, v) =
  (v - v0[0]) / (v1[0] - v0[0]) * (v1[1] - v0[1]) + v0[1]
;

/**
 * INCOMPLETE!
 * Truncates the beginning, end or both of the extrusion.
 *
 * @param obj (skin object)
 *   Object to remove values before in points.  Value extracted from points MUST
 *   BE monotonically nondecreasing over the points list.
 * @param extract_order_value_fn (function(pt) : extracted_value)
 *   This take in a point and returns some value.  This is to allow selection of
 *   a particular axis or length for a given point to compare against value.
 * @param begin (number)
 *   The value to compare against the extracted value from a point.
 *   (Default: extract_order_value_fn(el(obj[SKIN_PTS()],  0)) )
 * @param end (number)
 *   The value to compare against the extracted value from a point.
 *   (Default: extract_order_value_fn(el(obj[SKIN_PTS()], -1)) )
 *
 * @returns (skin object)
 *   Updated skin object with all of the points before value removed.  If
 *   extracted value is not EXACTLY value, then will linearly interpolated to
 *   cup off EXACTLY at value.
 */
 /*
  * [1, 3, 5], begin = undef, end = 5 => begin_i = 0, end_i = 2 => no interpolation required
  * [1, 3, 5], begin = undef, end = 4 => begin_i = 0, end_i = 1 => end interpolation required
  */
function skin_limit(obj, extract_order_value_fn, begin, end) =
  // assert(begin <= end)
  let (
    pts = INCOMPLETE(obj[SKIN_PTS()]),
    last_i = el_idx(pts, -1),
    begin_i = is_undef(begin)
      ? 0
      : default(
          in_array(pts, function_find_lower(),
            function(pt) extract_order_value_fn(pt) - begin),
          0),
    end_i = is_undef(end)
      ? last_i
      : default(
          in_array(pts, function_find_upper(),
            function(pt) extract_order_value_fn(pt) - end),
          last_i),
    result =
      (begin_i == 0)
      ? (end_i == last_i)
        ? // nothing needs to be cut
          obj
        : // only ending needs to be cut
          let ( ept0 = pts[end_i-1], eev0 = extract_order_value_fn(ept0) )
          eev0 == end
          ? // interpolation not needed
            [
              for (i = [0 : end_i-1]) pts[i]
            ]
          : // interpolating
            let ( ept1 = pts[end_i  ], eev1 = extract_order_value_fn(ept1) )
            [
              for (i = [0 : end_i]) pts[i]
              ,
              interpolate([eev0, ept0], [eev1, ept1], end)
            ]
      : (is_undef(end_i) || end_i == 0)
        ? // only beginning need to be cut
          let ( bpt0 = pts[begin_i-1], bev0 = extract_order_value_fn(bpt0) )
          bev0 == begin
          ? // interpolation not needed
            [
              for (i = [begin_i : end_i]) pts[i]
            ]
          :
            let ( bpt1 = pts[begin_i  ], bev1 = extract_order_value_fn(bpt1) )
            [
              interpolate([bev0, bpt0], [bev1, bpt1], end)
              ,
              for (i = [0 : begin_i]) pts[i]
            ]
        : // both beginning and ending need to be cut
          let ( ept0 = pts[end_i-1], eev0 = extract_order_value_fn(ept0) )
          let ( bpt0 = pts[begin_i-1], bev0 = extract_order_value_fn(bpt0) )
          eev0 == end
            ? // no interpolation required
              bev0 == begin
              ?
              [
                for (i = [0 : end_i-1]) pts[i]
              ]
              : INCOMPLETE()
            : INCOMPLETE()
          ? INCOMPLETE()
          :
            let ( ept1 = pts[end_i  ], eev1 = extract_order_value_fn(ept1) )
            [
              for (i = [0 : end_i]) pts[i]
              ,
              interpolate([eev0, ept0], [eev1, ept1], end)
            ]
  )
  result
;

/**
 * For debugging, returns a string reporting the stats of a skin object.
 *
 * Asserts if the object's number of points doesn't correspond to the equation:
 *
 *   `(layers - 1) * pts_in_layer`
 *
 * @param obj (SKIN object)
 *   Object to verify.
 * @param disp_all_pts (bool)
 *   - If false, only returns the first and last points in the list.
 *   - If true, returns all points, with each layer of points on a separate line.
 *
 * @returns (string)
 *   A prettified/simplified view of points in the object.
 */
function skin_verify(obj, disp_all_pts = false) =
  let (
    pts_in_layer = obj[SKIN_PTS_IN_LAYER()],
    layers = obj[SKIN_LAYERS()],
    pts3d = obj[SKIN_PTS()],
    result = len(pts3d) == pts_in_layer * (layers + 1),
    output = str("pts_in_layer: ", pts_in_layer, ", layers: ", layers, " gives: ", pts_in_layer * (layers+1), " pts."),
    str_obj = skin_to_string(obj, !disp_all_pts)
  )
  assert(result, str(output, "  Actual pts: ", len(pts3d), "  obj: ", str_obj))
  str_obj
;

/**
 * Returns a function that can be used with skin_add_layer_if() to ensure that
 * the distance between layers don't exceed some length.
 *
 * @param obj (SKIN object)
 * @param max_diff (number)
 *   Maximum distance before adding another layer to reduce the distance below
 *   max_diff.
 * @param diff_fn (function(p0, p1) : distance_between_layers)
 *   This gives the distance between layers.  (Default: checks x distances)
 *
 *   @param p0 (point)
 *     The first point of the current layer.
 *   @param p1 (point)
 *     The first point of the next layer.
 *
 *   @returns (number)
 *     A value that states the distance between layers.
 *
 * @returns (function(i) : number_of_layers_to_add)
 *   Function that can be used with skin_add_layer_if().
 */
function skin_max_layer_distance_fn(obj, max_diff, diff_fn = function(p0, p1) p1.x - p0.x) =
  let (
    pts = obj[SKIN_PTS()],
    pts_in_layer = obj[SKIN_PTS_IN_LAYER()]
  )
  function(i)
    let (
      diff = diff_fn(pts[i], pts[i + pts_in_layer])
    )
    floor(diff / max_diff) - 1
;

function skin_max_pt_distance_fn(obj, max_diff) =
  let (
    pts = obj[SKIN_PTS()],
    pts_in_layer = obj[SKIN_PTS_IN_LAYER()]
  )
  function(i)
    let (
      diff = max(in_array(
          extract(pts, i+pts_in_layer, i+pts_in_layer*2-1)
        - extract(pts, i             , i+pts_in_layer  -1),
        function_map(), function(pt) norm(pt)))
    )
    floor(diff / max_diff) - 1
;

// Simple extrusion along the x axis.
//
// Note: Extrusions can go in any direction by making the extrusion axis
//       dependent on i.
module skin_example1() {
  rectangular_prism_fn = function(i)
  [
    [ i, 0, 0 ],
    [ i, 1, 0 ],
    [ i, 1, 1 ],
    [ i, 0, 1 ]
  ];

  test_skin = 
    skin_extrude(rectangular_prism_fn, 0, 3)
  ;
  echo("test_skin: ", test_skin);
  skin_to_polyhedron(test_skin);
}

// Making two separate extrusions.
module skin_example2() {
  rectangular_prism_fn = function(i)
  [
    [ i, 0, 0 ],
    [ i, 1, 0 ],
    [ i, 1, 1 ],
    [ i, 0, 1 ]
  ];
  triangular_prism_fn = function(i)
  [
    [ i, 0, 0 ],
    [ i, 1, 0 ],
    [ i, 0, 1 ]
  ];

  test_skin = [
    skin_extrude(rectangular_prism_fn, 0, 3),
    skin_extrude(triangular_prism_fn, -3, 0)
  ];
  echo("test_skin: ", test_skin);
  skin_to_polyhedron(test_skin);
}

// Joining 2 extrusions of different layer point size by duplicating a point to
// keep the layer point size the same.  Faces which are degenerate triangles are
// filtered, so this is ok.
module skin_example3() {
  rectangular_prism_fn = function(i)
  [
    [ i, 0, 0 ],
    [ i, 1, 0 ],
    [ i, 1, 1 ],
    [ i, 0, 1 ]
  ];
  triangular_prism_fn = function(i)
  [
    [ i, 0, 0 ],
    [ i, 1, 0 ],
    [ i, 1, 0 ],
    [ i, 0, 1 ]
  ];
  hybrid_fn = function(i)
    i < 0 ? triangular_prism_fn(i) : rectangular_prism_fn(i)
  ;
  test_skin = 
    skin_extrude(hybrid_fn, -3, 3)
  ;
  echo("test_skin: ", test_skin);
  skin_to_polyhedron(
    let (
      pts = test_skin[SKIN_PTS()],
      pts_in_layer = test_skin[SKIN_PTS_IN_LAYER()]
    )
    skin_add_layer_if(test_skin, skin_max_layer_distance_fn(test_skin, 0.333)
      // function(i)
      //   let (
      //     diff = pts[i + pts_in_layer].x - pts[i].x,
      //     max_diff = 0.5
      //   )
      //   floor(diff / max_diff) - 1
    )
  );
}

skin_example3();