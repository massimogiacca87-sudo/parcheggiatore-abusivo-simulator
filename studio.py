"""
LO STUDIO — squadra multi-agente per "Parcheggiatore Abusivo Simulator"

Come si usa (dal terminale, nella cartella del progetto):
    python studio.py                      -> ti chiede l'obiettivo del lancio
    python studio.py "sistema i bug dell'audio e migliora le texture delle auto"

Chi c'è:
  - IL DIRETTORE (modello top): legge il progetto, decide di quali specialisti c'è bisogno,
    li CREA da solo (salvandoli in /agenti), li riusa nei lanci successivi e affida loro compiti piccoli.
  - GLI SPECIALISTI (modello economico): grafica, animazioni, texture, audio, UI, bugfix...
    Correggono bug e fanno miglioramenti tecnici IN AUTONOMIA, con un commit git per ogni compito.

Regole imposte dal codice (non solo "chieste" agli agenti):
  - Massimo è il lead designer: modifiche di gameplay/feature o modifiche grandi
    richiedono il suo permesso, chiesto qui nel terminale (s/n).
  - Gli agenti non toccano i file che hai modificato e non ancora committato.
  - Ogni compito finito = commit git dei soli file toccati dagli agenti.
"""

import os
import re
import sys
import json
import difflib
import secrets
import datetime
import subprocess
from pathlib import Path
from typing import Optional, Type

from pydantic import BaseModel, Field
from crewai import Agent, Task, Crew
from crewai.tools import BaseTool

# Evita crash con emoji/accenti nella console di Windows
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

# =============================================================================
# CONFIGURAZIONE
# =============================================================================
ROOT = Path(r"C:\Users\Max\Downloads\Parcheggiatore Abusivo Simulator").resolve()

# Modelli: il Direttore ragiona con quello top, gli specialisti con quello economico.
# Se il modello degli specialisti non esiste/non risponde, lo script ripiega su quello del Direttore.
MODELLO_DIRETTORE = os.environ.get("STUDIO_MODELLO_DIRETTORE", "anthropic/claude-opus-5")
MODELLO_SPECIALISTI = os.environ.get("STUDIO_MODELLO_SPECIALISTI", "anthropic/claude-sonnet-5")

# Limiti per tenere sotto controllo i costi
MAX_AGENTI_SALVATI = 15          # quanti specialisti possono esistere in /agenti
MAX_INCARICHI_PER_LANCIO = 8     # quanti compiti il Direttore può affidare in un lancio
MAX_ITER_DIRETTORE = 40
MAX_ITER_SPECIALISTA = 25

# Soglie oltre le quali serve il permesso di Massimo
MAX_RIGHE_MODIFICA_AUTONOMA = 60     # righe cambiate in una singola modifica
MAX_RIGHE_NUOVO_FILE_AUTONOMO = 150  # righe di un nuovo file di codice

# Percorso di Godot (facoltativo) per far verificare agli agenti che il gioco si avvii senza errori.
# Imposta una volta:  setx GODOT_PATH "C:\percorso\Godot_v4.3-stable_win64.exe"
GODOT_EXE = os.environ.get("GODOT_PATH", "").strip().strip('"')

CARTELLA_AGENTI = ROOT / "agenti"
CARTELLA_OUTPUT = ROOT / "crew_output"
FILE_PROPOSTE = CARTELLA_OUTPUT / "PROPOSTE.md"
FILE_REGISTRO = CARTELLA_OUTPUT / "REGISTRO_MODIFICHE.md"

CARTELLE_ESCLUSE = {
    ".git", ".godot", ".import", "__pycache__", "node_modules",
    ".venv", "venv", "env", ".vs", ".vscode", ".idea", "_claude_tmp",
}
ESTENSIONI_BINARIE = {
    ".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".ico", ".svg",
    ".ogg", ".wav", ".mp3", ".mp4", ".webm",
    ".glb", ".gltf", ".fbx", ".obj", ".blend", ".blend1",
    ".exe", ".pck", ".dll", ".so", ".zip", ".7z", ".rar", ".wasm", ".pdf",
    ".ttf", ".otf", ".woff", ".woff2", ".res", ".scn", ".ctex", ".stex",
}
# File che gli agenti non possono MAI modificare
FILE_INTOCCABILI = {"studio.py", "designer.py", "artista.py", ".gitignore", ".gitattributes"}
# File modificabili solo con permesso
FILE_PROTETTI = {"project.godot", "export_presets.cfg"}
# Categorie in cui gli agenti possono agire da soli
CATEGORIE_AUTONOME = {"bugfix", "tecnico", "documentazione", "asset"}
CATEGORIE_TUTTE = CATEGORIE_AUTONOME | {"gameplay", "feature"}

REGOLE_STUDIO = f"""
REGOLE DELLO STUDIO (valgono per tutti, sempre):
- Il lead designer del gioco è MASSIMO. Le nuove feature e i cambi di gameplay li decide lui.
- Puoi correggere in autonomia BUG di sistemi e gameplay GIÀ ESISTENTI (categoria 'bugfix')
  e fare MIGLIORAMENTI TECNICI (categoria 'tecnico': performance, pulizia codice, grafica, shader,
  audio, texture, animazioni, stabilità), purché il comportamento di gioco resti quello voluto.
- Tutto ciò che cambia COME SI GIOCA (es. come si parcheggiano le auto, economia, regole, nuove
  meccaniche) è 'gameplay' o 'feature': PRIMA usa lo strumento chiedi_permesso e procedi solo se
  ricevi un codice_permesso. Se Massimo rifiuta, NON farlo e annotalo nel resoconto.
- Anche le modifiche grandi (oltre {MAX_RIGHE_MODIFICA_AUTONOMA} righe cambiate) o a project.godot richiedono permesso:
  preferisci sempre modifiche piccole e atomiche.
- Il gioco usa Godot 4.3 e GDScript: l'indentazione è con TAB. Copia il testo_originale esattamente
  come lo vedi in leggi_file.
- Prima di modificare un file, leggilo. Dopo ogni compito completato usa salva_con_git con un
  messaggio breve in italiano. Se è configurato Godot, usa verifica_godot dopo modifiche al codice.
- Non creare cartelle di versione (es. /0.65) e non cancellare file.
- I tuoi documenti, piani e prompt per immagini vanno in 'crew_output/'.
- Percorsi sempre RELATIVI alla root del progetto (es. 'DOcumentazione/ROADMAP.md').
"""


