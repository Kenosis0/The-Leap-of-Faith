extends Node3D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var bttn_anim: AnimationPlayer = $CanvasLayer/PanelContainer/AnimationPlayer
@onready var lumen: Node3D = $"Lumen/PIXAR LAmp2"


func _ready() -> void:
	anim.play("Start")
	bttn_anim.play("idle")


#func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	#print(anim_name)
	#if anim_name == "Start":
		##print("Can now jump")
		#anim.play("ChangeScene")


func enable_jump() -> void:
	#print("can_jump is set to ", GameManager.can_jump)
	anim.play("ChangeScene")
	
	await anim.animation_finished
	
	GameManager.can_jump = true


func _on_button_pressed() -> void:
	lumen.anim_tree.set("parameters/Jump/blend_amount", 1.0)
