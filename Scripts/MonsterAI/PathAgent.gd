class_name PathAgent extends Resource

@export var speed: float = 3

var navigation_agent_3d: NavigationAgent3D
var agent: Agent


func update(delta_time: float) -> void:
	var destination = navigation_agent_3d.get_next_path_position()
	var local_destination = destination - agent.global_position
	var direction = local_destination.normalized()
	
	navigation_agent_3d.set_target_position(agent.target_pos)
	
	agent.velocity = direction * speed
	agent.move_and_slide()
