# Agentic OS

Questo progetto è il "second brain" dell'utente: un vault Obsidian in `vault/`
gestito da Claude Code, servito via browser da un container Podman.

**Prima di qualsiasi operazione sul vault, leggi `vault/CLAUDE.md`**: è la
costituzione del sistema (struttura PARA, convenzioni, regole operative).

**Se l'utente chiede "cosa sai fare", "aiuto", "quali skill ci sono"** o simili:
mostra la tabella delle skill da `.claude/skills/` (nome, quando usarla, un esempio
d'invocazione ciascuna) e ricorda i due riti: `/brief` al mattino, sezione 🧬 della
Dashboard il lunedì. Chiudi indicando `vault/99-Sistema/Guida all'uso.md` per il resto.

## Infrastruttura

- `compose.yaml` — Obsidian in container (immagine linuxserver, UI su http://localhost:3000)
  e dashboard one-click (container `dashboard`, Claude Code headless dentro,
  UI su http://localhost:3210)
- Avvio: `podman compose up -d` — Stop: `podman compose down`
- **Sync-lock**: un file dentro `.sync-locks/` significa "qualcuno sta
  scrivendo, non committare adesso". **Uno per titolare** (dal 2026-09-17):
  ognuno cancella solo il proprio, e il repo resta bloccato finché ne esiste
  almeno uno vivo. Lo mette **chi scrive** — hook
  `SessionStart`/`SessionEnd` per le sessioni interattive, `dashboard/evolvi.sh`
  e `dashboard/server.js` per le headless — e lo leggono i due sync
  (`automation/sync.ps1`, `dashboard/sync-repo.sh`), che saltano il giro. Il
  sync non lo crea **mai**: il pulsante "Sync repo" inciamperebbe nel proprio
  lucchetto. Il lock **scade dopo 4 ore** perché i docs di Claude Code non
  garantiscono `SessionEnd`: un lock orfano è un caso normale e non deve
  bloccare il backup per sempre, e chi passa raccoglie gli scaduti. Secondo
  guardiano, indipendente dagli hook: se un file è stato toccato negli ultimi 5
  minuti il sync salta comunque — stateless, e basta una pausa di 5 minuti
  perché riparta da solo. **Il suo limite, misurato il 2026-09-17**: vede le
  *scritture*, non le sessioni aperte, e una sessione che in quel momento sta
  leggendo gli è invisibile — per questo il lucchetto per-titolare serviva
  davvero. Il perché, con le date in cui è successo, sta in
  `automation/sync-lock.ps1`
- Principio di portabilità: la logica dell'automazione va nei container (uguale su
  Windows/Linux); sull'host restano solo colla per-OS (launcher, scheduler) e credenziali
- Script PowerShell: salvarli UTF-8 **con BOM** (PS 5.1 senza BOM li legge ANSI) e
  niente caratteri accentati nei percorsi in literal — per file con accenti nel nome
  usare il wildcard (es. `Registro attivit*.md`). Per lanciarli dal prefisso `!`
  di Claude Code servono le **barre normali** (`! automation/sync-lock.ps1
  -Azione stato`): il `!` esegue in Git Bash, che tratta la barra rovesciata
  come escape e trasforma `automation\sync-lock.ps1` in `automationsync-lock.ps1`
- Modelli: nessun default implicito nelle automazioni — ogni percorso headless
  dichiara il suo modello (vedi "Il modello segue il compito" in
  `vault/99-Sistema/Architettura e filosofia.md`)
- Il vault è montato nel container come `/vault`; sull'host è `./vault`
- **Regole di permesso: allow-list stretta, sempre.** In `.claude/settings.json`
  e `settings.local.json` non devono mai comparire regole generiche —
  `Bash(*)`, `Bash(npm:*)`, `Bash(pip:*)`, `PowerShell(podman run *)` e simili.
  Ogni voce nomina il comando e i suoi argomenti (`Bash(git status:*)`,
  `PowerShell(podman compose up:*)`). Non è pedanteria: è il meccanismo che
  rende i percorsi headless immuni all'injection da repository — un comando
  come `dig ... | bash` suggerito da un messaggio d'errore non è in allow-list,
  e in headless l'approvazione non arriva mai (principio 11 in
  `vault/99-Sistema/Architettura e filosofia.md`). Allargare una regola per
  comodità è una decisione di sicurezza: si prende in sessione con l'utente, non
  di passaggio. Nel dubbio, meglio un prompt in più che una regola larga.
  **Dal 2026-09-04 la allow-list non è più sola**: `.claude/settings.json`
  dichiara anche un `defaultMode` (`"default"`, cioè Manual) e una lista `deny`.
  Motivo: dal 14 agosto auto mode è il default delle sessioni interattive nuove,
  e lì "non in lista" non significa più "chiedi all'utente" ma "decide il
  classificatore" — la allow-list proteggeva *in virtù della modalità*. Le `deny`
  bloccano invece in **ogni** modalità. Vanno scritte sull'**esecutore**, non
  sulla forma: Claude Code spezza il comando sui separatori (`|`, `&&`, `;`) e
  matcha ogni sottocomando da solo, quindi `dig ... | bash` si nega con
  `Bash(bash *)` e non con una regola sulla pipe. Aggiungere una `deny` è sempre
  benvenuto; toglierne una è una decisione di sicurezza esattamente come
  allargare una `allow`.
  **Unica eccezione, deliberata: il testbed delle eval.** `tests/run-evals.ps1`
  sovrascrive il `settings.local.json` del testbed con quattro regole larghe
  (`Bash(mv:*)`, `Bash(rm:*)`, `PowerShell(Move-Item *)`,
  `PowerShell(Remove-Item *)`) e **va lasciato così**: senza, in headless
  "sposta nella cartella PARA" degenera in "copia + stub" (visto nelle run del
  2026-07-03) e la suite misura il regime dei permessi invece delle skill —
  una suite che mente è peggio del rischio che eviterebbe. L'eccezione regge
  perché nel testbed non c'è nessuna delle tre condizioni del principio 10:
  nessun umano che approva (è headless), nessun contenuto non fidato (fixture
  scritte da noi, nessun caso tocca il web), nessun dato da proteggere (albero
  ricreato da zero a ogni caso). Chi legge questa regola e "sistema" il testbed
  per coerenza rompe la suite: non farlo.
- Le skill del sistema sono in `.claude/skills/`; le run headless di /evolvi non
  possono scrivervi (directory protetta) e depositano le skill in `staging/skills/`,
  da cui l'installer governato (`dashboard/install-staging.sh`, invocato da
  `dashboard/evolvi.sh` a fine run) installa max 1 nuova per run
