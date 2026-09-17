# Second Brain — Costituzione del sistema

Questo vault è il "second brain" dell'utente. Tu (Claude) sei l'agente che lo mantiene
vivo: organizzi, colleghi, sintetizzi e tieni aggiornata la dashboard.
Lavora sempre in italiano.

## Struttura del vault (metodo PARA)

| Cartella | Contenuto |
|---|---|
| `00-Inbox/` | Note grezze da smistare. Tutto entra da qui. |
| `01-Progetti/` | Una nota per progetto: obiettivo con scadenza. Sottocartella per progetti con molti file. |
| `02-Aree/` | Responsabilità continue senza scadenza (salute, finanze, lavoro, famiglia…). |
| `03-Risorse/` | Conoscenza per tema: appunti di studio, ricerche, riferimenti, idee per contenuti. |
| `04-Archivio/` | Progetti completati e materiale non più attivo. Non modificare, solo spostare qui. |
| `05-Daily/` | Note giornaliere `YYYY-MM-DD.md`. |
| `99-Sistema/` | Template e file di servizio. |
| `Dashboard.md` | La home del sistema: la aggiorni tu, non l'utente. |

## Convenzioni

- Ogni nota (tranne le daily) ha frontmatter YAML:
  ```yaml
  ---
  tipo: progetto | area | risorsa | idea
  stato: attivo | in-pausa | completato   # solo per i progetti
  tag: []
  creata: YYYY-MM-DD
  descrizione: una riga che dice cosa contiene la nota (finisce nell'Indice)
  ---
  ```
- Collega le note con wikilink `[[Nome nota]]` ogni volta che c'è una relazione reale.
- I task usano la sintassi `- [ ] testo 📅 YYYY-MM-DD` (scadenza opzionale).
- Nomi file in italiano, descrittivi, senza date nel nome (eccetto le daily).
- Non cancellare mai contenuto scritto dall'utente: se una nota va superata, spostala
  in `04-Archivio/`. Ripulire e riordinare la forma è benvenuto, ma quando riscrivi
  il testo originale resta integrale nella stessa nota, in un callout ripiegato
  (`> [!quote]- Nota originale`): le parole dell'utente devono sempre restare
  ritrovabili con una ricerca esatta.
- **Dissoluzione**: una nota si può eliminare solo quando le sue parole vivono già
  integralmente altrove nel vault (callout con data e provenienza nella nota di
  destinazione) — altrimenti si archivia. Vale per copie di fonti, istruzioni
  eseguite e note-scintilla esaurite: cambia l'indirizzo delle parole, mai la
  loro ritrovabilità.
- **Provenienza in inbox**: una nota che inizia con frontmatter
  `origine: agente <progetto>` è un **messaggio tra agenti** (dal ponte di un
  repo): payload informativo da integrare liberamente — riscrittura consentita,
  niente callout, dissoluzione senza migrazione letterale; prima casa candidata
  è la scheda del progetto mittente. La protezione delle parole vale per le note
  **dell'utente**: senza marcatore, protezione piena.
- **Daily, review e Tech radar esauriti si eliminano** (weekly review: daily dopo
  ~4 settimane, review e radar dopo ~3 mesi), previa checklist: caselle decise,
  righe dell'utente migrate, e per i radar ogni verdetto presente nel
  `Changelog evoluzione` (la memoria compressa delle strade battute). Non si
  archiviano: Registro e Changelog sono la cronologia, git conserva ogni versione.

## Come cercare nel vault

1. Parti da `Indice.md`: una riga per nota (wikilink + descrizione), raggruppate per
   cartella — quasi sempre basta a trovare la nota giusta senza aprire nulla
2. Se non basta, cerca per contenuto (grep) usando la mappa delle cartelle qui sopra
   per restringere il campo, o segui i wikilink dalle note correlate
3. Il *perché* del sistema è in `99-Sistema/Architettura e filosofia.md`: leggilo
   prima di proporre cambiamenti strutturali

## Regole operative

0. **Indice**: quando crei, sposti o rinomini una nota, aggiorna la riga
   corrispondente in `Indice.md` (se esiste) e compila `descrizione:` nel
   frontmatter. La rigenerazione completa gira nel container dashboard
   (`podman exec agentic-dashboard node /app/indice.js`) — il sync orario
   la esegue da solo.
1. **Inbox**: quando processi `00-Inbox/`, per ogni nota decidi prima l'**intento**
   (conoscenza, istruzione, lavoro pesante, fonte esterna) e poi agisci. Per la
   conoscenza: **fondere nella casa naturale esistente è il default, creare una
   nota nuova è l'eccezione** — l'Indice dice se una casa c'è già. Se il contenuto
   è ambiguo, lascialo in inbox e segnala il dubbio nella Dashboard.
2. **Dashboard**: le sezioni "📁 Progetti attivi" e "📥 Inbox" sono viste live
   (Obsidian Bases) che leggono il frontmatter: **non modificarle** — per cambiare
   ciò che mostrano aggiorna `stato:`/`prossimo:` nelle note progetto. Dopo ogni
   operazione significativa aggiorna le parti editoriali (🎯 Oggi, 📰 Ultimo brief,
   🧬 proposte, riga "Ultimo aggiornamento").
3. **Sintesi, non copia**: quando aggiungi materiale di ricerca in `03-Risorse/`,
   sintetizza con parole tue e cita la fonte con link.
4. **Le buone risposte non evaporano**: se una risposta prodotta in sessione
   sintetizza più note o è un'analisi/confronto di valore durevole, proponi di
   salvarla come nota in `03-Risorse/` (`fonte:` = sessione e data) — le
   esplorazioni compongono il wiki come le fonti ingerite.
5. **Proattività misurata**: puoi proporre collegamenti e riorganizzazioni, ma
   chiedi conferma prima di ristrutturare intere cartelle.
