---
name: distilla
description: Distilla fonti esterne in note di conoscenza in 03-Risorse - video YouTube (in Video/), documenti pdf/docx/testo (in Documenti/), pagine web (in Web/). Con un argomento processa quella fonte; senza argomenti processa la coda (video non distillati e file in inbox). Usare quando l'utente passa un link o un file, o chiede di processare la coda.
---

# Distilla — da fonte esterna a conoscenza

Leggi prima `vault/CLAUDE.md`. Tre tipi di fonte, stesso flusso
(estrai → delega al distillatore → proponi → chiudi):

- **Video YouTube** — url `youtube.com/watch` o `youtu.be`
- **Documento** — percorso di un file (pdf, docx, txt, md…), tipicamente una
  **copia usa-e-getta** depositata in `vault/00-Inbox/` (non è una nota dell'utente)
- **Pagina web** — qualsiasi altro url http(s)

**Con argomento**: processa quella fonte. **Senza argomenti (coda)**: cerca URL
YouTube non distillati nelle note (inbox in testa) e file non-markdown in
`00-Inbox/`. Le pagine web **non** entrano in coda da sole — le note sono piene
di link di riferimento: si distillano solo su richiesta esplicita. Una fonte è
già distillata se il suo URL/nome file compare in un frontmatter `fonte:` sotto
`03-Risorse/` (confronta per video-ID o nome file, non per stringa esatta).
Se le fonti da processare sono più di una, conferma prima quali: ognuna costa
minuti e token.

## 1. Estrai

- **Video**: `podman compose run --rm media-tools "<url>"` → stampa un JSON con
  `outdir` (`media-work/<id>/`): lì trovi `metadata.json` e `transcript.txt`.
  Sponsor/autopromo già tagliati (SponsorBlock); se i sottotitoli mancano scatta
  il fallback Whisper (lento la prima volta); `--force-whisper` per sottotitoli pessimi.
- **Documento**: testo, markdown e PDF il distillatore li legge direttamente —
  nessuna estrazione. Per docx/pptx/xlsx:
  `podman compose run --rm media-tools "/vault/00-Inbox/<file>"` →
  `media-work/<slug>/estratto.md` (il vault è montato in sola lettura nel container).
- **Pagina web**: WebFetch dell'url con prompt "restituisci il contenuto integrale
  della pagina in markdown, ignorando navigazione, footer e boilerplate"; salva
  il risultato in `media-work/<slug>/pagina.md` più un `metadata.json` con
  url, titolo e data.

## 2-3. Pulisci, valuta e distilla (delega al distillatore)

Delega all'agente **distillatore** (gira su Sonnet 5: il modello giusto per la
sintesi, e più economico), passandogli percorso della sorgente + metadati e il
tipo di fonte. L'agente giudica il contenuto e scrive la nota:

- video → `vault/03-Risorse/Video/` (template-video)
- documento → `vault/03-Risorse/Documenti/` (template-documento)
- pagina web → `vault/03-Risorse/Web/` (template-documento, `fonte:` = url)

**Se la sottocartella non esiste, creala**: la destinazione è quella qui sopra,
sempre, anche in un vault nuovo o in un albero che finora ha tenuto le note
piatte in `03-Risorse/`. Non dedurre la destinazione dal layout che trovi, e non
saltare il passo perché "la cartella non c'è". Vale anche per il template: se
manca, scrivi comunque il frontmatter completo. Regola nata da un FAIL della eval
suite del 2026-09-16, dove la nota era finita piatta in `03-Risorse/` con questa
esatta motivazione — mentre il 09-04, sulla fixture identica, la cartella era
stata creata: un passo lasciato implicito si decide a testa o croce.

aggiornando l'Indice e **integrando le note correlate generate dall'agente**
(arricchimenti, conferme, segnalazioni "superato da" — mai le note dell'utente);
ti restituisce percorso della nota, note integrate, idee azionabili e una riga
di sintesi. Chiedigli sempre anche il **verdetto sulla fonte** (affidabile /
con la tara?): se significativo, va riportato in [[Fonti tech autorevoli]].
Se l'agente non è disponibile, fai tu stesso il lavoro seguendo le sue istruzioni
(`.claude/agents/distillatore.md`).

## 4. Proponi (mai applicare)

Se la fonte suggerisce migliorie concrete al sistema, aggiungile come checkbox
nella sezione 🧬 di `vault/Dashboard.md` con link alla nota — la governance è
quella di sempre: le modifiche le approva l'utente, o le valuterà /evolvi.
Per skill nuove ben definite puoi depositare una bozza in `staging/skills/`.

## 5. Chiudi

- Aggiorna `vault/99-Sistema/Registro attività.md` (l'Indice lo cura il distillatore)
- Se la fonte veniva da una nota, annota nella nota il wikilink alla distillazione
- **Copia in inbox**: quando la nota esiste e l'Indice è aggiornato, **elimina il
  file dall'inbox** — è una copia usa-e-getta, non una nota dell'utente; il
  `fonte:` della nota ne conserva il nome. Se i permessi negano l'eliminazione
  (run headless), lascia il file e segnala che è eliminabile
- I file in `media-work/` sono temporanei (fuori da git, potati dal sync): la
  conoscenza vive nella nota. Più fonti = una nota ciascuna

**Fatto quando**: per ogni fonte esiste una nota in `03-Risorse/Video|Documenti|Web/`
con `fonte:` nel frontmatter e un verdetto sulla fonte, l'Indice ha la riga, la
nota d'origine è annotata col wikilink, la copia in inbox è eliminata (o
segnalata come eliminabile) e il Registro ha la riga della run.
