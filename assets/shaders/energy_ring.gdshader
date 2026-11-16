shader_type spatial;
// Zırhın yansıttığı enerji çemberi: yatay bir düzlemde kesikli, dönen, hafif nabız atan halka.
// Silah yuvalarının olduğu açılarda halka parlar. Düzlem XZ'de; UV.x dünya +X, UV.y dünya +Z.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.55, 0.15, 1.0);
// Düzlemin yarı boyu ve halka yarıçapı (m).
uniform float half_size = 1.3;
uniform float radius = 1.0;
uniform float width = 0.03;
uniform float dash_count = 28.0;
uniform float spin_speed = 0.25;
uniform float pulse_speed = 3.0;
uniform float intensity = 1.6;
// Yuva sayısı ve ilk yuvanın açısı (radyan); yuva açılarında halka parlar.
uniform float slot_count = 1.0;
uniform float start_angle = 0.0;
uniform float slot_spread = 0.22;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0 * half_size;
	float r = length(p);
	float edge = abs(r - radius);
	float ring = 1.0 - smoothstep(0.0, width, edge);
	float halo = 1.0 - smoothstep(0.0, width * 5.0, edge);
	float angle = atan(p.y, p.x);
	float dash = step(0.45, fract(angle / TAU * dash_count - TIME * spin_speed));
	float slot_glow = 0.0;
	if (slot_count > 0.5) {
		float gap = TAU / slot_count;
		float d = abs(mod(angle - start_angle + gap * 0.5, gap) - gap * 0.5);
		slot_glow = 1.0 - smoothstep(0.0, slot_spread, d);
	}
	float pulse = 0.85 + 0.15 * sin(TIME * pulse_speed);
	float alpha = ring * (0.35 + 0.65 * dash) + halo * (0.18 + 0.6 * slot_glow);
	ALBEDO = color.rgb * intensity * pulse;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
