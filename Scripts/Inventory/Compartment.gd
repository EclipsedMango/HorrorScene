class_name Compartment

signal compartment_changed(slots: Array[Vector2i])

# Compartment size.
var size: Vector2i = Vector2i(0, 0)

# Null == Empty.
var grid: Array = []

var items: Dictionary = {}


func _init(size: Vector2i) -> void:
	self.size = size
	
	grid.resize(size.y)
	
	for y: int in range(size.y):
		grid[y] = []
		grid[y].resize(size.x)
		
		for x: int in range(size.x):
			grid[y][x] = null


func can_place_item(item: Item, pos: Vector2i) -> bool:
	if item == null:
		return true
	
	# Left and top of item
	if pos.x < 0 or pos.y < 0:
		return false
	
	# Right and bottom of item
	if pos.x + item.size.x > size.x || pos.y + item.size.y > size.y:
		return false
	
	for y: int in range(item.size.y):
		for x: int in range(item.size.x):
			if grid[pos.y + y][pos.x + x] != null:
				return false
	
	return true


func add_item(item: Item) -> bool:
	for y: int in range(size.y):
		for x: int in range(size.x):
			var position = Vector2i(x, y)
			if set_item(item, position):
				return true
	
	return false


func set_item(item: Item, slot: Vector2i) -> bool:
	if item == null:
		return remove_item(slot)
	
	if !can_place_item(item, slot):
		return false
	
	_perform_placement(item, slot)
	return true


func remove_item(pos: Vector2i) -> bool:
	pos = get_item_pos(pos)
	
	if !items.has(pos):
		return false
	
	var item: Item = items[pos]
	items.erase(pos)
	
	var changed_slots: Array[Vector2i] = []
	
	for y: int in range(item.size.y):
		for x: int in range(item.size.x):
			grid[pos.y + y][pos.x + x] = null
			changed_slots.append(Vector2i(pos.x + x, pos.y + y))
	
	compartment_changed.emit(changed_slots)
	return true


func get_item(pos: Vector2i) -> Item:
	return grid[pos.y][pos.x]


func get_item_pos(pos: Vector2i) -> Vector2i:
	for slot: Vector2i in items:
		var item: Item = items[slot]
		if pos.x >= slot.x && pos.x < slot.x + item.size.x && \
				pos.y >= slot.y && pos.y < slot.y + item.size.y:
			return slot
	
	return pos


func _perform_placement(item: Item, pos: Vector2i):
	items[pos] = item
	
	var changed_slots: Array[Vector2i] = []
	
	for y: int in range(item.size.y):
		for x: int in range(item.size.x):
			grid[pos.y + y][pos.x + x] = item
			changed_slots.append(Vector2i(pos.x + x, pos.y + y))
	
	compartment_changed.emit(changed_slots)
