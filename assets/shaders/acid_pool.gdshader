shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
// Asit havuzu (tükürücü): yerde yeşil parlayan daire, kenarı yumuşak, kabarcıklı. fade 0..1: son saniyede söner.
// seed: havuz başına kabarcık düzeni ve zamanı farklı olsun.

uniform vec4 acid_color : source_color = vec4(0.3, 0.85, 0.15, 1.0);
uniform vec4 core_color : source_color = vec4(0.65, 1.0, 0.3, 1.0);
uniform float max_alpha = 0.78;
uniform float cells = 5.0;
instance uniform float fade = 1.0;
instance uniform float seed = 0.0;

varying vec2 centered_uv;

void vertex() {
	centered_uv = UV * 2.0 - 1.0;
}

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	float d = length(centered_uv);
	// Yumuşak kenar: gövde 0.78'e dek dolu, 1.0'da sıfır.
	float body = 1.0 - smoothstep(0.72, 1.0, d);
	// Kabarcıklar: hücre başına bir halka, kendi ritminde büyüyüp sönen.
	vec2 g = centered_uv * cells + vec2(seed * 13.7, seed * 7.1);
	vec2 cell = floor(g);
	vec2 f = fract(g) - 0.5;
	float h = hash21(cell);
	vec2 off = (vec2(hash21(cell + 3.1), hash21(cell + 7.7)) - 0.5) * 0.5;
	float phase = fract(TIME * (0.25 + 0.35 * h) + h * 6.0);
	float radius = phase * 0.34;
	float ring = smoothstep(0.05, 0.0, abs(length(f - off) - radius)) * (1.0 - phase);
	ring *= step(0.35, h) * (1.0 - smoothstep(0.6, 0.95, d));
	float core = 1.0 - smoothstep(0.0, 0.8, d);
	vec3 col = mix(acid_color.rgb, core_color.rgb, core * 0.55 + ring * 0.6);
	ALBEDO = col;
	EMISSION = col * (0.6 + 0.8 * ring);
	ALPHA = clamp((body * (0.55 + 0.25 * core) + ring * 0.5) * max_alpha, 0.0, 1.0) * fade * step(d, 1.0);
}
