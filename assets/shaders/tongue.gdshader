shader_type spatial;
render_mode cull_back;
// Islak et dil: koyu kırmızı/mor benekli, düşük pürüzlülük, boyuna sırtlar, uca doğru koyulaşma.

uniform vec3 color_a : source_color = vec3(0.6, 0.13, 0.19);
uniform vec3 color_b : source_color = vec3(0.48, 0.11, 0.25);
uniform vec3 color_tip : source_color = vec3(0.22, 0.03, 0.08);
uniform float roughness_value : hint_range(0.0, 1.0) = 0.2;
uniform float ridge_freq = 70.0;
uniform float ridge_strength = 1.0;
uniform float rim_amount : hint_range(0.0, 1.0) = 0.6;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float height_at(vec2 uv) {
	float ridge = sin(uv.y * ridge_freq) * 0.5 + 0.5;
	float grain = vnoise(vec2(uv.x * 14.0, uv.y * 60.0));
	return ridge * 0.6 + grain * 0.4;
}

void fragment() {
	float n = vnoise(vec2(UV.x * 7.0, UV.y * 28.0));
	float n2 = vnoise(vec2(UV.x * 19.0, UV.y * 80.0));
	vec3 col = mix(color_a, color_b, smoothstep(0.3, 0.7, n));
	col *= 0.55 + 0.7 * n2;
	col = mix(col, color_tip, smoothstep(0.6, 0.85, n2) * 0.5);
	col = mix(col, color_tip, smoothstep(0.45, 1.0, UV.y) * 0.75);
	ALBEDO = col;
	ROUGHNESS = roughness_value;
	SPECULAR = 1.0;
	CLEARCOAT = 0.6;
	CLEARCOAT_ROUGHNESS = 0.08;
	// Türev tabanlı çıkıntı: sırtlar normali bozar.
	float h = height_at(UV);
	vec3 sx = dFdx(VERTEX);
	vec3 sy = dFdy(VERTEX);
	vec3 r1 = cross(sy, NORMAL);
	vec3 r2 = cross(NORMAL, sx);
	float det = dot(sx, r1);
	vec3 grad = sign(det) * (dFdx(h) * r1 + dFdy(h) * r2);
	NORMAL = normalize(abs(det) * NORMAL - ridge_strength * 0.02 * grad);
	RIM = rim_amount;
	RIM_TINT = 0.5;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = vec3(1.0, 0.55, 0.65) * fres * 0.2;
}

