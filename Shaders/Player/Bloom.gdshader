shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float threshold : hint_range(0.0, 5.0) = 1.0;
uniform float soft_knee : hint_range(0.0, 1.0) = 0.5;
uniform float strength  : hint_range(0.0, 4.0) = 1.2;
uniform int   taps      : hint_range(4, 64) = 24;
uniform float length_px : hint_range(0.0, 2000.0) = 140.0;
uniform float falloff   : hint_range(0.5, 0.99) = 0.86;
uniform vec3  tint_top    = vec3(0.95, 1.00, 0.98);
uniform vec3  tint_bottom = vec3(1.00, 0.95, 0.98);
uniform bool  clamp_output = true;

// New: control horizontal width independent of highlight width
uniform float width_px : hint_range(0.0, 16.0) = 1.0;     // Gaussian half-width of visible smear
uniform float column_pitch_px : hint_range(1.0, 16.0) = 1.0; // Column snap spacing (1 = 1px)
uniform bool  snap_columns = true;
uniform bool  gaussian_profile = true;                    // true=gaussian, false=soft box
uniform int   peak_search_px : hint_range(0, 8) = 0;      // Optional: find local brightest column within +/- N px

vec3 prefilter(vec3 c) {
	float l = max(max(c.r, c.g), c.b);
	float knee = max(threshold * soft_knee, 1e-6);
	float w = smoothstep(threshold - knee, threshold + knee, l);
	return c * w;
}

float prefilter_luma(vec2 uv) {
	vec3 p = prefilter(texture(screen_texture, uv).rgb);
	return max(max(p.r, p.g), p.b);
}

void fragment() {
	vec4 src = texture(screen_texture, SCREEN_UV);
	vec3 color = src.rgb;

	if (taps <= 0 || length_px <= 0.0 || strength <= 0.0) {
		COLOR = src;
	}

	// Column snapping: pick a column center to sample along vertically
	float pitch_uv = SCREEN_PIXEL_SIZE.x * max(column_pitch_px, 1.0);
	float snap_x = snap_columns
		? floor(SCREEN_UV.x / pitch_uv + 0.5) * pitch_uv
		: SCREEN_UV.x;

	// Optional: shift to the brightest column near the snapped one
	if (peak_search_px > 0) {
		float best_l = -1.0;
		float best_x = snap_x;
		// Search within +/- peak_search_px pixels
		for (int k = -8; k <= 8; k++) {
			if (abs(k) > peak_search_px) continue;

			float off = float(k) * SCREEN_PIXEL_SIZE.x;
			float l = prefilter_luma(vec2(snap_x + off, SCREEN_UV.y));

			if (l > best_l) {
				best_l = l;
				best_x = snap_x + off;
			}
		}
		snap_x = best_x;
	}

	// Horizontal weight so the smear only shows within width_px of the chosen column
	float dx_uv = SCREEN_UV.x - snap_x;
	float dx_px = abs(dx_uv) / SCREEN_PIXEL_SIZE.x;
	float h_weight = 1.0;
	if (width_px > 0.0) {
		if (gaussian_profile) {
			float s = dx_px / max(width_px, 1e-6);
			h_weight = exp(-0.5 * s * s);
		} else {
			// Soft box profile
			float t = clamp(dx_px / max(width_px, 1e-6), 0.0, 1.0);
			h_weight = 1.0 - t * t * (3.0 - 2.0 * t); // smoothstep(0->1)
		}
	}

	// Vertical sampling
	vec2 texel = vec2(0.0, SCREEN_PIXEL_SIZE.y);
	float step_px = length_px / float(taps);
	vec2 step_uv = texel * step_px;

	vec3 acc = vec3(0.0);
	float w = 1.0;
	float wsum = 0.0;

	vec2 uv_up = vec2(snap_x, SCREEN_UV.y);
	vec2 uv_dn = vec2(snap_x, SCREEN_UV.y);

	for (int i = 1; i <= 64; i++) {
		if (i > taps) break;

		uv_up -= step_uv;
		uv_dn += step_uv;

		vec3 s_up = prefilter(texture(screen_texture, uv_up).rgb);
		vec3 s_dn = prefilter(texture(screen_texture, uv_dn).rgb);

		acc += s_up * w * tint_top;
		acc += s_dn * w * tint_bottom;

		wsum += 2.0 * w;
		w *= falloff;
	}

	vec3 streak = acc / max(wsum, 1e-5);
	vec3 outc = color + streak * strength * h_weight;

	if (clamp_output) {
		outc = clamp(outc, vec3(0.0), vec3(1.0));
	}

	COLOR = vec4(outc, src.a);
}