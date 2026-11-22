shader_type spatial;
// Elektrik direği: düz renk, ışık alan; fade > 0 iken noktalı eleme (malzeme opak kalır, direk askeri örtünce yumuşakça seyrelir).

uniform vec4 albedo : source_color = vec4(0.1, 0.075, 0.055, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.9;
uniform float fade = 0.0;

void fragment() {
	if (fade > 0.0) {
		float noise = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
		if (noise < fade) {
			discard;
		}
	}
	ALBEDO = albedo.rgb;
	ROUGHNESS = roughness;
}
