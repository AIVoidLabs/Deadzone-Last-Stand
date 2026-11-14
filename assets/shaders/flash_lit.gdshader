shader_type spatial;
// Düz renkli, ışık alan malzeme. flash örnek başına (instance) ayarlanır:
// aynı malzeme tüm zombilerde paylaşılır, vuruş parlaması tek örneği etkiler.

uniform vec4 albedo : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
instance uniform float flash = 0.0;

void fragment() {
	ALBEDO = mix(albedo.rgb, flash_color.rgb, flash);
	EMISSION = flash_color.rgb * flash * 0.6;
	ROUGHNESS = roughness;
}
