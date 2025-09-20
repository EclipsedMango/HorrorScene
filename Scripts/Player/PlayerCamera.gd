extends Camera3D

const LOOK_LIMIT: float = PI / 2

@export_group("blur")
@export var blur_far_max: float = 100
@export var blur_far_min: float = 2
@export var blur_near_max: float = 2
@export var blur_near_min: float = 0
@export var blur_range: float = -2

@onready var player_body: CharacterBody3D = $"../.."
@onready var player_torch: SpotLight3D = %PlayerTorch
@onready var blur_cast: RayCast3D = $"../../BlurCast"

@onready var start_pos: Vector3 = position

# Camera settings (Gets defined in _ready)
var mouse_sensitivity: float
var zoom_max: float
var zoom_min: float
var sprinting_fov_amount: float
var current_fov: float

var wanted_dir: Vector2 = Vector2.ZERO
var previous_rotation: Vector3 = Vector3.ZERO

var cam_offset: Vector3 = Vector3.ZERO

func _ready():
	# Set player defined variables.
	mouse_sensitivity = player_body.mouse_sensitivity
	zoom_max = player_body.zoom_max
	zoom_min = player_body.zoom_min
	sprinting_fov_amount = player_body.sprinting_fov_amount
	
	current_fov = fov
	player_torch.visible = false


func _physics_process(delta: float) -> void:
	var time_elapsed: float = Time.get_ticks_usec() * 0.000001
	
	if Input.is_action_just_pressed("f"):
		player_torch.visible = !player_torch.visible
	
	# FOV zoom to mimic zooming on a camera
	if Input.is_action_just_pressed("mouse_up") && current_fov > zoom_max:
		current_fov -= 1
	elif Input.is_action_just_pressed("mouse_down") && current_fov < zoom_min:
		current_fov += 1
	
	# Adds small delay between mouse movement and camera reacting
	rotation.z = angle_difference(player_body.rotation.y, previous_rotation.y) * 0.25
	player_body.rotation.y = lerp_angle(player_body.rotation.y, wanted_dir.x, delta * 15.0) 
	rotation.x = lerp_angle(rotation.x, wanted_dir.y, delta * 15.0)
	
	# TODO: add realistic camera shake.
	if player_body.current_state == player_body.State.WALKING:
		var freq: float = 8.0
		var amp: float = 0.03
		cam_offset = cam_offset.move_toward(_handle_camera_bobbing(time_elapsed, freq, amp), 0.25 * delta)
	else:
		cam_offset = cam_offset.move_toward(Vector3.ZERO, 0.25 * delta)
	
	# Adds small delay between mouse movement and camera reacting
	var current_rotation: Vector3 = Vector3(rotation.x, player_body.rotation.y, rotation.z)
	get_tree().create_timer(0.05).timeout.connect(func(): previous_rotation = current_rotation)
	get_tree().create_timer(0.1).timeout.connect(func(): player_torch.global_rotation = current_rotation)
	
	_handle_blur(delta)
	
	position = cam_offset + start_pos


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion && !player_body.inventory_open:
		wanted_dir.x -= event.relative.x * mouse_sensitivity
		wanted_dir.y = clampf(wanted_dir.y - (event.relative.y * mouse_sensitivity), -LOOK_LIMIT, LOOK_LIMIT)
		player_body.velocity = player_body.velocity.rotated(Vector3.UP, -event.relative.x * mouse_sensitivity)


func _handle_blur(delta: float) -> void:
	var lerp_speed: float = 10
	blur_cast.target_position.z = blur_range
	
	if blur_cast.is_colliding():
		var origin = blur_cast.global_transform.origin
		var collision_point = blur_cast.get_collision_point()
		var dist = origin.distance_to(collision_point)
		
		attributes.dof_blur_far_distance = lerpf(attributes.dof_blur_far_distance, blur_far_min * dist, delta * lerp_speed)
		attributes.dof_blur_near_distance = lerpf(attributes.dof_blur_near_distance, blur_near_min, delta * lerp_speed)
		
	else:
		attributes.dof_blur_far_distance = lerpf(attributes.dof_blur_far_distance, blur_far_max, delta * lerp_speed)
		attributes.dof_blur_near_distance = lerpf(attributes.dof_blur_near_distance, blur_near_max, delta * lerp_speed)


func _handle_camera_bobbing(time_elapsed: float, freq: float, amp: float) -> Vector3:
	var offset: Vector3 = Vector3.ZERO
	offset.x = (sin(time_elapsed) * amp) + (sin((time_elapsed + 0.5) * (freq)) * 0.025)
	offset.y = (sin(time_elapsed * freq) * amp) + (sin((time_elapsed + 0.5) * (freq * 2)) * 0.025)
	return offset
