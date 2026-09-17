#!/bin/sh
# Sync del repo dal container dashboard: commit locale sempre; pull+push solo
# se il token git è configurato (vedi entrypoint.sh). Implementazione canonica
# del sync (automation/sync.ps1 è la colla Windows in via di assottigliamento).
cd /workspace || exit 1

# --- Sync-lock: non committare a meta' sessione (vedi automation/sync-lock.ps1)
LOCK=/workspace/.sync-lock
if [ -f "$LOCK" ]; then
    eta=$(( $(date +%s) - $(stat -c %Y "$LOCK") ))
    if [ "$eta" -lt 14400 ]; then
        echo "[sync] sessione in corso (.sync-lock di $((eta / 60)) min fa): salto il giro"
        exit 0
    fi
    echo "[sync] .sync-lock scaduto ($((eta / 3600))h): lo ignoro e procedo"
    rm -f "$LOCK"
fi

# Rete di sicurezza che non dipende dagli hook: qualcosa toccato negli ultimi
# 5 minuti = c'e' qualcuno che scrive adesso. Salto e riprovo al giro dopo.
if [ -n "$(find vault automation dashboard tests -type f -newermt '-5 minutes' -print -quit 2>/dev/null)" ]; then
    echo "[sync] modifiche di meno di 5 minuti fa: qualcuno sta scrivendo, salto il giro"
    exit 0
fi

# Riparazione dell'indice (deterministica, zero LLM) prima del commit
node /app/indice.js

# Igiene log tecnici: automation/logs oltre 30 giorni, media-work oltre 14
find automation/logs -type f -mtime +30 -delete 2>/dev/null
find media-work -mindepth 1 -maxdepth 1 -type d -mtime +14 -exec rm -rf {} + 2>/dev/null

# Il messaggio elenca cosa entra davvero nel commit: il sync raccoglie anche il
# lavoro di sessioni in corso, quindi un messaggio generico rende il commit
# inservibile come punto di ripristino — ed è a questi commit che rimanda il
# Changelog evoluzione.
git add -A
if git diff --cached --quiet; then
    echo "[sync] nessuna modifica locale da committare"
else
    n=$(git diff --cached --name-only | wc -l | tr -d ' ')
    aree=$(git -c core.quotepath=false diff --cached --name-only \
        | awk -F/ '{ if (NF > 1) print $1"/"$2; else print $1 }' \
        | sort -u \
        | awk '{ printf "%s%s", sep, $0; sep = ", " } END { print "" }' \
        | cut -c1-60)
    oggetto="sync (container): $n file - $aree"
    {
        echo "$oggetto"
        echo
        git -c core.quotepath=false diff --cached --name-only | head -20
        [ "$n" -gt 20 ] && echo "... e altri $((n - 20)) file"
    } > /tmp/sync-msg.txt
    git commit -F /tmp/sync-msg.txt >/dev/null
    rm -f /tmp/sync-msg.txt
    echo "[sync] commit: $oggetto"
fi

if [ ! -f /root/.git-credentials ]; then
    echo "[sync] ATTENZIONE: token git assente - commit locale fatto, pull/push saltati."
    echo "[sync] Per abilitare l'allineamento col remoto: token GitHub (fine-grained,"
    echo "[sync] solo repo agentic-os, permesso Contents read/write) nel file"
    echo "[sync] ~/.agentic-os/git-token sull'host, poi: podman compose restart dashboard"
    exit 0
fi

if ! git pull --rebase origin master; then
    echo "[sync] CONFLITTO o errore: rebase interrotto. Risolvi da una sessione claude sull'host."
    exit 1
fi
git push origin master && echo "[sync] allineato col remoto"
