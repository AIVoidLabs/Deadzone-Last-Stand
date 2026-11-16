shader_type canvas_item;
// Ekran kenarı kızarması: ortası saydam, kenarlara doğru koyu kırmızı. strength 0..1.
render_mode unshaded;

uniform vec4 color : source_color = vec4(0.65, 0.02, 0.02, 1.0);
uniform float strength = 0.0;
// Kızarmanın başladığı uzaklık (0 merkez, 1 köşe).
uniform float inner = 0.45;
uniform float softness = 0.55;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	// Köşeler kenarlardan biraz daha koyu kalsın diye eliptik uzaklık.
	float d = length(p * vec2(0.85, 1.0)) / 1.31;
	float edge = smoothstep(inner, inner + softness, d);
	COLOR = vec4(color.rgb, edge * strength);
}
