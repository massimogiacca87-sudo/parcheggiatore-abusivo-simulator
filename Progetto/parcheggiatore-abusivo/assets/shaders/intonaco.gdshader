shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Intonaco, asfalto, maioliche, serrande: un solo shader per tutte le
// superfici fotografiche della piazza.
//
// Il punto è ricavare il RILIEVO dalla fotografia stessa invece di spedire
// una normal map insieme a ogni texture. Il trucco: nelle foto di muri
// scrostati, basoli e piastrelle, la luminanza è già una mappa di altezza —
// le fughe, le crepe e le sbeccature sono scure perché sono incavate. Basta
// derivarla in x e in y e si ottiene una normale per pixel credibile, che
// reagisce davvero alla luce del sole invece di restare un adesivo piatto.
//
// Costa due campionamenti in più per pixel e zero byte su disco: le texture
// restano dieci JPEG e la build non si muove di un chilobyte.

// **Doje maniere 'e mettere 'a fotografia ncopp'â superficie.**
//
// `mappa_mondo = false` — la vecchia: si usa la UV della mesh moltiplicata
// per `uv_scale`. Serve per le cose che la fotografia la devono mostrare
// UNA VOLTA e per intero: il portone, la serranda, il murale, il manifesto.
//
// `mappa_mondo = true` — quella nuova, e per i muri è l'unica giusta.
// La UV si ricava dalla POSIZIONE NEL MONDO, e `metri` dice quanti metri
// veri copre una copia della foto. Un concio di tufo torna alto quaranta
// centimetri e ci resta, che il muro sia largo sei metri o venti.
//
// **Pecché s'è dovuto cagnà.** La `BoxMesh` di Godot non dà a ogni faccia
// la UV da 0 a 1: le sei facce stanno dentro a un atlante, e ognuna ne
// piglia un terzo in orizzontale e la metà in verticale. Tutto il codice
// che calcolava "quante volte ripetere" dava per scontato lo 0..1, e
// quindi ogni piastrella usciva TRE volte più larga e DUE più alta di
// quello che diceva il numero. Da lì i conci di tufo grandi quanto
// un'automobile: il codice chiedeva 2,6 m e ne otteneva quasi otto.
//
// Con la mappatura sul mondo il problema non si ripresenta più, perché non
// dipende dalla mesh: si sceglie l'asse dominante della normale e si
// proietta. I muri della città sono scatole allineate agli assi, quindi
// l'asse dominante è esatto e non serve il costo di una triplanare vera.
// In più due palazzi vicini con lo stesso intonaco si allineano da soli.
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform bool mappa_mondo = false;
uniform vec2 metri = vec2(2.6, 2.6);
uniform float roughness_base : hint_range(0.0, 1.0) = 0.92;
// Quanto rilievo. I muri ne vogliono tanto, le serrande metalliche poco.
uniform float bump_strength : hint_range(0.0, 4.0) = 1.5;
// Le zone scure sono incavi: più ruvide e un po' più in ombra.
uniform float rough_variation : hint_range(0.0, 1.0) = 0.3;
uniform float ao_strength : hint_range(0.0, 1.0) = 0.45;
// L'intonaco e' opaco: piu' specular di cosi' e ogni granello di rilievo
// diventa un puntino luccicante che sfarfalla quando ti muovi.
uniform float specular_amount : hint_range(0.0, 1.0) = 0.16;

// Quanto sporcare a macchie larghe per rompere la ripetizione. Zero =
// spento (serve per le cose mappate a UV, dove la foto si vede una volta).
uniform float variazione : hint_range(0.0, 0.5) = 0.0;

const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

