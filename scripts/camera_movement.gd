extends Camera3D

@export var move_speed := 6.0
@export var fast_multiplier := 2.5
@export var mouse_sensitivity := 0.002

var _yaw := 0.0
var _pitch := 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_yaw = rotation.y
	_pitch = rotation.x

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clamp(_pitch, -PI * 0.49, PI * 0.49)

		rotation = Vector3(_pitch, _yaw, 0.0)

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	var dir := Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		dir -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		dir += transform.basis.z
	if Input.is_action_pressed("move_left"):
		dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		dir += transform.basis.x
	if Input.is_action_pressed("move_up"):
		dir += transform.basis.y
	if Input.is_action_pressed("move_down"):
		dir -= transform.basis.y

	if dir != Vector3.ZERO:
		dir = dir.normalized()

	var speed := move_speed
	if Input.is_action_pressed("move_fast"):
		speed *= fast_multiplier

	global_position += dir * speed * delta
