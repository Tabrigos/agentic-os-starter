---
name: weekly-review
description: Revisione settimanale del vault - avanzamento progetti, task scaduti, archiviazione, priorità della prossima settimana. Usare quando l'utente chiede la review o revisione settimanale.
---

# Weekly review

Leggi prima `vault/CLAUDE.md`. Poi:

1. **Progetti** (`01-Progetti/`): per ognuno valuta l'avanzamento dai task e dal log.
   **Prima di dichiarare fermo un progetto, controlla `git log` sulla sua scheda**
   (`git log --since=<inizio finestra> -- "vault/01-Progetti/<nome>*"`): il ponte
   dei repo di progetto scrive direttamente nella scheda senza passare dal
   Registro attività, quindi "nessuna riga nel Registro" non significa "nessun
   lavoro". La review del 2026-09-02 ha evitato l'errore per un soffio: sette
   giorni di sprint su un progetto, invisibili a Registro, daily e /evolvi.
   Proponi (senza eseguire senza conferma) di archiviare in `04-Archivio/` quelli
   con tutti i task chiusi, oppure **`attivo` e fermi da oltre un mese**.
   **La soglia del mese non vale per `in-pausa`** (decisione dell'utente del
   2026-09-04, dopo tre review con la stessa domanda): una pausa dichiarata, con
   un `prossimo:` esplicito, è uno stato legittimo a tempo indeterminato e non
   uno stallo — non riproporne l'archiviazione a ogni review
2. **Task scaduti**: elenca i `- [ ]` con `📅` passata e chiedi se riprogrammare o
   eliminare. **Se nel vault non esiste nessun `📅`, il passo vale una riga sola** —
   non una sezione, e non si riapre la domanda se togliere il campo: deciso
   dall'utente il 2026-09-16 dopo otto review che riportavano «zero task scaduti»
   misurando il nulla. Il campo resta nella costituzione perché costa una riga ed
   è sintassi Obsidian Tasks standard: il giorno che serve una scadenza vera è già lì
3. **Inbox**: se ci sono note in `00-Inbox/`, esegui il flusso di processa-inbox
4. **Daily della settimana** (`05-Daily/`): estrai i punti salienti in 4-5 righe.
   **Raccogli le caselle Focus rimaste aperte** nelle daily della settimana: ognuna
   va portata avanti (entra nelle priorità della prossima settimana) oppure chiusa
   spuntandola con data e motivo — nessuna casella muore in silenzio
5. **Session mining**: rileggi le righe recenti (~3 settimane) del
   `vault/99-Sistema/Registro attività.md` a caccia di due cose distinte:
   - **errori ricorrenti e attriti** → formula 1-2 regole candidate da
     trascrivere (in CLAUDE.md o nella skill interessata)
   - **workflow ripetuti senza skill**: la stessa sequenza di operazioni fatta
     a mano ≥3 volte è una **skill candidata** — descrivila in una riga
     (innesco, passi, esito) e ricorda che la creazione segue la governance
     di sempre (staging, tetto, scorecard)
   In entrambi i casi mettile nella review come **proposte** — mai applicarle
   da solo
6. **Lint del wiki** (`03-Risorse/`, a campione — non esaustivo): cerca note
   orfane (nessun wikilink in entrata), claim superati da note più recenti,
   contraddizioni tra note affini, concetti citati in più note che meriterebbero
   una nota propria, **note-scintilla esaurite** (tipo `idea` con i task tutti
   chiusi e la conoscenza già altrove: candidate a dissoluzione o fusione, con
   le parole dell'utente nel callout della destinazione) e checkbox aperte che
   ristagnano da settimane. I wikilink mancanti tra note **generate dall'agente**
   (con `fonte:`) puoi aggiungerli subito; tutto il resto va nella review come
   proposta — le note dell'utente non si toccano mai senza ok
7. **Igiene del tempo**:
   - **daily più vecchie di ~4 settimane → eliminale** (niente archivio: git
     conserva ogni versione, il Registro è la cronologia consultabile). Prima,
     la checklist di dissoluzione: caselle Focus tutte decise (vale il passo 4)
     e nessuna riga scritta dall'utente non ancora migrata in una nota vera — se
     c'è, migrala col callout datato, poi elimina
   - **review più vecchie di ~3 mesi** → stessa checklist, stessa fine
   - **Tech radar più vecchi di ~3 mesi** (in `03-Risorse/Evoluzione/`) →
     eliminali, previa checklist: ogni voce del radar (applicata/proposta/
     scartata) ha la sua riga nel `Changelog evoluzione` — se manca, aggiungila
     prima; le proposte ancora aperte vivono già in Dashboard 🧬. I verdetti
     sono la memoria, il radar è il verbale: il primo resta, il secondo muore
   - se il Registro attività supera le ~50 righe, sposta le più vecchie in coda a
     `vault/99-Sistema/Registro attività — archivio.md` (ordine cronologico)
8. Scrivi la review in `vault/05-Daily/<oggi>-review.md` e aggiorna `vault/Dashboard.md`
9. Chiudi proponendo le 3 priorità della prossima settimana, motivate
10. Aggiungi una riga in cima alla tabella di `vault/99-Sistema/Registro attività.md`

**Fatto quando**: la review esiste in `05-Daily/` con avanzamenti, scaduti,
priorità, l'esito del session mining e del lint del wiki (anche "nessun
pattern/nessun rilievo"); nessuna casella Focus della settimana è rimasta aperta
senza decisione; daily oltre le 4 settimane eliminate con checklist di
dissoluzione (review oltre i 3 mesi idem) e Registro attivo sotto le ~50 righe.
