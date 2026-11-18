shader_type spatial;
// Yakın dövüş izi: rüzgar gibi ince, yumuşak hilal. UV.x = yarıçap oranı (0 merkez, 1 dış kenar), UV.y = yay boyunca (0 başlangıç).
// Savurmada parlak uç yay boyunca ilerler, arkasında incelerek sönen rüzgar çizgileri kalır.
// Dürtmede (thrust) uç merkezden dışa doğru ilerleyen ince bir çizgidir.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;

uniform vec4 color : source_color = vec4(1.0);
uniform bool thrust = false;
// Genel parlaklık (0..1); rüzgar izi hafif kalmalı.
uniform float intensity = 0.55;
// Savurmanın geldiği yer (0..1) ve genel soluklaşma (1 görünür, 0 yok); örnek başına.
instance uniform float reveal = 0.0;
instance uniform float fade = 0.0;

float hash(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

// Yarıçap boyunca ince, düzensiz rüzgar çizgileri (0..1).
float wind_lines(float r, float along) {
	float lane = r * 26.0;
	float id = floor(lane);
	float f = fract(lane);
	float line = 1.0 - smoothstep(0.0, 0.32, abs(f - 0.5));
	// Her çizginin kendi uzunluğu ve kopukluğu var.
	float gap = step(0.35, fract(along * (1.5 + hash(id) * 2.0) + hash(id + 7.0)));
	return line * mix(0.35, 1.0, hash(id + 3.0)) * mix(0.4, 1.0, gap);
}

void fragment() {
	float a;
	if (thrust) {
		// Dışa doğru ilerleyen uç; arkasında incelen iz. Yana doğru yumuşak.
		float side = 1.0 - smoothstep(0.0, 0.5, abs(UV.y - 0.5));
		float tail = smoothstep(reveal - 0.65, reveal, UV.x) * (1.0 - smoothstep(reveal, reveal + 0.05, UV.x));
		float core = pow(side, 3.0) * (0.55 + 0.45 * tail);
		a = core * tail;
	} else {
		// Uca yaklaştıkça kalınlaşan, kuyrukta incelen hilal.
		float tail = smoothstep(reveal - 0.75, reveal, UV.y);
		float lead = 1.0 - smoothstep(reveal - 0.02, reveal + 0.1, UV.y);
		// Yayın iki ucu da yumuşak açılır: düz kesik kenar kalmaz.
		float ends = smoothstep(0.0, 0.15, UV.y) * (1.0 - smoothstep(0.85, 1.0, UV.y));
		float inner = mix(0.93, 0.62, tail);
		float band = smoothstep(inner, inner + 0.12, UV.x) * (1.0 - smoothstep(0.9, 1.0, UV.x));
		float rim = smoothstep(0.84, 0.95, UV.x) * (1.0 - smoothstep(0.95, 1.0, UV.x));
		float lines = wind_lines(UV.x, UV.y);
		a = (band * (0.25 + 0.75 * lines) + rim * 0.6) * pow(tail, 1.6) * lead * ends;
	}
	ALBEDO = mix(color.rgb, vec3(1.0), 0.25) * 1.4;
	ALPHA = clamp(a * fade * intensity, 0.0, 1.0);
}
