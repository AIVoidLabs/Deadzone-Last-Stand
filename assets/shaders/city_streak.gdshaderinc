// Hız yönünde uzayan, kameraya dönen çubuk tabanı (kıvılcım, duman şeridi). Parçacık: particle_flag_align_y = true.
mat4 streak_basis(mat4 model, mat4 inv_view) {
	vec3 pos = model[3].xyz;
	float sx = length(model[0].xyz);
	float sy = length(model[1].xyz);
	vec3 y = model[1].xyz / max(sy, 0.0001);
	vec3 to_cam = normalize(inv_view[3].xyz - pos);
	vec3 x = cross(y, to_cam);
	float l = length(x);
	x = l < 0.001 ? inv_view[0].xyz : x / l;
	vec3 z = cross(x, y);
	return mat4(vec4(x * sx, 0.0), vec4(y * sy, 0.0), vec4(z, 0.0), vec4(pos, 1.0));
}
