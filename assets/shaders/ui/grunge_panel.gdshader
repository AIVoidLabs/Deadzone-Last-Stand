shader_type canvas_item;
// Yırtık kenarlı kirli siyah panel. Kenar gürültüsü piksel uzayında (her boyutta aynı).

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec2 rect_size = vec2(300.0, 200.0);
uniform vec4 base : source_color = vec4(0.065, 0.055, 0.05, 0.95);
uniform vec4 edge_color : source_color = vec4(0.65, 0.6, 0.545, 1.0);
uniform float torn = 5.0;
uniform float edge_strength = 0.35;

void fragment() {
	vec2 p = UV * rect_size;
	float dx = min(p.x, rect_size.x - p.x);
	float dy = min(p.y, rect_size.y - p.y);
	float d = min(dx, dy);
	float n = texture(noise_tex, p / 190.0).r * 0.6 + texture(noise_tex, p / 41.0).g * 0.4;
	float sh = texture(noise_tex, vec2(p.x / 520.0, p.y / 22.0)).b;
	float sv = texture(noise_tex, vec2(p.x / 22.0, p.y / 520.0)).b;
	float streak = (dy < dx) ? sh : sv;
	d += (n - 0.5) * 2.0 * torn + (streak - 0.5) * torn * 0.9;
	float a = smoothstep(1.0, 3.5, d);
	float grain = texture(noise_tex, p / 120.0).g;
	vec3 col = base.rgb * (0.8 + 0.5 * grain);
	float rim = (1.0 - smoothstep(2.5, 11.0, d)) * edge_strength * (0.5 + streak);
	col = mix(col, edge_color.rgb * 0.55, rim);
	COLOR = vec4(col, base.a * a);
}
