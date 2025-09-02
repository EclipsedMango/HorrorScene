shader_type canvas_item;

// If you are reading this, yeah I used ai because im too lazy to combine the three shaders i had.
// I don't like the comments it leaves but cbf cleaning this file up.

// This is the one and only texture we need to read from.
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

//==============================================================
// UNIFORMS (Gathered from all 3 shaders and prefixed for clarity)
//==============================================================

group_uniforms General;
uniform float darken_multiply : hint_range(0.0, 1.0, 0.1);

group_uniforms Fisheye;
// Anti fish eye (negative amount) / fish eye (positive)
uniform float fisheye_amount : hint_range(-2.5, 2.5) = 1.75;

group_uniforms ChromaticAberration;
uniform float ca_red_offset: hint_range(-0.1, 0.1, 0.001) = 0.003;
uniform float ca_green_offset: hint_range(-0.1, 0.1, 0.001) = 0.001;
uniform float ca_blue_offset: hint_range(-0.1, 0.1, 0.001) = 0.0;
uniform float ca_intensity: hint_range(0.0, 10.0, 0.1) = 1.0;

group_uniforms Vignette;
// A simple intensity control for the vignette.
uniform float vignette_intensity : hint_range(0.0, 2.0, 0.1) = 1.0;

group_uniforms VHS_Effect;
uniform vec2 vhs_resolution = vec2(1500.0, 1500.0);
uniform int vhs_samples = 3;
uniform float vhs_crease_noise: hint_range(0.0, 2.0, 0.1) = 1.0;
uniform float vhs_crease_opacity: hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float vhs_filter_intensity: hint_range(0.0, 1.0, 0.1) = 0.0;
uniform sampler2D vhs_noise_texture: filter_linear_mipmap, repeat_enable;

group_uniforms VHS_TapeCrease;
uniform float vhs_tape_crease_smear: hint_range(0.0, 2.0, 0.1) = 0.2;
uniform float vhs_tape_crease_intensity: hint_range(0.0, 1.0, 0.1) = 0.1;
uniform float vhs_tape_crease_jitter: hint_range(0.0, 1.0, 0.01) = 0.10;
uniform float vhs_tape_crease_speed: hint_range(-2.0, 2.0, 0.1) = 0.5;
uniform float vhs_tape_crease_discoloration: hint_range(0.0, 2.0, 0.1) = 0.0;

group_uniforms VHS_BottomBorder;
uniform float vhs_bottom_border_thickness: hint_range(0.0,32.0, 0.1) = 3.0;
uniform float vhs_bottom_border_jitter: hint_range(0.0, 24.0, 0.5) = 6.0;

group_uniforms VHS_Noise;
uniform float vhs_noise_intensity: hint_range(0.0, 1.0, 0.1) = 0.2;


//==============================================================
// HELPER FUNCTIONS (Gathered from VHS shader)
//==============================================================

float v2random(vec2 uv) {
	// Make sure to assign your noise texture to the uniform in the Inspector!
	return texture(vhs_noise_texture, mod(uv, vec2(1.0))).x;
}

mat2 rotate2D(float t) {
	return mat2(vec2(cos(t), sin(t)), vec2(-sin(t), cos(t)));
}

vec3 rgb2yiq(vec3 rgb) {
	return mat3(vec3(0.299, 0.596, 0.211), vec3(0.587, -0.274, -0.523), vec3(0.114, -0.322, 0.312)) * rgb;
}

vec3 yiq2rgb(vec3 yiq) {
	return mat3(vec3(1.0, 1.0, 1.0), vec3(0.956, -0.272, -1.106), vec3(0.621, -0.647, 1.703)) * yiq;
}


//==============================================================
// MAIN FRAGMENT SHADER
//==============================================================