# =============================================================================
# STATO DEL LANCIO
# =============================================================================
class Stato:
    incarichi_affidati = 0
    approvazioni: dict = {}        # codice -> titolo approvato
    da_committare: set = set()     # percorsi relativi (posix) toccati e non ancora committati
    file_bloccati: set = set()     # file con modifiche non committate di Massimo all'avvio (lowercase posix)
    commit_iniziale: str = ""
    agente_corrente: str = "direttore"
    git_ok: bool = False


def adesso(formato="%Y-%m-%d %H:%M"):
    return datetime.datetime.now().strftime(formato)


# =============================================================================
# UTILITÀ PERCORSI
# =============================================================================
def risolvi_percorso(percorso: Optional[str]) -> Path:
    """Percorsi assoluti o relativi alla ROOT; devono restare dentro al progetto."""
    if percorso is None or str(percorso).strip() in ("", ".", "./", "None"):
        return ROOT
    testo = str(percorso).strip().strip('"').strip("'")
    p = Path(testo)
    if not p.is_absolute():
        parti = p.parts
        if parti and parti[0].lower() == ROOT.name.lower():
            p = Path(*parti[1:]) if len(parti) > 1 else Path(".")
        p = ROOT / p
    p = p.resolve()
    root_norm = os.path.normcase(str(ROOT))
    p_norm = os.path.normcase(str(p))
    if p_norm != root_norm and not p_norm.startswith(root_norm + os.sep):
        raise ValueError(f"Il percorso '{percorso}' è fuori dalla cartella del progetto.")
    return p


def relativo(p: Path) -> str:
    try:
        r = p.relative_to(ROOT).as_posix()
        return r if r else "."
    except ValueError:
        return str(p)


def in_zona_libera(p: Path) -> bool:
    """crew_output/ e agenti/ sono il 'quaderno' degli agenti: niente limiti lì."""
    rel = relativo(p).lower()
    return rel.startswith("crew_output/") or rel.startswith("agenti/")


def leggi_testo(p: Path) -> str:
    with open(p, "r", encoding="utf-8", errors="replace", newline="") as fh:
        return fh.read()


def scrivi_testo(p: Path, testo: str):
    p.parent.mkdir(parents=True, exist_ok=True)
    with open(p, "w", encoding="utf-8", newline="") as fh:
        fh.write(testo)


def appendi(p: Path, testo: str):
    p.parent.mkdir(parents=True, exist_ok=True)
    with open(p, "a", encoding="utf-8") as fh:
        fh.write(testo)


def trova_progetto_godot() -> Optional[Path]:
    for cartella, sottocartelle, files in os.walk(ROOT):
        sottocartelle[:] = [d for d in sottocartelle if d not in CARTELLE_ESCLUSE and d.lower() != "build"]
        if "project.godot" in files:
            return Path(cartella)
    return None


# =============================================================================
# GIT
# =============================================================================
def git(*args, timeout=60, grezzo=False):
    try:
        r = subprocess.run(
            ["git", *args], cwd=ROOT, capture_output=True, text=True,
            encoding="utf-8", errors="replace", timeout=timeout,
        )
        if grezzo:
            return r.returncode, r.stdout
        return r.returncode, (r.stdout + r.stderr).strip()
    except FileNotFoundError:
        return 127, "git non trovato nel PATH"
    except subprocess.TimeoutExpired:
        return 124, "git: timeout"


def file_modificati_da_massimo() -> set:
    codice, out = git("status", "--porcelain", "-z", "--untracked-files=all", grezzo=True)
    if codice != 0:
        return set()
    voci = out.split("\0")
    risultato = set()
    salta = False
    for v in voci:
        if salta:
            salta = False
            continue
        if len(v) < 4:
            continue
        stato, percorso = v[:2], v[3:]
        if stato[0] in "RC":
            salta = True
        risultato.add(percorso.replace("\\", "/").lower().rstrip("/"))
    return risultato


def file_bloccato(rel: str) -> bool:
    r = rel.lower()
    if r.startswith("crew_output/") or r.startswith("agenti/"):
        return False
    for b in Stato.file_bloccati:
        if r == b or (b and r.startswith(b + "/")):
            return True
    return False


def commit_file_toccati(messaggio: str) -> str:
    if not Stato.git_ok:
        return "Git non disponibile: modifiche salvate su disco ma senza commit."
    if not Stato.da_committare:
        return "Nessuna modifica da committare."
    files = sorted(Stato.da_committare)
    codice, out = git("add", "--", *files)
    if codice != 0:
        return f"Errore git add: {out}"
    messaggio = f"[studio/{Stato.agente_corrente}] {messaggio.strip()[:150]}"
    codice, out = git("commit", "-m", messaggio, "--", *files)
    if codice != 0:
        if "nothing to commit" in out or "nulla di cui eseguire il commit" in out:
            Stato.da_committare.clear()
            return "Niente da committare (i file non sono cambiati)."
        return f"Errore git commit: {out}"
    Stato.da_committare.clear()
    return f"Commit eseguito: {messaggio}\nFile: {', '.join(files)}"


# =============================================================================
# STRUMENTI DI LETTURA
# =============================================================================
class ElencaInput(BaseModel):
    percorso: Optional[str] = Field(default=".", description="Cartella relativa alla root (es. 'DOcumentazione'). '.' = root.")
    profondita: Optional[int] = Field(default=2, description="Livelli di sottocartelle da mostrare (1-6).")


