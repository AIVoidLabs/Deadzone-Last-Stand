shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
// Boss hücum şeridi (yerde, kırmızı): kenar çizgileri + akan oklar; locked = 1 iken (son 0.3 sn) parlak ve sabit.
// UV.y şerit boyunca; len şerit uzunluğu (m).

uniform vec4 color : source_color = vec4(1.0, 0.12, 0.08, 1.0);
instance uniform float locked = 0.0;
instance uniform float len = 10.0;

void fragment() {
	float edge = smoothstep(0.0, 0.07, UV.x) * (1.0 - smoothstep(0.93, 1.0, UV.x));
	float rim = 1.0 - edge;
	float flow = fract(UV.y * len * 0.35 - TIME * 2.4 * (1.0 - locked));
	float chevron = smoothstep(0.0, 0.18, flow) * (1.0 - smoothstep(0.18, 0.4, flow));
	float pulse = 0.75 + 0.25 * sin(TIME * 22.0);
	float fill = mix(0.16, 0.34, locked);
	ALBEDO = mix(color.rgb, vec3(1.0, 0.8, 0.4), locked * 0.5);
	ALPHA = clamp((fill + chevron * 0.22 + rim * 0.75) * mix(1.0, pulse, locked) * mix(0.7, 1.0, locked), 0.0, 1.0);
}
