#!/bin/sh
# Ciclo /evolvi headless — implementazione canonica nel container (identica su
# Windows/Linux). L'host la invoca via scheduler (Task Scheduler / cron) con:
#   podman exec agentic-dashboard sh /app/evolvi.sh
# oppure dal pulsante "Evolvi" della dashboard.
cd /workspace || exit 1

# Lucchetto del sync: questa run scrive nel vault per parecchi minuti e il sync
# orario non deve committarla a meta'. Il lock lo mette qui e non in server.js
# cosi' vale per tutte e tre le vie d'invocazione (pulsante, scheduler, exec a
# mano); il trap lo toglie comunque vada, anche se la run muore.
LOCK=/workspace/.sync-lock
printf '%s evolvi.sh nel container\n' "$(date '+%Y-%m-%dT%H:%M:%S')" > "$LOCK"
trap 'rm -f "$LOCK"' EXIT INT TERM

echo "[evolvi] avvio $(date '+%Y-%m-%dT%H:%M:%S')"
# Modello dichiarato (direttiva "il modello segue il compito", applicata per
# fase): l'orchestratore gira sul modello top — la Fase 2 decide cosa entra nel
# sistema, ed è la decisione autonoma a più alta leva dell'agentic OS — mentre
# la raccolta (Fase 1) è delegata dalla skill all'agente `ricercatore` su
# Sonnet 5: i token costosi ragionano sui digest, mai sui risultati grezzi.
# --permission-mode dichiarato: il default di Claude Code (2.1.198+: "Manual")
# può bloccare una run schedulata in attesa di un'approvazione che non arriverà.
# acceptEdits = modifiche ai file libere; i comandi Bash restano governati dalle
# allow-rules (i guardrail sono codice, non prompt).
# "Top" significa il top DISPONIBILE, non un nome fisso: Opus 5 dal 2026-07-26
# (prima Opus 4.8 dal 2026-07-06; Fable 5 ritirato dal 2026-07-07).
claude -p "/evolvi" --model claude-opus-5 --permission-mode acceptEdits --output-format text 2>&1
echo "[evolvi] fine, exit code $?"

# Verifica esterna del contratto "Fatto quando" — l'auto-report dell'agente non
# fa fede (failure mode documentato: nota "Loop agentici" del 2026-07-08, la
# quota di "fatto" dichiarati a lavoro parziale cresce nel tempo). Il verifier
# sta fuori dall'agente, in codice: constata e segnala, non corregge.
today=$(date +%Y-%m-%d)
verifica_ok=1
[ -f "vault/03-Risorse/Evoluzione/$today Tech radar.md" ] \
    || { echo "[verifica] manca il Tech radar di oggi"; verifica_ok=0; }
grep -q "| $today " "vault/99-Sistema/Changelog evoluzione.md" \
    || { echo "[verifica] nessuna riga di oggi nel Changelog evoluzione"; verifica_ok=0; }
git log --since=midnight --format=%s | grep -q "^evolvi:" \
    || { echo "[verifica] nessun commit 'evolvi:' di oggi"; verifica_ok=0; }
if [ "$verifica_ok" = "1" ]; then
    echo "[verifica] contratto 'Fatto quando' rispettato"
else
    echo "[verifica] ATTENZIONE: run incompleta, non fidarsi del report dell'agente"
fi

# Installazione governata delle skill dalla staging (max 1 nuova, mai 'evolvi')
sh /app/install-staging.sh

# Riparazione dell'indice + commit se serve
node /app/indice.js
if ! git diff --quiet -- vault/Indice.md; then
    git add vault/Indice.md && git commit -m "evolvi: indice del vault rigenerato" >/dev/null
    echo "[indice] rigenerato e committato"
fi
