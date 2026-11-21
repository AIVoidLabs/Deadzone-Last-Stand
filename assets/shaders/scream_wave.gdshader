shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
// Çığlıkçının ses dalgası: ince, soluk mor halka; progress 0..1 halkayı merkezden kenara taşır ve söndürür.

uniform vec4 color : source_color = vec4(0.72, 0.58, 0.95, 1.0);
uniform float thickness = 0.05;
instance uniform float progress = 0.0;

void fragment() {
	float d = length(UV * 2.0 - 1.0);
	float ring = smoothstep(progress - thickness, progress, d) * (1.0 - smoothstep(progress, progress + 0.02, d));
	ALBEDO = color.rgb;
	ALPHA = ring * (1.0 - progress) * 0.85;
}
