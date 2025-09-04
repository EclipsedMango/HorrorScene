class_name WanderBehaviour extends Behaviour


func enter(agent: Agent) -> void:
	agent.set_color(Color.GHOST_WHITE)


func exit(agent: Agent) -> void:
	agent.set_color(Color.GHOST_WHITE)


func update(agent: Agent, delta_time: float) -> void:
	if agent.is_path_complete():
		var point: Vector3 = Vector3(randf_range(-250, 250), 0, randf_range(-250, 250))
		agent.go_to_point(point)


func evaluate(agent: Agent) -> float:
	return 0.25