class ElencaCartellaTool(BaseTool):
    name: str = "elenca_cartella"
    description: str = "Elenca file e sottocartelle del progetto (salta .git, .godot e cache)."
    args_schema: Type[BaseModel] = ElencaInput

    def _run(self, percorso: Optional[str] = ".", profondita: Optional[int] = 2) -> str:
        try:
            base = risolvi_percorso(percorso)
        except ValueError as e:
            return f"Errore: {e}"
        if not base.exists():
            return f"Errore: '{percorso}' non esiste. Prova con percorso '.'."
        if not base.is_dir():
            return f"'{relativo(base)}' è un file: usa leggi_file."
        try:
            profondita = max(1, min(int(profondita or 2), 6))
        except (TypeError, ValueError):
            profondita = 2
        righe = [f"Contenuto di '{relativo(base)}' (profondità {profondita}):"]
        limite, conteggio = 500, 0

        def esplora(cartella: Path, livello: int):
            nonlocal conteggio
            try:
                voci = sorted(cartella.iterdir(), key=lambda x: (not x.is_dir(), x.name.lower()))
            except PermissionError:
                righe.append("  " * livello + "[accesso negato]")
                return
            for v in voci:
                if conteggio >= limite:
                    return
                if v.is_dir():
                    if v.name in CARTELLE_ESCLUSE:
                        continue
                    righe.append("  " * livello + f"[DIR] {v.name}/")
                    conteggio += 1
                    if livello + 1 < profondita:
                        esplora(v, livello + 1)
                else:
                    try:
                        kb = v.stat().st_size / 1024
                    except OSError:
                        kb = 0
                    righe.append("  " * livello + f"{v.name}  ({kb:.1f} KB)")
                    conteggio += 1

        esplora(base, 0)
        if conteggio >= limite:
            righe.append(f"... troncato a {limite} voci: esplora una sottocartella.")
        return "\n".join(righe)


class LeggiInput(BaseModel):
    percorso: str = Field(description="File relativo alla root (es. 'DOcumentazione/ROADMAP.md').")
    riga_inizio: Optional[int] = Field(default=1, description="Prima riga (da 1).")
    numero_righe: Optional[int] = Field(default=400, description="Quante righe (max 1000).")


class LeggiFileTool(BaseTool):
    name: str = "leggi_file"
    description: str = (
        "Legge un file di testo del progetto (.md, .txt, .gd, .tscn, .tres, .json, .cfg, .gdshader...). "
        "Per file lunghi leggi a blocchi con riga_inizio/numero_righe."
    )
    args_schema: Type[BaseModel] = LeggiInput

    def _run(self, percorso: str = None, riga_inizio: Optional[int] = 1, numero_righe: Optional[int] = 400) -> str:
        if not percorso:
            return "Errore: specifica 'percorso'."
        try:
            f = risolvi_percorso(percorso)
        except ValueError as e:
            return f"Errore: {e}"
        if not f.exists():
            return f"Errore: '{percorso}' non esiste. Usa elenca_cartella o cerca_testo."
        if f.is_dir():
            return f"'{relativo(f)}' è una cartella: usa elenca_cartella."
        if f.suffix.lower() in ESTENSIONI_BINARIE:
            return f"'{relativo(f)}' è un file binario ({f.suffix}): non leggibile come testo."
        try:
            inizio = max(1, int(riga_inizio or 1))
        except (TypeError, ValueError):
            inizio = 1
        try:
            quante = max(1, min(int(numero_righe or 400), 1000))
        except (TypeError, ValueError):
            quante = 400
        try:
            tutte = leggi_testo(f).replace("\r\n", "\n").split("\n")
        except Exception as e:
            return f"Errore di lettura: {e}"
        totale = len(tutte)
        blocco = tutte[inizio - 1: inizio - 1 + quante]
        fine = inizio - 1 + len(blocco)
        testa = f"=== {relativo(f)} — righe {inizio}-{fine} di {totale} ===\n"
        coda = f"\n=== Continua con riga_inizio={fine + 1} ===" if fine < totale else ""
        return testa + "\n".join(blocco) + coda


class CercaInput(BaseModel):
    testo: str = Field(description="Parola o frase da cercare (maiuscole/minuscole indifferenti).")
    percorso: Optional[str] = Field(default=".", description="Cartella in cui cercare (default: tutto).")
    estensioni: Optional[str] = Field(
        default=".md,.txt,.gd,.tscn,.tres,.json,.cfg,.gdshader,.godot",
        description="Estensioni separate da virgola.",
    )


class CercaTestoTool(BaseTool):
    name: str = "cerca_testo"
    description: str = "Cerca un testo in tutti i file del progetto; restituisce file:riga: contenuto."
    args_schema: Type[BaseModel] = CercaInput

    def _run(self, testo: str = None, percorso: Optional[str] = ".", estensioni: Optional[str] = None) -> str:
        if not testo:
            return "Errore: specifica 'testo'."
        try:
            base = risolvi_percorso(percorso)
        except ValueError as e:
            return f"Errore: {e}"
        if not base.is_dir():
            return f"Errore: '{percorso}' non è una cartella."
        est = {
            (e if e.strip().startswith(".") else "." + e.strip()).lower()
            for e in (estensioni or ".md,.txt,.gd,.tscn,.tres,.json,.cfg,.gdshader,.godot").split(",")
            if e.strip()
        }
        ago, risultati, limite = testo.lower(), [], 120
        for cartella, sottocartelle, files in os.walk(base):
            sottocartelle[:] = [d for d in sottocartelle if d not in CARTELLE_ESCLUSE]
            for nome in files:
                p = Path(cartella) / nome
                if p.suffix.lower() not in est:
                    continue
                try:
                    with open(p, "r", encoding="utf-8", errors="replace") as fh:
                        for n, riga in enumerate(fh, 1):
                            if ago in riga.lower():
                                risultati.append(f"{relativo(p)}:{n}: {riga.strip()[:200]}")
                                if len(risultati) >= limite:
                                    break
                except Exception:
                    continue
                if len(risultati) >= limite:
                    break
            if len(risultati) >= limite:
                break
        if not risultati:
            return f"Nessun risultato per '{testo}'."
        extra = f"\n... troncato a {limite}." if len(risultati) >= limite else ""
        return f"{len(risultati)} risultati per '{testo}':\n" + "\n".join(risultati) + extra


# =============================================================================
# PERMESSI (Massimo decide)
# =============================================================================
class PermessoInput(BaseModel):
    titolo: str = Field(description="Titolo breve della proposta.")
    descrizione: str = Field(description="Cosa vuoi cambiare, perché, e cosa cambia per il giocatore.")
    file_coinvolti: Optional[str] = Field(default="", description="File che verrebbero modificati.")
    categoria: Optional[str] = Field(default="gameplay", description="gameplay | feature | tecnico | bugfix")


