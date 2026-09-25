shader_type sky;
render_mode use_debanding;

// 'O cielo 'e Napule
//
// Sostituisce il ProceduralSkyMaterial di Godot, che sa fare una cosa sola:
// una sfumatura verticale fra due colori. Va benissimo finché il cielo è un
// fondale; smette di bastare appena il cielo diventa mezza inquadratura —
// e in una città di vicoli, dove si cammina guardando in su, lo è quasi
// sempre.
//
// Qui dentro ci sono quattro cose che quello non ha:
//
//   1. una sfumatura a TRE colori (zenit, cielo medio, orizzonte) con una
//      curva regolabile: il salto duro fra azzurro e foschia era la cosa
//      che più faceva "grafica di gioco";
//   2. nuvole vere, fatte con due strati di rumore frazionale che scorrono
//      a velocità diverse. Non sono un cielo dipinto: si muovono, si
//      addensano e si sfilacciano, e di sera prendono il colore del sole
//      dal basso;
//   3. il sole con l'alone, che scalda l'aria intorno e all'orizzonte si
//      allarga come succede davvero;
//   4. le stelle, che escono da sole quando cala la notte.
//
// Tutto è pilotato da `giorno_notte.gd`, che qui dentro tocca solo dei
// uniform: la logica dell'ora del giorno resta di là, dove stava.

group_uniforms Colori;
uniform vec3 col_zenit : source_color = vec3(0.10, 0.32, 0.72);
uniform vec3 col_cielo : source_color = vec3(0.35, 0.58, 0.85);
uniform vec3 col_orizzonte : source_color = vec3(0.82, 0.86, 0.88);
uniform vec3 col_terra : source_color = vec3(0.30, 0.29, 0.27);
uniform float curva : hint_range(0.2, 4.0) = 1.35;

group_uniforms Nuvole;
uniform float nuvole_copertura : hint_range(0.0, 1.0) = 0.42;
uniform float nuvole_densita : hint_range(0.0, 3.0) = 1.0;
uniform float nuvole_velocita : hint_range(0.0, 0.05) = 0.0075;
uniform float nuvole_scala : hint_range(0.4, 8.0) = 2.1;
uniform vec3 nuvole_chiaro : source_color = vec3(1.0, 0.99, 0.97);
uniform vec3 nuvole_scuro : source_color = vec3(0.56, 0.58, 0.64);

group_uniforms Sole;
uniform float sole_disco : hint_range(0.9990, 0.99999) = 0.99965;
uniform float alone : hint_range(0.0, 3.0) = 1.15;

group_uniforms Notte;
// 0 = giorno pieno, 1 = notte fonda. Accende stelle e spegne le nuvole.
uniform float notte : hint_range(0.0, 1.0) = 0.0;


