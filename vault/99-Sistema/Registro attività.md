---
tipo: sistema
---

# Registro attività

Memoria di sessione dell'agente: ogni esecuzione di una skill aggiunge una riga
**in cima** alla tabella. `/brief` rilegge le righe recenti per dare continuità
tra una sessione e l'altra. Tenere le sintesi a una riga; oltre le ~50 righe,
la weekly review sposta le più vecchie in `Registro attività — archivio.md`
(il file attivo resta magro: è letto dagli agenti a ogni run).

È anche la fonte da cui `/evolvi` conta l'**uso reale** di ogni skill: una skill
che non compare qui per tre settimane è una skill che non serve.

Ancora nessuna riga: si popola alla prima run di una skill.
