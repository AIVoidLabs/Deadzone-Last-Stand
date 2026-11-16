shader_type spatial;
// Yerdeki kan lekesi: yatay kare üstünde düzensiz kenarlı leke + çevresinde birkaç damla.
// MultiMesh örneği başına: COLOR (renk ve solma alfası), INSTANCE_CUSTOM.x (biçim tohumu).
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform float roughness_value : hint_range(0.0, 1.0) = 0.35;

varying float seed;
varying vec4 tint;

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

void vertex() {
	seed = INSTANCE_CUSTOM.x;
	// Örnek rengi sRGB olarak gelir; ışık hesabı doğrusal renk ister.
	tint = vec4(pow(COLOR.rgb, vec3(2.2)), COLOR.a);
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float edge = 0.55 + 0.06 * sin(a * 3.0 + seed * 6.283) + 0.035 * sin(a * 7.0 + seed * 19.0);
	float shape = 1.0 - smoothstep(edge - 0.06, edge, r);
	for (int i = 0; i < 4; i++) {
		float fi = float(i);
		float da = hash(seed * 13.1 + fi * 3.7) * 6.283;
		float dd = 0.7 + 0.22 * hash(seed * 7.3 + fi * 1.9);
		float dr = 0.05 + 0.07 * hash(seed * 3.1 + fi * 5.3);
		vec2 c = vec2(cos(da), sin(da)) * dd;
		shape = max(shape, 1.0 - smoothstep(dr - 0.03, dr, length(p - c)));
	}
	ALBEDO = tint.rgb * mix(0.6, 1.0, smoothstep(0.0, edge, r));
	ROUGHNESS = roughness_value;
	ALPHA = shape * tint.a;
}
