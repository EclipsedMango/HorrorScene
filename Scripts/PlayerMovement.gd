extends CharacterBody3D


const LOOK_LIMIT: float = PI / 2

@export_group("Movement")
@export var SPEED: float = 2
@export var sprint_multiplier: float = 2.25
@export var max_stamina: float = 15
@export var stamina: float = 15
@export var stamina_regen_amount: float = 2
@export var stamina_regen_wait: float = 1.5

@export_group("Camera")
@export var MOUSE_SENSITIVITY: float = 0.001
@export var zoom_max: float = 50
@export var zoom_min: float = 75
@export var sprinting_fov_amount: float = 10

@onready var head: Camera3D = $Head
@onready var player_torch: SpotLight3D = $Head/PlayerTorch
@onready var debug_info: Label = $ScreenEffects/DebugInfo/DebugInfo

var walk_time: float = 0
var current_fov: float = 0
var is_screen_shaking: bool = false
var is_sprinting: bool = false
var stamina_check: bool = false
var capture_mouse: bool = false

var wanted_dir: Vector2 = Vector2.ZERO
var previous_rotation: Vector3 = Vector3.ZERO

var noise: Noise = FastNoiseLite.new()


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	current_fov = head.fov
	
	player_torch.visible = false
	stamina_check = false


func _process(delta: float) -> void:
	# Adds small delay between mouse movement and camera reacting
	head.rotation.z = angle_difference(rotation.y, previous_rotation.y) * 0.25
	rotation.y = lerp_angle(rotation.y, wanted_dir.x, delta * 15.0) 
	head.rotation.x = lerp_angle(head.rotation.x, wanted_dir.y, delta * 15.0)
	
	# Adds screen shake while moving
	if is_screen_shaking:
		# Increase screen shake while sprinting
		if is_sprinting:
			walk_time += delta * 2.0
		
		walk_time += delta
		head.rotation.z += noise.get_noise_1d(walk_time * 75.0) * 0.1
	
	if Input.is_action_just_pressed("escape"):
		capture_mouse = !capture_mouse
		
		if capture_mouse:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Adds small delay between mouse movement and camera reacting
	var current_rotation: Vector3 = Vector3(head.rotation.x, rotation.y, head.rotation.z)
	get_tree().create_timer(0.05).timeout.connect(func(): previous_rotation = current_rotation)
	get_tree().create_timer(0.1).timeout.connect(func(): player_torch.global_rotation = current_rotation)


func _physics_process(delta: float) -> void:
	var vel: Vector2 = Vector2(velocity.x, velocity.z)
	
	# Add the gravity
	if !is_on_floor():
		velocity.y -= (delta * 1.5)
	
	var speed: float = SPEED
	is_sprinting = false
	
	# Adds a delay before stamina regen
	if Input.is_action_just_released("shift"):
		stamina_check = false
		get_tree().create_timer(stamina_regen_wait).timeout.connect(func(): stamina_check = true)
	
	# Sprinting
	if Input.is_action_pressed("shift") && stamina > 0:
		speed *= sprint_multiplier
		is_sprinting = true
		stamina -= 10 * delta
	elif stamina < max_stamina:
		# Stamina Regen
		if stamina_check == true:
			stamina += stamina_regen_amount * delta

	# FOV increase while sprinting
	if is_sprinting:
		head.fov = move_toward(head.fov, current_fov + sprinting_fov_amount, 40 * delta)
	else:
		head.fov = move_toward(head.fov, current_fov, 40 * delta)

	var input_dir := Input.get_vector("a", "d", "w", "s")
	var direction := (Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, wanted_dir.x)).normalized()
	
	if direction:
		is_screen_shaking = true
		
		var dir := Vector2(direction.x, direction.z) * speed
		var newVel := vel.move_toward(dir, 15 * delta)
		
		if vel.length() > 0.1 && abs(dir.angle() - vel.angle()) > TAU / 8.0:
			newVel = dir
		
		vel = newVel
	else:
		is_screen_shaking = false
		vel = vel.move_toward(Vector2.ZERO, 30 * delta)

	velocity.x = vel.x
	velocity.z = vel.y

	if Input.is_action_just_pressed("f"):
		player_torch.visible = !player_torch.visible

	# FOV zoom to mimic zooming on a camera
	if Input.is_action_just_pressed("mouse_up") && current_fov > zoom_max:
		current_fov -= 1
	elif Input.is_action_just_pressed("mouse_down") && current_fov < zoom_min:
		current_fov += 1

	# Important testing info
	debug_info.text = str("Speed: ", vel.length(), "\nStamina: ", stamina, "\nVelocity: ", velocity, "\nPos: ", global_position, "\nFOV: ", head.fov, "\nCamRotation: ", head.rotation)

	move_and_slide()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		wanted_dir.x -= event.relative.x * MOUSE_SENSITIVITY
		wanted_dir.y = clampf(wanted_dir.y - (event.relative.y * MOUSE_SENSITIVITY), -LOOK_LIMIT, LOOK_LIMIT)
		velocity = velocity.rotated(Vector3.UP, -event.relative.x * MOUSE_SENSITIVITY)
