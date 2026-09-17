---
name: installa
description: Presenta il sistema e guida la prima installazione - racconta cos'è e a cosa serve, controlla i requisiti (runtime container, git, credenziali), dice cosa manca e come rimediare, installa su conferma e poi spiega come si usa. Usare al primo avvio in un clone appena scaricato, o quando l'utente chiede cos'è questo progetto, come si installa o come si comincia.
---

# Installazione e primo avvio

Sei la prima cosa che l'utente incontra. Può non aver mai visto il sistema, e
può non sapere cosa sia un vault, PARA o una skill. Parla in italiano, in
concreto, senza gergo non spiegato.

> **Questa skill chiede prima di agire, ed è l'unica.** Tutte le altre skill del
> sistema agiscono e poi chiedono, perché in headless una domanda pre-azione
> blocca la run per sempre. Qui vale il contrario per due motivi: gira solo in
> sessione interattiva, al primo avvio, e le sue azioni **cambiano la macchina
> dell'utente** (installa pacchetti, avvia container, registra attività
> pianificate). Chi legge le altre skill e "corregge" questa per coerenza
> rompe il patto con chi installa: non farlo.

## Passo 0 — capire dove siamo

Prima di parlare, guarda. Non chiedere quello che puoi vedere.

- il sistema è **già installato**? Indizi: i container `obsidian` e
  `agentic-dashboard` esistono; `vault/05-Daily/` ha delle note; il Registro
  attività ha righe; il vault non contiene più le note d'esempio
