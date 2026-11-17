shader_type spatial;
// Prototip zemini: hareketi okunur kılan ince ızgara çizgileri, arena dışı koyu.
// stains > 0: asfalt lekeleri ve ince doku (iki ölçekte değer gürültüsü), düz zemin cansız görünmesin.

uniform vec4 base_color : source_color = vec4(0.24, 0.25, 0.27, 1.0);
uniform vec4 line_color : source_color = vec4(0.31, 0.32, 0.35, 1.0);
uniform vec4 outside_color : source_color = vec4(0.14, 0.14, 0.16, 1.0);
uniform float cell = 2.0;
uniform float line_width = 0.04;
uniform float arena_half = 30.0;
uniform float stains = 0.0;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 g = abs(fract(world_pos.xz / cell - 0.5) - 0.5) * cell;
	float d = min(g.x, g.y);
	float line = 1.0 - smoothstep(line_width, line_width + fwidth(d) * 1.5, d);
	vec3 inside = mix(base_color.rgb, line_color.rgb, line);
	if (stains > 0.0) {
		float big = value_noise(world_pos.xz * 0.18) * 0.65 + value_noise(world_pos.xz * 0.5) * 0.35;
		float grain = value_noise(world_pos.xz * 6.0);
		float shade = 1.0 + stains * ((big - 0.5) * 0.9 + (grain - 0.5) * 0.25);
		inside *= shade;
	}
	float outside = step(arena_half, max(abs(world_pos.x), abs(world_pos.z)));
	ALBEDO = mix(inside, outside_color.rgb, outside);
	ROUGHNESS = 0.95;
}