void fragment() {

    //----------------------------------------------------------
    // STAGE 1: UV MANIPULATION (Fisheye + VHS Jitter)
    // We calculate the final texture coordinate we need to sample from.
    //----------------------------------------------------------

    // --- 1a. Fisheye Calculation ---
    vec2 fisheye_uv;
    vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 ndc = FRAGCOORD.xy / resolution.xy;
	float aspect = resolution.x / resolution.y;

	vec2 centeredAspect = vec2(0.5, 0.5); // Using 0.5, 0.5 for standard screen UV space
	vec2 d = ndc - centeredAspect;
	float rr = length(d);
	float power = fisheye_amount;
	float bind = sqrt(dot(centeredAspect, centeredAspect));

	if (power > 0.0) {
		fisheye_uv = centeredAspect + normalize(d) * tan(rr * power) * bind / tan(bind * power);
	} else if (power < 0.0) {
		fisheye_uv = centeredAspect + normalize(d) * atan(rr * -power * 10.0) * bind / atan(-power * bind * 10.0);
	} else {
		fisheye_uv = ndc;
	}

    // --- 1b. VHS UV Distortion ---
    vec2 final_uv = fisheye_uv; // Start with the result of the fisheye

    // Tape wave.
	final_uv.x += (v2random(vec2(final_uv.y / 10.0, TIME / 10.0) / 1.0) - 0.5) / vhs_resolution.x * 1.0;
	final_uv.x += (v2random(vec2(final_uv.y, TIME * 10.0)) - 0.5) / vhs_resolution.x * 1.0;

	// Tape crease calculations (we need tc_phase and tc_noise for color grading later).
	float tc_phase = smoothstep(0.9, 0.96, sin(final_uv.y * 8.0 - (TIME * vhs_tape_crease_speed + vhs_tape_crease_jitter * v2random(TIME * vec2(0.67, 0.59))) * PI * 1.2));
	float tc_noise = smoothstep(0.3, 1.0, v2random(vec2(final_uv.y * 4.77, TIME)));
	float tc = tc_phase * tc_noise;
	final_uv.x = final_uv.x - tc / vhs_resolution.x * 8.0 * vhs_tape_crease_smear;

	// Switching noise (bottom bar).
	float sn_phase = smoothstep(1.0 - vhs_bottom_border_thickness / vhs_resolution.y, 1.0, final_uv.y);
	final_uv.x += sn_phase * (v2random(vec2(final_uv.y * 100.0, TIME * 10.0)) - 0.5) / vhs_resolution.x * vhs_bottom_border_jitter;

    //----------------------------------------------------------
    // STAGE 2: SAMPLING (Chromatic Aberration)
    // Using our final distorted UV, we sample the original texture.
    //----------------------------------------------------------

    vec2 red_uv = final_uv - vec2(ca_red_offset * ca_intensity, 0.0);
	vec2 green_uv = final_uv - vec2(ca_green_offset * ca_intensity, 0.0);
	vec2 blue_uv = final_uv - vec2(ca_blue_offset * ca_intensity, 0.0);

	float r = texture(SCREEN_TEXTURE, red_uv).r;
	float g = texture(SCREEN_TEXTURE, green_uv).g;
	float b = texture(SCREEN_TEXTURE, blue_uv).b;

    // This is our starting color for the color grading stage.
	vec3 color = vec3(r, g, b);


    //----------------------------------------------------------
    // STAGE 3: COLOR GRADING (Vignette + VHS Color Effects)
    // Now we apply effects that modify the color we just fetched.
    //----------------------------------------------------------

    // --- 3a. Vignette ---
	// Vignette (darkens corners, keeps center clean)
	float dist_to_center = distance(SCREEN_UV, vec2(0.5));
	float vignette = 1.0 - smoothstep(0.15, 0.75, dist_to_center); // adjust 0.5/0.75
	color *= mix(1.0, vignette, vignette_intensity);

    // --- 3b. VHS Color Effects ---
    // Crease noise
	float cn = tc_noise * vhs_crease_noise * (0.7 * tc_phase * vhs_tape_crease_intensity + 0.3);
	if (0.29 < cn) {
		vec2 V = vec2(0.0, vhs_crease_opacity);
		vec2 uvt = (final_uv + V.yx * v2random(vec2(final_uv.y, TIME))) * vec2(0.1, 1.0);
		float n0 = v2random(uvt);
		float n1 = v2random(uvt + V.yx / vhs_resolution.x);
		if (n1 < n0) {
			color = mix(color, 2.0 * V.yyy, pow(n0, 10.0));
		}
	}

    // AC beat
	color *= 1.0 + 0.1 * smoothstep(0.4, 0.6, v2random(vec2(0.0, 0.1 * (SCREEN_UV.y + TIME * 0.2)) / 10.0));

	// Color noise
	color *= 1.0 - vhs_noise_intensity * 0.5 + vhs_noise_intensity * texture(vhs_noise_texture, mod(final_uv * vec2(1.0, 1.0) + TIME * vec2(5.97, 4.45), vec2(1.0))).xyz;
	color = clamp(color, 0.0, 1.0);

	// Final YIQ color space transform
	color = rgb2yiq(color);
	color = vec3(0.9, 1.1, 1.5) * color + vec3(0.1, -0.1, 0.0) * vhs_filter_intensity;
	color = yiq2rgb(color);


    //----------------------------------------------------------
    // STAGE 4: FINAL OUTPUT
    //----------------------------------------------------------
	COLOR = vec4(clamp(color, 0.0, 1.0) * darken_multiply, 1.0);
}