- che sistema operativo è (lo sai dall'ambiente) e in che cartella siamo

Se risulta **già installato**, non riproporre l'installazione: di' cosa hai
trovato, poi salta al Passo 6 (come si usa) e offri `/brief`.

## Passo 1 — presentazione

Racconta in poche righe, adattando a cosa ha chiesto l'utente:

- è un **second brain**: le tue note in markdown, in `vault/`, organizzate col
  metodo PARA (Progetti, Aree, Risorse, Archivio) più inbox e note giornaliere
- le note **restano file di testo**: niente database, niente formati chiusi. Se
  domani togli l'agente, ti resta una cartella di markdown che si legge ovunque
- un agente (Claude Code) le organizza, le collega e le sintetizza con delle
  **skill**: il brief del mattino, lo smistamento dell'inbox, la revisione
  settimanale, la distillazione di video e documenti in note di conoscenza
- una volta a settimana `/evolvi` cerca novità nel campo degli agenti, le
  giudica rispetto a com'è fatto il sistema, applica quelle a basso rischio e
  **propone** le altre. Le proposte le approvi tu, non si applicano da sole
- ci sono **tre finestre**: Obsidian nel browser per leggere e scrivere, il
  terminale con Claude Code per le skill, e una dashboard a pulsanti
- il *perché* di ogni scelta sta in `vault/99-Sistema/Architettura e filosofia.md`,
  il come si usa in `vault/99-Sistema/Guida all'uso.md`

## Passo 2 — controllo dei requisiti

Verifica, uno per uno, e **non fermarti al primo che manca**: raccogli tutto e
fai un quadro solo. Il quadro completo fa decidere, una notizia alla volta fa
perdere la pazienza.

| Cosa | Come si controlla | Serve a |
|---|---|---|
| Claude Code | sta già girando, sei tu | tutto |
| git | `git --version` | storia, backup, sync |
| runtime container | `podman --version`, se manca `docker --version` | Obsidian e dashboard |
| macchina podman (Windows/macOS) | `podman machine list` | far girare i container |
| credenziali Claude | esiste `~/.claude/.credentials.json`? | i container le montano per le run headless |
| node | `node --version` | facoltativo: marca la cartella come fidata |
| gh | `gh --version` | facoltativo: serve solo se vuoi clonare via GitHub CLI |

**Se un controllo viene bloccato dai permessi, non inventare il risultato.** La
allow-list di questo sistema è stretta di proposito, e comandi banali come
`git --version` o `podman --version` non sono pre-approvati: in sessione
interattiva compare una richiesta di conferma, in headless il comando fallisce e
basta. In entrambi i casi segna quella riga come **da verificare** e offri due
strade: riprovare con l'approvazione, oppure farti incollare dall'utente
l'output dei comandi. Un quadro con dei buchi dichiarati serve; un quadro
inventato fa installare alla cieca. Spiega anche perché succede: è la stessa
regola che rende sicure le run headless, e vederla all'opera al primo minuto è
un buon modo per capirla.

**Sul runtime, di' la verità.** Il sistema è costruito su **podman**: le
automazioni sull'host invocano `podman` per nome in sette file. Con solo docker
i container partono, ma sync orario, pulsanti della dashboard e test
deterministici no. Quindi: se c'è podman, tutto a posto; se c'è solo docker,
spiega questo e proponi di installare podman accanto (convivono senza problemi).

## Passo 3 — il quadro

Presenta una tabella con **presente / manca** e, per ciò che manca, il comando
esatto per il sistema operativo di chi legge:

- Windows: `winget install RedHat.Podman`, poi `podman machine init` e `podman machine start`
- Debian/Ubuntu: `sudo apt install podman podman-compose`
- Fedora: `sudo dnf install podman podman-compose`
- macOS: `brew install podman`, poi `podman machine init` e `podman machine start`
  (nota: il sistema è stato sviluppato e collaudato su Windows e Linux)

Se mancano le **credenziali Claude**, la cura è una sola: chiudere questa
sessione, lanciare `claude` una volta e fare il login, che crea il file.

## Passo 4 — la conferma, che è di chi installa

Non installare niente prima di un sì esplicito. Di' con precisione cosa farà
l'installazione, perché tocca la macchina:

- scarica e avvia **due container** (Obsidian su `:3000`, dashboard su `:3210`)
- marca questa cartella come **fidata** per Claude Code
- registra un'**attività pianificata oraria** che fa commit del vault
- registra l'attività di `/evolvi`, **disattivata**: si lancia a mano finché non
  ti fidi del ciclo

Se serve installare pacchetti di sistema (podman), avvisa che quei comandi **non
sono in allow-list**: comparirà una richiesta di permesso da approvare. In
alternativa l'utente può lanciarli da sé, e in Claude Code basta il prefisso `!`
davanti al comando. Non aggirare il permesso in nessun modo.

## Passo 5 — installazione

Solo dopo il sì:

- Windows: `powershell -ExecutionPolicy Bypass -File automation\setup-pc.ps1`
- Linux: `sh automation/setup-linux.sh`

Lo script deduce da sé la cartella giusta: è il clone in cui si trova. Non
passare `-Primario` a meno che l'utente non stia promuovendo di proposito questa
macchina a primaria, e spiega cosa vuol dire (le automazioni schedulate girano
su un PC solo).

Poi **verifica davvero**, non dedurre dall'assenza di errori:

- i container `obsidian` e `agentic-dashboard` risultano attivi
- http://localhost:3000 e http://localhost:3210 rispondono
- `podman exec agentic-dashboard node /app/indice.js` rigenera l'Indice

Se qualcosa non risponde, la causa più comune su Windows è la macchina podman
spenta: `podman machine start`, poi `podman compose up -d`.

## Passo 6 — come si usa

- **`/brief`** è il rito del mattino: scadenze, progetti, inbox. Fallo provare subito
- il vault arriva con **note d'esempio** (due progetti, un'area, qualche nota in
  inbox): servono a vedere le skill al lavoro. Consiglia `/processa-inbox` per
  guardare dove finiscono le note e perché, e poi di cancellarle e metterci la
  propria roba
- il **secondo rito** è il lunedì: la sezione 🧬 della Dashboard, dove si
  approvano o bocciano le proposte di `/evolvi`. Senza quello il sistema smette
  di crescere
- `tests\run-evals.ps1` misura le skill e fissa la propria baseline. Conviene
  lanciarlo una volta ora, per avere un punto di partenza
- dove leggere: `vault/99-Sistema/Guida all'uso.md` per l'uso quotidiano,
  `vault/99-Sistema/Architettura e filosofia.md` per il perché,
  `vault/CLAUDE.md` per le convenzioni del vault

**Avviso da dare sempre, anche se non lo chiede.** Se ha preso il progetto con
un fork pubblico, le sue note finirebbero online al primo push. Il vault va in
un **repo privato suo**: crearne uno, puntarci `origin`, e il sync orario fa il
resto. Dillo prima che scriva qualcosa di personale, non dopo.

## Passo 7 — congedarsi

Questa skill serve una volta sola. Dillo: si può cancellare
`.claude/skills/installa/` quando l'installazione è andata, e il sistema resta
con le sue sette skill di lavoro. Se resta lì, la governance delle skill la
segnalerà come inutilizzata alla prima revisione, che è il comportamento giusto.

**Fatto quando**: l'utente sa cos'è il sistema, i requisiti sono chiari, e o è
installato e verificato, o sa esattamente cosa gli manca e come ottenerlo.
