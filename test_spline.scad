use <test>
use <spline>
use <helpers>
include <spline_consts>

_fl = function(l) fl("test_spline.scad", l);

// --- Test data ---

// Catmull-Rom: 5 points, 4 segments.
_cr_pts = [
  [0, 0, 0],
  [10, 5, 0],
  [20, 0, 5],
  [30, 10, 5],
  [40, 0, 0]
];

// Bezier: 7 points (3 anchors + 4 handles), 2 segments.
_bz_pts = [
  [0, 0, 0],       // P0 anchor
  [5, 10, 0],      // H0out
  [15, 10, 0],     // H1in
  [20, 0, 0],      // P1 anchor
  [25, -10, 0],    // H1out
  [35, -10, 0],    // H2in
  [40, 0, 0]       // P2 anchor
];

// --- Type checks ---

module test_spline_is_spline() {
  s = spline_new(_cr_pts);
  test_truthy(is_spline(s), _fl(33));
  test_falsy(is_spline([1, 2, 3]), _fl(34));
  test_falsy(is_spline("SPLINE"), _fl(35));
}

module test_spline_is_spoly() {
  s = spline_new(_cr_pts);
  sp = spline_to_spoly(s, 0.1);
  test_truthy(is_spoly(sp), _fl(40));
  test_falsy(is_spoly(s), _fl(41));
  test_falsy(is_spoly([1, 2, 3]), _fl(42));
}

// --- Segment count ---

module test_spline_segment_count_catmull_rom() {
  s_open = spline_new(_cr_pts);
  test_eq(4, spline_segment_count(s_open), _fl(48));

  s_closed = spline_new(_cr_pts, closed = true);
  test_eq(5, spline_segment_count(s_closed), _fl(51));
}

module test_spline_segment_count_bezier() {
  s_open = spline_new(_bz_pts, type = SPLINE_T_BEZIER);
  test_eq(2, spline_segment_count(s_open), _fl(55));

  // Closed Bezier: 9 points -> 3 segments.
  closed_pts = [
    [0, 0, 0], [5, 10, 0], [15, 10, 0],
    [20, 0, 0], [25, -10, 0], [35, -10, 0],
    [40, 0, 0], [35, 10, 0], [5, 10, 0]
  ];
  s_closed = spline_new(closed_pts, closed = true, type = SPLINE_T_BEZIER);
  test_eq(3, spline_segment_count(s_closed), _fl(63));
}

// --- Catmull-Rom point evaluation ---

module test_spline_catmull_rom_point_at() {
  s = spline_new(_cr_pts);

  // t=0 of segment i should return pts[i].
  p0 = spline_point_at(s, 0, 0);
  test_approx_eq(_cr_pts[0], p0, 1e-6, _fl(72));

  p1 = spline_point_at(s, 1, 0);
  test_approx_eq(_cr_pts[1], p1, 1e-6, _fl(75));

  // t=1 of segment i should return pts[i+1].
  p0_end = spline_point_at(s, 0, 1);
  test_approx_eq(_cr_pts[1], p0_end, 1e-6, _fl(79));

  p3_end = spline_point_at(s, 3, 1);
  test_approx_eq(_cr_pts[4], p3_end, 1e-6, _fl(82));

  // Midpoint should differ from both endpoints.
  p_mid = spline_point_at(s, 1, 0.5);
  test_truthy(norm(p_mid - _cr_pts[1]) > 0.01, _fl(86));
  test_truthy(norm(p_mid - _cr_pts[2]) > 0.01, _fl(87));
}

// --- Catmull-Rom tangent evaluation ---

module test_spline_catmull_rom_tangent_at() {
  s = spline_new(_cr_pts);

  // Tangent should be non-zero.
  t0 = spline_tangent_at(s, 0, 0);
  test_gt(norm(t0), 0, _fl(95));

  t1 = spline_tangent_at(s, 1, 0.5);
  test_gt(norm(t1), 0, _fl(98));
}

// --- Bezier point evaluation ---

module test_spline_bezier_point_at() {
  s = spline_new(_bz_pts, type = SPLINE_T_BEZIER);

  // t=0 of segment 0 -> first anchor P0.
  p0 = spline_point_at(s, 0, 0);
  test_approx_eq(_bz_pts[0], p0, 1e-6, _fl(107));