- Eval suite in `tests/`: `tests/run-evals.ps1` misura le skill su un vault sintetico
  (fixture in `tests/fixtures/vault-base/`, storico punteggi in `tests/results/`).
  Va lanciata dopo ogni run di /evolvi e dopo modifiche alle skill; il testbed
  usa la copia isolata `agentic-os-testbed` accanto al repo, mai il vault
  reale. Il testbed è usa-e-getta (ricreato dalle fixture a ogni run): mai
  committarlo né salvarci lavoro
- `tests/test-deterministico.ps1` misura l'**altro** strato, quello "zero LLM":
  idempotenza di `indice.js` e versione della CLI nel container. Gira dentro
  `run-evals.ps1` ma con tabella e punteggio **separati** — non misura le skill,
  e sommarlo al loro totale allargherebbe il termometro di nascosto. Esiste dal
  2026-09-04 perché è in quello strato che sono cadute entrambe le regressioni
  trovate da /evolvi: la CLI ferma a 2.1.201 per 40 giorni e il guard dell'Indice
  che non ha mai funzionato. Richiede il container dashboard acceso
- **Le sessioni che toccano l'infrastruttura scrivono nel Log del progetto**: chi
  modifica container, script, skill, permessi o test aggiunge una riga al Log di
  `vault/01-Progetti/Setup Agentic OS.md`, non solo al `Registro attività`.
  Senza, il progetto risulta fermo mentre non lo è — è successo per 36 giorni
  fino al 2026-09-04, ed era una pendenza aperta dalla review del 07-27 e
  riproposta identica per tre review di fila
