shader_type spatial;
// Yerdeki kristal: kendi ekseninde döner ve hafifçe süzülür (CPU'ya iş düşmez), kenarları parlar.
// INSTANCE_CUSTOM.r: örnek başına faz (0..1), kristaller aynı anda dönmesin.

uniform vec4 albedo : source_color = vec4(0.2, 0.95, 0.8, 1.0);
uniform float emission_strength = 0.35;
uniform float rim_strength = 0.9;
uniform float spin_speed = 2.2;
uniform float bob_height = 0.08;
uniform float bob_speed = 3.0;

void vertex() {
	float phase = INSTANCE_CUSTOM.r * 6.2831853;
	float a = TIME * spin_speed + phase;
	mat2 rot = mat2(vec2(cos(a), -sin(a)), vec2(sin(a), cos(a)));
	VERTEX.xz = rot * VERTEX.xz;
	NORMAL.xz = rot * NORMAL.xz;
	VERTEX.y += sin(TIME * bob_speed + phase) * bob_height;
}

void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = 0.25;
	SPECULAR = 0.8;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = albedo.rgb * (emission_strength + rim * rim_strength);
}