class ChiediPermessoTool(BaseTool):
    name: str = "chiedi_permesso"
    description: str = (
        "Chiede a Massimo (il lead designer) il permesso per una modifica di gameplay/feature o una modifica grande. "
        "Se approva ricevi un codice_permesso da passare a modifica_file/crea_file. Se rifiuta, NON procedere."
    )
    args_schema: Type[BaseModel] = PermessoInput

    def _run(self, titolo: str = "", descrizione: str = "", file_coinvolti: Optional[str] = "",
             categoria: Optional[str] = "gameplay") -> str:
        voce = (
            f"\n## {adesso()} — {titolo}\n"
            f"- Chi chiede: {Stato.agente_corrente}\n- Categoria: {categoria}\n"
            f"- File: {file_coinvolti or '-'}\n\n{descrizione}\n"
        )
        if not sys.stdin or not sys.stdin.isatty():
            appendi(FILE_PROPOSTE, voce + "\n**Esito: IN ATTESA (Massimo non era presente)**\n")
            return ("Massimo non è presente: proposta registrata in crew_output/PROPOSTE.md. "
                    "NON procedere con questa modifica; passa ad altro.")

        print("\n" + "=" * 78)
        print(f"  RICHIESTA DI PERMESSO da: {Stato.agente_corrente}")
        print("=" * 78)
        print(f"  {titolo}")
        print(f"  Categoria: {categoria}   File: {file_coinvolti or '-'}")
        print("-" * 78)
        print(descrizione)
        print("=" * 78)
        print("\a", end="")  # beep
        try:
            risposta = input("Approvi? [s = sì / n = no / oppure scrivi un commento]: ").strip()
        except (EOFError, KeyboardInterrupt):
            risposta = "n"

        if risposta.lower() in ("s", "si", "sì", "y", "yes", "ok"):
            codice = "OK-" + secrets.token_hex(3).upper()
            Stato.approvazioni[codice] = titolo
            appendi(FILE_PROPOSTE, voce + f"\n**Esito: APPROVATA ({codice})**\n")
            return f"APPROVATO da Massimo. codice_permesso={codice} (usalo nelle modifiche di questa proposta)."
        if risposta.lower() in ("n", "no", ""):
            appendi(FILE_PROPOSTE, voce + "\n**Esito: RIFIUTATA**\n")
            return "RIFIUTATO da Massimo. Non fare questa modifica e annotalo nel resoconto."
        appendi(FILE_PROPOSTE, voce + f"\n**Esito: COMMENTO di Massimo:** {risposta}\n")
        return (f"Massimo NON ha approvato, ma ha commentato: \"{risposta}\". "
                "Non hai il permesso: se vuoi, adatta la proposta e richiedi.")


def motivi_per_permesso(categoria: str, righe: int, rel: str, nuovo_file: bool) -> list:
    motivi = []
    if categoria not in CATEGORIE_AUTONOME:
        motivi.append(f"categoria '{categoria}': gameplay e feature le decide Massimo")
    soglia = MAX_RIGHE_NUOVO_FILE_AUTONOMO if nuovo_file else MAX_RIGHE_MODIFICA_AUTONOMA
    if righe > soglia:
        motivi.append(f"modifica grande ({righe} righe, soglia {soglia})")
    if Path(rel).name.lower() in FILE_PROTETTI:
        motivi.append(f"'{Path(rel).name}' è un file protetto")
    return motivi


def controlla_scrivibile(p: Path) -> Optional[str]:
    rel = relativo(p)
    parti = set(Path(rel).parts)
    if parti & CARTELLE_ESCLUSE:
        return f"'{rel}' è in una cartella di sistema: non modificabile."
    if p.name.lower() in FILE_INTOCCABILI:
        return f"'{p.name}' non è modificabile dagli agenti."
    if p.suffix.lower() in ESTENSIONI_BINARIE or p.suffix.lower() == ".import":
        return f"'{rel}' è un file binario/generato: non modificabile come testo."
    if file_bloccato(rel):
        return (f"'{rel}' ha modifiche di Massimo non ancora committate: non toccarlo. "
                "Annotalo nel resoconto come cosa da fare dopo.")
    return None


# =============================================================================
# STRUMENTI DI SCRITTURA
# =============================================================================
class ModificaInput(BaseModel):
    percorso: str = Field(description="File da modificare, relativo alla root.")
    testo_originale: str = Field(description="Testo ESATTO da sostituire (copiato da leggi_file, TAB inclusi). Deve comparire una sola volta: includi abbastanza contesto.")
    testo_nuovo: str = Field(description="Testo che prende il posto di testo_originale.")
    categoria: str = Field(description="bugfix | tecnico | documentazione | asset | gameplay | feature")
    motivo: str = Field(description="Perché fai questa modifica (una frase).")
    codice_permesso: Optional[str] = Field(default=None, description="Codice ricevuto da chiedi_permesso, se serve.")


