extends CharacterBody3D


const SPEED = 2
const MOUSE_SENSITIVITY: float = 0.001
const LOOK_LIMIT: float = PI / 2

@onready var head: Camera3D = $Head
@onready var player_torch: SpotLight3D = $Head/PlayerTorch
@onready var debug_info: Label = $ScreenEffects/DebugInfo/DebugInfo

var walk_time: float = 0
var stamina: float = 15
var current_fov: float = 0
var is_screen_shaking: bool = false
var is_sprinting: bool = false

var wanted_dir: Vector2 = Vector2.ZERO
var previous_rotation: Vector3 = Vector3.ZERO

var noise: Noise = FastNoiseLite.new()


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	player_torch.visible = false
	current_fov = head.fov


func _process(delta: float) -> void:
	head.rotation.z = angle_difference(rotation.y, previous_rotation.y) * 0.25
	rotation.y = lerp_angle(rotation.y, wanted_dir.x, delta * 15.0) 
	head.rotation.x = lerp_angle(head.rotation.x, wanted_dir.y, delta * 15.0)
	
	if is_screen_shaking:
		if is_sprinting:
			walk_time += delta * 2.0
		
		walk_time += delta
		head.rotation.z += noise.get_noise_1d(walk_time * 75.0) * 0.1
	
	var current_rotation: Vector3 = Vector3(head.rotation.x, rotation.y, head.rotation.z)
	get_tree().create_timer(0.075).timeout.connect(func(): previous_rotation = current_rotation)


func _physics_process(delta: float) -> void:
	var vel: Vector2 = Vector2(velocity.x, velocity.z)
	
	# Add the gravity.
	if !is_on_floor():
		velocity.y -= (delta * 1.5)
	
	var speed: float = SPEED
	is_sprinting = false
	
	# Sprinting
	if Input.is_action_pressed("shift") && stamina >= 0:
		speed *= 2
		is_sprinting = true
		stamina -= 10 * delta
	elif stamina <= 15:
		stamina += 4 * delta

	if is_sprinting:
		head.fov = move_toward(head.fov, current_fov + 10, 40 * delta)
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

	if Input.is_action_just_pressed("mouse_up") && current_fov > 50:
		current_fov -= 1
	elif Input.is_action_just_pressed("mouse_down") && current_fov < 75:
		current_fov += 1

	debug_info.text = str("Speed: ", vel.length(), "\nStamina: ", stamina, "\nVelocity: ", velocity, "\nPos: ", global_position, "\nFOV: ", head.fov, "\nCamRotation: ", head.rotation)

	move_and_slide()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		wanted_dir.x -= event.relative.x * MOUSE_SENSITIVITY
		wanted_dir.y = clampf(wanted_dir.y - (event.relative.y * MOUSE_SENSITIVITY), -LOOK_LIMIT, LOOK_LIMIT)
		velocity = velocity.rotated(Vector3.UP, -event.relative.x * MOUSE_SENSITIVITY)