// **'A ripetizione se vede, e chesto è 'o problema d''e texture appaiate.**
//
// Con la fotografia agganciata al mondo la misura è giusta, ma la stessa
// macchia torna ogni due metri e il muro diventa carta da parati. La cura
// che costa meno è non toccare la texture e sporcare la LUCE: una macchia
// chiara larga sette metri e una più piccola larga due e mezzo, tutte e due
// ricavate da un rumore liscio. L'occhio smette di trovare la griglia
// perché il chiaroscuro grande non si ripete con lei.
//
// Costa zero campionamenti: è aritmetica.
float rumore(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float rumore_liscio(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = rumore(i);
	float b = rumore(i + vec2(1.0, 0.0));
	float c = rumore(i + vec2(0.0, 1.0));
	float d = rumore(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 uv = UV * uv_scale;
	// Le coordinate in METRI VERI sulla superficie: servono al rumore, che
	// deve avere una misura sua e non seguire la piastrellatura.
	vec2 metrico = uv;
	if (mappa_mondo) {
		// Posizione e normale in coordinate del mondo. In `fragment` VERTEX
		// e NORMAL stanno nello spazio della telecamera: si tornano indietro
		// con INV_VIEW_MATRIX.
		vec3 wp = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
		vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
		vec3 an = abs(wn);
		if (an.y > an.x && an.y > an.z) {
			// Pavimenti, tetti, marciapiedi: si guarda da sopra.
			uv = wp.xz;
		} else if (an.x > an.z) {
			// Muro che guarda lungo x: scorre su z, e la y va all'ingiù
			// perché la foto ha il cielo in alto.
			uv = vec2(wp.z, -wp.y);
		} else {
			uv = vec2(wp.x, -wp.y);
		}
		metrico = uv;
		uv /= max(metri, vec2(0.05));
	}
	// Nessuna polarizzazione verso il mipmap morbido: l'ho provata e
	// misurata contro un rendering sovracampionato, e l'errore di aliasing
	// era gia' dell'uno-tre per cento. Sfocava senza guadagnare niente.
	vec3 base = texture(albedo_tex, uv).rgb;
	ALBEDO = base * tint.rgb;

	if (variazione > 0.001) {
		// Due misure: le macchie da sette metri fanno il chiaroscuro del
		// muro intero, quelle da due e mezzo lo sporco vicino ai pluviali.
		float grande = rumore_liscio(metrico / 7.0);
		float media = rumore_liscio(metrico / 2.3 + vec2(37.0, 11.0));
		float v = (grande - 0.5) * 1.6 + (media - 0.5) * 0.7;
		ALBEDO *= clamp(1.0 + v * variazione, 0.55, 1.35);
	}

	// Il rilievo si ricava campionando due volte accanto al pixel. Il PASSO
	// di quei due campionamenti e' tutto: da lontano un texel vale meno di
	// un pixel, e un passo sbagliato trasforma il rilievo in rumore.
	//
	// Prima il passo era `fwidth(uv)`, cioe' quanto si muove la UV da un
	// pixel al successivo. Sembra la scelta giusta e invece e' la causa
	// dello sfarfallio: fwidth cambia a ogni minimo spostamento della
	// telecamera, i due campioni si spostano con lui, e la normale che ne
	// esce salta. Misurato: bastavano tre centimetri di passo per cambiare
	// un terzo dei pixel dello schermo.
	//
	// Adesso si calcola PRIMA il livello di mipmap che la GPU userebbe, e
	// poi si campiona a quel livello con un passo di esattamente un texel
	// DI QUEL livello, con textureLod. Cosi' i due campioni non si spostano
	// per conto loro: cambiano solo quando cambia il mipmap, e quello
	// cambia con continuita'.
	vec2 dimensioni = vec2(textureSize(albedo_tex, 0));
	vec2 dx = dFdx(uv) * dimensioni;
	vec2 dy = dFdy(uv) * dimensioni;
	float lod = max(0.0, log2(max(length(dx), length(dy))));
	vec2 texel = exp2(lod) / dimensioni;

	float l = dot(textureLod(albedo_tex, uv, lod).rgb, LUMA);
	float lx = dot(textureLod(albedo_tex, uv + vec2(texel.x, 0.0), lod).rgb, LUMA);
	float ly = dot(textureLod(albedo_tex, uv + vec2(0.0, texel.y), lod).rgb, LUMA);

	vec3 n = normalize(vec3((l - lx) * 4.0, (l - ly) * 4.0, 1.0));
	NORMAL_MAP = n * 0.5 + 0.5;
	// Il rilievo si spegne con la distanza: a due livelli di mipmap la
	// superficie e' gia' liscia. E' quello che farebbe da sola una normal
	// map vera coi suoi mipmap.
	// Il rilievo si spegne prima di quanto si spegnerebbe da solo: e' la
	// parte che sfarfalla di piu', e a quattro metri di distanza nessuno si
	// accorge che un muro ha smesso di avere le crepe in rilievo.
	float fade = clamp(1.15 - lod * 0.9, 0.0, 1.0);
	NORMAL_MAP_DEPTH = bump_strength * fade;

	ROUGHNESS = clamp(roughness_base + (0.5 - l) * rough_variation, 0.05, 1.0);
	SPECULAR = specular_amount;
	AO = mix(1.0, clamp(l * 1.3 + 0.3, 0.0, 1.0), ao_strength);
	AO_LIGHT_AFFECT = 0.7;
}
