shader_type canvas_item;
// Yazıda aşınma: gürültüyle küçük boşluklar (okunaklılık için hafif).

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform float wear = 0.55;
uniform float scale = 170.0;

void fragment() {
	vec2 p = FRAGCOORD.xy / scale;
	float g = texture(noise_tex, p * 2.3).g;
	float r = texture(noise_tex, p * 0.9 + vec2(0.37, 0.11)).r;
	float eroded = smoothstep(0.30, 0.45, g * 0.6 + r * 0.6);
	COLOR.a *= 1.0 - (1.0 - eroded) * wear * (0.55 + 0.45 * step(0.55, r));
}
