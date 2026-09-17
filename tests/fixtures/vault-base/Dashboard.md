---
tipo: sistema
---

# 🧠 Dashboard

> Aggiornata dalle skill di Claude Code.

## 🎯 Oggi

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
