---
name: processa-inbox
description: Smista l'inbox per intento - conoscenza (fusa o archiviata in PARA), istruzioni (eseguite), lavori pesanti (in coda), fonti esterne (proposte a /distilla). Usare quando l'utente chiede di processare, smistare o svuotare l'inbox.
---

# Processa inbox

Leggi prima `vault/CLAUDE.md` per struttura e convenzioni. L'inbox è il canale
di prompt **asincrono** dell'utente: non tutto è contenuto da archiviare — molte
note sono messaggi per l'agente. Per ogni nota in `vault/00-Inbox/`:

0. **Provenienza prima di tutto**: una nota che inizia con frontmatter
   `origine: agente <progetto>` è un **messaggio tra agenti** (dal ponte di un
   repo), non una nota dell'utente — niente callout né conservazione letterale:
   integra liberamente il contenuto nella destinazione giusta (prima candidata:
   la scheda del progetto mittente in `01-Progetti/`, poi le note di tema) e
   dissolvi la nota. Senza marcatore = nota dell'utente, protezione piena.
1. **Triage per intento** — classifica (una nota mista si separa nelle sue parti):
   - **Conoscenza**: idea, appunto, riflessione, estratto incollato con commenti → passo 2
   - **Istruzione leggera**: tocca note esistenti — riattivare/pausare un progetto,
     aggiungere task o step, cambiare `stato:`/`prossimo:` → passo 3
   - **Lavoro pesante**: ricerche su un tema, assimilazioni, tutto ciò che richiede
     web o crea conoscenza nuova → passo 4
   - **Fonte esterna**: file non-markdown o URL → passo 5

2. **Conoscenza → fondi, o crea come eccezione**:
   - cerca la **casa naturale** esistente (prima l'Indice, poi grep): se c'è,
     integra lì — le parole dell'utente entrano come callout datato
     (`> [!quote]- Nota originale (inbox, YYYY-MM-DD)`) nella nota di destinazione,
     e la nota inbox si **dissolve** (le parole ora vivono nella casa)
   - se una casa naturale non c'è: crea la nota in PARA (frontmatter, wikilink,
     policy del riordino qui sotto). Meglio una piccola nota nuova che un'idea
     sepolta in una nota affine-ma-non-troppo
3. **Istruzione leggera → eseguila**: applica la modifica alla nota bersaglio,
   porta il testo originale dell'istruzione in un callout nella nota bersaglio
   (o nel suo Log) e dissolvi la nota inbox — l'istruzione si scioglie
   nell'azione. Se un'operazione è negata dai permessi (es. eliminazione in
   headless), fai ciò che puoi e segnala il resto
4. **Lavoro pesante → mai d'impulso**: trasforma la richiesta in checkbox
   "Da fare" nella nota del tema (fondendo o creando, come al passo 2) e
   **proponila a fine run** — l'esecuzione parte solo su conferma dell'utente
5. **Sensore fonti** — sempre con conferma prima di processare
   (ogni fonte costa minuti e token):
   - **File non-markdown in inbox** (pdf, docx, txt…): NON sono note dell'utente —
     mai frontmatter, callout o smistamento PARA. Sono copie usa-e-getta da
     assimilare: lasciale dove sono e proponi `/distilla <percorso>` per ciascuna
   - **URL YouTube** nelle note processate non ancora distillati (nessuna nota
     sotto `03-Risorse/` con quel video in `fonte:`): segnalali e proponi `/distilla`
   - **Link a pagine web** nelle note processate: elencali e chiedi **quali**
     distillare — un link di riferimento non è una richiesta di assimilazione

6. A fine giro riassumi all'utente cosa è successo, in una tabella
   (nota → intento → esito). Il conteggio inbox e i progetti attivi in
   `vault/Dashboard.md` sono viste live (Bases): si aggiornano da sole con il
   frontmatter giusto. Tocca la Dashboard solo per le parti editoriali
   (dubbi da segnalare, riga "Ultimo aggiornamento")

A fine run aggiungi una riga in cima alla tabella di `vault/99-Sistema/Registro attività.md`.

## Policy di conservazione

Il contenuto non si perde mai; la forma si può (e spesso si deve) migliorare —
le note in inbox sono scritte di getto:

- nota breve o già chiara → riportala tal quale, senza duplicarla
- nota che beneficia di un riordino → nel corpo va la versione ripulita e
  strutturata, e in fondo il testo originale **integrale**, in un callout ripiegato:

  ```
  > [!quote]- Nota originale (inbox, YYYY-MM-DD)
  > il testo esattamente come l'ha scritto l'utente
  ```

- una nota inbox si **elimina** solo quando le sue parole vivono già integralmente
  altrove nel vault (fusione o istruzione eseguita, sempre col callout di cui sopra)
- **Verifica, non ricordare**: prima di eliminare una nota inbox dell'utente, cerca
  con un grep a match esatto una sua frase distintiva nella nota di destinazione.
  Se la ricerca non la trova, il callout manca: aggiungilo e ripeti la verifica —
  senza riscontro la dissoluzione è vietata (lascia la nota in inbox e segnalalo)

La regola di fondo: le parole dell'utente devono sempre restare ritrovabili con
una ricerca esatta. La parafrasi si aggiunge, non sostituisce; la dissoluzione
cambia l'indirizzo, non la ritrovabilità.

**Fatto quando**: `00-Inbox/` è vuota (o ogni residuo ha un motivo annotato:
dubbio, fonte in attesa di conferma), ogni parola dell'utente resta ritrovabile
con una ricerca esatta (nella casa naturale, nel callout della nota bersaglio o
in una nota nuova), i lavori pesanti sono in coda come checkbox e proposti, e il
Registro ha la riga della run.