  // t=1 of segment 0 -> second anchor P1.
  p1 = spline_point_at(s, 0, 1);
  test_approx_eq(_bz_pts[3], p1, 1e-6, _fl(111));

  // t=0 of segment 1 -> P1.
  p1_start = spline_point_at(s, 1, 0);
  test_approx_eq(_bz_pts[3], p1_start, 1e-6, _fl(115));

  // t=1 of segment 1 -> P2.
  p2 = spline_point_at(s, 1, 1);
  test_approx_eq(_bz_pts[6], p2, 1e-6, _fl(119));

  // Bezier midpoint: B(0.5) = 0.125*P0 + 0.375*P1 + 0.375*P2 + 0.125*P3
  // For segment 0: P0=[0,0,0], P1=[5,10,0], P2=[15,10,0], P3=[20,0,0]
  expected_mid = 0.125*_bz_pts[0] + 0.375*_bz_pts[1] + 0.375*_bz_pts[2] + 0.125*_bz_pts[3];
  p_mid = spline_point_at(s, 0, 0.5);
  test_approx_eq(expected_mid, p_mid, 1e-6, _fl(125));
}

// --- Bezier tangent evaluation ---

module test_spline_bezier_tangent_at() {
  s = spline_new(_bz_pts, type = SPLINE_T_BEZIER);

  // B'(0) = 3*(P1 - P0) for segment 0.
  t0 = spline_tangent_at(s, 0, 0);
  expected_t0 = 3 * (_bz_pts[1] - _bz_pts[0]);
  test_approx_eq(expected_t0, t0, 1e-6, _fl(134));

  // B'(1) = 3*(P3 - P2) for segment 0.
  t1 = spline_tangent_at(s, 0, 1);
  expected_t1 = 3 * (_bz_pts[3] - _bz_pts[2]);
  test_approx_eq(expected_t1, t1, 1e-6, _fl(139));

  // Tangent at midpoint should be non-zero.
  t_mid = spline_tangent_at(s, 0, 0.5);
  test_gt(norm(t_mid), 0, _fl(143));
}

// --- Spline to SPOLY ---

module test_spline_to_spoly_catmull_rom() {
  s = spline_new(_cr_pts);
  sp = spline_to_spoly(s, 0.1);

  pts = sp[SPOLY_PTS];
  ctrl_is = sp[SPOLY_CTRL_IS];

  // More points than segments (subdivision happened).
  test_gt(len(pts), 5, _fl(157));

  // CTRL_IS has segment_count + 1 entries.
  test_eq(5, len(ctrl_is), _fl(160));

  // First and last CTRL_IS.
  test_eq(0, ctrl_is[0], _fl(163));
  test_eq(len(pts) - 1, ctrl_is[len(ctrl_is) - 1], _fl(164));

  // Points at CTRL_IS match original control points.
  for (i = [0 : len(_cr_pts) - 1])
    test_approx_eq(_cr_pts[i], pts[ctrl_is[i]], 1e-6, _fl(168));

  // Closed flag matches.
  test_falsy(sp[SPOLY_CLOSED], _fl(180));

  // Tangents via public API are unit length.
  t0 = spoly_tangent_at(sp, 0, 0);
  test_approx_eq(1, norm(t0), 1e-4, _fl(184));
  t_mid = spoly_tangent_at(sp, 2, 0.5);
  test_approx_eq(1, norm(t_mid), 1e-4, _fl(186));
}

module test_spline_to_spoly_bezier() {
  s = spline_new(_bz_pts, type = SPLINE_T_BEZIER);
  sp = spline_to_spoly(s, 0.1);

  pts = sp[SPOLY_PTS];
  ctrl_is = sp[SPOLY_CTRL_IS];

  // CTRL_IS has segment_count + 1 = 3 entries (anchors only).
  test_eq(3, len(ctrl_is), _fl(192));

  // First point is P0.
  test_approx_eq(_bz_pts[0], pts[ctrl_is[0]], 1e-6, _fl(195));

  // Second anchor is P1 (index 3 in original).
  test_approx_eq(_bz_pts[3], pts[ctrl_is[1]], 1e-6, _fl(198));

