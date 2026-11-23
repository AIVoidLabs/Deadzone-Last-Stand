shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
// Boss hücumunun yanan yarığı (yerde, yukarıdan): düzensiz, dallanan koyu çatlak çizgileri + çatlakların içinden ve
// kenarlarında sönen turuncu kor parıltısı. Işınsal (çarkıfelek) desen yok: çatlaklar iki yönde hizalı dalgalı çizgilerin
// gürültüyle bozulmuş kesişimidir. Düzlem 2x2 birim. power: 1 yanıyor, 0'a doğru sönüyor; seed her parçada farklı desen.

uniform vec4 glow_color : source_color = vec4(1.0, 0.4, 0.07, 1.0);
uniform vec4 crack_color : source_color = vec4(0.03, 0.015, 0.01, 1.0);
uniform float crack_width = 0.07;
uniform float glow_width = 0.22;
instance uniform float power = 1.0;
instance uniform float seed = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// Çatlak mesafesi: gürültüyle bükülmüş koordinatlarda hücre kenarlarına uzaklık (Voronoi-benzeri kırık çizgiler).
float crack_dist(vec2 p) {
	vec2 g = floor(p);
	vec2 f = fract(p);
	float best = 8.0;
	float second = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 o = vec2(float(x), float(y));
			vec2 pt = o + vec2(hash(g + o + seed * 31.0), hash(g + o + 17.0 + seed * 13.0));
			float d = length(pt - f);
			if (d < best) {
				second = best;
				best = d;
			} else if (d < second) {
				second = d;
			}
		}
	}
	return second - best;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	vec2 q = p * 2.2 + vec2(noise(p * 3.0 + seed * 9.0), noise(p * 3.0 + 5.0 + seed * 7.0)) * 0.9 + seed * 20.0;
	float cd = crack_dist(q);
	float line = 1.0 - smoothstep(0.0, crack_width, cd);
	float halo = 1.0 - smoothstep(crack_width, glow_width, cd);
	// Kenarlara doğru çatlaklar seyrekleşir ve söner (yuvarlak leke kenarı belli olmasın).
	float fade_edge = 1.0 - smoothstep(0.45, 0.95, d);
	float flicker = 0.85 + 0.15 * sin(TIME * 7.0 + seed * 40.0 + q.x * 3.0);
	float ember = (line * 0.9 + halo * 0.45) * flicker * power;
	vec3 col = mix(crack_color.rgb, glow_color.rgb, clamp(ember * 1.2, 0.0, 1.0));
	ALBEDO = col;
	ALPHA = clamp((line * 0.85 + halo * 0.5) * fade_edge * mix(0.35, 1.0, power), 0.0, 0.9);
}
