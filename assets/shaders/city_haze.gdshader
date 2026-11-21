shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled;
// 8.3e: yer seviyesinde yavaş kayan çok saydam pus; ateşlerin yakınında turuncu ışık saçar.

uniform vec4 haze_color : source_color = vec4(0.05, 0.04, 0.032, 1.0);
uniform float alpha = 0.12;
uniform float scale = 0.07;
uniform vec2 drift = vec2(0.5, 0.2);
uniform vec3 fires[8];
uniform int fire_count = 0;
varying vec3 wpos;

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

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 q = wpos.xz * scale + drift * TIME * 0.05;
	float n = vnoise(q) * 0.6 + vnoise(q * 2.3 + 7.0) * 0.4;
	float warm = 0.0;
	for (int i = 0; i < 8; i++) {
		if (i >= fire_count) break;
		warm += fires[i].z * pow(clamp(1.0 - distance(wpos.xz, fires[i].xy) / 6.0, 0.0, 1.0), 2.0);
	}
	vec3 col = mix(haze_color.rgb, vec3(0.9, 0.32, 0.1), clamp(warm, 0.0, 0.6));
	float edge = smoothstep(0.0, 0.2, UV.x) * smoothstep(1.0, 0.8, UV.x) * smoothstep(0.0, 0.2, UV.y) * smoothstep(1.0, 0.8, UV.y);
	ALBEDO = col;
	ALPHA = alpha * (0.35 + n * 1.2) * (1.0 + warm * 1.5) * edge;
}
