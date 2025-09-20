extends Camera3D

@export var bag_max_rotation_degrees: float = 45.0
@export var bag_rotation_speed: float = 5.0

@onready var bag: Node3D = %Bag
@onready var bag_torch: SpotLight3D = %BagTorch
@onready var player: CharacterBody3D = $"../../../.."
@onready var left_comp: CompartmentUI = %Compartment1
@onready var right_comp: CompartmentUI = %Compartment2
@onready var back_comp: CompartmentUI = %Compartment3
@onready var front_comp: CompartmentUI = %Compartment4

var previous_hover_meshes: Array[MeshInstance3D] = []

var inventory_open: bool = false

var open_compartment: CompartmentUI = null

func _ready() -> void:
	player.inventory_interaction.connect(_inventory_interaction)
	inventory_open = false
	bag.visible = false
	bag_torch.visible = false


func _inventory_interaction() -> void:
	inventory_open = !inventory_open
	bag.visible = !bag.visible
	bag_torch.visible = !bag_torch.visible


func _process(delta: float) -> void:
	if !inventory_open:
		bag.rotation_degrees.y = lerp(bag.rotation_degrees.y, 0.0, delta * bag_rotation_speed)
		bag.rotation_degrees.x = lerp(bag.rotation_degrees.x, 0.0, delta * bag_rotation_speed)
		return
	
	if Input.is_action_just_pressed("left_click"):
		var result: Dictionary = _cast_ray()
		if result:
			var comp_name: String = result.collider.name
			_compartment_selected(left_comp, comp_name, "LeftCompartment", Vector2(0.4, 0.0), 0.5)
			_compartment_selected(right_comp, comp_name, "RightCompartment", Vector2(-0.4, 0.0), 0.5)
			_compartment_selected(front_comp, comp_name, "FrontCompartment", Vector2(0.0, 0.25), 0.35)
			_compartment_selected(back_comp, comp_name, "BackCompartment", Vector2(0.0, -0.25), 0.35)
	
	_handle_inventory_bag_rotation(delta)
	_handle_hover_effect()


func _compartment_selected(comp: CompartmentUI, comp_name: String, desired_comp: String, offset: Vector2, scal: float) -> void:
	if comp_name == desired_comp:
		if open_compartment != null && open_compartment != comp:
			open_compartment.visible = false
		
		comp.visible = !comp.visible
		
		var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
		var tween2: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
		if comp.visible:
			open_compartment = comp
		else:
			open_compartment = null
			offset = Vector2.ZERO
			scal = 0.5
		
		tween.tween_property(bag, "position", Vector3(offset.x, offset.y - 0.065, bag.position.z), 0.3)
		tween2.tween_property(bag, "scale", Vector3(scal, scal, scal), 0.3)


func _fish_eye(pos: Vector2, power: float) -> Vector2:
	var fisheye_uv: Vector2
	
	var res: Vector2 = get_window().size
	
	var ndc: Vector2 = pos / res
	var aspect: float = res.x / res.y
	
	var centered_aspect := Vector2(0.5, 0.5)
	var d: Vector2 = ndc - centered_aspect
	var rr: float = d.length()
	
	var bind: float = sqrt(centered_aspect.dot(centered_aspect))
	
	if power > 0.0:
		fisheye_uv = centered_aspect + d.normalized() * tan(rr * power) * bind / tan(bind * power)
	elif power < 0.0:
		fisheye_uv = centered_aspect + d.normalized() * atan(rr * -power * 10.0) * bind / atan(-power * bind * 10.0)
	else:
		fisheye_uv = ndc
	
	return fisheye_uv * res


func _handle_inventory_bag_rotation(delta: float) -> void:
	var vp: Viewport = get_viewport()
	var vp_size: Vector2 = Vector2(vp.size)
	var mouse_pos: Vector2 = vp.get_mouse_position() - (Vector2(bag.position.x, -bag.position.y) * 600)
	
	var nx: float = (mouse_pos.x / vp_size.x) * 2.0 - 1.0
	var ny: float = (mouse_pos.y / vp_size.y) * 2.0 - 1.0
	
	var sensitivity: float = 4.0  
	
	var target_y_deg: float = clamp(-nx * (sensitivity * 1.5) * bag_max_rotation_degrees, 
			-bag_max_rotation_degrees, bag_max_rotation_degrees)
	
	var target_x_deg: float = clamp(-ny * sensitivity * bag_max_rotation_degrees, 
			-bag_max_rotation_degrees, bag_max_rotation_degrees)
	
	bag.rotation_degrees.y = lerp(bag.rotation_degrees.y, target_y_deg, delta * bag_rotation_speed)
	bag.rotation_degrees.x = lerp(bag.rotation_degrees.x, target_x_deg, delta * bag_rotation_speed)


func _handle_hover_effect() -> void:
	var result: Dictionary = _cast_ray()
	
	for mesh in previous_hover_meshes:
		mesh.layers = 1
	
	previous_hover_meshes.clear()
	
	if result:
		var collider: Area3D = result.collider
		
		for mesh in collider.get_children():
			if mesh is MeshInstance3D:
				mesh.layers = 2
				previous_hover_meshes.append(mesh)


func _cast_ray() -> Dictionary:
	var mouse_pos: Vector2 = _fish_eye(get_viewport().get_mouse_position(), 1.5)
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	
	var ray_origin: Vector3 = global_position
	var ray_end: Vector3 = ray_origin + project_ray_normal(mouse_pos) * 100.0
	
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = true
	
	return space_state.intersect_ray(query)
