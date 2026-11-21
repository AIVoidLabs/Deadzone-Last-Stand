shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
// Boss yer dövmesinin şok halkası (yerde): genişleyen parlak ön kenar + arkasında çatlak izi.
// Düzlem 2x2 birim ölçeklenir (yarı boy H); front/width düzlem yarı boyuna oranlı (0..1). scar çatlak izinin görünürlüğü.

uniform vec4 ring_color : source_color = vec4(1.0, 0.62, 0.28, 1.0);
uniform vec4 crack_color : source_color = vec4(0.06, 0.03, 0.02, 1.0);
instance uniform float front = 0.0;
instance uniform float width = 0.05;
instance uniform float scar = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	float a = atan(p.y, p.x);
	float band = smoothstep(front - width, front, d) * (1.0 - smoothstep(front, front + 0.012, d));
	// Çatlak izi: ön kenarın gerisinde kırık radyal çizgiler (hücre başına rastgele), uzaklaştıkça seyrek.
	float cell = hash(vec2(floor(a * 7.0), floor(d * 55.0)));
	float streak = hash(vec2(floor(a * 7.0), 3.0));
	float crack = step(0.7, cell) * step(0.45, streak) * (1.0 - smoothstep(0.0, 0.9, d / max(front, 0.001)) * 0.5);
	crack *= step(d, front - width * 0.5) * step(0.03, d);
	float shade = clamp(1.0 - front * 0.4, 0.0, 1.0);
	vec3 col = mix(crack_color.rgb, ring_color.rgb, band);
	ALBEDO = col;
	ALPHA = clamp(band * 0.85 * shade + crack * 0.6 * scar, 0.0, 1.0);
}
