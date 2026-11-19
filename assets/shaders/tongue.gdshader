shader_type spatial;
render_mode cull_back;
// Islak et dil: koyu kırmızı/mor benekli, düşük pürüzlülük, ince tırtıl (papilla), uca doğru koyulaşma.
// UV.y kökten uca 0..1 (renk geçişi), UV2.x kökten metre: doku dilin boyuyla gerilmez; sert halka
// (boğum) çizgisi yok, yukarıdan oyun kamerasında titremesin diye yumuşak.

uniform vec3 color_a : source_color = vec3(0.62, 0.14, 0.2);
uniform vec3 color_b : source_color = vec3(0.5, 0.12, 0.26);
uniform vec3 color_tip : source_color = vec3(0.26, 0.04, 0.09);
uniform float roughness_value : hint_range(0.0, 1.0) = 0.22;
// Metre başına papilla sıklığı ve normal bozma gücü.
uniform float papilla_per_m = 26.0;
uniform float bump_strength = 0.35;
uniform float rim_amount : hint_range(0.0, 1.0) = 0.6;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

// x ekseninde period hücrede sarar (borunun çevresi dikişsiz).
float vnoise(vec2 p, float period) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float x0 = mod(i.x, period);
	float x1 = mod(i.x + 1.0, period);
	float a = hash21(vec2(x0, i.y));
	float b = hash21(vec2(x1, i.y));
	float c = hash21(vec2(x0, i.y + 1.0));
	float d = hash21(vec2(x1, i.y + 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	float m = UV2.x;
	float blotch = vnoise(vec2(UV.x * 6.0, m * 3.0), 6.0);
	float papilla = vnoise(vec2(UV.x * 18.0, m * papilla_per_m), 18.0);
	vec3 col = mix(color_a, color_b, smoothstep(0.3, 0.75, blotch));
	col *= 0.82 + 0.3 * papilla;
	col = mix(col, color_tip, smoothstep(0.5, 1.0, UV.y) * 0.7);
	ALBEDO = col;
	ROUGHNESS = roughness_value + 0.15 * papilla;
	SPECULAR = 0.9;
	CLEARCOAT = 0.6;
	CLEARCOAT_ROUGHNESS = 0.1;
	// Türev tabanlı hafif çıkıntı (papilla).
	vec3 sx = dFdx(VERTEX);
	vec3 sy = dFdy(VERTEX);
	vec3 r1 = cross(sy, NORMAL);
	vec3 r2 = cross(NORMAL, sx);
	float det = dot(sx, r1);
	vec3 grad = sign(det) * (dFdx(papilla) * r1 + dFdy(papilla) * r2);
	NORMAL = normalize(abs(det) * NORMAL - bump_strength * 0.02 * grad);
	RIM = rim_amount;
	RIM_TINT = 0.5;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = vec3(1.0, 0.55, 0.65) * fres * 0.18;
}
