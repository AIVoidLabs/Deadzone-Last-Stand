shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
// 8.3e: vitrin camı: içi yanıyor; çerçeve ve pencere demirleri koyu, arkada kaynayan turuncu-kırmızı ateş.

uniform float hdr = 2.6;
uniform float cols = 4.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	float n = vnoise(vec2(UV.x * 9.0, UV.y * 4.0 - TIME * 2.2)) * 0.6 + vnoise(vec2(UV.x * 20.0, UV.y * 9.0 - TIME * 4.0)) * 0.4;
	float heat = clamp((1.0 - UV.y) * 1.1 + n * 0.8 - 0.35, 0.0, 1.0);
	vec3 col = mix(vec3(0.5, 0.04, 0.01), vec3(1.0, 0.45, 0.08), smoothstep(0.1, 0.6, heat));
	col = mix(col, vec3(1.0, 0.9, 0.5), smoothstep(0.7, 1.0, heat));
	float bar = step(abs(fract(UV.x * cols) - 0.5), 0.46);
	float frame = step(0.04, UV.x) * step(UV.x, 0.96) * step(0.06, UV.y) * step(UV.y, 0.96);
	ALBEDO = col * hdr * bar * frame + vec3(0.01) * (1.0 - bar * frame);
}