class ModificaFileTool(BaseTool):
    name: str = "modifica_file"
    description: str = (
        "Modifica un file di testo sostituendo un pezzo esatto con uno nuovo. "
        "Usalo per bugfix e miglioramenti tecnici. Gameplay/feature o modifiche grandi richiedono codice_permesso."
    )
    args_schema: Type[BaseModel] = ModificaInput

    def _run(self, percorso: str = None, testo_originale: str = None, testo_nuovo: str = "",
             categoria: str = "bugfix", motivo: str = "", codice_permesso: Optional[str] = None) -> str:
        if not percorso or not testo_originale:
            return "Errore: servono 'percorso' e 'testo_originale'."
        categoria = (categoria or "").strip().lower()
        if categoria not in CATEGORIE_TUTTE:
            return f"Errore: categoria deve essere una di {sorted(CATEGORIE_TUTTE)}."
        try:
            f = risolvi_percorso(percorso)
        except ValueError as e:
            return f"Errore: {e}"
        if not f.is_file():
            return f"Errore: '{percorso}' non esiste. Per un file nuovo usa crea_file."
        errore = controlla_scrivibile(f)
        if errore:
            return f"Errore: {errore}"

        grezzo = leggi_testo(f)
        crlf = "\r\n" in grezzo
        contenuto = grezzo.replace("\r\n", "\n")
        vecchio = (testo_originale or "").replace("\r\n", "\n")
        nuovo = (testo_nuovo or "").replace("\r\n", "\n")

        occorrenze = contenuto.count(vecchio)
        if occorrenze == 0:
            # Tentativo: l'agente ha usato 4 spazi al posto dei TAB
            v2, n2 = vecchio.replace("    ", "\t"), nuovo.replace("    ", "\t")
            if contenuto.count(v2) == 1:
                vecchio, nuovo, occorrenze = v2, n2, 1
        if occorrenze == 0:
            prima = vecchio.strip().split("\n")[0].strip()
            simili = difflib.get_close_matches(prima, [r.strip() for r in contenuto.split("\n")], n=3, cutoff=0.6)
            suggerimento = ("\nRighe simili trovate:\n" + "\n".join(simili)) if simili else ""
            return ("Errore: testo_originale non trovato nel file. Rileggi il file con leggi_file e copia "
                    "il testo esatto (TAB inclusi)." + suggerimento)
        if occorrenze > 1:
            return f"Errore: testo_originale compare {occorrenze} volte. Aggiungi righe di contesto per renderlo unico."

        risultato = contenuto.replace(vecchio, nuovo, 1)
        diff = list(difflib.unified_diff(contenuto.split("\n"), risultato.split("\n"), lineterm="", n=0))
        righe_cambiate = sum(1 for r in diff if (r.startswith("+") or r.startswith("-"))
                             and not r.startswith("+++") and not r.startswith("---"))

        if not in_zona_libera(f):
            motivi = motivi_per_permesso(categoria, righe_cambiate, relativo(f), nuovo_file=False)
            if motivi and codice_permesso not in Stato.approvazioni:
                return ("SERVE IL PERMESSO DI MASSIMO: " + "; ".join(motivi) +
                        ". Usa chiedi_permesso spiegando la modifica, poi riprova con il codice_permesso ricevuto. "
                        "Oppure spezza la modifica in parti più piccole se è solo tecnica.")

        if crlf:
            risultato = risultato.replace("\n", "\r\n")
        scrivi_testo(f, risultato)
        rel = relativo(f)
        Stato.da_committare.add(rel)
        appendi(FILE_REGISTRO, f"- {adesso()} [{Stato.agente_corrente}] {categoria} {rel} "
                               f"({righe_cambiate} righe): {motivo}\n")
        anteprima = "\n".join(diff[:40])
        return f"OK: '{rel}' modificato ({righe_cambiate} righe). Ricorda salva_con_git a fine compito.\n{anteprima}"


class CreaInput(BaseModel):
    percorso: str = Field(description="Percorso del nuovo file, relativo alla root. Documenti e prompt vanno in 'crew_output/'.")
    contenuto: str = Field(description="Contenuto completo del file.")
    categoria: str = Field(description="bugfix | tecnico | documentazione | asset | gameplay | feature")
    motivo: str = Field(description="Perché crei questo file.")
    codice_permesso: Optional[str] = Field(default=None, description="Codice da chiedi_permesso, se serve.")


class CreaFileTool(BaseTool):
    name: str = "crea_file"
    description: str = (
        "Crea un NUOVO file di testo (script, shader, documento, prompt per immagini...). "
        "Non sovrascrive file esistenti del gioco (usa modifica_file). In 'crew_output/' puoi anche sovrascrivere."
    )
    args_schema: Type[BaseModel] = CreaInput

    def _run(self, percorso: str = None, contenuto: str = "", categoria: str = "documentazione",
             motivo: str = "", codice_permesso: Optional[str] = None) -> str:
        if not percorso:
            return "Errore: specifica 'percorso'."
        categoria = (categoria or "").strip().lower()
        if categoria not in CATEGORIE_TUTTE:
            return f"Errore: categoria deve essere una di {sorted(CATEGORIE_TUTTE)}."
        try:
            f = risolvi_percorso(percorso)
        except ValueError as e:
            return f"Errore: {e}"
        if re.search(r"(^|/)v?\d+\.\d+[a-z]?(/|$)", relativo(f).lower()):
            return "Errore: vietato creare cartelle di versione (es. /0.65). Si lavora solo con git."
        errore = controlla_scrivibile(f)
        if errore:
            return f"Errore: {errore}"
        libera = in_zona_libera(f)
        if f.exists() and not libera:
            return f"Errore: '{relativo(f)}' esiste già. Usa modifica_file."
        righe = (contenuto or "").count("\n") + 1
        if not libera:
            motivi = motivi_per_permesso(categoria, righe, relativo(f), nuovo_file=True)
            if motivi and codice_permesso not in Stato.approvazioni:
                return ("SERVE IL PERMESSO DI MASSIMO: " + "; ".join(motivi) +
                        ". Usa chiedi_permesso, poi riprova con il codice_permesso.")
        scrivi_testo(f, contenuto or "")
        rel = relativo(f)
        Stato.da_committare.add(rel)
        appendi(FILE_REGISTRO, f"- {adesso()} [{Stato.agente_corrente}] {categoria} NUOVO {rel} ({righe} righe): {motivo}\n")
        return f"OK: creato '{rel}' ({righe} righe)."


class CommitInput(BaseModel):
    messaggio: str = Field(description="Descrizione breve in italiano di cosa hai fatto (es. 'Fix audio clacson che non si fermava').")


class SalvaConGitTool(BaseTool):
    name: str = "salva_con_git"
    description: str = "Fa git add + commit dei SOLI file modificati dagli agenti. Usalo alla fine di ogni compito atomico."
    args_schema: Type[BaseModel] = CommitInput

    def _run(self, messaggio: str = "Modifiche dello studio") -> str:
        return commit_file_toccati(messaggio or "Modifiche dello studio")


class VuotoInput(BaseModel):
    pass