// --- Rumore -----------------------------------------------------------
//
// Value noise a base hash. Non è il più bello che ci sia, ma è quello che
// non richiede né texture né tabelle: il cielo deve poter girare anche
// sulla build web, dove ogni risorsa in più è un secondo di caricamento.

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float rumore(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	// Interpolazione di Hermite: senza, si vedono i quadretti della griglia.
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Rumore frazionale: cinque ottave, ognuna metà della precedente. È quello
// che dà alle nuvole i bordi sfilacciati invece delle macchie tonde.
float fbm(vec2 p) {
	float somma = 0.0;
	float peso = 0.5;
	for (int i = 0; i < 5; i++) {
		somma += peso * rumore(p);
		p *= 2.03;   // non esattamente 2: se no le ottave si allineano
		peso *= 0.5;
	}
	return somma;
}


void sky() {
	vec3 dir = normalize(EYEDIR);
	float su = dir.y;

	// --- La volta ---------------------------------------------------
	// Due miscele invece di una: dall'orizzonte al cielo medio e dal cielo
	// medio allo zenit. La curva schiaccia il gradiente verso il basso,
	// che è dove sta davvero la foschia.
	float h = clamp(su, 0.0, 1.0);
	float t = pow(h, 1.0 / curva);
	vec3 cielo = mix(col_orizzonte, col_cielo, smoothstep(0.0, 0.42, t));
	cielo = mix(cielo, col_zenit, smoothstep(0.34, 1.0, t));

	// **Sotto l'orizzonte.**
	//
	// Non e' terra: e' foschia. Alla prima prova il gradiente scendeva in
	// fretta verso il colore di terra e sotto la linea dell'orizzonte
	// compariva un campo verde-oliva piatto, che da una terrazza si vedeva
	// benissimo ed era la cosa piu' finta di tutto il fondale.
	//
	// Adesso scende pianissimo (0.55 invece di 0.30) e parte gia' dal
	// colore d'orizzonte: quello che si vede sotto la linea e' la stessa
	// caligine che c'e' sopra, appena piu' densa. Le colline vere le mette
	// la citta' con la geometria, non il cielo.
	vec3 sotto = mix(col_orizzonte, col_terra, smoothstep(0.02, 0.55, -su));
	vec3 colore = mix(sotto, cielo, smoothstep(-0.015, 0.015, su));

	// --- Il sole ----------------------------------------------------
	float coseno = dot(dir, -LIGHT0_DIRECTION);
	// L'alone: largo, morbido, del colore della luce. È quello che fa
	// sembrare l'aria calda intorno al sole invece di un disco incollato.
	float g = pow(max(coseno, 0.0), 90.0);
	colore += LIGHT0_COLOR * g * alone * LIGHT0_ENERGY * 0.55;
	// Il disco vero e proprio, con un filo di sfumatura sul bordo.
	float disco = smoothstep(sole_disco, sole_disco + 0.00012, coseno);
	colore = mix(colore, LIGHT0_COLOR * (1.6 + LIGHT0_ENERGY),
		disco * step(-0.02, su));

	// --- Le nuvole --------------------------------------------------
	//
	// Si proietta la direzione su un piano a quota fissa: è la
	// proiezione che dà la prospettiva giusta, cioè nuvole grandi sopra
	// la testa e schiacciate verso l'orizzonte. Sotto i cinque gradi si
	// spegne tutto, se no all'orizzonte il rumore si stira all'infinito.
	float quota = max(su, 0.055);
	vec2 piano = dir.xz / quota * nuvole_scala;
	float scorri = TIME * nuvole_velocita;

	// Due strati: quello basso corre di più e fa i filamenti, quello alto
	// fa i banconi. Le velocità sono diverse apposta: due strati che vanno
	// insieme sembrano un'unica texture che scivola.
	float basso = fbm(piano + vec2(scorri * 3.1, scorri * 1.4));
	float alto = fbm(piano * 0.55 + vec2(-scorri * 1.7, scorri * 0.8));
	float massa = basso * 0.62 + alto * 0.55;

	// La copertura decide quanta parte del cielo è coperta; la densità
	// quanto sono compatte. Sono separate perché di sera si vuole poco
	// cielo coperto ma nuvole molto marcate.
	float soglia = 1.0 - nuvole_copertura;
	float nuvola = smoothstep(soglia, soglia + 0.30, massa) * nuvole_densita;
	// Spente a filo d'orizzonte e spente di notte.
	nuvola *= smoothstep(0.0, 0.16, su) * (1.0 - notte * 0.75);
	nuvola = clamp(nuvola, 0.0, 1.0);

	// L'ombra dentro alla nuvola: la parte più spessa è più scura, e la
	// luce del sole la accende dal lato giusto. È l'unica cosa che le fa
	// sembrare volume invece che macchie.
	float spessore = smoothstep(soglia, soglia + 0.55, massa);
	vec3 tinta = mix(nuvole_scuro, nuvole_chiaro, spessore);
	tinta += LIGHT0_COLOR * pow(max(coseno, 0.0), 7.0) * 0.5 * LIGHT0_ENERGY;
	colore = mix(colore, tinta, nuvola);

	// --- Le stelle --------------------------------------------------
	//
	// **Non si proiettano su un piano.** Il primo tentativo usava la stessa
	// proiezione delle nuvole (dir.xz / dir.y): vicino all'orizzonte quella
	// stira all'infinito, e le stelle uscivano come scaglie allungate — una
	// nevicata invece di un cielo. Qui si va in coordinate sferiche, dove
	// ogni cella e' grande piu' o meno uguale dappertutto.
	//
	// E ogni stella e' un PUNTO dentro alla sua cella, non la cella intera:
	// si tira a sorte dove sta e si disegna una macchiolina tonda. E' la
	// differenza fra un cielo stellato e un quadrettato bianco.
	if (notte > 0.01) {
		vec2 sfera = vec2(atan(dir.z, dir.x) * 34.0,
			asin(clamp(su, -1.0, 1.0)) * 34.0);
		vec2 cella = floor(sfera);
		vec2 dentro = fract(sfera);
		float seme = hash21(cella);
		if (seme > 0.9880) {
			vec2 dove = vec2(hash21(cella + vec2(3.7, 1.3)),
				hash21(cella + vec2(11.9, 7.1)));
			float d = length(dentro - dove);
			// Le stelle non sono tutte uguali: una su tre e' piu' grossa.
			float misura = mix(0.030, 0.070, hash21(cella + vec2(21.1, 5.5)));
			float punto = smoothstep(misura, 0.0, d);
			float luce = 0.55 + 0.45 * sin(TIME * (1.1 + seme * 3.0) + seme * 40.0);
			colore += vec3(0.92, 0.94, 1.0) * punto * luce * notte
				* smoothstep(0.01, 0.22, su);
		}
	}

	COLOR = colore;
}
