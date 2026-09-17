---
name: restyling-frontend
description: Restyling o creazione di pagine web frontend con design a palette validata e verifica visiva via screenshot headless. Usare quando l'utente chiede di rifare/migliorare la grafica di una pagina web o di crearne una nuova (dashboard, cruscotti, frontend di progetto).
---

# Restyling frontend con verifica screenshot

Il flusso vale per restyling e pagine nuove, in questo repo e nei repo di progetto.

1. **Design prima del codice**: se la pagina contiene cruscotti, tile di stato o
   grafici, carica la skill `dataviz` e usa la sua palette di riferimento
   (superfici, inchiostri, colori di stato). I contrasti degli accenti si
   **calcolano** con un one-liner Node (WCAG: ≥ 4.5:1 per testo, ≥ 3:1 per
   componenti UI), mai a occhio — scegli la variante chiara e quella scura
   che passano la soglia sulle rispettive superfici.
2. **Regole fisse del design**:
   - stato mai affidato al solo colore: pallino/icona sempre accompagnati
     dalla parola ("da fare", "3 da allineare");
   - tema chiaro+scuro con CSS custom properties: blocco light su `:root`,
     dark in `@media (prefers-color-scheme: dark)` con `:root:not([data-tema="chiaro"])`,
     override espliciti `:root[data-tema="chiaro"|"scuro"]`; toggle salvato in
     `localStorage` e parametro `?tema=` in URL (vale solo per la pagina:
     serve a prove e screenshot);
   - zero dipendenze esterne se la pagina è servita da un container del sistema.
3. **Implementa e controlla la sintassi**: se l'HTML è inline in un server JS,
   `node --check <file>` prima del deploy (attenzione a backtick e `${` dentro
   i template literal).
4. **Deploy**: se il file è copiato nell'immagine (COPY nel Dockerfile) serve
   `podman compose build <servizio>` + `podman compose up -d <servizio>`; poi
   verifica con curl: 200 sulla pagina e risposta sensata dagli endpoint dati.
5. **Verifica visiva** con Edge headless, entrambi i temi:
   ```
   msedge --headless=new --window-size=1280,1600 --virtual-time-budget=8000 --screenshot=<scratchpad>\pagina-chiaro.png "http://localhost:<porta>/?tema=chiaro"
   ```
   (idem con `?tema=scuro`; il PNG può comparire con qualche secondo di ritardo:
   attendere in polling, non dedurre il fallimento). Leggi le immagini e guarda
   il layout — collisioni di etichette, elementi orfani nelle griglie, overflow —
   poi itera fino a pulito.
6. **Caveat headless** (imparati sul campo, su un frontend WebGL):
   mai `--disable-gpu` su contenuti WebGL; un run nero NON prova un bug
   (screenshot = conferma positiva, mai prova di regressione); le interazioni
   (click, toggle) non si verificano in headless → chiedi all'utente la prova
   manuale finale e registra l'esito.
7. **Vault** (se il lavoro riguarda l'agentic OS o un progetto con scheda):
   registra il task in `vault/Dashboard.md` (🎯 Oggi) all'inizio, chiudilo solo
   a verifica utente avvenuta; riga in `vault/99-Sistema/Registro attività.md`;
   log nella scheda progetto in `vault/01-Progetti/`.

**Fatto quando**: la pagina deployata risponde 200, gli screenshot dei due temi
sono stati letti e il layout è pulito, la verifica manuale delle interazioni è
stata chiesta all'utente, e il vault riflette inizio e chiusura del lavoro.
