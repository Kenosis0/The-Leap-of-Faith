@tool
extends Camera3D

@export var active: bool = false
@export var look_speed: float = 6.0
@export var target: Node3D
@export var offset: Vector3 = Vector3(0, 0, 0)

@export_category("Path")
@export var path: Path3D
@export_range(0.0, 1.0) var progress = 0.0

@onready var glass_jar: Node3D = $"../GlassJar"
@onready var socket: Node3D = $"../Socket"

var targets: Array[Node3D]
var t_index: int = 0


func _ready() -> void:
	if socket:
		targets.append(socket)
	else:
		printerr("ERROR")
	
	if glass_jar:
		targets.append(glass_jar)
	else:
		printerr("ERROR")


func _process(delta: float) -> void:
	follow_path()
	
	if active == false:
		return
		
	if not target:
		return

	var look_pos = target.global_position + offset

	var desired_transform = global_transform.looking_at(
		look_pos,
		Vector3.UP
	)

	global_transform.basis = global_transform.basis.slerp(
		desired_transform.basis,
		look_speed * delta
	)


func follow_path() -> void:
	if not path:
		return
	
	var point: PathFollow3D = path.get_child(0)
	
	point.progress_ratio = progress
	
	global_position = point.global_position


func change_target() -> void:
	look_speed = 1.0
	
	var new_target = targets[t_index]
	target = new_target
	offset.y = -.3
	t_index += 1
