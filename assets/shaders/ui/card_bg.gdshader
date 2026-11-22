shader_type canvas_item;
// Kart zemini: kategori iki tonunda akan duman/alev, yırtık siyah kenar, sıçrama, vinyet.
// card_mask.png: R silüet, G kir (üst/yan siyahı), B sıçrama.

uniform sampler2D mask_tex : filter_linear;
uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec4 hot : source_color = vec4(0.88, 0.14, 0.1, 1.0);
uniform vec4 deep : source_color = vec4(0.29, 0.03, 0.03, 1.0);
uniform vec4 rim_color : source_color = vec4(0.65, 0.6, 0.55, 1.0);
uniform float rim_mix = 0.2;
uniform float intensity = 1.0;
uniform float glow = 0.0;
uniform float dim = 0.0;
uniform float seed = 0.0;
uniform vec2 halo_center = vec2(0.5, 0.3);
uniform float speed = 0.06;

float flame(vec2 uv, float t) {
	vec2 p = uv * vec2(1.35, 0.8) + vec2(seed, seed * 0.37);
	float w = texture(noise_tex, p * 0.55 + vec2(0.0, -t * 0.5)).r;
	float w2 = texture(noise_tex, p * 0.9 + vec2(0.4, -t * 0.8)).r;
	vec2 q = p + (vec2(w, w2) - 0.5) * 0.55;
	float a = texture(noise_tex, q * vec2(1.2, 0.8) + vec2(0.0, -t * 1.0)).r;
	float b = texture(noise_tex, q * vec2(2.7, 1.9) + vec2(0.31, -t * 1.8)).r;
	return smoothstep(0.18, 0.82, a * 0.65 + b * 0.35);
}

void fragment() {
	vec2 uv = UV;
	vec4 m = texture(mask_tex, uv);
	float t = TIME * speed * (1.0 + glow * 0.7);
	float f = flame(uv, t);
	// Alev profili: alt-orta ve amblem arkası parlak, üst ve kenar sönük
	float vy = smoothstep(0.02, 0.5, uv.y) * (1.0 - smoothstep(0.78, 1.0, uv.y) * 0.45);
	float vx = 1.0 - smoothstep(0.25, 0.62, abs(uv.x - 0.5));
	float prof = 0.22 + 0.5 * vy * (0.45 + 0.55 * vx);
	float heat = (f - 0.5) * 1.5 + prof + 0.12;
	float hd = length((uv - halo_center) * vec2(1.0, 0.8));
	heat += exp(-hd * hd * 10.0) * 0.38;
	heat = clamp(heat * intensity + glow * 0.08, 0.0, 1.0);
	heat = pow(heat, 1.35);
	vec3 ink = vec3(0.03, 0.02, 0.02);
	vec3 col = mix(ink, deep.rgb, smoothstep(0.0, 0.42, heat));
	col = mix(col, hot.rgb, smoothstep(0.3, 0.8, heat));
	col = mix(col, hot.rgb * 1.2 + vec3(0.13, 0.08, 0.04), smoothstep(0.75, 1.0, heat) * 0.7);
	// ince duman çizgileri: koyu ve parlak damarlar
	float smoke = texture(noise_tex, uv * vec2(1.6, 1.2) + vec2(seed * 0.6 + 0.2, -t * 0.4)).r;
	col *= 0.62 + 0.7 * smoothstep(0.25, 0.75, smoke);
	// kir ve yırtık siyah: üst, yanlar, alt köşeler
	col = mix(col, ink, clamp(m.g * 1.04, 0.0, 1.0));
	// sıçrama: koyu kan + birkaç sıcak damla
	float sp = m.b;
	float warm = step(0.5, texture(noise_tex, uv * 5.0 + seed).g);
	vec3 splat_col = mix(deep.rgb * 0.28, hot.rgb * 0.95, warm * 0.55);
	col = mix(col, splat_col, sp * 0.7);
	// iç vinyet
	vec2 q = (uv - 0.5) * vec2(1.1, 0.95);
	col *= 1.0 - smoothstep(0.28, 0.78, length(q)) * 0.55;
	// tebeşir kartın kenarında: nadirlik tonu halkası (iç kenar çizgisi)
	vec2 px = vec2(0.012, 0.0082);
	float inner = min(min(texture(mask_tex, uv + vec2(px.x, 0.0)).r, texture(mask_tex, uv - vec2(px.x, 0.0)).r),
			min(texture(mask_tex, uv + vec2(0.0, px.y)).r, texture(mask_tex, uv - vec2(0.0, px.y)).r));
	float rim = clamp(m.r - inner, 0.0, 1.0);
	col = mix(col, rim_color.rgb, rim * rim_mix * (0.6 + 0.4 * f));
	col += hot.rgb * glow * 0.05;
	col = mix(col, vec3(dot(col, vec3(0.3, 0.55, 0.15))) * 0.5, dim);
	COLOR = vec4(col, m.r);
}
