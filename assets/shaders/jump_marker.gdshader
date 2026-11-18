shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
// Zıplayanın iniş işareti: yerde yanıp sönen halka + hafif dolgu. urgency 0..1: inişe yaklaştıkça
// daha hızlı titrer, dolgu koyulaşır. Halkanın dış kenarı iniş şokunun gerçek sınırıdır.

uniform vec4 color : source_color = vec4(1.0, 0.2, 0.15, 1.0);
uniform float age = 0.0;
uniform float urgency : hint_range(0.0, 1.0) = 0.0;

varying vec2 centered_uv;

void vertex() {
	centered_uv = UV * 2.0 - 1.0;
}

void fragment() {
	float d = length(centered_uv);
	float ring = smoothstep(0.80, 0.87, d) * (1.0 - smoothstep(0.96, 1.0, d));
	float fill = (1.0 - smoothstep(0.88, 1.0, d)) * (0.05 + 0.20 * urgency);
	float pulse = 0.65 + 0.35 * sin(age * (7.0 + 16.0 * urgency));
	ALBEDO = mix(color.rgb, vec3(1.0, 0.9, 0.4), urgency * 0.5);
	ALPHA = clamp(ring * 0.95 * pulse + fill, 0.0, 1.0) * step(d, 1.0);
}
