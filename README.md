# Agentic OS — un second brain che si auto-migliora

Un vault [Obsidian](https://obsidian.md) organizzato col metodo PARA, gestito da
[Claude Code](https://claude.com/claude-code), che ogni settimana cerca il modo
di diventare più capace. Note in markdown, nessun database, nessun lock-in: se
domani togli l'agente, ti restano dei file di testo.

Non è un prodotto: è un sistema personale, documentato fin nelle motivazioni,
pensato per essere clonato e reso proprio.

```
┌─ 5. EVAL SUITE ────────── tests/: misura le skill, baseline vs regressioni ─┐
│ ┌─ 4. DASHBOARD ───────── Dashboard.md: stato, proposte, pulsanti ────────┐ │
│ │ ┌─ 3. AUTOMAZIONI ───── sync orario, /evolvi settimanale ─────────────┐ │ │
│ │ │ ┌─ 2. SKILL ───────── .claude/skills/: brief, inbox, review, ... ─┐ │ │ │
│ │ │ │ ┌─ 1. MEMORIA ───── vault/ markdown (PARA) + Registro attività ┐│ │ │ │
│ │ │ │ └──────────────────────────────────────────────────────────────┘│ │ │ │
│ │ │ └──────────────────────────────────────────────────────────────────┘ │ │ │
│ │ └──────────────────────────────────────────────────────────────────────┘ │ │
│ └──────────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────┘
   Infrastruttura: Obsidian e dashboard in container Podman, repo git
```

## Cosa c'è dentro

| Componente | Cosa fa |
|---|---|
| `vault/` | La memoria: cartelle PARA, costituzione del sistema, template |
| `.claude/skills/` | Sette skill: brief, smistamento inbox, nuovo progetto, weekly review, distillazione di fonti, restyling frontend, e il ciclo di evoluzione |
| `.claude/agents/` | Subagenti su modello economico: distillatore, ricercatore, scettico |
| `dashboard/` | Container con Claude Code headless: cruscotto a pulsanti su `:3210`, generatore dell'indice, sync git |
| `automation/` | Colla per-OS: bootstrap, sync orario, lucchetto anti-conflitto |
| `tests/` | Eval suite: misura le skill su un vault sintetico e dà un punteggio |
| `media-tools/` | Container per trascrizioni e estrazioni, usato da `/distilla` |
| `compose.yaml` | Obsidian su `:3000`, dashboard su `:3210` |

## Le tre finestre

| Finestra | A cosa serve | Dove |
|---|---|---|
| **Obsidian** | Per te: leggere, scrivere, navigare | http://localhost:3000 |
| **Claude Code** | Per l'agente: le skill, con dialogo | `claude` nella cartella |
| **Dashboard** | Cruscotto a pulsanti, semafori di salute | http://localhost:3210 |

## Installazione

Prerequisiti, una volta sola.

Windows (PowerShell):

```powershell
winget install Git.Git GitHub.cli
irm https://claude.ai/install.ps1 | iex
winget install RedHat.Podman
podman machine init; podman machine start
```

Linux: installa `git`, `podman` (con `podman-compose` o `docker-compose`) e
Claude Code col package manager della distro.

Poi fai il login una volta a `gh auth login -w -p https` e una volta a `claude`,
che crea il token store montato dai container.

Installazione vera e propria:

```powershell
git clone https://github.com/Tabrigos/agentic-os-starter "$env:USERPROFILE\lavoro\agentic-os"
cd "$env:USERPROFILE\lavoro\agentic-os"
powershell -ExecutionPolicy Bypass -File automation\setup-pc.ps1
```

Su Linux: `git clone https://github.com/Tabrigos/agentic-os-starter ~/lavoro/agentic-os` e poi
`sh automation/setup-linux.sh`.

Lo script marca la cartella come trusted per Claude Code, avvia i container e
registra il sync orario. **Tieni il nome della cartella `agentic-os`**: la
documentazione e il ponte coi repo di progetto usano quel percorso come
convenzione (`%USERPROFILE%\lavoro\agentic-os`, su Linux `~/lavoro/agentic-os`).

Verifica finale: `claude` nella cartella, poi `/brief`.

Il vault arriva con la configurazione di Obsidian già pronta ma **senza tema**:
se vuoi lo stesso aspetto, installa *Minimal* di kepano dai temi della community
(Impostazioni → Aspetto → Temi). Lo snippet CSS del sistema è già incluso e attivo.

## I primi passi

Il vault arriva con qualche nota d'esempio, giusto per vedere le skill al lavoro.

1. `/brief` — il rito del mattino: scadenze, progetti, inbox
2. `/processa-inbox` — guarda dove finiscono le note d'esempio e perché
3. Cancella gli esempi e mettici la tua roba
4. `tests\run-evals.ps1` — fissa la tua baseline, così saprai se un'evoluzione peggiora le skill

Poi ci sono **due riti** che tengono vivo il sistema. `/brief` al mattino, e il
lunedì la sezione 🧬 della Dashboard, dove approvi o bocci le proposte di
`/evolvi`. Senza il secondo, il sistema smette di crescere.

## Prima di fidarti: leggi come sono fatti i permessi

Questo sistema esegue un agente in headless, cioè senza nessuno che approvi.
Le difese sono tre e stanno in `.claude/settings.json`:

- una **allow-list stretta**: ogni voce nomina il comando e i suoi argomenti, mai `Bash(*)`
- un **`defaultMode`** dichiarato, perché la forza di una allow-list dipende dalla modalità
- una lista **`deny`** scritta sugli esecutori (`bash`, `sh`, `dig`), che blocca in *ogni* modalità

Il perché, con i due casi reali che hanno prodotto queste regole, sta nei
principi 10 e 11 di `vault/99-Sistema/Architettura e filosofia.md`. Se allarghi
una regola per comodità stai prendendo una decisione di sicurezza: fallo
sapendolo.

**Un'eccezione deliberata**: `tests/run-evals.ps1` sovrascrive il
`settings.local.json` del *testbed* con quattro regole larghe. È voluto e
documentato in `CLAUDE.md`. Vale solo per la copia usa-e-getta del vault
sintetico, mai per il vault vero. Non "sistemarlo" per coerenza: rompe la suite.

## Renderlo tuo

- **La costituzione** è `vault/CLAUDE.md`: struttura, convenzioni, regole operative
- **Il perché** è `vault/99-Sistema/Architettura e filosofia.md`: principi e decisioni scartate
- **Come si usa** è `vault/99-Sistema/Guida all'uso.md`
- **Le regole del repo** sono in `CLAUDE.md` alla radice

Il sistema è in **italiano** e l'agente risponde in italiano: è una scelta scritta
nella costituzione, si cambia lì.

Per il backup e il multi-PC serve un tuo repo git privato: crealo, punta `origin`
lì e il sync orario fa il resto. Il vault non deve stare in un repo pubblico.

## Licenza

MIT, vedi `LICENSE`. Le note del vault d'esempio sono contenuto fittizio.
