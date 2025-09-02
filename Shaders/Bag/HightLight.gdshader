shader_type spatial;
render_mode unshaded;

uniform vec4 outline_color : source_color;
uniform float outline_width = 1.0;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture;
uniform sampler2D NORMAL_TEXTURE : hint_normal;

void fragment() {
    vec2 pixel_size = 1.0 / VIEWPORT_SIZE;
    vec3 base_col = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;

    float center_depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
    vec3 center_normal = texture(NORMAL_TEXTURE, SCREEN_UV).rgb;

    float edge = 0.0;

    for(int y = -1; y <= 1; y++) {
        for(int x = -1; x <= 1; x++) {
            vec2 offset = vec2(float(x),float(y)) * pixel_size * outline_width;

            float sample_depth = texture(DEPTH_TEXTURE, SCREEN_UV + offset).r;
            vec3 sample_normal = texture(NORMAL_TEXTURE, SCREEN_UV + offset).rgb;

            // detect depth discontinuity
            if (abs(sample_depth - center_depth) > 0.002) {
                edge = 1.0;
            }

            // detect normal discontinuity
            if (distance(sample_normal, center_normal) > 0.2) {
                edge = 1.0;
            }
        }
    }

    if (edge > 0.0) {
        ALBEDO = outline_color.rgb;
    } else {
        ALBEDO = base_col;
    }
}