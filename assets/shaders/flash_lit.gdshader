shader_type spatial;
// Düz renkli ya da dokulu, ışık alan malzeme (doku verilmezse yalnız albedo rengi). flash örnek başına (instance) ayarlanır:
// aynı malzeme tüm zombilerde paylaşılır, vuruş parlaması tek örneği etkiler.

uniform vec4 albedo : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform sampler2D albedo_texture : source_color, hint_default_white, filter_linear_mipmap;
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
instance uniform float flash = 0.0;

void fragment() {
	vec3 base = albedo.rgb * texture(albedo_texture, UV).rgb;
	ALBEDO = mix(base, flash_color.rgb, flash);
	EMISSION = flash_color.rgb * flash * 0.6;
	ROUGHNESS = roughness;
}
