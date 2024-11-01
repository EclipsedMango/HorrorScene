// This shader is the only shader created by, the other shaders have credit at the top.
shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture;

uniform float RedOffset: hint_range(-1.0, 1.0, 0.001);
uniform float GreenOffset: hint_range(-1.0, 1.0, 0.001);
uniform float BlueOffset: hint_range(-1.0, 1.0, 0.001);

void fragment() {
	vec4 ScreenTexture = texture(SCREEN_TEXTURE, SCREEN_UV);
	float distToEdge = distance(UV, vec2(0.5));

	// Simple Vignette thats effected by color of pixel.
	float vigDist = (distToEdge - 0.5);
	vec4 Vignette = vec4(ScreenTexture.r - vigDist, ScreenTexture.g - vigDist, ScreenTexture.b - vigDist, 1.0);

	// Simple Chromatic Abberation
	vec4 r = texture(SCREEN_TEXTURE, SCREEN_UV - RedOffset);
	vec4 g = texture(SCREEN_TEXTURE, SCREEN_UV - GreenOffset);
	vec4 b = texture(SCREEN_TEXTURE, SCREEN_UV - BlueOffset);
	vec4 ChromaticAbberation = vec4(r.r, g.g, b.b, 1.0);
	vec4 finalOutput = Vignette * ChromaticAbberation;

	COLOR = finalOutput;
}