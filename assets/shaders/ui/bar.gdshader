shader_type canvas_item;
// Çubuk: mürekkep zemin, dolgu, geciken hasar gölgesi, çentikler, kemik rengi ince çerçeve.

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec2 rect_size = vec2(200.0, 18.0);
uniform vec4 fill_color : source_color = vec4(0.7, 0.07, 0.1, 1.0);
uniform vec4 lag_color : source_color = vec4(1.0, 0.85, 0.7, 1.0);
uniform vec4 back_color : source_color = vec4(0.04, 0.03, 0.03, 0.92);
uniform vec4 frame_color : source_color = vec4(0.65, 0.6, 0.545, 1.0);
uniform float value = 1.0;
uniform float lag = 1.0;
uniform float notch = 0.0;
uniform float flash = 0.0;

void fragment() {
	vec2 p = UV * rect_size;
	float n = texture(noise_tex, p / 60.0).g;
	float rag = (n - 0.5) * 3.0 / rect_size.x;
	float fv = 1.0 - smoothstep(value + rag - 0.003, value + rag + 0.003, UV.x);
	float fl = 1.0 - smoothstep(lag + rag - 0.003, lag + rag + 0.003, UV.x);
	vec3 col = back_color.rgb;
	float a = back_color.a;
	col = mix(col, lag_color.rgb, fl * (1.0 - fv) * 0.85);
	float shade = 0.82 + 0.3 * (1.0 - abs(UV.y - 0.4) * 1.6);
	vec3 fc = fill_color.rgb * shade * (0.9 + 0.2 * n) + vec3(flash * 0.4);
	col = mix(col, fc, fv);
	if (notch > 0.0) {
		float k = UV.x / notch;
		float ln = abs(fract(k + 0.5) - 0.5) * notch * rect_size.x;
		col = mix(col, vec3(0.03, 0.02, 0.02), (1.0 - smoothstep(0.6, 1.4, ln)) * 0.8 * step(0.5, k) * step(k, 1.0 / notch - 0.5));
	}
	float edge = min(min(p.x, rect_size.x - p.x), min(p.y, rect_size.y - p.y));
	float fr = 1.0 - smoothstep(1.0, 2.2, edge + (n - 0.5) * 0.8);
	col = mix(col, frame_color.rgb * 0.8, fr);
	a = max(a, fr);
	COLOR = vec4(col, a);
}
