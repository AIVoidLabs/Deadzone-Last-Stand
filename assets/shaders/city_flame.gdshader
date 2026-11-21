shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
// Stilize dil dil alev (8.3c): aşağı geniş, yukarı sivri, keskin kenar; içte sarı-beyaz, dışta turuncu-kırmızı.
// Parçacık billboard; INSTANCE_CUSTOM.y = yaşam oranı, COLOR.a = şeffaflık çarpanı.

uniform vec4 core_color : source_color = vec4(1.0, 0.92, 0.55, 1.0);
uniform vec4 mid_color : source_color = vec4(1.0, 0.5, 0.1, 1.0);
uniform vec4 edge_color : source_color = vec4(0.85, 0.12, 0.03, 1.0);
uniform float scroll_speed = 1.6;
uniform float edge_sharp = 0.07;

varying float seed;
varying float age;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	seed = fract(sin(dot(MODEL_MATRIX[3].xz, vec2(12.9898, 78.233)) + INSTANCE_CUSTOM.x * 3.7) * 43758.5453);
	age = INSTANCE_CUSTOM.y;
	vec3 sc = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	mat4 bb = mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	bb[0] *= sc.x;
	bb[1] *= sc.y;
	bb[2] *= sc.z;
	MODELVIEW_MATRIX = VIEW_MATRIX * bb;
}

void fragment() {
	float h = 1.0 - UV.y;
	float x = (UV.x - 0.5) * 2.0;
	float t = TIME * scroll_speed + seed * 20.0;
	// yanlara dalgalanan, yukarı sivrilen gövde
	float sway = (vnoise(vec2(h * 3.0 + seed * 9.0, t)) - 0.5) * 0.7 * h;
	float width = pow(max(1.0 - h, 0.0), 0.75) * (0.55 + 0.45 * smoothstep(0.0, 0.25, h));
	float flick = vnoise(vec2(x * 2.5 + seed * 5.0, h * 4.0 - t * 1.5));
	width *= 0.8 + 0.4 * flick;
	float d = abs(x - sway) / max(width, 0.001);
	float body = 1.0 - smoothstep(1.0 - edge_sharp * 3.0, 1.0, d);
	body *= step(0.02, h) * smoothstep(0.0, 0.05, h);
	float a = body * (1.0 - smoothstep(0.55, 1.0, age)) * COLOR.a;
	if (a < 0.35) discard;
	// iç çekirdek: merkeze ve aşağıya yakın = sarı-beyaz
	float heat = clamp((1.0 - d) * 1.3 - h * 0.55 + (flick - 0.5) * 0.3, 0.0, 1.0);
	vec3 col = mix(edge_color.rgb, mid_color.rgb, smoothstep(0.0, 0.4, heat));
	col = mix(col, core_color.rgb, smoothstep(0.55, 0.9, heat));
	ALBEDO = col;
	ALPHA = 1.0;
}
