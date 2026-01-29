extends Path3D
# Based on Elijah Martin/Palin_drome, minimally hardened.

@export_range(3, 200, 1) var number_of_segments: int = 10
@export_range(3, 50, 1) var mesh_sides: int = 6
@export var cable_thickness: float = 0.1
@export var fixed_start_point: bool = true
@export var fixed_end_point: bool = true
@export var rigidbody_attached_to_start: RigidBody3D
@export var rigidbody_attached_to_end: RigidBody3D
@export var material: Material

@onready var mesh: CSGPolygon3D = $CSGPolygon3D

var segments: Array[RigidBody3D] = []
var joints: Array[PinJoint3D] = []
var curve_points: Array[Vector3] = []

func _ready() -> void:
	# Hard reset arrays (prevents duplicates on scene reload / tool runs)
	segments.clear()
	joints.clear()
	curve_points.clear()

	# Store transform, build in local-zero like original
	var rotation_buffer := rotation
	var position_buffer := position
	rotation = Vector3.ZERO
	position = Vector3.ZERO

	if curve == null or curve.point_count < 2:
		push_error("Path3D needs a Curve3D with >= 2 points.")
		rotation = rotation_buffer
		position = position_buffer
		return

	var distance := curve.get_baked_length()

	# Sample points (local space)
	for i in range(number_of_segments + 1):
		curve_points.append(curve.sample_baked((distance * float(i)) / float(number_of_segments), true))

	# Rebuild curve with exact point count
	curve.clear_points()

	# Create segments + joints
	for i in range(number_of_segments):
		var rb := RigidBody3D.new()
		add_child(rb)
		segments.append(rb)

		var p0 := curve_points[i]
		var p1 := curve_points[i + 1]
		rb.position = p0 + (p1 - p0) * 0.5

		var cs := CollisionShape3D.new()
		rb.add_child(cs)

		var cap := CapsuleShape3D.new()
		cap.radius = cable_thickness
		cap.height = (p1 - p0).length()
		cs.shape = cap

		# Orientation like original
		rb.look_at_from_position(rb.position + Vector3(0.001, 0, -0.001), p1)
		rb.rotation.x += PI / 2.0

		# Joint at p0
		var j := PinJoint3D.new()
		add_child(j)
		j.position = p0

		if i == 0:
			# We'll wire node_a/node_b after top_level move (matches original behavior)
			pass
		else:
			j.node_a = segments[i - 1].get_path()
			j.node_b = segments[i].get_path()

		joints.append(j)

		# Add curve point p0
		curve.add_point(p0)

	# Add final curve point
	curve.add_point(curve_points[number_of_segments])

	# Mesh polygon
	var myShape := PackedVector2Array()
	for i in range(mesh_sides):
		var ang := 2.0 * PI * float(i + 1) / float(mesh_sides)
		myShape.append(Vector2(sin(ang), cos(ang)) * cable_thickness)

	mesh.polygon = myShape
	if material:
		mesh.material = material

	# Restore rotation, then move children to world via top_level (original approach)
	rotation = rotation_buffer

	for segment in segments:
		segment.top_level = true
		segment.position += position_buffer
	for joint in joints:
		joint.top_level = true
		joint.position += position_buffer

	# Reset Path3D rotation to zero (original style)
	rotation = Vector3.ZERO

	# Wire first joint properly
	if fixed_start_point:
		# Pin the first segment to world by leaving node_a empty (Godot treats empty as world)
		joints[0].node_b = segments[0].get_path()
	else:
		# If not fixed, still connect segment 0 to segment 1 through joint 1 already
		joints[0].node_b = segments[0].get_path()

	# End joint if fixed OR if attaching to rigidbody
	var need_end_joint := fixed_end_point or rigidbody_attached_to_end != null
	if need_end_joint:
		var end_joint := PinJoint3D.new()
		add_child(end_joint)
		end_joint.top_level = true

		# IMPORTANT: if attached rigidbody exists, place joint exactly at rigidbody (prevents gap)
		if rigidbody_attached_to_end:
			end_joint.position = rigidbody_attached_to_end.global_position
		else:
			end_joint.position = curve_points[-1] + position_buffer

		end_joint.node_a = segments[number_of_segments - 1].get_path()
		joints.append(end_joint)

	# Attach start rigidbody (matches your original behavior)
	if rigidbody_attached_to_start:
		joints[0].node_b = rigidbody_attached_to_start.get_path()

	# Attach end rigidbody
	if rigidbody_attached_to_end:
		joints[-1].node_b = rigidbody_attached_to_end.get_path()

func _physics_process(_delta: float) -> void:
	# GUARANTEE we only write within existing point_count
	var pc := curve.point_count
	if pc == 0 or segments.is_empty():
		return

	# Expect pc == number_of_segments + 1, but clamp to be safe
	var max_seg = min(number_of_segments, segments.size())

	for p in range(pc):
		if p < max_seg:
			var seg := segments[p]
			var cap := (seg.get_child(0) as CollisionShape3D).shape as CapsuleShape3D
			curve.set_point_position(
				p,
				seg.position + seg.transform.basis.y * (cap.height * 0.5)
			)
		else:
			var last := segments[max_seg - 1]
			var capL := (last.get_child(0) as CollisionShape3D).shape as CapsuleShape3D
			curve.set_point_position(
				p,
				last.position - last.transform.basis.y * (capL.height * 0.5)
			)
