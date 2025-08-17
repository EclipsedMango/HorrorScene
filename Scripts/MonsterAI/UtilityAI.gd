class_name UtilityAI extends Behaviour

@export var behaviours: Array[Behaviour] = []

var _timer: float = 0
var _cooldown: float = 0.5

var _current_behaviour: Behaviour


func add_behaviour(behaviour: Behaviour) -> void:
	behaviours.append(behaviour)


func update(agent: CharacterBody3D, delta_time: float) -> void:
	_timer += delta_time
	if _timer < _cooldown:
		if _current_behaviour != null:
			_current_behaviour.update(agent, delta_time)
		
		return
	
	var best_eval: float = 0
	var new_behaviour: Behaviour = null
	
	for behaviour in behaviours:
		var eval: float = behaviour.evaluate(agent)
		print(eval)
		
		if eval > best_eval:
			best_eval = eval
			new_behaviour = behaviour
	
	if new_behaviour != null && new_behaviour != _current_behaviour:
		if _current_behaviour != null:
			_current_behaviour.exit(agent)
		
		_current_behaviour = new_behaviour
		_current_behaviour.enter(agent)
	
	_timer = 0
	_current_behaviour.update(agent, delta_time)
