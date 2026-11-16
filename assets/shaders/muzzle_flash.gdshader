shader_type spatial;
// Namlu parlaması: kameraya dönük kare üstünde yıldız biçimli, toplamalı parıltı.
// angle ve strength örnek başına; her atışta yıldız biraz farklı döner ve söner.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 core_color : source_color = vec4(1.0, 0.95, 0.7, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 0.5, 0.1, 1.0);
uniform float spikes = 5.0;
uniform float intensity = 2.5;
instance uniform float angle = 0.0;
instance uniform float strength = 0.0;

void vertex() {
	// Kareyi kameraya çevir (konum ve ölçek korunur).
	mat4 billboard = mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	float scale = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * billboard * mat4(vec4(scale, 0, 0, 0), vec4(0, scale, 0, 0), vec4(0, 0, scale, 0), vec4(0, 0, 0, 1));
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float a = atan(p.y, p.x) + angle;
	float star = 0.55 + 0.45 * cos(a * spikes);
	float shape = 1.0 - smoothstep(0.0, star, r);
	float core = 1.0 - smoothstep(0.0, 0.35, r);
	ALBEDO = mix(edge_color.rgb, core_color.rgb, core) * intensity;
	ALPHA = clamp(shape * strength, 0.0, 1.0);
}
