shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
// Zıplayanın iniş gölgesi: yere yaklaşan cismin gölgesi. urgency 0..1: inişe yaklaştıkça koyulaşır ve keskinleşir.
// Dış kenar (d = 1) iniş şokunun gerçek sınırıdır; ince düşük kontrastlı halka onu belli eder.
// lock_pulse 0..1: kilitlenme anında kenar çizgisi bir kez nabız atar.

uniform vec4 shadow_color : source_color = vec4(0.02, 0.03, 0.05, 1.0);
uniform float urgency : hint_range(0.0, 1.0) = 0.0;
uniform float lock_pulse : hint_range(0.0, 1.0) = 0.0;
uniform float max_darkness = 0.7;
uniform float soft_start = 0.6;     // urgency 0'da gölgenin yumuşaklık genişliği (yarıçap oranı)
uniform float soft_end = 0.12;      // urgency 1'de
uniform float edge_width = 0.035;
uniform float edge_strength = 0.28;

varying vec2 centered_uv;

void vertex() {
	centered_uv = UV * 2.0 - 1.0;
}

void fragment() {
	float d = length(centered_uv);
	float soft = mix(soft_start, soft_end, urgency);
	float body = 1.0 - smoothstep(1.0 - soft - 0.02, 0.97, d);
	// merkeze doğru hafif koyulaşma: gerçek gölge çekirdeği
	float core = 1.0 - smoothstep(0.0, 0.9, d);
	float dark = max_darkness * mix(0.35, 1.0, urgency);
	float alpha = body * dark * (0.75 + 0.25 * core);
	// kenar halkası
	float ring = smoothstep(1.0 - edge_width * 2.0, 1.0 - edge_width, d) * (1.0 - smoothstep(0.985, 1.0, d));
	float ring_a = ring * (edge_strength * (0.4 + 0.6 * urgency) + 0.5 * lock_pulse);
	alpha = clamp(alpha + ring_a, 0.0, 1.0);
	ALBEDO = mix(shadow_color.rgb, vec3(0.55, 0.62, 0.72), ring * (0.35 + 0.65 * lock_pulse));
	ALPHA = alpha * step(d, 1.0);
}
