// 'A videocassetta (0.62) — righe, colori che scappano di lato, ogni tanto
// uno strappo del nastro. Base: "VHS Scanline Glitch" di hailyn e "VHS
// Tape Effect" di blblblblb (tutti e due CC0, godotshaders.com), da
// assets/esterni/shader. Cambiato: l'effetto del nastro originale
// moltiplicava l'immagine per cinque e per un rumore pieno (diventava
// bianca e granulosa); qui il rumore è leggero, il nastro scorre piano e
// la vignetta è quella di un televisore vecchio.
shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear;
uniform float strappo : hint_range(0.0, 1.0) = 0.06;
uniform float colore_spostato : hint_range(0.0, 0.01) = 0.0025;
uniform float righe : hint_range(0.0, 0.2) = 0.045;
uniform float rumore_forza : hint_range(0.0, 0.3) = 0.05;
uniform float vignetta : hint_range(0.0, 1.0) = 0.55;

float rand(vec2 co) {
	return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = floor(TIME * 12.0);
	// Lo strappo: una banda orizzontale che scivola di lato, ogni tanto.
	if (rand(vec2(t, 0.0)) < strappo) {
		float banda = rand(vec2(t, 1.0));
		if (abs(uv.y - banda) < 0.04) {
			uv.x += (rand(vec2(t, uv.y)) - 0.5) * 0.03;
		}
	}
	float r = texture(SCREEN_TEXTURE, uv + vec2(colore_spostato, 0.0)).r;
	float g = texture(SCREEN_TEXTURE, uv).g;
	float b = texture(SCREEN_TEXTURE, uv - vec2(colore_spostato, 0.0)).b;
	vec3 c = vec3(r, g, b);
	// Le righe: fisse, fitte, e una larga che scorre piano.
	float fitte = sin(uv.y / SCREEN_PIXEL_SIZE.y * 1.6) * 0.5 + 0.5;
	float larga = sin((uv.y + TIME * 0.08) * 18.0) * 0.5 + 0.5;
	c *= 1.0 - righe * fitte - righe * 0.6 * larga;
	c += (rand(uv * 431.0 + fract(TIME * 31.0)) - 0.5) * rumore_forza;
	// Colori un po' slavati, come una cassetta registrata tre volte.
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(lum), c, 0.82) * vec3(1.02, 1.0, 0.96);
	float d = distance(uv, vec2(0.5));
	c *= 1.0 - vignetta * smoothstep(0.3, 0.8, d);
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
