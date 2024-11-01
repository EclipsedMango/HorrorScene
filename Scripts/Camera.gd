extends Camera3D

# Variables to control the shake intensity and speed
var shake_intensity: float = 0.2 # Controls how far the camera shakes
var shake_speed: float = 20.0 # Controls how fast the camera shakes

# Internal time tracker
var time_elapsed: float = 0.0

func _process(delta):
	time_elapsed += delta * shake_speed

	# Calculate small random offsets
	var x_offset = (noise(time_elapsed) - 0.5) * shake_intensity
	var y_offset = (noise(time_elapsed + 100.0) - 0.5) * shake_intensity
	var z_offset = (noise(time_elapsed + 200.0) - 0.5) * shake_intensity

	# Apply offsets to the camera position
	position = Vector3(x_offset, y_offset, z_offset)

# Simple noise function for randomized shake
func noise(seed: float) -> float:
	return (sin(seed * 1234.5678) * 43758.5453)
