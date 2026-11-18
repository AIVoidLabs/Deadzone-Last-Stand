shader_type spatial;
// Mermi izi: ince uzun kutu; öndeki uç parlak, kuyruğa doğru söner. Kutu yerel +Z'ye (gidiş yönü) bakar.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 head_color : source_color = vec4(1.0, 0.95, 0.75, 1.0);
uniform vec4 tail_color : source_color = vec4(1.0, 0.55, 0.15, 1.0);
uniform float tracer_length = 1.0;
uniform float intensity = 2.2;
// Örnek başına renk (rgb); alfa 0 ise yukarıdaki varsayılan renkler. Kuyruk, baş renginin koyu tonu.
instance uniform vec4 tint = vec4(0.0);

varying float along;

void vertex() {
	// 0 kuyruk, 1 baş.
	along = clamp(VERTEX.z / tracer_length + 0.5, 0.0, 1.0);
}

void fragment() {
	float fade = pow(along, 1.6);
	vec3 head = tint.a > 0.0 ? mix(tint.rgb, vec3(1.0), 0.45) : head_color.rgb;
	vec3 tail = tint.a > 0.0 ? tint.rgb * 0.7 : tail_color.rgb;
	ALBEDO = mix(tail, head, smoothstep(0.6, 1.0, along)) * intensity;
	ALPHA = fade;
}
