// 'A botta (0.62) — quando ti colpiscono: i colori si separano verso i
// bordi e lo schermo si scurisce e si arrossa ai margini, e passa in mezzo
// secondo. Base: "Chromatic Aberration + Vignette" di Ructoon (CC0,
// godotshaders.com), da assets/esterni/shader. Cambiato: tutto scala con
// `forza` (0 = niente, 1 = botta piena), che il gioco fa scendere da sé.
shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear;
uniform float forza : hint_range(0.0, 1.0) = 0.0;
uniform float spostamento : hint_range(0.0, 20.0) = 9.0;

void fragment() {
	vec2 dal_centro = SCREEN_UV - vec2(0.5);
	float d = length(dal_centro);
	vec2 sp = normalize(dal_centro + vec2(0.0001)) * SCREEN_PIXEL_SIZE * spostamento
		* forza * smoothstep(0.1, 0.7, d);
	float r = texture(SCREEN_TEXTURE, SCREEN_UV + sp).r;
	float g = texture(SCREEN_TEXTURE, SCREEN_UV).g;
	float b = texture(SCREEN_TEXTURE, SCREEN_UV - sp).b;
	vec3 c = vec3(r, g, b);
	float bordo = smoothstep(0.32, 0.78, d) * forza;
	c = mix(c, c * vec3(0.55, 0.12, 0.1), bordo * 0.85);
	COLOR = vec4(c, 1.0);
}
