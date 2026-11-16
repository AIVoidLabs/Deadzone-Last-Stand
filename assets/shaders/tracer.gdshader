shader_type spatial;
// Mermi izi: ince uzun kutu; öndeki uç parlak, kuyruğa doğru söner. Kutu yerel +Z'ye (gidiş yönü) bakar.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 head_color : source_color = vec4(1.0, 0.95, 0.75, 1.0);
uniform vec4 tail_color : source_color = vec4(1.0, 0.55, 0.15, 1.0);
uniform float tracer_length = 1.0;
uniform float intensity = 2.2;

varying float along;

void vertex() {
	// 0 kuyruk, 1 baş.
	along = clamp(VERTEX.z / tracer_length + 0.5, 0.0, 1.0);
}

void fragment() {
	float fade = pow(along, 1.6);
	ALBEDO = mix(tail_color.rgb, head_color.rgb, smoothstep(0.6, 1.0, along)) * intensity;
	ALPHA = fade;
}