class VerificaGodotTool(BaseTool):
    name: str = "verifica_godot"
    description: str = "Avvia Godot in modalità headless sul progetto e riporta errori di script/parse. Usalo dopo modifiche al codice."
    args_schema: Type[BaseModel] = VuotoInput

    def _run(self) -> str:
        if not GODOT_EXE or not Path(GODOT_EXE).exists():
            return "Godot non configurato (variabile GODOT_PATH): verifica non disponibile, rileggi con cura il codice modificato."
        progetto = trova_progetto_godot()
        if not progetto:
            return "project.godot non trovato."
        try:
            r = subprocess.run(
                [GODOT_EXE, "--headless", "--path", str(progetto), "--quit"],
                capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=180,
            )
            testo = r.stdout + "\n" + r.stderr
        except subprocess.TimeoutExpired:
            return "Godot non ha terminato entro 180 secondi."
        except Exception as e:
            return f"Errore nell'avvio di Godot: {e}"
        chiavi = ("error", "parse error", "script error", "failed", "invalid", "warning")
        rilevanti = [r for r in testo.splitlines() if any(k in r.lower() for k in chiavi)]
        if not rilevanti:
            return "Godot si è avviato e chiuso senza errori o warning."
        return "Output rilevante di Godot:\n" + "\n".join(rilevanti[-80:])


# =============================================================================
# GESTIONE AGENTI (il Direttore crea la squadra)
# =============================================================================
def slug(nome: str) -> str:
    s = re.sub(r"[^a-z0-9_]+", "_", (nome or "").lower()).strip("_")
    return s[:40]


def carica_agente(nome: str) -> Optional[dict]:
    p = CARTELLA_AGENTI / f"{slug(nome)}.json"
    if not p.exists():
        return None
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        return None


def salva_agente(dati: dict):
    CARTELLA_AGENTI.mkdir(parents=True, exist_ok=True)
    p = CARTELLA_AGENTI / f"{dati['nome']}.json"
    p.write_text(json.dumps(dati, ensure_ascii=False, indent=2), encoding="utf-8")
    Stato.da_committare.add(relativo(p))


def tutti_gli_agenti() -> list:
    if not CARTELLA_AGENTI.exists():
        return []
    agenti = []
    for p in sorted(CARTELLA_AGENTI.glob("*.json")):
        try:
            agenti.append(json.loads(p.read_text(encoding="utf-8")))
        except Exception:
            continue
    return agenti


class CreaAgenteInput(BaseModel):
    nome: str = Field(description="Nome breve senza spazi (es. 'texture_artist', 'audio_designer').")
    ruolo: str = Field(description="Ruolo professionale (es. 'Texture Artist PSX low-poly').")
    obiettivo: str = Field(description="Obiettivo permanente dello specialista.")
    backstory: str = Field(description="Esperienza e competenze specifiche (Godot 4.3, stile del gioco, Napoli...).")
    area: str = Field(description="Branca di cui si occupa: grafica, animazioni, texture, audio, ui, codice, performance, documentazione...")
    puo_modificare_file: Optional[bool] = Field(default=True, description="False = può solo leggere e scrivere in crew_output.")
    aggiorna: Optional[bool] = Field(default=False, description="True per aggiornare uno specialista già esistente.")


class CreaAgenteTool(BaseTool):
    name: str = "crea_agente"
    description: str = (
        "Crea (e salva per i lanci futuri) un nuovo specialista dedicato a una piccola branca del gioco. "
        "Controlla PRIMA con elenca_agenti che non esista già uno specialista adatto."
    )
    args_schema: Type[BaseModel] = CreaAgenteInput

    def _run(self, nome: str = "", ruolo: str = "", obiettivo: str = "", backstory: str = "",
             area: str = "", puo_modificare_file: Optional[bool] = True, aggiorna: Optional[bool] = False) -> str:
        n = slug(nome)
        if not n or not ruolo or not obiettivo:
            return "Errore: servono almeno nome, ruolo e obiettivo."
        esistente = carica_agente(n)
        if esistente and not aggiorna:
            return f"Esiste già lo specialista '{n}' ({esistente.get('ruolo')}). Usalo con affida_compito, o passa aggiorna=true."
        if not esistente and len(tutti_gli_agenti()) >= MAX_AGENTI_SALVATI:
            return f"Limite di {MAX_AGENTI_SALVATI} specialisti raggiunto: riusa quelli esistenti."
        dati = esistente or {"nome": n, "creato_il": adesso(), "incarichi": 0, "memoria": []}
        dati.update({
            "ruolo": ruolo.strip(), "obiettivo": obiettivo.strip(), "backstory": backstory.strip(),
            "area": (area or "").strip(), "puo_modificare_file": bool(puo_modificare_file),
            "aggiornato_il": adesso(),
        })
        salva_agente(dati)
        azione = "aggiornato" if esistente else "creato"
        print(f"\n>>> Il Direttore ha {azione} lo specialista: {n} — {ruolo}\n")
        return f"Specialista '{n}' {azione} e salvato in agenti/{n}.json."


class ElencaAgentiTool(BaseTool):
    name: str = "elenca_agenti"
    description: str = "Mostra gli specialisti già esistenti nello studio, con area, numero di incarichi e ultimo lavoro."
    args_schema: Type[BaseModel] = VuotoInput

    def _run(self) -> str:
        agenti = tutti_gli_agenti()
        if not agenti:
            return "Nessuno specialista ancora. Creane con crea_agente quando servono."
        righe = [f"Specialisti ({len(agenti)}/{MAX_AGENTI_SALVATI}):"]
        for a in agenti:
            ultimo = a.get("memoria", [])[-1]["compito"][:120] if a.get("memoria") else "-"
            righe.append(
                f"- {a['nome']}: {a.get('ruolo')} | area: {a.get('area')} | incarichi: {a.get('incarichi', 0)} "
                f"| modifica file: {'sì' if a.get('puo_modificare_file', True) else 'no'} | ultimo: {ultimo}"
            )
        righe.append(f"Incarichi usati in questo lancio: {Stato.incarichi_affidati}/{MAX_INCARICHI_PER_LANCIO}")
        return "\n".join(righe)


def strumenti_lettura():
    return [ElencaCartellaTool(), LeggiFileTool(), CercaTestoTool()]


def strumenti_specialista(puo_modificare: bool):
    base = strumenti_lettura() + [CreaFileTool(), ChiediPermessoTool()]
    if puo_modificare:
        base += [ModificaFileTool(), SalvaConGitTool(), VerificaGodotTool()]
    else:
        base += [SalvaConGitTool()]
    return base


