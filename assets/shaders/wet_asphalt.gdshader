shader_type spatial;
// Islak asfalt (8.3a): gürültü maskeli birikintiler (düşük pürüzlülük, koyu) ve ince tane. Yansıma ışıklardan gelir.

uniform vec4 base_color : source_color = vec4(0.13, 0.135, 0.15, 1.0);
uniform float puddle_scale = 0.06;
uniform float puddle_threshold = 0.5;
uniform float wet_roughness = 0.05;
uniform float dry_roughness = 0.5;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash2(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash2(i), hash2(i + vec2(1.0, 0.0)), f.x), mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	return vnoise(p) * 0.55 + vnoise(p * 2.1 + 7.3) * 0.3 + vnoise(p * 4.3 + 3.1) * 0.15;
}

void fragment() {
	float n = fbm(wpos.xz * puddle_scale);
	float puddle = smoothstep(puddle_threshold, puddle_threshold + 0.1, n);
	float grain = vnoise(wpos.xz * 9.0) * 0.5 + vnoise(wpos.xz * 31.0) * 0.5;
	ALBEDO = base_color.rgb * (1.0 - 0.4 * puddle) * (0.8 + 0.4 * grain);
	ROUGHNESS = mix(dry_roughness * (0.85 + 0.3 * grain), wet_roughness, puddle);
	SPECULAR = mix(0.45, 0.9, puddle);
}
