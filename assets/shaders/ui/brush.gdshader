shader_type canvas_item;
// Fırça / sıçrama / tebeşir maskesi boyar. R kaplama, G kıl çizgisi parlaklığı.
// sweep: soldan sağa boya akar (düzensiz uç). wobble: tebeşir titremesi.

uniform sampler2D mask_tex : filter_linear;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 tint_dark : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float detail_amount = 0.6;
uniform float sweep = 1.0;
uniform float wobble = 0.0;
uniform float wobble_rate = 9.0;

void fragment() {
	vec2 uv = UV;
	if (wobble > 0.0) {
		float k = floor(TIME * wobble_rate);
		vec2 j = vec2(fract(sin(k * 12.9898) * 43758.5453), fract(sin(k * 78.233) * 12345.6789)) - 0.5;
		uv += j * wobble;
	}
	vec4 m = texture(mask_tex, uv);
	float cov = m.r;
	float edge = sweep * 1.3 - 0.1 + (m.g - 0.5) * 0.3;
	cov *= (1.0 - smoothstep(edge - 0.03, edge, UV.x)) * step(0.001, sweep);
	vec3 col = mix(tint_dark.rgb, tint.rgb, mix(1.0, clamp(m.g * 1.25, 0.0, 1.0), detail_amount));
	COLOR = vec4(col, cov * tint.a);
}
