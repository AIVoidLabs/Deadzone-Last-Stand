shader_type spatial;
// Yakın dövüş kesik izi: yay dilimi, savurmayla birlikte açılan parlak uçlu iz. UV.x = yarıçap oranı, UV.y = yay boyunca (0 başlangıç).
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;

uniform vec4 color : source_color = vec4(1.0);
// Savurmanın geldiği yer (0..1) ve genel soluklaşma (1 görünür, 0 yok); örnek başına.
instance uniform float reveal = 0.0;
instance uniform float fade = 0.0;

void fragment() {
	float radial = smoothstep(0.1, 1.0, UV.x);
	float rim = smoothstep(0.8, 1.0, UV.x);
	float head = smoothstep(reveal - 0.55, reveal, UV.y) * (1.0 - smoothstep(reveal, reveal + 0.02, UV.y));
	float a = (radial * 0.32 + rim * 0.8) * head * fade;
	ALBEDO = color.rgb * 1.6;
	ALPHA = clamp(a, 0.0, 1.0);
}
