use <test>
use <transform>
use <helpers>

_fl = function(l) fl("test_transform.scad", l);

module test_transform_transpose() {
  // Basic 2x3 matrix
  m1 = [[1, 2, 3], [4, 5, 6]];
  t1 = [[1, 4], [2, 5], [3, 6]];
  test_eq(t1, transpose(m1), _fl(11));

  // Square matrix
  m2 = [[1, 2], [3, 4]];
  t2 = [[1, 3], [2, 4]];
  test_eq(t2, transpose(m2), _fl(16));

  // Single row
  m3 = [[1, 2, 3]];
  t3 = [[1], [2], [3]];
  test_eq(t3, transpose(m3), _fl(21));

  // Empty matrix
  m4 = [];
  test_eq([], transpose(m4), _fl(25));

  // Identity matrix transpose
  identity_3x3 = [[1, 0, 0], [0, 1, 0], [0, 0, 1]];
  test_eq(identity_3x3, transpose(identity_3x3), _fl(29));
}

module test_transform_homogenise() {
  // homogenise expects a LIST of points, not a single point
  // 2D points to homogeneous (n=3 for 2D homogeneous)
  pts_2d = [[1, 2]];
  test_eq([[1, 2, 1]], homogenise(pts_2d, 3), _fl(35));

  // 3D points to homogeneous (n=4 for 3D homogeneous)
  pts_3d = [[1, 2, 3]];
  test_eq([[1, 2, 3, 1]], homogenise(pts_3d, 4), _fl(39));

  // List of multiple 3D points
  pts_multi = [[1, 2, 3], [4, 5, 6]];
  expected_multi = [[1, 2, 3, 1], [4, 5, 6, 1]];
  test_eq(expected_multi, homogenise(pts_multi, 4), _fl(44));

  // Single dimension points
  pts_1d = [[5]];
  test_eq([[5, 1]], homogenise(pts_1d, 2), _fl(48));
}

module test_transform_dehomogenise() {
  // dehomogenise expects a LIST of points and n is the OUTPUT dimension count
  // n must be < len(input_point) since input has n+1 dimensions
  // Homogeneous to 2D (n=2: output 2D from 3D input)
  pts_h_2d = [[2, 4, 2]];
  test_eq([[1, 2]], dehomogenise(pts_h_2d, 2), _fl(54));

  // Homogeneous to 3D (n=3: output 3D from 4D input)
  pts_h_3d = [[2, 4, 6, 2]];
  test_eq([[1, 2, 3]], dehomogenise(pts_h_3d, 3), _fl(58));

  // List of multiple homogeneous points
  pts_h_multi = [[1, 2, 3, 1], [2, 4, 6, 1]];
  expected_multi = [[1, 2, 3], [2, 4, 6]];
  test_eq(expected_multi, dehomogenise(pts_h_multi, 3), _fl(63));

  // Scale factor != 1
  pts_scaled = [[2, 4, 2]];
  test_eq([[1, 2]], dehomogenise(pts_scaled, 2), _fl(67));
}

module test_transform_homogenise_transform() {
  // Homogenise a transformation matrix (input must be square, smaller than n)
  // 3x3 matrix homogenised to 4x4
  trans_mat = homogenise_transform([[1, 0, 0], [0, 1, 0], [0, 0, 1]], 4);
  // Result should be a 4x4 homogeneous transformation matrix
  test_eq(4, len(trans_mat), _fl(74));
  test_eq(4, len(trans_mat[0]), _fl(75));
}

module test_transform_rot_x() {
  // Rotation about X by 0 degrees
  rot_0 = rot_x(0);
  test_eq([[1, 0, 0], [0, 1, 0], [0, 0, 1]], rot_0, _fl(81));

  // Rotation about X by 90 degrees
  rot_90 = rot_x(90);
  test_approx_eq([1, 0, 0], rot_90[0], 1e-6, _fl(85));
  test_approx_eq([0, 0, -1], rot_90[1], 1e-6, _fl(86));
  test_approx_eq([0, 1, 0], rot_90[2], 1e-6, _fl(87));