def esegui_specialista(dati: dict, compito: str, risultato_atteso: str, modello: str) -> str:
    memoria = dati.get("memoria", [])
    testo_memoria = ""
    if memoria:
        testo_memoria = "\nIL TUO LAVORO PRECEDENTE (per continuità):\n" + "\n".join(
            f"- {m['data']}: {m['compito'][:150]} -> {m['esito'][:300]}" for m in memoria[-5:]
        )
    agente = Agent(
        role=dati["ruolo"],
        goal=dati["obiettivo"],
        backstory=dati.get("backstory", "") + "\n" + REGOLE_STUDIO + testo_memoria,
        llm=modello,
        tools=strumenti_specialista(dati.get("puo_modificare_file", True)),
        allow_delegation=False,
        verbose=True,
        max_iter=MAX_ITER_SPECIALISTA,
    )
    task = Task(
        description=(
            f"{compito}\n\nLavora per piccoli passi atomici. Alla fine di ogni passo completato e funzionante "
            "usa salva_con_git. Se qualcosa richiede il permesso di Massimo, chiedilo con chiedi_permesso."
        ),
        expected_output=(
            f"{risultato_atteso}\n\nChiudi SEMPRE con un resoconto: cosa hai modificato (file), commit fatti, "
            "cosa non hai potuto fare e perché, permessi chiesti ed esito."
        ),
        agent=agente,
    )
    return str(Crew(agents=[agente], tasks=[task], verbose=True).kickoff())


class AffidaInput(BaseModel):
    nome_agente: str = Field(description="Nome dello specialista (da elenca_agenti).")
    compito: str = Field(description="Compito piccolo e preciso, con i file e le info necessarie.")
    risultato_atteso: Optional[str] = Field(default="Resoconto di cosa è stato fatto.", description="Cosa deve consegnare.")


class AffidaCompitoTool(BaseTool):
    name: str = "affida_compito"
    description: str = (
        "Affida un compito piccolo e ben definito a uno specialista esistente, che lo esegue subito "
        "e ti restituisce il resoconto. Un compito = una cosa sola."
    )
    args_schema: Type[BaseModel] = AffidaInput

    def _run(self, nome_agente: str = "", compito: str = "",
             risultato_atteso: Optional[str] = "Resoconto di cosa è stato fatto.") -> str:
        if Stato.incarichi_affidati >= MAX_INCARICHI_PER_LANCIO:
            return (f"Limite di {MAX_INCARICHI_PER_LANCIO} incarichi per lancio raggiunto. "
                    "Chiudi il lancio con il resoconto finale e metti il resto tra i prossimi passi.")
        dati = carica_agente(nome_agente)
        if not dati:
            return f"Lo specialista '{nome_agente}' non esiste. Usa elenca_agenti o crea_agente."
        if not compito:
            return "Errore: specifica il compito."

        Stato.incarichi_affidati += 1
        precedente = Stato.agente_corrente
        Stato.agente_corrente = dati["nome"]
        print(f"\n{'#' * 78}\n# INCARICO {Stato.incarichi_affidati}/{MAX_INCARICHI_PER_LANCIO} "
              f"-> {dati['nome']} ({dati['ruolo']})\n# {compito[:200]}\n{'#' * 78}\n")
        try:
            try:
                esito = esegui_specialista(dati, compito, risultato_atteso or "", MODELLO_SPECIALISTI)
            except Exception as e:
                msg = str(e).lower()
                if MODELLO_SPECIALISTI != MODELLO_DIRETTORE and any(
                    k in msg for k in ("not_found", "not found", "404", "model", "invalid")
                ):
                    print(f"\n[!] Modello specialisti '{MODELLO_SPECIALISTI}' non disponibile ({e}). "
                          f"Ripiego su '{MODELLO_DIRETTORE}'.\n")
                    esito = esegui_specialista(dati, compito, risultato_atteso or "", MODELLO_DIRETTORE)
                else:
                    raise
            # Commit di sicurezza per quanto rimasto in sospeso
            if Stato.da_committare:
                esito += "\n\n[Commit automatico di fine incarico] " + commit_file_toccati(f"Incarico: {compito[:80]}")
        except Exception as e:
            esito = f"L'incarico è fallito con un errore: {e}"
        finally:
            Stato.agente_corrente = precedente

        dati["incarichi"] = dati.get("incarichi", 0) + 1
        dati.setdefault("memoria", []).append({"data": adesso(), "compito": compito[:300], "esito": esito[:600]})
        dati["memoria"] = dati["memoria"][-6:]
        salva_agente(dati)

        file_incarico = CARTELLA_OUTPUT / "incarichi" / f"{adesso('%Y%m%d_%H%M%S')}_{dati['nome']}.md"
        scrivi_testo(file_incarico, f"# Incarico a {dati['nome']}\n\n## Compito\n{compito}\n\n## Esito\n{esito}\n")

        if len(esito) > 6000:
            esito = esito[:6000] + f"\n... (resoconto completo in {relativo(file_incarico)})"
        return f"RESOCONTO DI {dati['nome']}:\n{esito}"


# =============================================================================
# IL DIRETTORE
# =============================================================================
def crea_direttore() -> Agent:
    return Agent(
        role="Direttore dello Studio (Producer tecnico)",
        goal=(
            "Portare 'Parcheggiatore Abusivo Simulator' verso la chiusura: trovare e far correggere bug, "
            "far migliorare la qualità tecnica (grafica, animazioni, texture, audio, performance), "
            "costruendo e coordinando una squadra di specialisti."
        ),
        backstory=(
            "Sei un producer tecnico esperto di giochi indie in Godot. Non scrivi codice tu: capisci lo stato del "
            "progetto, spezzi il lavoro in compiti piccoli e li affidi allo specialista giusto. Se manca uno "
            "specialista per una branca (es. grafica, animazioni, texture, audio, UI, codice/bugfix, performance) "
            "lo CREI con crea_agente, dandogli ruolo, competenze e backstory precise e coerenti con lo stile del gioco. "
            "Riusi sempre gli specialisti esistenti invece di crearne doppioni. Massimo è il lead designer: "
            "le idee di gameplay le raccogli come proposte, non le imponi.\n" + REGOLE_STUDIO
        ),
        llm=MODELLO_DIRETTORE,
        tools=strumenti_lettura() + [ElencaAgentiTool(), CreaAgenteTool(), AffidaCompitoTool(), ChiediPermessoTool()],
        allow_delegation=False,
        verbose=True,
        max_iter=MAX_ITER_DIRETTORE,
    )


