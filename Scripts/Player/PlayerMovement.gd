extends CharacterBody3D

enum State { IDLE, WALKING, SPRINTING }

signal inventory_interaction(action: bool) # If inv opened action == true

@export_group("Movement")
@export var SPEED: float = 2.0
@export var sprint_multiplier: float = 2.25

@export_group("Stamina")
@export var max_stamina: float = 15.0
@export var stamina_depletion_rate: float = 10.0
@export var stamina_regen_rate: float = 4.0
@export var stamina_regen_cooldown: float = 1.5

@export_group("Camera")
@export var mouse_sensitivity: float = 0.001
@export var zoom_max: float = 50
@export var zoom_min: float = 75
@export var sprinting_fov_amount: float = 10

@onready var inventory: CanvasLayer = %Inventory

var current_state: State = State.IDLE
var stamina: float = 15.0

var inventory_open: bool = false

var _stamina_regen_timer: float = 0.0
var _input_dir := Vector2.ZERO

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	inventory.visible = false
	
	stamina = max_stamina


func _unhandled_input(event: InputEvent) -> void:
	_input_dir = Input.get_vector("a", "d", "w", "s")


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("escape"):
		inventory_open = !inventory_open
		
		if inventory_open:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			inventory.visible = true
			inventory_interaction.emit()
			
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			inventory.visible = false
			inventory_interaction.emit()
	


func _physics_process(delta: float) -> void:
	_update_state()
	
	match current_state:
		State.IDLE:
			_handle_stamina_regen(delta)
		State.WALKING:
			_handle_stamina_regen(delta)
		State.SPRINTING:
			stamina = max(stamina - stamina_depletion_rate * delta, 0)
			_stamina_regen_timer = stamina_regen_cooldown
	
	_apply_movement(delta)


func _apply_movement(delta: float):
	if !is_on_floor():
		velocity.y -= 9.8 * delta
	
	# Determine speed based on state
	var current_speed = SPEED
	if current_state == State.SPRINTING:
		current_speed *= sprint_multiplier
	
	var direction = (transform.basis * Vector3(_input_dir.x, 0, _input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()


func _update_state():
	var is_moving = _input_dir != Vector2.ZERO and is_on_floor()
	var wants_to_sprint = is_moving and Input.is_action_pressed("shift") and stamina > 0
	
	if wants_to_sprint:
		current_state = State.SPRINTING
	elif is_moving:
		current_state = State.WALKING
	else:
		current_state = State.IDLE


func _handle_stamina_regen(delta: float):
	if _stamina_regen_timer > 0:
		_stamina_regen_timer -= delta
	elif stamina < max_stamina:
		stamina = min(stamina + stamina_regen_rate * delta, max_stamina)