  // Rotation about X by 180 degrees
  rot_180 = rot_x(180);
  test_approx_eq([1, 0, 0], rot_180[0], 1e-6, _fl(91));
  test_approx_eq([0, -1, 0], rot_180[1], 1e-6, _fl(92));
  test_approx_eq([0, 0, -1], rot_180[2], 1e-6, _fl(93));
}

module test_transform_rot_y() {
  // Rotation about Y by 0 degrees
  rot_0 = rot_y(0);
  test_eq([[1, 0, 0], [0, 1, 0], [0, 0, 1]], rot_0, _fl(99));

  // Rotation about Y by 90 degrees
  rot_90 = rot_y(90);
  test_approx_eq([0, 0, 1], rot_90[0], 1e-6, _fl(103));
  test_approx_eq([0, 1, 0], rot_90[1], 1e-6, _fl(104));
  test_approx_eq([-1, 0, 0], rot_90[2], 1e-6, _fl(105));

  // Rotation about Y by 180 degrees
  rot_180 = rot_y(180);
  test_approx_eq([-1, 0, 0], rot_180[0], 1e-6, _fl(109));
  test_approx_eq([0, 1, 0], rot_180[1], 1e-6, _fl(110));
  test_approx_eq([0, 0, -1], rot_180[2], 1e-6, _fl(111));
}

module test_transform_rot_z() {
  // Rotation about Z by 0 degrees
  rot_0 = rot_z(0);
  test_eq([[1, 0, 0], [0, 1, 0], [0, 0, 1]], rot_0, _fl(117));

  // Rotation about Z by 90 degrees
  rot_90 = rot_z(90);
  test_approx_eq([0, -1, 0], rot_90[0], 1e-6, _fl(121));
  test_approx_eq([1, 0, 0], rot_90[1], 1e-6, _fl(122));
  test_approx_eq([0, 0, 1], rot_90[2], 1e-6, _fl(123));

  // Rotation about Z by 180 degrees
  rot_180 = rot_z(180);
  test_approx_eq([-1, 0, 0], rot_180[0], 1e-6, _fl(127));
  test_approx_eq([0, -1, 0], rot_180[1], 1e-6, _fl(128));
  test_approx_eq([0, 0, 1], rot_180[2], 1e-6, _fl(129));
}

module test_transform_is_point() {
  // Valid 2D point
  test_truthy(is_point([1, 2], 2), _fl(134));
  test_truthy(is_point([0, 0], 2), _fl(135));

  // Valid 3D point
  test_truthy(is_point([1, 2, 3], 3), _fl(138));
  test_truthy(is_point([0, 0, 0], 3), _fl(139));

  // Invalid: wrong dimension
  test_falsy(is_point([1, 2], 3), _fl(142));
  test_falsy(is_point([1, 2, 3], 2), _fl(143));

  // Invalid: contains non-numbers
  test_falsy(is_point([1, "2"], 2), _fl(146));
  test_falsy(is_point([1, 2, undef], 3), _fl(147));

  // Invalid: not a list
  test_falsy(is_point(123, 3), _fl(150));
  test_falsy(is_point("string", 3), _fl(151));
}

module test_transform_is_vector() {
  // Valid 3D vectors
  test_truthy(is_vector([1, 0, 0], 3), _fl(156));
  test_truthy(is_vector([0, 1, 0], 3), _fl(157));
  test_truthy(is_vector([1, 1, 1], 3), _fl(158));

  // Valid 2D vectors
  test_truthy(is_vector([1, 0], 2), _fl(161));

  // Invalid: wrong dimension
  test_falsy(is_vector([1, 2, 3], 2), _fl(164));
  test_falsy(is_vector([1, 2], 3), _fl(165));

  // Invalid: contains non-numbers
  test_falsy(is_vector([1, "2", 0], 3), _fl(168));

