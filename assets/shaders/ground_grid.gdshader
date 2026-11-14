shader_type spatial;
// Prototip zemini: hareketi okunur kılan ince ızgara çizgileri, arena dışı koyu.

uniform vec4 base_color : source_color = vec4(0.24, 0.25, 0.27, 1.0);
uniform vec4 line_color : source_color = vec4(0.31, 0.32, 0.35, 1.0);
uniform vec4 outside_color : source_color = vec4(0.14, 0.14, 0.16, 1.0);
uniform float cell = 2.0;
uniform float line_width = 0.04;
uniform float arena_half = 30.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 g = abs(fract(world_pos.xz / cell - 0.5) - 0.5) * cell;
	float d = min(g.x, g.y);
	float line = 1.0 - smoothstep(line_width, line_width + fwidth(d) * 1.5, d);
	vec3 inside = mix(base_color.rgb, line_color.rgb, line);
	float outside = step(arena_half, max(abs(world_pos.x), abs(world_pos.z)));
	ALBEDO = mix(inside, outside_color.rgb, outside);
	ROUGHNESS = 0.95;
}
