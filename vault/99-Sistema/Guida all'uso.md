---
tipo: sistema
tag: [guida]
creata: 2026-07-03
descrizione: Guida utente rapida - le due finestre, il flusso quotidiano, dove sta cosa e i comandi essenziali
---

# Guida all'uso

## Le finestre (un solo cervello)

Il second brain sono i **file markdown in `vault/`**. Ci sono tre modi di toccarli:

| Finestra | A cosa serve | Come si apre |
|---|---|---|
| **Obsidian** (browser) | Per te: leggere, scrivere note, navigare Dashboard e report | http://localhost:3000 → vault `/vault` |
| **Claude Code** (terminale) | Per l'agente: le skill (`/brief`, `/processa-inbox`…), con dialogo | `cd %USERPROFILE%\lavoro\agentic-os` poi `claude` |
| **Dashboard one-click** (browser) | Cruscotto operativo: pulsanti con badge, semafori di salute (inbox, brief, review, eval, sync), ultima run in markdown, sync forzato | parte con lo stack (`podman compose up -d`) → http://localhost:3210; scorciatoia: `automation\dashboard.cmd` (Linux: `dashboard.sh`) |

La dashboard lancia le skill in headless (senza dialogo): per le operazioni che
richiedono conferme o decisioni resta meglio il terminale.

Le skill **non** sono dentro Obsidian: la [[Dashboard]] le elenca, ma si lanciano
dal terminale. Le due finestre convivono: lanci una skill e vedi la Dashboard
aggiornarsi in Obsidian.

## Il flusso: orientarsi qui, lavorare nei progetti

Le sessioni hanno ruoli diversi — non si lavora sul codice da dentro l'agentic-os:

1. **Mattina (2 min)** — Claude Code in `agentic-os` → `/brief`: task in scadenza,
   stato dei progetti, inbox. Decidi dove va l'energia oggi.
2. **Giornata** — lavori nei progetti come sempre: Claude Code *dentro* la cartella
   del progetto (lì ci sono contesto e permessi giusti). Idee e appunti volanti →
   due righe in `00-Inbox/`, senza organizzarle. Documenti da assimilare (PDF,
   Word, testo) → una copia in `00-Inbox/`; link YouTube o pagine web → incollali
   in una nota: `/distilla` li trasforma in conoscenza (e le copie si eliminano da sole).
3. **Chiusura di una sessione di lavoro (30 sec)** — prima di chiudere, di' a Claude:
   *"aggiorna il vault"*. Il CLAUDE.md di ogni progetto contiene il **ponte**: il
   contratto che definisce cosa leggere a inizio sessione (la scheda) e cosa
   aggiornare alla fine (Log, task, `prossimo:`, decisioni) — testo canonico in
   [[template-ponte-progetto]], percorso risolto dalla convenzione
   `%USERPROFILE%\lavoro\agentic-os`, uguale su ogni PC. Le scoperte durevoli
   fatte in progetto viaggiano verso il cervello via `00-Inbox/`.
4. **Lunedì (10 min)** — sezione 🧬 della [[Dashboard]]: approva o boccia le proposte
   di `/evolvi`, scorri il [[Changelog evoluzione]]. Senza questo rito il sistema
   smette di crescere.
5. **Quando serve** — `/processa-inbox` se l'inbox si accumula; `/weekly-review` a
   fine settimana. Per trasformare un flusso appena riuscito in una skill basta
   chiederlo in sessione: la skill dedicata `/impara` è stata ritirata il
   2026-07-26 (zero usi in 23 giorni) perché quel lavoro lo facevano già
   `/evolvi` o una sessione diretta — è nata così `/restyling-frontend`.

## Il ponte coi progetti (come si lavora nei repo)

Ogni repo di progetto ha nel suo `CLAUDE.md` il blocco "Second brain" — il
**ponte** (testo canonico: [[template-ponte-progetto]]; design:
2026-07-05 Il ponte progetto-cervello). In pratica:

