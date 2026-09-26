// (0.62) Copia da gioco di assets/esterni/shader/lente_sporca/dirty_lens.gdshader.
// Dirty Lens (lente sporca) — scritto per Parcheggiatore Abusivo Simulator, rilasciato CC0.
// Su GodotShaders non esiste uno shader "dirty lens" dedicato: questo è originale.
// Effetto: aloni, ditate e polvere sulla "lente" che si accendono dove l'immagine è luminosa
// (fari, lampioni, sole), come succede con una fotocamera vera.
//
// USO: CanvasLayer > ColorRect a schermo intero (anchors Full Rect, mouse_filter Ignore)
//      > Material = ShaderMaterial con questo shader.
// Facoltativo: in "dirt_texture" metti un'immagine di sporco in scala di grigi
// (es. res://assets/esterni/materiali/decals/... o una texture grunge) per uno sporco "vero";
// se la lasci vuota lo sporco è generato proceduralmente.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D dirt_texture : hint_default_black, filter_linear_mipmap, repeat_disable;
uniform bool use_dirt_texture = false;

uniform float dirt_strength : hint_range(0.0, 2.0, 0.01) = 0.6;   // quanto si vede lo sporco
uniform float bloom_threshold : hint_range(0.0, 1.0, 0.01) = 0.65; // da che luminosità lo sporco "si accende"
uniform float bloom_blur : hint_range(0.0, 6.0, 0.1) = 3.5;        // mip usato per l'alone (più alto = più diffuso)
uniform float base_haze : hint_range(0.0, 0.3, 0.005) = 0.03;      // velatura costante (lente mai pulita)
uniform float smudge_scale : hint_range(1.0, 20.0, 0.1) = 5.0;     // grandezza delle ditate procedurali
uniform float dust_amount : hint_range(0.0, 1.0, 0.01) = 0.35;     // puntini di polvere
uniform vec3 dirt_tint : source_color = vec3(1.0, 0.93, 0.8);      // colore caldo dello sporco
uniform float seed = 7.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21) + seed);
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 5; i++) {
		v += amp * vnoise(p);
		p *= 2.03;
		amp *= 0.5;
	}
	return v;
}

float procedural_dirt(vec2 uv, float aspect) {
	vec2 p = vec2(uv.x * aspect, uv.y);
	// ditate: macchie morbide e irregolari
	float smudges = smoothstep(0.55, 0.85, fbm(p * smudge_scale));
	// strisciate diagonali (pulita col dito...)
	float streak = smoothstep(0.6, 0.9, fbm(vec2(p.x * smudge_scale * 0.35 + p.y * smudge_scale * 1.4, p.y * 0.8)));
	// polvere: puntini piccoli e sparsi
	vec2 g = p * 60.0;
	float speck = step(1.0 - dust_amount * 0.04, hash(floor(g)));
	float dot_shape = 1.0 - smoothstep(0.1, 0.45, length(fract(g) - 0.5));
	float dust = speck * dot_shape;
	// bordi della lente più sporchi del centro
	float edge = smoothstep(0.2, 0.75, length(uv - 0.5));
	return clamp(smudges * 0.8 + streak * 0.5 + dust + edge * 0.25, 0.0, 1.0);
}

void fragment() {
	vec3 base = texture(screen_tex, SCREEN_UV).rgb;
	// versione sfocata della scena = da dove arriva la luce che "illumina" lo sporco
	vec3 blurred = textureLod(screen_tex, SCREEN_UV, bloom_blur).rgb;
	float lum = dot(blurred, vec3(0.299, 0.587, 0.114));
	float glow = smoothstep(bloom_threshold, 1.0, lum);

	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float dirt = use_dirt_texture ? texture(dirt_texture, SCREEN_UV).r : procedural_dirt(SCREEN_UV, aspect);

	vec3 lens_light = blurred * dirt_tint * dirt * (glow * dirt_strength + base_haze);
	COLOR = vec4(base + lens_light, 1.0);
}
