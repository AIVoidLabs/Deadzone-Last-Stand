shader_type spatial;
// Köşe renkli zombi malzemesi (Aşama V.4, Blender'da tamamen üretilen zombiler): renk Blender'da
// köşelere yazılır; (1 - COLOR.a) parıltı maskesidir (göz, boğaz kesesi). flash / fade / burn
// örnek başına, flash_lit ile aynı sözleşme (ZombieVisual aynı parametreleri ayarlar).

uniform float roughness : hint_range(0.0, 1.0) = 0.62;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// Parıltı gücü: göz ve kese.
uniform float glow_strength = 2.4;
// Yakın bakışta ten ve kumaşa ince alaca (köşe rengi çözünürlüğünü saklar).
uniform float detail_strength : hint_range(0.0, 0.5) = 0.12;
instance uniform float flash = 0.0;
instance uniform float fade = 0.0;
instance uniform float burn = 0.0;
// Çeşit renk tonu (sürüde aynı ağın renk farkı), 1 = değişmez.
instance uniform vec3 tint = vec3(1.0);

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float value_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x), mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x), mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void fragment() {
	if (fade > 0.0) {
		float n = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
		if (n < fade) {
			discard;
		}
	}
	float detail = value_noise(local_pos * 28.0) * 0.6 + value_noise(local_pos * 70.0) * 0.4;
	vec3 base = COLOR.rgb * tint * (1.0 - detail_strength + detail_strength * 2.0 * detail);
	float glow = 1.0 - COLOR.a;
	ALBEDO = mix(base, flash_color.rgb, flash);
	EMISSION = flash_color.rgb * flash * 0.6 + COLOR.rgb * glow * glow_strength;
	if (burn > 0.0) {
		float pulse = 0.65 + 0.35 * sin(TIME * 11.0 + NODE_POSITION_WORLD.x * 3.0);
		ALBEDO = mix(ALBEDO, vec3(1.0, 0.35, 0.05), burn * 0.35);
		EMISSION += vec3(1.0, 0.38, 0.06) * burn * pulse * 0.9;
	}
	ROUGHNESS = roughness;
}
