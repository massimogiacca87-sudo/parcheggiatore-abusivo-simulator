// 'A pellicola (0.62) — grana da film, un poco di vignetta e il colore
// appena caldo. Base: "Film Grain" di mujtaba-io (CC0,
// godotshaders.com/shader/film-grain-shader), da assets/esterni/shader.
// Cambiato: la grana si muove col tempo (nell'originale stava ferma sullo
// schermo, e ferma non è grana: è sporco sul monitor) e si pesa meno sulle
// zone scure, come fa la pellicola vera.
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float grana : hint_range(0.0, 0.3) = 0.07;
uniform float vignetta : hint_range(0.0, 1.0) = 0.35;
uniform vec3 tono : source_color = vec3(1.04, 1.0, 0.93);

float rumore(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 c = texture(screen_texture, SCREEN_UV).rgb;
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	vec2 cella = floor(SCREEN_UV / SCREEN_PIXEL_SIZE / 1.5);
	float n = rumore(cella + fract(TIME * 24.0) * 97.0) - 0.5;
	c += n * grana * (0.35 + lum * 0.65);
	c *= tono;
	float d = distance(SCREEN_UV, vec2(0.5));
	c *= 1.0 - vignetta * smoothstep(0.35, 0.85, d);
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
