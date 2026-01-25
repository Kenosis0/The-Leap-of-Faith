extends Node3D

@export var anim: AnimationPlayer
@export var anim_tree: AnimationTree


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		#anim.play("AwakeIdle_001")
		
		anim_tree.set("parameters/OneShot/request", 1)