1. **Apri la sessione nel repo** (`claude` dentro la cartella del progetto) e
   chiedi "dove eravamo rimasti?": l'agente legge la scheda in `01-Progetti/` —
   rotta, decisioni, task — e riparte da lì
2. **Lavori normalmente**; se emerge una scoperta durevole (fonte, idea,
   conoscenza), l'agente butta due righe in `00-Inbox/` del cervello: il
   triage la smisterà
3. **Chiudi con "aggiorna il vault"**: log, task, `prossimo:` e decisioni
   finiscono nella scheda — il brief di domattina e le viste della Dashboard
   li vedono da soli
4. **Nuovo progetto con repo?** `/nuovo-progetto` propone l'installazione del
   ponte; l'aggiornamento dei ponti quando il cervello evolve è compito del
   cervello, non tuo

## Dove sta cosa

- **[[Dashboard]]** — la home: oggi, progetti, inbox, proposte di evoluzione, skill
- **[[Indice]]** — una riga per ogni nota del vault
- **Report di /evolvi** — `03-Risorse/Evoluzione/` (i "Tech radar" settimanali)
- **[[Architettura e filosofia]]** — perché il sistema è fatto così
- **[[Registro attività]]** — cosa hanno fatto le skill, run dopo run
- **Storico e rollback** — repo git in `agentic-os/`: ogni evoluzione è un commit

## Comandi essenziali

```
podman compose up -d      # avvia Obsidian (dalla cartella agentic-os)
podman compose down       # ferma il container
claude                    # apri l'agente (dalla cartella agentic-os)
automation\dashboard.cmd  # dashboard one-click su http://localhost:3210
git log --oneline         # storia delle evoluzioni
git revert <commit>       # annulla un'evoluzione
tests\run-evals.ps1       # misura le skill e confronta con la baseline
```

## Più PC: come funziona la sincronizzazione

Il cervello "vero" è il **tuo** repo git privato; ogni PC è
un clone. L'attività pianificata `AgenticOS-Sync` allinea tutto ogni ora (commit
locale → pull → push); per forzare subito: `automation\sync.ps1`.

- **Nuovo PC**: installa git + Claude Code + gh (autenticato, `gh auth login`),
  poi scarica ed esegui `automation/setup-pc.ps1` dal repo — clona, marca trusted,
  avvia il container e registra il sync orario
- **Un solo primario**: le automazioni schedulate girano SOLO sul PC primario;
  `/evolvi` arriva **in pausa** — solo esecuzione manuale
  (pulsante Evolvi della dashboard o `automation\run-evolvi.ps1`). Sugli altri
  PC il bootstrap va lanciato senza `-Primario`
- **Conflitti**: rari coi markdown; se il sync si ferma segnalando un conflitto,
  apri claude nella cartella e chiedi di risolverlo
- **Regola d'igiene**: a fine lavoro su un PC, lascia che il sync giri (o lancialo
  a mano) prima di passare all'altro

## Sviluppare il sistema stesso

Anche l'agentic OS è un progetto, e si sviluppa **da dentro** (`claude` in
`agentic-os`): lì ci sono contesto, skill e permessi giusti, e le modifiche
finiscono nel repo con la loro storia. La cartella madre `lavoro` serve solo
per lavori trasversali a più progetti.

- **Due canali di sviluppo**: le modifiche che chiedi tu sono normali sessioni
  interattive; le modifiche che propone il sistema passano da `/evolvi` con la
  sua governance. Stesso posto, gate diversi.
- **Dopo aver toccato una skill**: lancia `tests\run-evals.ps1` e confronta col
  punteggio precedente (la baseline la fissa la tua prima run) — se scende, regressione.
  Le eval girano con modello **fissato** su Sonnet 5 (fa da "pavimento": se una
  skill passa lì, regge ovunque); i report precedenti al pin giravano su Fable 5,
  il report annota sempre il modello usato.
- **Il testbed (`lavoro/agentic-os-testbed`) è usa-e-getta**: viene distrutto e
  ricreato dalle fixture a ogni esecuzione dei test. Mai committarlo, mai
  salvarci lavoro: tutto ciò che conta è già nel repo (fixture, runner, risultati).
