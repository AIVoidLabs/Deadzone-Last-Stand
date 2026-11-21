shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled;
// 8.3e: ince, yumuşak kenarlı duman şeridi (hız yönünde uzar); rengi parçacık rampasından (altı ateşle aydınlık).
#include "res://assets/shaders/city_streak.gdshaderinc"

varying float seed;

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
	MODELVIEW_MATRIX = VIEW_MATRIX * streak_basis(MODEL_MATRIX, INV_VIEW_MATRIX);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float across = smoothstep(1.0, 0.0, abs(p.x));
	float along = smoothstep(1.0, 0.5, abs(p.y));
	float n = vnoise(vec2(p.x * 2.0 + seed * 9.0, UV.y * 3.0 - TIME * 0.5 + seed * 5.0));
	ALBEDO = COLOR.rgb * 0.6;
	ALPHA = across * along * (0.55 + 0.9 * n) * COLOR.a;
}
