shader_type spatial;
// 8.3h: yere yatık sürü lekeleri (kan, yanık, yağ, lastik, çatlak). Kenney maskesi + biçim kipleri.
// Örnek başına: COLOR (rgb parlaklık çarpanı, a opaklık), INSTANCE_CUSTOM.x (tohum).
// mode 0: maske, 1: gölcük/damla (düzensiz kenar + maske sıçraması), 2: sürüklenme izi (x boyunca), 3: lastik izi.
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D mask : filter_linear, repeat_disable;
uniform int mode = 0;
uniform vec4 core_color : source_color = vec4(0.2, 0.015, 0.02, 1.0);
uniform vec4 edge_color : source_color = vec4(0.06, 0.02, 0.015, 1.0);
uniform float roughness_value = 0.4;
uniform float spec = 0.4;
uniform float splash = 0.8;

varying float seed;
varying vec4 inst;

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

float vnoise(float x) {
	float i = floor(x);
	return mix(hash(i), hash(i + 1.0), smoothstep(0.0, 1.0, fract(x)));
}

vec2 rot(vec2 p, float a) {
	float c = cos(a);
	float s = sin(a);
	return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

void vertex() {
	seed = INSTANCE_CUSTOM.x;
	inst = vec4(pow(COLOR.rgb, vec3(2.2)), COLOR.a);
}

void fragment() {
	vec2 q = UV - 0.5;
	float a = 0.0;
	float inner = 0.0;
	if (mode == 0) {
		vec2 uv = rot(q, floor(seed * 4.0) * 1.5708) + 0.5;
		if (fract(seed * 7.0) > 0.5) {
			uv.x = 1.0 - uv.x;
		}
		a = texture(mask, uv).a;
		inner = smoothstep(0.45, 0.95, a);
	} else if (mode == 1) {
		vec2 p = q * 2.0;
		float r = length(p);
		float ang = atan(p.y, p.x);
		float edge = 0.5 + 0.09 * sin(ang * 2.0 + seed * 40.0) + 0.07 * sin(ang * 3.0 + seed * 23.0) + 0.05 * sin(ang * 5.0 + seed * 11.0) + 0.03 * sin(ang * 9.0 + seed * 31.0);
		float shape = 1.0 - smoothstep(edge - 0.05, edge, r);
		float m = texture(mask, rot(q, seed * 6.283) * 1.2 + 0.5).a * splash;
		a = max(shape, m);
		inner = max(clamp((edge - r) / 0.3, 0.0, 1.0) * shape, smoothstep(0.45, 0.95, m) * 0.8);
	} else if (mode == 2) {
		float t = UV.x;
		float w = mix(0.3, 0.05, t) * (1.0 + 0.35 * sin(t * 13.0 + seed * 9.0) + 0.2 * sin(t * 31.0 + seed * 3.0));
		float d = abs(UV.y - 0.5 - 0.1 * sin(t * 6.0 + seed * 20.0) * (1.0 - t * 0.5));
		float shape = (1.0 - smoothstep(w - 0.035, w, d)) * smoothstep(0.0, 0.05, t) * (1.0 - smoothstep(0.8, 1.0, t));
		shape *= 0.35 + 0.65 * smoothstep(0.25, 0.6, vnoise(t * 18.0 + seed * 20.0 + UV.y * 3.0));
		float m = texture(mask, vec2(t, UV.y)).a * (1.0 - t) * splash;
		a = max(shape, m);
		inner = clamp((w - d) / (w * 0.9), 0.0, 1.0) * shape;
	} else {
		float t = UV.x;
		float line = 0.0;
		for (int i = 0; i < 2; i++) {
			float y = 0.5 + (float(i) - 0.5) * 0.56;
			line = max(line, 1.0 - smoothstep(0.012, 0.035, abs(UV.y - y)));
		}
		float dash = 0.35 + 0.65 * smoothstep(0.3, 0.6, vnoise(t * 55.0 + seed * 30.0));
		a = line * dash * smoothstep(0.0, 0.12, t) * (1.0 - smoothstep(0.7, 1.0, t));
		inner = 1.0;
	}
	ALBEDO = mix(edge_color.rgb, core_color.rgb, inner) * inst.rgb;
	ALPHA = clamp(a, 0.0, 1.0) * inst.a;
	ROUGHNESS = roughness_value;
	SPECULAR = spec;
}
