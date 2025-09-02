class_name CompartmentUI extends GridContainer

const SLOT_UI = preload("res://Scenes/Player/SlotUI.tscn")

# Compartment size.
@export var compartment_size: Vector2i = Vector2i(5, 5)
@export var grid_size: int = 150
@export var padding: Vector2i = Vector2i.ONE * 8
@export var test_item: Item
@export var test_item2: Item

@onready var compartment: Compartment = Compartment.new(compartment_size)

var cursor_item: Item = null
var clicked_pos: Vector2i = Vector2.ZERO

func _ready() -> void:
	columns = compartment_size.x
	
	for y: int in range(compartment.size.y):
		for x: int in range(compartment.size.x):
			var slot_ui: Node = SLOT_UI.instantiate()
			add_child(slot_ui)
			slot_ui.gui_input.connect(_item_gui_input.bind(Vector2i(x, y)))
	
	compartment.compartment_changed.connect(_compartment_changed.unbind(1))


func _compartment_changed() -> void:
	queue_redraw()


# TODO: remove this when item and cursor_item rendering are seperated from container.
func _process(delta: float) -> void:
	queue_redraw()


func _item_gui_input(event: InputEvent, pos: Vector2i) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(event.pressed)
			
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			compartment.set_item(test_item, pos)
			
		else:
			compartment.set_item(test_item2, pos)


func _handle_left_click(pressed: bool) -> void:
	var pos: Vector2i = get_local_mouse_position() / (grid_size + get_theme_constant("h_separation"))
	if pos.x >= compartment_size.x || pos.x < 0 || pos.y >= compartment_size.y || pos.y < 0:
		return
	
	if (cursor_item != null) == pressed:
		return
	
	var item_under_mouse: Item = compartment.get_item(pos)
	var target_pos: Vector2i = compartment.get_item_pos(pos)
	
	# If cursor empty
	if cursor_item == null:
		clicked_pos = pos - target_pos
		compartment.remove_item(target_pos)
		cursor_item = item_under_mouse
		return
	
	var place_pos = pos - clicked_pos
	var valid_move = false
	
	compartment.remove_item(target_pos)
	valid_move = compartment.can_place_item(cursor_item, place_pos)
	compartment.set_item(item_under_mouse, target_pos)
	
	# TODO: the move was invalid add an animation or something idk.
	if !valid_move:
		return
	
	# Swap items.
	compartment.remove_item(target_pos)
	compartment.set_item(cursor_item, place_pos)
	
	cursor_item = item_under_mouse
	clicked_pos = pos - target_pos


func _handle_left_click_release(pos: Vector2i) -> void:
	pass


func _draw() -> void:
	for slot: Vector2i in compartment.items:
		var item: Item = compartment.items[slot]
		var pos: Vector2i = slot * (grid_size + get_theme_constant("h_separation")) + padding
		
		draw_texture_rect(item.texture, Rect2(pos, _get_item_size(item.size)), false)
	
	if cursor_item != null:
		draw_texture_rect(cursor_item.texture, Rect2(
					get_local_mouse_position() - grid_size * 0.5 * (Vector2i.ONE + clicked_pos * 2), 
					_get_item_size(cursor_item.size)
				), false)


func _get_item_size(item_size: Vector2i) -> Vector2i:
	return item_size * grid_size + get_theme_constant("h_separation") * (item_size - Vector2i.ONE) - padding * 2
