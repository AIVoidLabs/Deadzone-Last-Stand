shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;
// Küçük, düzensiz, hızlı titreyen alev dili (8.3e): çekirdek sarı-beyaz HDR, kenar turuncu-kırmızı.
// Parçacık billboard; INSTANCE_CUSTOM.y = yaşam oranı, COLOR.a = şeffaflık çarpanı.

uniform vec4 core_color : source_color = vec4(1.0, 0.92, 0.55, 1.0);
uniform vec4 mid_color : source_color = vec4(1.0, 0.5, 0.1, 1.0);
uniform vec4 edge_color : source_color = vec4(0.85, 0.12, 0.03, 1.0);
uniform float scroll_speed = 3.2;
uniform float hdr = 3.0;
uniform float edge_sharp = 0.07;

varying float seed;
varying float age;

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
	seed = fract(sin(dot(MODEL_MATRIX[3].xz, vec2(12.9898, 78.233)) + INSTANCE_CUSTOM.x * 3.7) * 43758.5453);
	age = INSTANCE_CUSTOM.y;
	vec3 sc = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	mat4 bb = mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	bb[0] *= sc.x;
	bb[1] *= sc.y;
	bb[2] *= sc.z;
	MODELVIEW_MATRIX = VIEW_MATRIX * bb;
}

void fragment() {
	float h = 1.0 - UV.y;
	float x = (UV.x - 0.5) * 2.0;
	float t = TIME * scroll_speed + seed * 20.0;
	// kabarık, tabanı geniş yuvarlak gövde; yanlara salınır
	float sway = (vnoise(vec2(h * 2.0 + seed * 9.0, t * 0.7)) - 0.5) * 0.5 * h;
	float w = sqrt(max(1.0 - h * h * 0.85, 0.0)) * 0.95;
	float dist = abs(x - sway) / max(w, 0.05);
	// 3 katman gürültü: farklı ölçek ve hız, yukarı akar
	float n = vnoise(vec2(x * 2.0 + seed * 7.0, h * 2.5 - t)) * 0.5
		+ vnoise(vec2(x * 4.5 - seed * 3.0, h * 5.0 - t * 1.7)) * 0.3
		+ vnoise(vec2(x * 9.0 + seed * 5.0, h * 9.0 - t * 2.6)) * 0.2;
	// üste doğru parçalanan dil kenarları
	float density = (1.0 - dist) + (n - 0.5) * (0.5 + h * 1.4) - h * 0.3;
	density *= smoothstep(0.0, 0.06, h);
	float a = smoothstep(0.02, 0.55, density) * (1.0 - smoothstep(0.55, 1.0, age)) * COLOR.a;
	a *= 1.0 - 0.6 * smoothstep(0.55, 1.0, h);
	float heat = clamp(density * 1.1 - h * 0.45 + (n - 0.5) * 0.3, 0.0, 1.0);
	vec3 col = mix(edge_color.rgb, mid_color.rgb, smoothstep(0.05, 0.4, heat));
	col = mix(col, core_color.rgb, smoothstep(0.5, 0.9, heat));
	ALBEDO = col * mix(0.9, hdr, smoothstep(0.3, 0.8, heat));
	ALPHA = a;
}
