shader_type spatial;
// 8.3h: yere yapışık kâğıt/poşet: yırtık köşeli, buruşuk (düzensiz kenar), kirli. Kenney dirt maskesiyle lekeli.
// Örnek başına: COLOR (renk), INSTANCE_CUSTOM.x (tohum), .y (0 yaprak, 1 buruşuk top, 2 şerit).
render_mode cull_disabled, shadows_disabled;

uniform sampler2D grime : filter_linear, repeat_enable;
uniform bool shaped = true;
uniform float roughness_value = 0.95;

varying float seed;
varying float kind;
varying vec4 inst;

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

void vertex() {
	seed = INSTANCE_CUSTOM.x;
	kind = INSTANCE_CUSTOM.y;
	inst = vec4(pow(COLOR.rgb, vec3(2.2)), 1.0);
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	if (shaped) {
		float d;
		if (kind > 0.5 && kind < 1.5) {
			float ang = atan(p.y, p.x);
			d = length(p) - (0.8 + 0.13 * sin(ang * 3.0 + seed * 30.0) + 0.09 * sin(ang * 5.0 + seed * 17.0) + 0.06 * sin(ang * 8.0 + seed * 9.0));
		} else {
			vec2 b = abs(p) - 0.85;
			d = max(b.x, b.y);
			for (int i = 0; i < 4; i++) {
				float fi = float(i);
				vec2 c = vec2(mod(fi, 2.0) * 2.0 - 1.0, floor(fi / 2.0) * 2.0 - 1.0);
				float cut = hash(seed * 7.0 + fi * 3.1);
				if (cut > 0.45) {
					float size = 0.35 + 0.6 * hash(seed * 13.0 + fi);
					d = max(d, (dot(p, c) - (1.7 - size)) * 0.5);
				}
			}
			d += (hash(floor(UV.x * 9.0) + floor(UV.y * 9.0) * 17.0 + seed * 50.0) - 0.5) * 0.12;
		}
		if (d > 0.0) {
			discard;
		}
	}
	float g = texture(grime, UV * 0.9 + vec2(hash(seed), hash(seed + 3.0))).a;
	float crumple = 0.78 + 0.22 * hash(floor(UV.x * 5.0 + seed * 9.0) * 3.0 + floor(UV.y * 5.0) * 11.0);
	ALBEDO = inst.rgb * crumple * (1.0 - 0.5 * g);
	ROUGHNESS = roughness_value;
	SPECULAR = 0.1;
}
