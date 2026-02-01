extends Node3D

@onready var animation_player: AnimationPlayer = $Lumen/Lamp/AnimationPlayer

func _ready() -> void:
	animation_player.play("AwakeIdle")
