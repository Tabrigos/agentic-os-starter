# Agentic OS — un second brain che si auto-migliora

Un vault [Obsidian](https://obsidian.md) organizzato col metodo PARA, gestito da
[Claude Code](https://claude.com/claude-code), che ogni settimana cerca il modo
di diventare più capace. Note in markdown, nessun database, nessun lock-in: se
domani togli l'agente, ti resta una cartella di file di testo.

Non è un prodotto: è un sistema personale, documentato fin nelle motivazioni,
fatto per essere clonato e reso proprio.

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

## Installarlo: chiedilo all'assistente

Il progetto si installa da sé. Non serve leggere questo file fino in fondo prima
di cominciare.

1. **Installa Claude Code** e fai il login una volta sola, lanciando `claude` e
   seguendo il browser. Su Windows: `irm https://claude.ai/install.ps1 | iex`
2. **Scarica il progetto**, con `git clone` o come archivio zip
3. **Apri un terminale dentro la cartella** e scrivi `claude`
4. **Scrivi `/installa`**

Da lì in poi ci pensa l'assistente: ti racconta cos'è, controlla cosa hai già
sulla macchina, ti dice cosa manca e con quale comando si ottiene, e installa
**solo dopo che gli hai detto di sì**. Se preferisci prima capire, chiedigli
"cos'è questo progetto?" e rispondi dopo.

Va bene anche non usare il comando: se apri `claude` qui dentro e chiedi "come
si installa?", finisce nello stesso posto.

## ⚠️ Le tue note e il fork pubblico

Se hai preso il progetto con un **fork**, quel fork è pubblico come l'originale,
e al primo `git push` le tue note finirebbero online.

Il vault deve stare in un **repo privato tuo**. Creane uno vuoto, puntaci
`origin`, e il sync orario fa il resto. Se non ti interessa il backup su un
remoto, togli semplicemente `origin` e resta tutto in locale: il sistema
funziona lo stesso, con la storia git sul tuo disco.

## Cosa ti serve

| Cosa | Perché | Obbligatorio |
|---|---|---|
| Claude Code | è l'agente che fa il lavoro | sì |
| git | storia, rollback, backup | sì |
| Podman | Obsidian e dashboard girano in container | sì |
| node | marca la cartella come fidata in automatico | no |
| GitHub CLI (`gh`) | solo se cloni via `gh` | no |

**Sul runtime, per essere chiari**: il sistema è costruito su Podman, e le
automazioni sull'host lo invocano per nome. Con solo Docker i container
partirebbero, ma sync orario, pulsanti della dashboard e test deterministici no.
Podman si installa in un comando e convive con Docker senza problemi.

Su Windows: `winget install Git.Git RedHat.Podman`, poi `podman machine init` e
`podman machine start`. Su Debian o Ubuntu: `sudo apt install git podman
podman-compose`.

## Quanto costa farlo girare

Il lavoro lo fa Claude Code, quindi il sistema consuma il tuo utilizzo di
Claude. Meglio saperlo prima di installarlo che dopo.

- le skill di tutti i giorni (`/brief`, `/processa-inbox`, `/weekly-review`)
  sono corte e girano sul modello economico
- **`/evolvi` è l'unica cosa cara**: gira sul modello top, legge il web e ragiona
  su cosa cambiare nel sistema. Arriva in pausa apposta, e si lancia a mano
- la eval suite apre sei sessioni headless di fila: lanciala quando cambi
  qualcosa, non per abitudine

Ogni percorso automatico dichiara il proprio modello, quindi un `/model` scelto
in sessione non cambia di nascosto il costo delle run schedulate.

## Cosa è esposto in rete

Le due interfacce web sono legate a **localhost**: si aprono dal browser del
computer su cui gira il sistema, non dagli altri computer della rete. È una
scelta, non una dimenticanza. L'interfaccia di Obsidian non ha password, e su
Linux una porta pubblicata senza indirizzo finisce su **tutte** le interfacce:
il vault sarebbe leggibile da chiunque stia sulla stessa wifi.

Se vuoi aprirlo di proposito, per leggere le note dal tablet o da un altro PC,
servono due cose **in quest'ordine**: prima una password sull'interfaccia di
Obsidian, con le variabili `CUSTOM_USER` e `PASSWORD` fra le `environment` del
servizio (immagine linuxserver), e solo dopo togli `127.0.0.1:` dalle righe
delle porte in `compose.yaml`.

## Le tre finestre

| Finestra | A cosa serve | Dove |
|---|---|---|
| **Obsidian** | per te: leggere, scrivere, navigare | http://localhost:3000 |
| **Claude Code** | per l'agente: le skill, con dialogo | `claude` nella cartella |
| **Dashboard** | cruscotto a pulsanti, semafori di salute | http://localhost:3210 |

Il vault arriva con qualche nota d'esempio, giusto per vedere le skill al
lavoro. Cancellale quando hai capito come funziona.

Obsidian è configurato ma **senza tema**: se vuoi lo stesso aspetto, installa
*Minimal* di kepano dai temi della community. Lo snippet del sistema è già lì.

## I due riti

Il sistema resta vivo con due abitudini, non di più.

- **`/brief` al mattino**: scadenze, progetti, inbox. Due minuti, e sai dove
  mettere l'energia oggi
- **La sezione 🧬 della Dashboard il lunedì**: approvi o bocci le proposte che
  `/evolvi` ha lasciato lì. Senza questo, il sistema smette di crescere

`/evolvi` arriva **in pausa**: si lancia a mano, dal pulsante della dashboard o
dallo script. La schedulazione si attiva quando ti fidi del ciclo.

## Cosa c'è dentro

| Componente | Cosa fa |
|---|---|
| `vault/` | la memoria: cartelle PARA, costituzione del sistema, template |
| `.claude/skills/` | brief, smistamento inbox, nuovo progetto, revisione settimanale, distillazione di fonti, restyling frontend, ciclo di evoluzione |
| `.claude/agents/` | subagenti su modello economico: distillatore, ricercatore, scettico |
| `dashboard/` | container con Claude Code headless: cruscotto, generatore dell'indice, sync git |
| `automation/` | colla per-OS: bootstrap, sync orario, lucchetto anti-conflitto |
| `tests/` | eval suite: misura le skill su un vault sintetico e dà un punteggio |
| `media-tools/` | container per trascrizioni ed estrazioni, usato da `/distilla` |

## Installarlo a mano

Se preferisci fare da te, invece dei passi qui sopra:

```powershell
git clone https://github.com/Tabrigos/agentic-os-starter "$env:USERPROFILE\lavoro\agentic-os"
cd "$env:USERPROFILE\lavoro\agentic-os"
powershell -ExecutionPolicy Bypass -File automation\setup-pc.ps1
```

Su Linux: clona dove preferisci, poi `sh automation/setup-linux.sh`.

Lo script capisce da solo che la cartella giusta è il clone in cui si trova.
Marca la cartella come fidata per Claude Code, avvia i container e registra il
sync orario. Verifica finale: `claude` nella cartella, poi `/brief`.

**Tieni il nome della cartella `agentic-os`**: la documentazione e il ponte coi
repo di progetto usano `%USERPROFILE%\lavoro\agentic-os` come convenzione (su
Linux `~/lavoro/agentic-os`).

## Prima di fidarti: come sono fatti i permessi

Questo sistema esegue un agente in headless, cioè senza nessuno che approvi. Le
difese stanno in `.claude/settings.json` e sono tre:

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
- **Il perché** è `vault/99-Sistema/Architettura e filosofia.md`: principi e alternative scartate
- **Come si usa** è `vault/99-Sistema/Guida all'uso.md`
- **Le regole del repo** sono in `CLAUDE.md` alla radice

Il sistema è in **italiano** e l'agente risponde in italiano: è una scelta
scritta nella costituzione, si cambia lì.

## Licenza

MIT, vedi `LICENSE`. Le note del vault d'esempio sono contenuto fittizio.
