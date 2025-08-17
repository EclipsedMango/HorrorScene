class_name FollowBehaviour extends Behaviour

var last_target_pos: Vector3
var range: float = 4


func enter(agent: Agent) -> void:
	agent.set_color(Color.RED)


func exit(agent: Agent) -> void:
	agent.set_color(Color.GHOST_WHITE)


func update(agent: Agent, physics_delta: float) -> void:
	var target: CharacterBody3D = agent.target
	agent.go_to_point(target.global_position)


func evaluate(agent: Agent) -> float:
	var target: CharacterBody3D = agent.target
	var dist: float = target.global_position.distance_to(agent.global_position)
	
	return max(0, 1.0 - (dist / range))