  // Invalid: not a list
  test_falsy(is_vector(123, 3), _fl(171));
}

module test_transform_is_bound_vector() {
  // Valid 3D bound vectors (two 3D points)
  test_truthy(is_bound_vector([[1, 2, 3], [4, 5, 6]], 3), _fl(176));
  test_truthy(is_bound_vector([[0, 0, 0], [1, 1, 1]], 3), _fl(177));

  // Valid 2D bound vectors
  test_truthy(is_bound_vector([[1, 2], [3, 4]], 2), _fl(180));

  // Invalid: only one point
  test_falsy(is_bound_vector([1, 2, 3], 3), _fl(183));
  test_falsy(is_bound_vector([[1, 2, 3]], 3), _fl(184));

  // Invalid: three points
  test_falsy(is_bound_vector([[1, 2, 3], [4, 5, 6], [7, 8, 9]], 3), _fl(187));

  // Invalid: wrong point dimensions
  test_falsy(is_bound_vector([[1, 2], [3, 4, 5]], 3), _fl(190));

  // Invalid: not a list
  test_falsy(is_bound_vector(123, 3), _fl(193));
}

module test_transform_rot_axis() {
  // Rotation by 0 degrees about any axis should be identity
  identity = rot_axis(0, [0, 0, 1]);
  test_approx_eq([[1, 0, 0], [0, 1, 0], [0, 0, 1]], identity, 1e-6, _fl(199));

  // Rotation about Z axis by 90 degrees (should match rot_z)
  rot_z_90 = rot_z(90);
  rot_axis_z = rot_axis(90, [0, 0, 1]);
  test_approx_eq(rot_z_90, rot_axis_z, 1e-6, _fl(204));

  // Rotation about X axis by 90 degrees
  rot_x_90 = rot_x(90);
  rot_axis_x = rot_axis(90, [1, 0, 0]);
  test_approx_eq(rot_x_90, rot_axis_x, 1e-6, _fl(209));

  // Rotation about Y axis by 90 degrees
  rot_y_90 = rot_y(90);
  rot_axis_y = rot_axis(90, [0, 1, 0]);
  test_approx_eq(rot_y_90, rot_axis_y, 1e-6, _fl(214));

  // Scaled axis (should normalize and produce same result)
  rot_scaled = rot_axis(90, [0, 0, 2]);  // 2x scaled Z axis
  rot_normal = rot_axis(90, [0, 0, 1]);
  test_approx_eq(rot_normal, rot_scaled, 1e-6, _fl(219));
}

module test_transform_rotate() {
  // Rotation about Z axis (default) - returns 3x3 matrix
  r_z = rotate(90);
  test_eq(3, len(r_z), _fl(226));
  test_eq(3, len(r_z[0]), _fl(227));

  // Rotation about specific axis - returns 3x3 matrix
  r_x = rotate(45, [1, 0, 0]);
  test_eq(3, len(r_x), _fl(231));
  test_eq(3, len(r_x[0]), _fl(232));

  // Rotation about normalized vector - returns 3x3 matrix
  r_axis = rotate(30, [1, 1, 1]);
  test_eq(3, len(r_axis), _fl(236));
  test_eq(3, len(r_axis[0]), _fl(237));
}

module test_transform_translate() {
  // Translation vector
  trans_v = [1, 2, 3];
  t_mat = translate(trans_v);

  // Should be 4x4 homogeneous matrix
  test_eq(4, len(t_mat), _fl(246));
  test_eq(4, len(t_mat[0]), _fl(247));

  // Last column should have translation values
  test_eq(1, t_mat[0][3], _fl(250));
  test_eq(2, t_mat[1][3], _fl(251));
  test_eq(3, t_mat[2][3], _fl(252));
  test_eq(1, t_mat[3][3], _fl(253));
}

module test_transform_scale() {
  // Uniform scale - returns 3x3 matrix
  s_vec = [2, 2, 2];
  s_mat = scale(s_vec);

  test_eq(3, len(s_mat), _fl(262));
  test_eq(3, len(s_mat[0]), _fl(263));