def crea_task_direttore(direttore: Agent, obiettivo: str) -> Task:
    return Task(
        description=(
            f"OBIETTIVO DI QUESTO LANCIO (deciso da Massimo):\n{obiettivo}\n\n"
            "Procedura:\n"
            "1) elenca_agenti per vedere la squadra attuale.\n"
            "2) Leggi la documentazione in 'DOcumentazione' (parti da MEMORIA_PROGETTO.md, ROADMAP.md, "
            "CHANGELOG.md, il NOVITA più recente) e, se serve, la struttura del progetto Godot in 'Progetto'.\n"
            "3) Pianifica compiti PICCOLI e atomici legati all'obiettivo.\n"
            "4) Per ogni compito scegli lo specialista giusto; se manca, crealo con crea_agente.\n"
            f"5) Affida i compiti con affida_compito (massimo {MAX_INCARICHI_PER_LANCIO} in questo lancio), "
            "dando allo specialista file e contesto necessari.\n"
            "6) Leggi i resoconti e, se serve, affida un compito correttivo.\n"
            "Non chiedere permessi per cose tecniche; chiedili solo per modifiche di gameplay/feature."
        ),
        expected_output=(
            "Un resoconto in italiano, in Markdown, con:\n"
            "## Fatto — cosa è stato corretto/migliorato, da chi, con quali commit\n"
            "## Squadra — specialisti creati o aggiornati in questo lancio\n"
            "## Proposte per Massimo — idee di gameplay/feature che richiedono la sua decisione\n"
            "## Problemi aperti — cosa non è stato possibile fare e perché\n"
            "## Prossimi passi consigliati — compiti per il prossimo lancio"
        ),
        agent=direttore,
    )


# =============================================================================
# AVVIO
# =============================================================================
def main():
    if not os.environ.get("ANTHROPIC_API_KEY"):
        print("ERRORE: variabile ANTHROPIC_API_KEY non impostata.")
        print('Esegui:  setx ANTHROPIC_API_KEY "la-tua-chiave"   e riapri il terminale.')
        sys.exit(1)
    if not ROOT.exists():
        print(f"ERRORE: cartella del progetto non trovata: {ROOT}")
        sys.exit(1)

    os.chdir(ROOT)
    CARTELLA_OUTPUT.mkdir(parents=True, exist_ok=True)
    CARTELLA_AGENTI.mkdir(parents=True, exist_ok=True)

    codice, out = git("rev-parse", "HEAD")
    Stato.git_ok = codice == 0
    if Stato.git_ok:
        Stato.commit_iniziale = out.strip()
        Stato.file_bloccati = file_modificati_da_massimo()
    else:
        print(f"[!] Git non disponibile ({out}). Le modifiche verranno salvate senza commit.")

    if len(sys.argv) > 1:
        obiettivo = " ".join(sys.argv[1:]).strip()
    else:
        predefinito = (
            "Controlla lo stato del progetto: individua e correggi bug nei sistemi esistenti, fai miglioramenti "
            "tecnici utili (stabilità, performance, grafica, audio) e raccogli come proposte per Massimo le idee "
            "di gameplay."
        )
        print("Qual è l'obiettivo di questo lancio? (Invio = controllo generale)")
        try:
            obiettivo = input("> ").strip() or predefinito
        except (EOFError, KeyboardInterrupt):
            obiettivo = predefinito

    print("\n" + "=" * 78)
    print("  LO STUDIO — Parcheggiatore Abusivo Simulator")
    print("=" * 78)
    print(f"  Obiettivo:   {obiettivo}")
    print(f"  Direttore:   {MODELLO_DIRETTORE}")
    print(f"  Specialisti: {MODELLO_SPECIALISTI}")
    print(f"  Squadra:     {len(tutti_gli_agenti())} specialisti salvati")
    print(f"  Godot:       {'configurato' if GODOT_EXE and Path(GODOT_EXE).exists() else 'non configurato (GODOT_PATH)'}")
    if Stato.file_bloccati:
        print(f"  Bloccati:    {len(Stato.file_bloccati)} file con tue modifiche non committate (gli agenti non li toccano)")
    print("=" * 78 + "\n")

    Stato.agente_corrente = "direttore"
    direttore = crea_direttore()
    task = crea_task_direttore(direttore, obiettivo)
    try:
        risultato = str(Crew(agents=[direttore], tasks=[task], verbose=True).kickoff())
    except KeyboardInterrupt:
        risultato = "Lancio interrotto da Massimo (Ctrl+C)."
        print("\n" + risultato)

    file_report = CARTELLA_OUTPUT / f"report_{adesso('%Y%m%d_%H%M')}.md"
    scrivi_testo(file_report, f"# Report dello Studio — {adesso()}\n\n**Obiettivo:** {obiettivo}\n\n{risultato}\n")
    Stato.da_committare.add(relativo(file_report))
    if (FILE_REGISTRO).exists():
        Stato.da_committare.add(relativo(FILE_REGISTRO))
    if FILE_PROPOSTE.exists():
        Stato.da_committare.add(relativo(FILE_PROPOSTE))
    for p in (CARTELLA_OUTPUT / "incarichi").glob("*.md") if (CARTELLA_OUTPUT / "incarichi").exists() else []:
        Stato.da_committare.add(relativo(p))
    Stato.agente_corrente = "direttore"
    print("\n" + commit_file_toccati("Report del lancio e aggiornamento squadra"))

    print("\n=== RESOCONTO DEL DIRETTORE ===\n")
    print(risultato)
    print(f"\n(Report salvato in {relativo(file_report)})")
    if Stato.git_ok and Stato.commit_iniziale:
        _, log = git("log", "--oneline", f"{Stato.commit_iniziale}..HEAD")
        if log:
            print("\nCommit di questo lancio (per annullarne uno: git revert <codice>):")
            print(log)


if __name__ == "__main__":
    main()
