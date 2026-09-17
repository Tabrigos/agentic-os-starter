---
name: brief
description: Genera il brief del giorno dal vault - task in scadenza, progetti attivi, inbox - e aggiorna Dashboard e daily note. Usare quando l'utente chiede il brief, il punto della situazione o cosa c'è da fare oggi.
---

# Brief del giorno

Leggi prima `vault/CLAUDE.md` per le convenzioni. Poi:

1. Raccogli dal vault:
   - Task aperti (`- [ ]`) in `01-Progetti/` e `02-Aree/`, con attenzione alle scadenze `📅` passate o entro 7 giorni
   - Progetti con `stato: attivo` e il loro prossimo passo
   - Numero di note in `00-Inbox/` da smistare
   - La daily note di ieri (se esiste) per il contesto
   - Le righe recenti di `vault/99-Sistema/Registro attività.md` per la continuità con le sessioni precedenti
   - **Se il Registro è muto, non concluderne che non è successo nulla**: guarda
     `git log --since=<ultima daily> -- vault/01-Progetti` — il ponte dei repo di
     progetto aggiorna le schede senza lasciare righe nel Registro (regola del
     2026-09-04, dalla review del 09-02: uno sprint di sette giorni era passato
     inosservato a tutti gli strumenti del vault)
2. Scrivi il brief in `vault/05-Daily/<oggi YYYY-MM-DD>.md` usando `99-Sistema/template-daily.md`
   (se la daily di oggi esiste già, aggiorna solo la sezione Focus senza toccare il resto)
3. Aggiorna in `vault/Dashboard.md` le sezioni "🎯 Oggi" e "📰 Ultimo brief"
   (callout `> [!tip]` con data/ora e sintesi di 2-3 righe — mantieni quel formato).
   "📁 Progetti attivi" e "📥 Inbox" sono viste live (Bases): **non toccarle**;
   se il quadro dei progetti è cambiato, aggiorna `stato:`/`prossimo:` nel
   frontmatter delle note progetto
4. Riporta il brief all'utente in chat, in forma compatta: scadenze urgenti prima

A fine run aggiungi una riga in cima alla tabella di `vault/99-Sistema/Registro attività.md`.

Non inventare task: riporta solo ciò che è scritto nel vault.

**Fatto quando**: la daily di oggi esiste con il Focus aggiornato, la Dashboard
ha "🎯 Oggi" e "📰 Ultimo brief" correnti, il brief è stato riportato in chat e
il Registro ha la riga della run.
