shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;
// 8.3e: ince, çok parlak (HDR) kıvılcım çubuğu; parçacık rengi + hdr çarpanı.
#include "res://assets/shaders/city_streak.gdshaderinc"

uniform float hdr = 7.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * streak_basis(MODEL_MATRIX, INV_VIEW_MATRIX);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float a = pow(clamp(1.0 - abs(p.x), 0.0, 1.0), 2.0) * smoothstep(1.0, 0.4, abs(p.y));
	ALBEDO = COLOR.rgb * hdr * a;
	ALPHA = COLOR.a;
}