  // Last anchor is P2 (index 6 in original).
  test_approx_eq(_bz_pts[6], pts[ctrl_is[2]], 1e-6, _fl(201));

  // Tangents via public API are unit length.
  t0 = spoly_tangent_at(sp, 0, 0.5);
  test_approx_eq(1, norm(t0), 1e-4, _fl(210));
}

// --- SPOLY queries ---

module test_spoly_point_at() {
  s = spline_new(_cr_pts);
  sp = spline_to_spoly(s, 0.1);

  pts = sp[SPOLY_PTS];
  ctrl_is = sp[SPOLY_CTRL_IS];

  // pct=0 at ctrl_idx i -> point at ctrl_is[i].
  p0 = spoly_point_at(sp, 0, 0);
  test_approx_eq(pts[ctrl_is[0]], p0, 1e-6, _fl(224));

  p1 = spoly_point_at(sp, 1, 0);
  test_approx_eq(pts[ctrl_is[1]], p1, 1e-6, _fl(227));

  // pct=1 at ctrl_idx i -> point at ctrl_is[i+1].
  p0_end = spoly_point_at(sp, 0, 1);
  test_approx_eq(pts[ctrl_is[1]], p0_end, 1e-6, _fl(231));
}

module test_spoly_tangent_at() {
  s = spline_new(_cr_pts);
  sp = spline_to_spoly(s, 0.1);

  // Tangent should be unit length.
  t0 = spoly_tangent_at(sp, 0, 0);
  test_approx_eq(1, norm(t0), 1e-4, _fl(239));

  t1 = spoly_tangent_at(sp, 1, 0.5);
  test_approx_eq(1, norm(t1), 1e-4, _fl(242));
}

// --- SPOLY split ---

module test_spoly_split() {
  s = spline_new(_cr_pts);
  sp = spline_to_spoly(s, 0.1);

  halves = spoly_split(sp, 2, 0.5);
  sp_a = halves[0];
  sp_b = halves[1];

  // Both halves are valid SPOLYs.
  test_truthy(is_spoly(sp_a), _fl(257));
  test_truthy(is_spoly(sp_b), _fl(258));

  // First half starts at original start.
  test_approx_eq(sp[SPOLY_PTS][0], sp_a[SPOLY_PTS][0], 1e-6, _fl(268));

  // Second half ends at original end.
  pts_b = sp_b[SPOLY_PTS];
  pts_orig = sp[SPOLY_PTS];
  test_approx_eq(pts_orig[len(pts_orig) - 1], pts_b[len(pts_b) - 1], 1e-6, _fl(273));

  // Split point matches between halves.
  pts_a = sp_a[SPOLY_PTS];
  test_approx_eq(pts_a[len(pts_a) - 1], pts_b[0], 1e-6, _fl(277));

  // CTRL_IS counts: first half has ctrl_idx+1 original + 1 split = ctrl_idx+2.
  test_eq(4, len(sp_a[SPOLY_CTRL_IS]), _fl(280));
}

// --- String conversion ---

module test_spline_to_string() {
  s_cr = spline_new(_cr_pts);
  str_cr = spline_to_string(s_cr);
  test_truthy(len(str_cr) > 0, _fl(287));

  s_bz = spline_new(_bz_pts, type = SPLINE_T_BEZIER);
  str_bz = spline_to_string(s_bz);
  test_truthy(len(str_bz) > 0, _fl(291));
}

module test_spoly_to_string() {
  s = spline_new(_cr_pts);
  sp = spline_to_spoly(s, 0.1);
  str_sp = spoly_to_string(sp);
  test_truthy(len(str_sp) > 0, _fl(298));
}

// --- Run all ---

module test_spline_all() {
  test_spline_is_spline();
  test_spline_is_spoly();
  test_spline_segment_count_catmull_rom();
  test_spline_segment_count_bezier();
  test_spline_catmull_rom_point_at();
  test_spline_catmull_rom_tangent_at();
  test_spline_bezier_point_at();
  test_spline_bezier_tangent_at();
  test_spline_to_spoly_catmull_rom();
  test_spline_to_spoly_bezier();
  test_spoly_point_at();
  test_spoly_tangent_at();
  test_spoly_split();
  test_spline_to_string();
  test_spoly_to_string();
}

test_spline_all();
