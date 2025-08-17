class_name Agent extends CharacterBody3D

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

@export var target: CharacterBody3D

@export var current_behaviour: Behaviour
@export var path_agent: PathAgent

var target_pos: Vector3


func _ready() -> void:
	path_agent.agent = self
	path_agent.navigation_agent_3d = navigation_agent_3d


func _physics_process(delta: float) -> void:
	if current_behaviour != null:
		current_behaviour.update(self, delta)
	
	path_agent.update(delta)


func set_current_behaviour(new_behaviour: Behaviour) -> void:
	current_behaviour = new_behaviour


func go_to_point(pos: Vector3) -> void:
	target_pos = pos


func is_path_complete() -> bool:
	return navigation_agent_3d.is_navigation_finished()


func set_color(color: Color) -> void:
	var mat: StandardMaterial3D = mesh_instance_3d.get_active_material(0)
	mat.albedo_color = color
	mesh_instance_3d.material_override = mat
