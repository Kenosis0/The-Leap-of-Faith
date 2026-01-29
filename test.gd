extends Node3D

@export var a: Node3D
@export var b: Node3D

@export var cable_length := 2.5
@export_range(4, 128, 1) var segments := 32
@export var gravity := Vector3.DOWN * 18.0
@export_range(0.0, 0.2, 0.001) var damping := 0.02
@export_range(4, 30, 1) var iters := 16
@export_range(1, 6, 1) var substeps := 2

# Collision (cheap + effective)
@export var enable_collision := true
@export var collision_radius := 0.02
@export var floor_y := 0.0  # simplest: collide with floor plane at Y

# Rendering (ribbon mesh)
@export var width := 0.02
@export var face_camera := true
@export var camera: Camera3D
@export var material: Material

var _p: PackedVector3Array
var _pp: PackedVector3Array
var _seg_len: float

var _mesh_instance: MeshInstance3D
var _mesh := ArrayMesh.new()

func _ready() -> void:
	_mesh_instance = MeshInstance3D.new()
	add_child(_mesh_instance)
	_mesh_instance.mesh = _mesh
	if material:
		_mesh_instance.material_override = material
	_rebuild()

func _rebuild() -> void:
	if not a or not b:
		return
	_seg_len = cable_length / float(segments)
	var n := segments + 1
	_p = PackedVector3Array(); _p.resize(n)
	_pp = PackedVector3Array(); _pp.resize(n)

	var pa := a.global_position
	var pb := b.global_position
	var dir := pb - pa
	var step := (dir / float(segments)) if dir.length() > 0.0001 else Vector3.RIGHT * _seg_len

	for i in range(n):
		var pos := pa + step * float(i)
		_p[i] = pos
		_pp[i] = pos

func _physics_process(delta: float) -> void:
	if not a or not b:
		return
	if _p.size() != segments + 1:
		_rebuild()
		return

	_seg_len = cable_length / float(segments)

	var step_dt := delta / float(substeps)
	for _s in range(substeps):
		_integrate(step_dt)
		_solve_constraints()
		if enable_collision:
			_solve_collisions()

	_build_mesh()

func _integrate(dt: float) -> void:
	var dt2 := dt * dt
	for i in range(1, _p.size() - 1):
		var pos := _p[i]
		var prev := _pp[i]
		var vel := (pos - prev) * (1.0 - damping)
		var next := pos + vel + gravity * dt2
		_pp[i] = pos
		_p[i] = next

	# pin ends
	_p[0] = a.global_position
	_pp[0] = _p[0]
	_p[_p.size() - 1] = b.global_position
	_pp[_p.size() - 1] = _p[_p.size() - 1]

func _solve_constraints() -> void:
	for _k in range(iters):
		_p[0] = a.global_position
		_p[_p.size() - 1] = b.global_position

		for i in range(_p.size() - 1):
			var p1 := _p[i]
			var p2 := _p[i + 1]
			var d := p2 - p1
			var lent := d.length()
			if lent < 0.000001:
				continue
			var diff := (lent - _seg_len) / lent
			var corr := d * diff

			if i == 0:
				_p[i + 1] = p2 - corr
			elif i + 1 == _p.size() - 1:
				_p[i] = p1 + corr
			else:
				_p[i] = p1 + corr * 0.5
				_p[i + 1] = p2 - corr * 0.5

func _solve_collisions() -> void:
	# Floor plane collision: y >= floor_y + radius
	var min_y := floor_y + collision_radius
	for i in range(1, _p.size() - 1):
		var p := _p[i]
		if p.y < min_y:
			p.y = min_y
			_p[i] = p

func _get_cam() -> Camera3D:
	return camera if camera else get_viewport().get_camera_3d()

func _build_mesh() -> void:
	var cam := _get_cam()
	if cam == null:
		return

	_mesh.clear_surfaces()

	var n := _p.size()
	var verts := PackedVector3Array(); verts.resize(n * 2)
	var uvs := PackedVector2Array(); uvs.resize(n * 2)
	var idx := PackedInt32Array(); idx.resize((n - 1) * 6)

	for i in range(n):
		var pos := _p[i]
		var tangent: Vector3
		if i == 0:
			tangent = (_p[1] - _p[0]).normalized()
		elif i == n - 1:
			tangent = (_p[n - 1] - _p[n - 2]).normalized()
		else:
			tangent = (_p[i + 1] - _p[i - 1]).normalized()

		var side: Vector3
		if face_camera:
			var to_cam := (cam.global_position - pos).normalized()
			side = tangent.cross(to_cam).normalized()
			if side.length() < 0.0001:
				side = Vector3.UP
		else:
			side = tangent.cross(Vector3.UP).normalized()
			if side.length() < 0.0001:
				side = tangent.cross(Vector3.FORWARD).normalized()

		var half := width * 0.5
		verts[i * 2] = pos - side * half
		verts[i * 2 + 1] = pos + side * half

		var t := float(i) / float(max(1, n - 1))
		uvs[i * 2] = Vector2(0, t)
		uvs[i * 2 + 1] = Vector2(1, t)

	var w := 0
	for i in range(n - 1):
		var a0 := i * 2
		var a1 := i * 2 + 1
		var b0 := (i + 1) * 2
		var b1 := (i + 1) * 2 + 1
		idx[w+0]=a0; idx[w+1]=b0; idx[w+2]=a1
		idx[w+3]=a1; idx[w+4]=b0; idx[w+5]=b1
		w += 6

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx

	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if material:
		_mesh_instance.material_override = material
