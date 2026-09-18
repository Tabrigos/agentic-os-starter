---
tipo: progetto
stato: attivo
prossimo: prima run di /brief, poi svuotare l'inbox d'esempio con /processa-inbox
tag: [sistema]
creata: 2026-09-18
descrizione: Il progetto che tiene vivo il sistema stesso - infrastruttura, skill, permessi, test
---

# Setup Agentic OS

**Obiettivo**: tenere vivo e in evoluzione il sistema che gestisce questo vault.
**Scadenza**: nessuna, è un progetto permanente.

Questa scheda esiste perché **anche l'agentic OS è un progetto**. Ogni sessione
che tocca container, script, skill, permessi o test aggiunge una riga al Log qui
sotto, oltre che al `Registro attività`. Senza, il progetto risulta fermo mentre
non lo è, e la weekly review lo segnala come abbandonato.

## Stato e decisioni note

- Sistema appena installato dal pacchetto. Nessuna personalizzazione ancora.
- `/evolvi` è **in pausa**: l'attività pianificata è registrata ma disabilitata.
  Si lancia a mano finché non ti fidi del ciclo.
- Il vault d'esempio che trovi in `00-Inbox/`, `01-Progetti/`, `02-Aree/` e
  `03-Risorse/` serve solo a far vedere le skill al lavoro: cancellalo quando
  hai capito come funziona.

## Task

- [ ] Lanciare `/brief` una prima volta
- [ ] Svuotare l'inbox d'esempio con `/processa-inbox` e guardare dove finiscono le note
- [ ] Sostituire le note d'esempio con i propri progetti e le proprie aree
- [ ] Lanciare `tests\run-evals.ps1` una volta per fissare la propria baseline
- [ ] Decidere se attivare il sync su un repo git privato

## Note

## Log

- 2026-09-18 — sistema installato dal pacchetto
