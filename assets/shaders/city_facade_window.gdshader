shader_type spatial;
// 8.3h: cephe penceresi (Kenney window maskesi). Çoğu karanlık cam; yanan olanlar sıcak sarı, bazıları soluk mavi TV ışığı.
// Örnek başına: COLOR (rgb renk, a opaklık), INSTANCE_CUSTOM.x (tohum), .y (1: TV titreşimi).
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D mask : filter_linear, repeat_disable;
uniform float hdr = 1.4;

varying vec4 inst;
varying float seed;
varying float tv;

void vertex() {
	inst = vec4(pow(COLOR.rgb, vec3(2.2)), COLOR.a);
	seed = INSTANCE_CUSTOM.x;
	tv = INSTANCE_CUSTOM.y;
}

void fragment() {
	float a = smoothstep(0.7, 0.95, texture(mask, UV).a);
	float f = 1.0;
	if (tv > 0.5) {
		float t = TIME * 2.3 + seed * 40.0;
		f = 0.8 + 0.18 * sin(t) + 0.12 * sin(t * 2.7 + 1.3) + 0.1 * sin(t * 6.1);
	}
	float lit = step(0.6, inst.a);
	float shade = mix(1.0, 0.7 + 0.5 * (1.0 - UV.y), lit);
	ALBEDO = inst.rgb * mix(1.0, hdr, lit) * f * shade;
	ALPHA = a * inst.a;
}
