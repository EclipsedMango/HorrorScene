class_name Item extends Resource

@export var item_name: String = "New Item"
@export_multiline var description: String = ""
@export var texture: Texture2D

@export var size: Vector2i = Vector2i(1, 1)

@export var stackable: bool = false
@export var max_stack_size: int = 1
