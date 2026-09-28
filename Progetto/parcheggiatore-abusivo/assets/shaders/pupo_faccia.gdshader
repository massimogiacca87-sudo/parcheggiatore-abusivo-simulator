// **'A faccia dipinta d''o pupo** (0.66)
//
// La pelle della testa dei personaggi nuovi, con sopra i tratti disegnati
// come in Schedule I: la faccia è liscia, e bocca, rughe e barba stanno in
// tre texture piccole che si moltiplicano sulla tinta della persona.
// Lo usa `human_builder._materiale_faccia()`, che imposta per nome:
//
//   pelle, peli            i colori della persona (peli = capelli, di solito)
//   tex_bocca, tex_rughe   RGB moltiplicativo: bianco = niente
//   tex_barba              maschera nel canale rosso: nero = niente peli,
//                          fino a ~0,55 peli radi (fanno ombra), verso 0,9
//                          barba fitta (fa il colore dei peli)
//
// **Questi nomi sono il contratto** con human_builder e con chi disegna le
// texture: non si cambiano da una parte sola.
//
// Le UV sono quelle della superficie `faccia` (tools/build_personaggi.py):
// proiezione piatta da davanti, (0,0) in alto a sinistra di chi guarda, e
// le facce che non guardano avanti tutte nell'angolo (0,015, 0,015), che
// nelle texture deve restare neutro. Neutro deve restare pure il bordo
// della superficie: lì attaccano orecchie, naso e palpebre, che sono
// StandardMaterial3D color pelle, e ogni differenza si vedrebbe come una
// cucitura.
//
// **Niente VERTEX**: la mesh è skinnata, la posa la mette lo scheletro.
// **Niente schermo, niente trucchi**: gira uguale in Forward+ e nella build
// web (Compatibility/OpenGL). Costo: tre letture di texture e una ventina
// di operazioni per pixel.

shader_type spatial;
// **'A stessa luce d''e ricchie.** Questi sono i render_mode che usa lo
// StandardMaterial3D di default (diffuso Burley, speculare Schlick-GGX), e
// in fondo si scrivono gli stessi ROUGHNESS / METALLIC / SPECULAR della
// pelle di human_builder (0,72 / 0 / 0,5). Uno diverso, e al bordo della
// faccia si vede il confine.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 pelle : source_color = vec4(0.86, 0.68, 0.54, 1.0);
uniform vec4 peli : source_color = vec4(0.16, 0.11, 0.08, 1.0);

// Bocca e rughe si leggono in sRGB (source_color), come l'albedo dello
// StandardMaterial3D: moltiplicare in lineare dà lo stesso scuro che vede
// chi le ha disegnate. La barba invece è una quantità (quanti peli), non un
// colore: si legge com'è. Filtro lineare con le mipmap: le mipmap però le
// deve avere la texture (nel .import `mipmaps/generate=true`), se no a
// dieci metri i puntini della barba sfarfallano invece di fare ombra.
uniform sampler2D tex_bocca : source_color, hint_default_white, filter_linear_mipmap, repeat_disable;
uniform sampler2D tex_rughe : source_color, hint_default_white, filter_linear_mipmap, repeat_disable;
uniform sampler2D tex_barba : hint_default_black, filter_linear_mipmap, repeat_disable;

// Quanto pesa la maschera della barba (1 = com'è disegnata; meno di 1 la
// fa più rada, e i peli chiari radi fanno ombra: vedi sotto).
uniform float barba_forza : hint_range(0.0, 1.0) = 1.0;
// 'O russore d''e guance: un velo di rosa, a zero si spegne.
uniform float rossore : hint_range(0.0, 0.3) = 0.05;
// Deve restare uguale alla ruvidità della pelle in human_builder.
uniform float ruvidita : hint_range(0.0, 1.0) = 0.72;

const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);
// Le guance, in coordinate d'immagine: sotto agli occhi e un poco in fuori.
const vec2 GUANCIA_SX = vec2(0.31, 0.60);
const vec2 GUANCIA_DX = vec2(0.69, 0.60);
const vec2 GUANCIA_R = vec2(0.11, 0.075);
// Il rosa: toglie verde e blu, aggiunge un filo di rosso (per unità di
// rossore, al centro della guancia).
const vec3 ROSA = vec3(0.5, -1.5, -1.2);
// L'ombra della barba tira al freddo: grigio con un poco di blu.
const vec3 FREDDO = vec3(0.88, 0.98, 1.18);

// Una macchia morbida che vale 1 al centro e 0 fuori dall'ellisse:
// **zero esatto** fuori, così il bordo della faccia resta pelle pura.
float guancia(vec2 uv, vec2 centro) {
	vec2 d = (uv - centro) / GUANCIA_R;
	float g = clamp(1.0 - dot(d, d), 0.0, 1.0);
	return g * g;
}

void fragment() {
	// La bocca si mette **dopo** la barba (vedi in fondo): una bocca aperta
	// sta sopra ai peli, non sotto.
	vec3 col = pelle.rgb * texture(tex_rughe, UV).rgb;

	float g = (guancia(UV, GUANCIA_SX) + guancia(UV, GUANCIA_DX)) * rossore;
	col *= vec3(1.0) + ROSA * g;

	// **'A barba.** Il colore dei peli dipinti dipende da quanto sono fitti,
	// cioè dal valore della maschera (dopo barba_forza):
	// * **radi** (la sfatta, che il collega disegna sotto 0,55): i peli corti
	//   non si vedono del colore loro, si vede l'ombra che fanno. Quindi il
	//   colore dei capelli un filo scurito (×0,8), **ma mai più chiaro di
	//   metà della pelle**: la barba sfatta di un vecchio coi capelli
	//   bianchi resta un'ombra grigia sulla faccia, invece di una spruzzata
	//   di puntini bianchi;
	// * **fitti** (barba piena, pizzetto, basette, verso 0,9): il colore dei
	//   capelli un filo scurito e basta, che una barba bianca è bianca pure
	//   su una pelle scura. I bordi sfumati passano per i radi, e fanno da
	//   ombra attorno alla barba come quella vera.
	// Coi peli scuri il tetto non scatta mai: è sempre il colore dei capelli.
	// Poi due ritocchi, che contano solo sui peli chiari: tra i peli si vede
	// un quinto del colore della pelle, e l'ombra tira un poco al freddo.
	// Provate le varianti: col freddo solo la barba piena bianca all'ombra
	// del cielo usciva una maschera blu, con la pelle sola la sfatta
	// sembrava sporco.
	float barba = texture(tex_barba, UV).r * barba_forza;
	float lp = dot(pelle.rgb, LUMA);
	float lh = max(dot(peli.rgb, LUMA), 0.0001);
	float fitta = smoothstep(0.55, 0.9, barba);
	vec3 tinta = peli.rgb * mix(min(0.8, 0.5 * lp / lh), 0.8, fitta);
	tinta *= mix(vec3(1.0), pelle.rgb / max(lp, 0.0001), 0.2);
	tinta = mix(tinta, FREDDO * dot(tinta, LUMA), 0.15);
	col = mix(col, tinta, barba);
	col *= texture(tex_bocca, UV).rgb;

	ALBEDO = col;
	ROUGHNESS = ruvidita;
	METALLIC = 0.0;
	SPECULAR = 0.5;
}