- **I test girano su qualsiasi PC** (sincronizza prima, per testare la versione
  corrente); le **automazioni schedulate solo sul primario**.
- **`/model` influenza solo le sessioni interattive**: tutte le run headless
  dichiarano esplicitamente il loro modello — Sonnet 5 per la routine (dashboard,
  eval, distillatore, ricercatore), il top disponibile (oggi Opus 4.8) per il
  giudizio di /evolvi (la raccolta la fa il ricercatore economico) — principio
  "il modello segue il compito" in [[Architettura e filosofia]].
- **Modello dedicato per una skill**: le SKILL.md non supportano un campo model;
  si fa con un subagente in `.claude/agents/` (es. `distillatore` su Sonnet 5,
  usato da `/distilla` per la sintesi).

## Domande frequenti

- **"Se chiudo una sessione perdo tutto?"** — La *conversazione* sì, come ogni chat;
  ma tutto ciò che conta (note, skill, report, commit) è su file. La regola è:
  ciò che è durevole va nel vault, mai lasciato solo in chat.
- **"L'automazione gira anche a PC spento?"** — La schedulazione di `/evolvi` arriva
  **in pausa**: si lancia a mano (pulsante Evolvi o
  `automation\run-evolvi.ps1`). Riattivandola (`Enable-ScheduledTask
  AgenticOS-Evolvi`) vale come prima: lunedì 09:00 dal Task Scheduler, con
  recupero se il PC era spento — quindi no, a PC spento non gira; la variante
  cloud è tra le proposte aperte.
- **"Claude Code dà problemi (run che si bloccano, errori d'ambiente strani)?"** —
  apri una sessione `claude` e lancia `/doctor` (alias `/checkup`): da luglio 2026
  è un checkup completo del setup che diagnostica i problemi e può correggerli.
  Da provare prima del debug manuale.
- **"Obsidian non si apre"** — container fermo: `podman compose up -d` da `agentic-os`.
- **"Il pulsante Sync della dashboard dice 'token assente'"** — senza token il
  pulsante committa solo in locale (il push resta al sync orario dell'host). Per
  abilitare pull+push dal container: crea un token GitHub *fine-grained* (solo
  repo `agentic-os`, permesso Contents read/write), salvalo come unica riga in
  `%USERPROFILE%\.agentic-os\git-token`, poi `podman compose restart dashboard`.
  Scorciatoia (riusa il token di gh, più ampio): `gh auth token | Out-File -Encoding ascii "$env:USERPROFILE\.agentic-os\git-token"`.
- **"Ho creato/modificato una nota da fuori (agente, editor, sync) ma in Obsidian
  non compare"** — normale in questo setup: gli eventi di modifica dei file non
  attraversano il confine Windows → container (limite noto di WSL2), quindi
  Obsidian non si accorge dei cambi fatti dal lato Windows. La nota è già sul
  disco: per vederla, `Ctrl+P` → **"Reload app without saving"** (~2 secondi).
  Il riavvio del container non serve.
- **"Un link a localhost cliccato dentro Obsidian dice 'non raggiungibile'"** —
  il click si apre *dentro* il container di Obsidian, dove `localhost` è il container
  stesso. Per i servizi dello stack usa il nome del container sulla rete compose
  (es. `http://agentic-dashboard:3210`); `http://localhost:...` vale solo dal
  browser del PC. I link della Dashboard sono già impostati così.
- **"Non riesco a incollare testo nella webapp"** — va concesso il permesso
  Appunti al browser: su Chrome/Edge, lucchetto nella barra indirizzi →
  *Impostazioni sito* → *Appunti* → Consenti (Firefox non lo supporta). Piano B:
  la sidebar della webapp (linguetta sul bordo) ha un pannello clipboard di
  passaggio. Da un altro PC via IP serve `https://<ip>:3001`, non http.
- **"Posso modificare le note a mano?"** — Certo, sono tue: Obsidian serve a quello.
  Evita solo di riorganizzare cartelle e indice a mano: quello è lavoro delle skill.
