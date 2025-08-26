shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Anti fish eye (negative amount) / fish eye (positive)
uniform float effect_amount : hint_range(-2.5, 2.5) = 1.75;

void fragment() {
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec4 fragCoord = FRAGCOORD;

	// Normalized coords
	vec2 ndc = fragCoord.xy / resolution.x;
	float aspect = resolution.x / resolution.y;

	vec2 centeredAspect = vec2(0.5, 0.5 / aspect);
	vec2 d = ndc - centeredAspect;
	float h = sqrt(dot(d, d));
	float power = effect_amount;

	//radius of 1:1 effect
	float bind;

	if (power > 0.0) {
		bind = sqrt(dot(centeredAspect, centeredAspect));
	} else {
		if (aspect < 1.0) {
			bind = centeredAspect.x;
		} else {
			bind = centeredAspect.y;
		}
	}

	vec2 uv;
	if (power > 0.0) {
		uv = centeredAspect + normalize(d) * tan(h * power) * bind / tan( bind * power);
	} else if (power < 0.0) {
		uv = centeredAspect + normalize(d) * atan(h * -power * 10.0) * bind / atan(-power * bind * 10.0);
	} else {
		uv = ndc;
	}
	uv.y *= aspect;

	vec4 fishScreenTexture = texture(SCREEN_TEXTURE, uv);

	vec3 col = texture(SCREEN_TEXTURE, uv).rgb;

	COLOR = vec4(col, 1.0);
}
