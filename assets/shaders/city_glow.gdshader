shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;
// 8.3e: zemine yayılan sahte ışık (yumuşak radyal, titreşen). Gerçek ışık menzil sınırına takılmasın diye.

uniform vec4 glow_color : source_color = vec4(1.0, 0.35, 0.08, 1.0);
uniform float energy = 0.55;
uniform float flicker = 0.3;
uniform float speed = 3.0;
uniform float seed = 0.0;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float fall = pow(clamp(1.0 - length(p), 0.0, 1.0), 2.2);
	float t = TIME * speed + seed;
	float f = 1.0 + flicker * (0.5 * sin(t * 1.7) + 0.35 * sin(t * 3.1 + 1.7) + 0.15 * sin(t * 7.3 + seed));
	ALBEDO = glow_color.rgb * energy * fall * max(f, 0.0);
	ALPHA = 1.0;
}
