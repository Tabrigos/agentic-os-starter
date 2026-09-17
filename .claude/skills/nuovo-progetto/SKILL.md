---
name: nuovo-progetto
description: Crea un nuovo progetto nel vault dal template, con frontmatter e link in Dashboard. Usare quando l'utente vuole iniziare/creare un nuovo progetto.
---

# Nuovo progetto

Il nome del progetto è nell'argomento della skill; se manca, chiedilo.

1. Leggi `vault/CLAUDE.md` per le convenzioni
2. Crea **subito** `vault/01-Progetti/<Nome>.md` da `vault/99-Sistema/template-progetto.md`,
   sostituendo `{{nome}}` e `{{data}}` (oggi, YYYY-MM-DD) e lasciando "da definire"
   nei campi che ancora non conosci. Questo passo viene prima di qualsiasi domanda:
   la nota esiste sempre, comunque vada il resto
3. Poi completa i campi (obiettivo, scadenza, primi 2-3 task): deducili dal contesto
   della conversazione o chiedili all'utente. Se una risposta non arriva, i campi
   restano "da definire" — si completano in una sessione futura
4. La sezione "📁 Progetti attivi" della Dashboard è una vista live (Bases) filtrata
   su `stato: attivo`: il progetto vi compare da solo se il frontmatter ha `stato:`
   e `prossimo:` compilati — verifica che ci siano, non toccare la Dashboard
5. Se nel vault esistono note correlate al tema, collegale con wikilink
6. **Ponte col repo**: se il progetto ha (o avrà) un repo di codice, proponi di
   installare nel suo `CLAUDE.md` il blocco "Second brain" dal testo canonico
   `vault/99-Sistema/template-ponte-progetto.md` — il ponte è proprietà del
   cervello, ma si scrive fuori da questo repo: serve l'ok dell'utente

**Fatto quando**: la nota esiste in `01-Progetti/` con frontmatter completo
(`tipo: progetto`, `stato: attivo`, `prossimo:` valorizzato) e compare da sola
nella vista live della Dashboard; se c'è un repo, il ponte è installato o
proposto.
