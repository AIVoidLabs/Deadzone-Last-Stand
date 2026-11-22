shader_type canvas_item;
// Ekran arkası: ucuz mip bulanıklığı + karartma + sıcak ton + vinyet + tane.

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform float blur_lod = 3.0;
uniform float dim = 0.6;
uniform float vignette = 0.85;

void fragment() {
	vec3 c;
	if (blur_lod > 0.01) {
		vec2 px = SCREEN_PIXEL_SIZE * exp2(blur_lod) * 0.7;
		c = textureLod(screen_tex, SCREEN_UV, blur_lod).rgb * 0.3;
		for (int i = 0; i < 8; i++) {
			float a = float(i) * 0.7853982;
			c += textureLod(screen_tex, SCREEN_UV + vec2(cos(a), sin(a)) * px, blur_lod).rgb * 0.0875;
		}
	} else {
		c = textureLod(screen_tex, SCREEN_UV, 0.0).rgb;
	}
	float l = dot(c, vec3(0.3, 0.55, 0.15));
	c = mix(c, vec3(l), 0.35);
	c *= vec3(1.08, 0.9, 0.78);
	c *= 1.0 - dim;
	float v = smoothstep(0.3, 0.95, length((SCREEN_UV - 0.5) * vec2(1.15, 1.0) * 1.45));
	c = mix(c, vec3(0.02, 0.012, 0.01), v * vignette);
	float g = texture(noise_tex, FRAGCOORD.xy / 256.0).g;
	c += (g - 0.5) * 0.05 * (0.4 + dim);
	COLOR = vec4(max(c, vec3(0.0)), 1.0);
}
