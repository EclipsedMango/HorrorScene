extends Camera3D

@export var bag_max_rotation_degrees: float = 45.0
@export var bag_rotation_speed: float = 5.0

@onready var bag: Node3D = %Bag
@onready var bag_torch: SpotLight3D = %BagTorch
@onready var player: CharacterBody3D = $"../../../.."

var hover_mesh: MeshInstance3D = null
var hover_material: StandardMaterial3D = preload("res://Shaders/Bag/Hightlight2.tres")
var original_mat: StandardMaterial3D = preload("res://Shaders/Bag/DefaultMat.tres")
var previous_hover_mesh: MeshInstance3D = null

var inventory_open: bool = false


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
	
	_handle_inventory_bag_rotation(delta)
	
	var mouse_pos: Vector2 = _fish_eye(get_viewport().get_mouse_position(), 1.75)
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	
	var ray_origin: Vector3 = global_position
	var ray_end: Vector3 = ray_origin + project_ray_normal(mouse_pos) * 100.0
	
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = true
	
	var result: Dictionary = space_state.intersect_ray(query)
	
	if result:
		var collider: Area3D = result.collider
		var mesh: MeshInstance3D = collider.get_node("MeshInstance3D")
		
		if mesh != previous_hover_mesh:
			if previous_hover_mesh:
				previous_hover_mesh.set_surface_override_material(0, original_mat)
			
			previous_hover_mesh = mesh
			original_mat = mesh.get_surface_override_material(0)
			
			mesh.set_surface_override_material(0, hover_material.duplicate())
		
	else:
		if previous_hover_mesh:
			previous_hover_mesh.set_surface_override_material(0, original_mat)
			previous_hover_mesh = null
			original_mat = null


func _fish_eye(pos: Vector2, power: float) -> Vector2:
	var res: Vector2 = get_window().size
	
	var ndc: Vector2 = pos / res.x
	var aspect: float = res.x / res.y
	
	var centered_aspect := Vector2(0.5, 0.5 / aspect)
	var d: Vector2 = ndc - centered_aspect
	
	var h: float = sqrt(d.dot(d))
	
	var bind: float
	
	if power > 0.0:
		bind = sqrt(centered_aspect.dot(centered_aspect))
	else:
		if aspect < 1.0:
			bind = centered_aspect.x
		else:
			bind = centered_aspect.y
	
	var uv: Vector2
	
	if power > 0.0:
		uv = centered_aspect + d.normalized() * tan(h * power) * bind / tan(bind * power)
	elif power < 0.0:
		uv = centered_aspect + d.normalized() * atan(h * -power * 10.0) * bind / atan(-power * bind * 10.0)
	else:
		uv = ndc
	
	uv.y *= aspect
	
	return uv * res


func _handle_inventory_bag_rotation(delta: float) -> void:
	var vp: Viewport = get_viewport()
	var vp_size: Vector2 = Vector2(vp.size)
	var mouse_pos: Vector2 = vp.get_mouse_position()
	
	var nx: float = (mouse_pos.x / vp_size.x) * 2.0 - 1.0
	var ny: float = (mouse_pos.y / vp_size.y) * 2.0 - 1.0
	
	var sensitivity: float = 4.0  
	
	var target_y_deg: float = clamp(-nx * (sensitivity * 1.5) * bag_max_rotation_degrees, 
			-bag_max_rotation_degrees, bag_max_rotation_degrees)
	
	var target_x_deg: float = clamp(-ny * sensitivity * bag_max_rotation_degrees, 
			-bag_max_rotation_degrees, bag_max_rotation_degrees)
	
	bag.rotation_degrees.y = lerp(bag.rotation_degrees.y, target_y_deg, delta * bag_rotation_speed)
	bag.rotation_degrees.x = lerp(bag.rotation_degrees.x, target_x_deg, delta * bag_rotation_speed)