  // Diagonal should have scale factors
  test_eq(2, s_mat[0][0], _fl(266));
  test_eq(2, s_mat[1][1], _fl(267));
  test_eq(2, s_mat[2][2], _fl(268));

  // Non-uniform scale
  s_nonuniform = [1, 2, 3];
  s_mat2 = scale(s_nonuniform);
  test_eq(1, s_mat2[0][0], _fl(274));
  test_eq(2, s_mat2[1][1], _fl(275));
  test_eq(3, s_mat2[2][2], _fl(276));
}

module test_transform_transform_points() {
  // Transform single point with identity matrix
  identity = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]];
  pt = [1, 2, 3];
  result = transform([pt], identity);
  test_approx_eq([1, 2, 3], result[0], 1e-6, _fl(284));

  // Transform list of points
  pts = [[0, 0, 0], [1, 1, 1], [2, 2, 2]];
  result_list = transform(pts, identity);
  test_eq(3, len(result_list), _fl(289));
}

module test_transform_identity() {
  // 2x2 identity
  id2 = identity(2);
  test_eq([[1, 0], [0, 1]], id2, _fl(295));

  // 3x3 identity
  id3 = identity(3);
  test_eq([[1, 0, 0], [0, 1, 0], [0, 0, 1]], id3, _fl(299));

  // 4x4 identity
  id4 = identity(4);
  test_eq(4, len(id4), _fl(303));
  test_eq(1, id4[0][0], _fl(304));
  test_eq(1, id4[1][1], _fl(305));
  test_eq(1, id4[2][2], _fl(306));
  test_eq(1, id4[3][3], _fl(307));
  test_eq(0, id4[0][1], _fl(308));
  test_eq(0, id4[1][0], _fl(309));
}

module test_transform_augment() {
  // Augment 2x2 with 2x1
  A = [[1, 2], [3, 4]];
  B = [[5], [6]];
  aug = augment(A, B);
  test_eq([[1, 2, 5], [3, 4, 6]], aug, _fl(317));

  // Augment 3x3 with 3x1
  A3 = [[1, 0, 0], [0, 1, 0], [0, 0, 1]];
  B3 = [[2], [3], [4]];
  aug3 = augment(A3, B3);
  test_eq(3, len(aug3), _fl(323));
  test_eq(4, len(aug3[0]), _fl(324));
  test_eq(2, aug3[0][3], _fl(325));
  test_eq(3, aug3[1][3], _fl(326));
  test_eq(4, aug3[2][3], _fl(327));
}

module test_transform_reorient_single_point() {
  // Single point reorientation
  start = [[0, 0, 0], [0, 0, 1]];
  end = [[1, 1, 1], [1, 1, 2]];
  T = reorient(start, end);

  // Result should be a 4x4 transformation matrix
  test_eq(4, len(T), _fl(337));
  test_eq(4, len(T[0]), _fl(338));
}

module test_transform_reorient_two_points() {
  // Two point reorientation (orientation + scale)
  start = [[0, 0, 0], [0, 0, 1], [1, 0, 0]];
  end = [[1, 1, 1], [1, 1, 2], [2, 1, 1]];
  T = reorient(start, end);

  test_eq(4, len(T), _fl(347));
  test_eq(4, len(T[0]), _fl(348));
}

module test_transform_all() {
  test_transform_transpose();
  test_transform_homogenise();
  test_transform_dehomogenise();
  test_transform_homogenise_transform();
  test_transform_rot_x();
  test_transform_rot_y();
  test_transform_rot_z();
  test_transform_is_point();
  test_transform_is_vector();
  test_transform_is_bound_vector();
  test_transform_rot_axis();
  test_transform_rotate();
  test_transform_translate();
  test_transform_scale();
  test_transform_transform_points();
  test_transform_identity();
  test_transform_augment();
  test_transform_reorient_single_point();
  test_transform_reorient_two_points();
}

test_transform_all();
