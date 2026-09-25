shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Il mare di Mergellina.
//
// È un piano solo, grande trecento metri per centosessanta, e tutto quello
// che lo fa sembrare acqua sta qui dentro. Niente geometria animata, niente
// particelle: un piano piatto e due mappe normali che scorrono.
//
// ## Perché due strati e non uno
//
// Una sola mappa normale che scorre si riconosce dopo due secondi: si vede
// il disegno traslare tutto insieme, come una fotografia tirata con la
// corda. Due strati alla stessa scala e in direzioni opposte sono già
// meglio, ma battono: ogni tanto i due disegni si allineano e per un attimo
// il mare "pulsa".
//
// Qui gli strati sono due, ma a scala DIVERSA (il secondo è 1,7 volte più
// fitto) e con velocità diverse e non proporzionali. Due frequenze
// incommensurabili non tornano mai in fase, quindi il mare non si ripete e
// non pulsa. È lo stesso motivo per cui gli accordi di due note stonate
// battono e quelli di due note lontane no.
//
// ## La schiuma
//
// `mare_schiuma` è la stessa mappa d'onda con le creste sbiancate. Non si
// usa come colore: si usa come MASCHERA, cioè si tiene solo dove è chiara,
// e la si fa scorrere più piano degli strati d'onda. Così la schiuma non
// insegue le onde — sta un po' indietro, come fa quella vera.
//
// E si accende **vicino alla riva**. La riva non e' a zero: e' a z = -21,
// perche' la citta' occupa gli z positivi e il mare sta tutto in negativo.
// La prima versione faceva `mondo.z / riva_metri` come se la riva fosse
// l'origine — e siccome sul mare mondo.z e' sempre negativo, il clamp lo
// portava a zero ovunque e la maschera di riva valeva UNO su tutti i
// trecento metri: il mare veniva bianco pieno, da riva fino all'orizzonte.
// Adesso si misura la distanza VERA dalla riva, e va passata da fuori.

uniform sampler2D onde : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D schiuma : source_color, filter_linear_mipmap, repeat_enable;

uniform vec3 colore_fondo : source_color = vec3(0.016, 0.098, 0.180);
uniform vec3 colore_alto : source_color = vec3(0.055, 0.286, 0.400);
uniform vec3 colore_schiuma : source_color = vec3(0.92, 0.96, 0.97);

// Quanti metri copre una piastrella d'onda. Grande: da riva le onde devono
// leggersi lunghe, non come increspature da pozzanghera.
uniform float scala_onde = 11.0;
uniform float velocita = 0.045;
uniform float forza_normale : hint_range(0.0, 3.0) = 0.55;
uniform float lucido : hint_range(0.0, 1.0) = 0.92;
// Dove sta la riva, in coordinate mondo, e per quanti metri al largo la
// schiuma resta piena.
uniform float riva_z = -21.0;
uniform float riva_metri = 5.0;
uniform float schiuma_soglia : hint_range(0.0, 1.0) = 0.80;

varying vec3 mondo;

void vertex() {
	mondo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Le UV si prendono dalle coordinate MONDO, non da UV: il piano è uno
	// solo e gigantesco, e con le UV del mesh la piastrella sarebbe stirata
	// su trecento metri.
	vec2 uv = mondo.xz / scala_onde;
	float t = TIME * velocita;

	vec3 n1 = texture(onde, uv + vec2(t, t * 0.62)).rgb * 2.0 - 1.0;
	vec3 n2 = texture(onde, uv * 1.7 - vec2(t * 0.83, t * 1.31)).rgb * 2.0 - 1.0;

	// **Quanto è lontano questo pezzo d'acqua.**
	//
	// Serve a spegnere il dettaglio con la distanza. Su trecento metri di
	// mare, una piastrella da dieci metri si ripete trenta volte, e da un
	// punto alto le trenta ripetizioni si vedono tutte insieme: viene fuori
	// una scacchiera, che è esattamente quello che l'acqua non è. Da
	// lontano l'acqua vera è una superficie liscia di un colore solo, e il
	// dettaglio si vede solo vicino.
	float dist = length(mondo - CAMERA_POSITION_WORLD);
	float vicino = 1.0 - clamp((dist - 25.0) / 95.0, 0.0, 1.0);

	vec3 n = normalize(vec3((n1.xy + n2.xy) * forza_normale * vicino, 1.0));
	NORMAL_MAP = n * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 1.0;

	// Il colore: più scuro dove l'onda scende, più chiaro sulle creste.
	float cresta = clamp(n1.y * 0.5 + n2.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 acqua = mix(colore_fondo, colore_alto, mix(0.42, cresta, vicino));

	// **La schiuma, e come si toglie la scacchiera.**
	//
	// Un solo campionamento della maschera di schiuma disegna la griglia
	// della texture: la piastrella ha dentro una struttura a celle, e
	// ripetuta si legge come un reticolo. La prima versione ne aveva una
	// sola e il mare sembrava un tovagliato.
	//
	// Qui se ne prendono DUE, a scale molto diverse e con una ruotata di
	// novanta gradi (le componenti scambiate), e si MOLTIPLICANO. Il
	// prodotto è chiaro solo dove sono chiare tutt'e due, e siccome le due
	// griglie hanno passo e orientamento diversi le coincidenze cadono
	// sparse: la struttura regolare sparisce.
	vec2 uf = mondo.xz / (scala_onde * 2.6);
	float f1 = texture(schiuma, uf + vec2(t * 0.35, -t * 0.22)).r;
	float f2 = texture(schiuma, uf.yx * 0.53 + vec2(-t * 0.19, t * 0.27)).r;
	float f = smoothstep(schiuma_soglia, schiuma_soglia + 0.18, f1 * f2 * 1.9);
	// La schiuma al largo è poca: quella vera sta sulle creste piu' alte e
	// sotto costa. Al largo il mare e' liscio.
	f *= 0.22 * vicino;

	// Sotto riva invece c'è sempre: è la risacca contro gli scogli.
	float bordo = 1.0 - clamp((riva_z - mondo.z) / riva_metri, 0.0, 1.0);
	f = clamp(f + bordo * bordo * 0.85, 0.0, 1.0);

	ALBEDO = mix(acqua, colore_schiuma, f);
	// La schiuma è opaca e ruvida, l'acqua è liscia e riflettente.
	ROUGHNESS = mix(1.0 - lucido, 0.85, f);
	METALLIC = 0.0;
	SPECULAR = mix(0.95, 0.2, f);
}
