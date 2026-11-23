shader_type canvas_item;
// Kart zemini: kıvrımlı duman/alev (domain warp), üstte ve kenarlarda siyaha yırtılan karanlık,
// parlak bölge yalnız amblemin çevresi ve bandın üstü. R silüet, G kir (card_mask.png).

uniform sampler2D mask_tex : filter_linear_mipmap;
uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform sampler2D splat_tex : repeat_disable, filter_linear_mipmap;
uniform vec4 hot : source_color = vec4(0.88, 0.14, 0.1, 1.0);
uniform vec4 deep : source_color = vec4(0.29, 0.03, 0.03, 1.0);
uniform vec4 rim_color : source_color = vec4(0.65, 0.6, 0.55, 1.0);
uniform float rim_mix = 0.2;
uniform float intensity = 1.0;
uniform float glow = 0.0;
uniform float dim = 0.0;
uniform float seed = 0.0;
uniform vec2 halo_center = vec2(0.5, 0.3);
uniform float speed = 0.05;
uniform vec4 splat_a = vec4(0.5, 0.6, 0.0, 1.0); // x, y, açı, ölçek
uniform vec4 splat_b = vec4(0.2, 0.3, 2.0, 0.8);
uniform float card_aspect = 0.675;

float nz(vec2 p) { return texture(noise_tex, p).r; }

float smoke(vec2 uv, float t) {
	vec2 p = uv * vec2(1.0, 0.95) + vec2(seed, seed * 0.61);
	vec2 w1 = vec2(nz(p * 0.6 + vec2(t * 0.6, -t * 0.4)), nz(p * 0.6 + vec2(3.7 - t * 0.5, 1.3 + t * 0.7)));
	vec2 q = p + (w1 - 0.5) * 0.7;
	float a = nz(q * 0.75 + vec2(0.0, -t * 0.7));
	float b = nz(q * 1.5 + vec2(0.7, -t * 1.0));
	return smoothstep(0.1, 0.9, a * 0.72 + b * 0.28);
}

float splat(vec2 uv, vec4 sp) {
	vec2 c = (uv - sp.xy) * vec2(card_aspect, 1.0);
	float cs = cos(sp.z);
	float sn = sin(sp.z);
	vec2 q = vec2(c.x * cs - c.y * sn, c.x * sn + c.y * cs) / sp.w + 0.5;
	if (q.x < 0.0 || q.x > 1.0 || q.y < 0.0 || q.y > 1.0) return 0.0;
	return texture(splat_tex, q).r;
}

void fragment() {
	vec2 uv = UV;
	vec4 m = texture(mask_tex, uv);
	float t = TIME * speed * (1.0 + glow * 0.7);
	float f = smoke(uv, t);
	// konum: amblem çevresi ve bandın üstü
	vec2 e = vec2((uv.x - halo_center.x) * card_aspect, uv.y - halo_center.y);
	float hd = length(e) + (f - 0.5) * 0.06;
	float emblem_zone = exp(-pow(hd / 0.34, 2.0));
	float band_zone = exp(-pow((uv.y - 0.58) / 0.13, 2.0)) * (1.0 - smoothstep(0.3, 0.62, abs(uv.x - 0.5)));
	float zone = clamp(emblem_zone * 0.9 + band_zone * 0.75, 0.0, 1.0);
	float heat = (f * 0.8 + 0.22) * (0.16 + 1.0 * zone) * intensity * 1.15;
	heat = clamp(heat + glow * 0.07, 0.0, 1.0);
	vec3 ink = vec3(0.025, 0.018, 0.016);
	vec3 col = mix(ink, deep.rgb * 0.8, smoothstep(0.0, 0.4, heat));
	col = mix(col, hot.rgb * 0.88, smoothstep(0.3, 0.78, heat));
	col = mix(col, hot.rgb * 1.02 + vec3(0.04), smoothstep(0.8, 1.0, heat) * 0.5);
	// üst ~%35 ve kenarlar siyaha yırtılır
	float top = 1.0 - smoothstep(0.0, 0.34, uv.y + (f - 0.5) * 0.2 + (texture(noise_tex, uv * 3.0 + seed).g - 0.5) * 0.08);
	float side = 1.0 - smoothstep(0.0, 0.2, min(uv.x, 1.0 - uv.x) + (f - 0.5) * 0.14);
	float bottom = 1.0 - smoothstep(0.62, 1.0, 1.0 - (uv.y - 0.55) * 1.0);
	col = mix(col, ink, clamp(top * 0.92 + side * 0.7, 0.0, 1.0) * (1.0 - emblem_zone * 0.45));
	col *= 1.0 - bottom * 0.3;
	// bandın arkası koyulur: boyalı şerit zeminden net ayrışsın (altında ince alev aralığı kalır)
	float band_dark = smoothstep(0.50, 0.53, uv.y) * (1.0 - smoothstep(0.655, 0.675, uv.y));
	col *= 1.0 - 0.75 * band_dark;
	// amblem arkası koyu duman diski + ince kategori halosu
	float disc = 1.0 - smoothstep(0.0, 0.2, hd);
	col = mix(col, col * 0.55, disc * 0.6);
	float halo = exp(-pow((hd - 0.3) / 0.05, 2.0));
	col += hot.rgb * halo * 0.4;
	// kir ve yırtık siyah (maske)
	col = mix(col, ink, clamp(m.g * 1.04, 0.0, 1.0));
	// sıçrama: kart başına konum / döndürme (instance seed)
	float sp = max(splat(uv, splat_a), splat(uv, splat_b) * 0.85);
	vec3 splat_col = mix(deep.rgb * 0.25, ink, 0.6);
	col = mix(col, splat_col, sp * 0.88);
	// iç vinyet
	vec2 q = (uv - 0.5) * vec2(1.1, 0.95);
	col *= 1.0 - smoothstep(0.3, 0.8, length(q)) * 0.5;
	// nadirlik çerçevesi
	vec2 px = vec2(0.012, 0.0082);
	float inner = min(min(texture(mask_tex, uv + vec2(px.x, 0.0)).r, texture(mask_tex, uv - vec2(px.x, 0.0)).r),
			min(texture(mask_tex, uv + vec2(0.0, px.y)).r, texture(mask_tex, uv - vec2(0.0, px.y)).r));
	float rim = clamp(m.r - inner, 0.0, 1.0);
	col = mix(col, rim_color.rgb, rim * rim_mix * (0.6 + 0.4 * f));
	col += hot.rgb * glow * 0.04;
	col = mix(col, vec3(dot(col, vec3(0.3, 0.55, 0.15))) * 0.5, dim);
	COLOR = vec4(col, m.r);
}
