shader_type spatial;
// Düz renkli ya da dokulu, ışık alan malzeme (doku verilmezse yalnız albedo rengi). flash örnek başına (instance) ayarlanır:
// aynı malzeme tüm zombilerde paylaşılır, vuruş parlaması tek örneği etkiler.

uniform vec4 albedo : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform sampler2D albedo_texture : source_color, hint_default_white, filter_linear_mipmap;
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
instance uniform float flash = 0.0;
// Kendi ışıması (silah kademesi): albedo rengiyle, 0 kapalı.
uniform float glow = 0.0;
// Palet dokulu modellerde renk şeması: UV örnek başına dikeyde kaydırılır.
instance uniform float palette_offset = 0.0;
// Solarak silinme (0 görünür, 1 yok): saydamlık yerine noktalı eleme, böylece malzeme opak kalır.
instance uniform float fade = 0.0;
// Yanma (0 kapalı, 1 yanıyor): turuncu nabız atan kor parlaması.
instance uniform float burn = 0.0;

// Kenar ışığı (8.3a): 0 = kapalı. Silüet kenarında soğuk emisyon.
uniform vec4 rim_color : source_color = vec4(0.55, 0.7, 1.0, 1.0);
uniform float rim_strength = 0.0;
uniform float rim_power = 4.0;

void fragment() {
	if (fade > 0.0) {
		float noise = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
		if (noise < fade) {
			discard;
		}
	}
	vec3 base = albedo.rgb * texture(albedo_texture, UV + vec2(0.0, palette_offset)).rgb;
	ALBEDO = mix(base, flash_color.rgb, flash);
	EMISSION = flash_color.rgb * flash * 0.6 + base * glow;
	if (burn > 0.0) {
		float pulse = 0.65 + 0.35 * sin(TIME * 11.0 + NODE_POSITION_WORLD.x * 3.0);
		ALBEDO = mix(ALBEDO, vec3(1.0, 0.35, 0.05), burn * 0.35);
		EMISSION += vec3(1.0, 0.38, 0.06) * burn * pulse * 0.9;
	}
	if (rim_strength > 0.0) {
		float rim = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), rim_power);
		EMISSION += rim_color.rgb * rim * rim_strength;
	}
	ROUGHNESS = roughness;
}
