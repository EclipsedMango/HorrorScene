extends SubViewportContainer

@onready var outline_viewport: SubViewport = $OutlineViewport


func _ready():
	material.set_shader_parameter("screen_texture", outline_viewport.get_texture())
