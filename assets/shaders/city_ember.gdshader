shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;
// 8.3e: yerde parlayan kor noktaları (MultiMesh, her örnek kendi fazında yanıp söner).

uniform float hdr = 4.0;
varying float ph;

void vertex() {
	ph = fract(sin(dot(MODEL_MATRIX[3].xz, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float dotv = pow(clamp(1.0 - length(p), 0.0, 1.0), 1.6);
	float t = TIME * (0.8 + ph * 2.2) + ph * 40.0;
	float blink = clamp(0.35 + 0.65 * sin(t) * sin(t * 0.37 + ph * 9.0), 0.0, 1.0);
	vec3 col = mix(vec3(0.9, 0.1, 0.02), vec3(1.0, 0.55, 0.12), blink);
	ALBEDO = col * hdr * dotv * (0.25 + blink);
	ALPHA = 1.0;
}
