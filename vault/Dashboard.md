---
tipo: sistema
descrizione: La home del sistema — priorità di oggi, progetti attivi, inbox, ultimo brief e coda delle proposte di evoluzione
---

# 🧠 Dashboard

%% ZONA FISSA - NON SPOSTARE E NON SCRIVERE QUI.
Il link alla dashboard interattiva sta in cima per scelta di design: se sta sotto
la riga "Ultimo aggiornamento", che cresce a ogni run, finisce sepolto sempre piu'
in basso. Le skill aggiungono in "Oggi", "Ultimo brief" e "Evoluzione" - mai qui
sopra. Regola in vault/CLAUDE.md. %%

> [!tip] ▶ Dashboard interattiva (quella coi pulsanti)
> **[Aprila da qui](http://agentic-dashboard:3210)** — link cliccabile da dentro Obsidian
> Dal browser del PC: http://localhost:3210 · Se lo stack è spento: `automation\dashboard.cmd`

> Sistema: [[Guida all'uso]] · [[Indice]] · [[Architettura e filosofia]] · [[Changelog evoluzione]] · [[Registro attività]]

> [!abstract]- Storico degli aggiornamenti di questa Dashboard (ripiegato: cresce a ogni run)
> Aggiornata dalle skill di Claude Code. Nessun aggiornamento ancora: lancia `/brief`.

## 🎯 Oggi

Sistema appena installato. Primo passo: apri una sessione `claude` in questa
cartella e lancia `/brief`.

## 📁 Progetti attivi

Vista live (Obsidian Bases): si aggiorna da sola. Il "prossimo passo" si cambia nel frontmatter `prossimo:` della nota progetto.

```base
filters:
  and:
    - file.inFolder("01-Progetti")
    - tipo == "progetto"
    - stato == "attivo"
properties:
  note.stato:
    displayName: Stato
  note.prossimo:
    displayName: Prossimo passo
views:
  - type: table
    name: Attivi
    order:
      - file.name
      - note.stato
      - note.prossimo
```

## 📥 Inbox

Vista live: le note qui sotto sono quelle ancora da smistare (vuota = inbox pulita).

```base
filters:
  and:
    - file.inFolder("00-Inbox")
views:
  - type: table
    name: Da smistare
    order:
      - file.name
      - file.mtime
```

## 📰 Ultimo brief

Nessun brief ancora generato.

## 🧬 Evoluzione

Nessuna run di `/evolvi` ancora. Il rito è settimanale: il lunedì apri questa
sezione, approvi o bocci le proposte e scorri il [[Changelog evoluzione]].
Senza questo rito il sistema smette di crescere.

`/evolvi` arriva **in pausa**: si lancia a mano (pulsante Evolvi della dashboard
interattiva o `automation\run-evolvi.ps1`). Per schedularlo davvero serve
riabilitare l'attività pianificata, e conviene farlo solo dopo qualche run
manuale andata bene.

## ⚡ Skill disponibili

| Comando | Cosa fa |
|---|---|
| `/brief` | Brief del giorno: task in scadenza, progetti, novità |
| `/processa-inbox` | Smista le note di `00-Inbox/` nelle cartelle PARA |
| `/nuovo-progetto <nome>` | Crea un progetto con template e lo aggiunge qui |
| `/weekly-review` | Revisione settimanale: avanzamenti, archiviazioni, priorità |
| `/evolvi` | Ciclo di auto-miglioramento: ricerca novità, analizza, applica/propone |
| `/distilla [url]` | Da video YouTube, documento o pagina web a nota di conoscenza |
| `/restyling-frontend` | Restyling/creazione di pagine web: palette validata, tema chiaro/scuro, verifica via screenshot headless |
