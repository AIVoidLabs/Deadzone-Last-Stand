shader_type canvas_item;
// Kirli kâğıt / metal panel: lif, lekeler, çizikler, köşelerde pas-kan. Yırtık kenar piksel uzayında.

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform sampler2D scratch_tex : repeat_enable, filter_linear;
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
	float low = texture(noise_tex, p / 330.0 + 0.37).r;
	float fiber = texture(noise_tex, p / 70.0).g;
	float brushed = texture(noise_tex, vec2(p.x / 600.0, p.y / 9.0)).b;
	vec3 col = base.rgb * (0.62 + 0.9 * low) * (0.86 + 0.28 * fiber);
	col += vec3(0.05, 0.045, 0.04) * (brushed - 0.45);
	// lekeler
	col *= 1.0 - smoothstep(0.55, 0.85, texture(noise_tex, p / 120.0 + 0.7).r) * 0.45;
	// çizikler
	float sc = texture(scratch_tex, p / 380.0).r + texture(scratch_tex, p.yx / 260.0 + 0.3).r * 0.7;
	col += vec3(0.62, 0.56, 0.48) * clamp(sc, 0.0, 1.0) * 0.16;
	// köşelerde pas ve kan
	vec2 c = min(p, rect_size - p);
	float cd = length(c) / (min(rect_size.x, rect_size.y) * 0.32);
	float cn = texture(noise_tex, p / 85.0 + 1.3).r;
	float rust = (1.0 - smoothstep(0.0, 0.7, cd + (cn - 0.5) * 0.55));
	vec3 rc = mix(vec3(0.34, 0.12, 0.05), vec3(0.32, 0.03, 0.04), step(0.55, texture(noise_tex, p / 400.0 + 2.0).r));
	col = mix(col, rc * (0.6 + 0.6 * cn), clamp(rust * 0.6, 0.0, 0.7));
	float rim = (1.0 - smoothstep(2.5, 11.0, d)) * edge_strength * (0.5 + streak);
	col = mix(col, edge_color.rgb * 0.55, rim);
	COLOR = vec4(col, base.a * a);
}
