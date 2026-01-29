@tool
extends Node3D

@onready var omni_light: OmniLight3D = %OmniLight3D
@onready var spot_light: SpotLight3D = %SpotLight3D
@onready var anim_tree: AnimationTree = $AnimationTree


@export_category("Light")
@export_subgroup("Omni")
@export var omni_energy: float  = 1.0:
	set = set_omni_enery
@export_range(0.0, 1.0) var omni_energy_ratio: float = 1.0:
	set = set_omni_ratio
@export var omni_range: float = 5.0:
	set = set_omni_range
@export_range(0.0, 2.0) var omni_attenuation: float = 1.0:
	set = set_omni_attenuation
@export_group("Spot")
@export var spot_energy: float  = 1.0:
	set = set_spot_enery
@export_range(0.0, 1.0) var spot_energy_ratio: float = 1.0:
	set = set_spot_ratio


func set_omni_enery(value) -> void:
	if omni_light == null:
		return
	if omni_energy_ratio != 1.0:
		omni_energy_ratio = 1.0
	
	omni_energy = value
	
	omni_light.light_energy = omni_energy


func set_omni_ratio(value) -> void:
	if omni_light == null:
		return
	omni_energy_ratio = value

	omni_light.light_energy = omni_energy_ratio * omni_energy


func set_omni_range(value) -> void:
	if omni_light == null:
		return
	omni_range = value
	omni_light.omni_range = omni_range


func set_omni_attenuation(value) -> void:
	if omni_light == null:
		return
	omni_attenuation = value
	omni_light.omni_attenuation = omni_attenuation


func set_spot_enery(value) -> void:
	if spot_light == null:
		return
	
	if spot_energy_ratio != 1.0:
		spot_energy_ratio = 1.0
	
	spot_energy = value
	
	spot_light.light_energy = spot_energy


func set_spot_ratio(value) -> void:
	if spot_light == null:
		return
	
	spot_energy_ratio = value
	
	var max_value = spot_energy
	spot_light.light_energy = spot_energy_ratio * spot_energy


func _ready() -> void:
	anim_tree.active = true
	
	await get_tree().create_timer(3).timeout
	
	var tween = get_tree().create_tween()
	
	tween.tween_property(anim_tree, "parameters/WakingUp/blend_amount", 1.0, 1)
	
	await tween.finished
	
	anim_tree.set("parameters/LookIdle/request", 1)




func anim_state_finished(anim_name: String) -> void:
	print("State ", anim_name, " Finished")
	
	if anim_name == "LookIdle":
		anim_tree.set("parameters/StretchShot/request", 1)
	elif anim_name == "Stretch":
		var tween = get_tree().create_tween()
		tween.tween_property(anim_tree, "parameters/LookAlert/add_amount", 1, 1)
	elif anim_name == "LookAlert":
		var tween = get_tree().create_tween()
		tween.tween_property(anim_tree, "parameters/Move/blend_amount", 1, 1)
	elif anim_name == "Move":
		var tween = get_tree().create_tween()
		tween.tween_property(anim_tree, "parameters/StopLook/blend_amount", 1, 1)
	elif anim_name == "StopLook":
		var tween = get_tree().create_tween()
		tween.tween_property(anim_tree, "parameters/Idle/blend_amount", 1, 1)
