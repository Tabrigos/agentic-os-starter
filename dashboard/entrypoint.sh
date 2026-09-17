#!/bin/sh
set -e

# Trust del workspace per le run headless. /root/.claude.json vive nel
# filesystem del container: questo passo è idempotente e rigenerato a ogni
# avvio, senza toccare la configurazione Claude dell'host (di cui montiamo
# solo .credentials.json, come unico token store condiviso).
node -e '
const fs = require("fs");
const p = "/root/.claude.json";
let j = {};
try { j = JSON.parse(fs.readFileSync(p, "utf8")); } catch (e) {}
j.projects = j.projects || {};
j.projects["/workspace"] = Object.assign({}, j.projects["/workspace"], { hasTrustDialogAccepted: true });
fs.writeFileSync(p, JSON.stringify(j, null, 2));
'

# Il repo è montato con proprietari "esterni": git dentro il container deve fidarsi
git config --global --add safe.directory /workspace 2>/dev/null || true

# Identità git per i commit del pulsante sync
git config --global user.name "agentic-os dashboard" 2>/dev/null || true
git config --global user.email "dashboard@agentic-os.local" 2>/dev/null || true

# Credenziali git opzionali: se l'host monta ~/.agentic-os con dentro git-token,
# il pulsante sync può fare anche pull/push (senza token: solo commit locale).
if [ -s /root/.agentic-os/git-token ]; then
    TOKEN=$(tr -d '\r\n ' < /root/.agentic-os/git-token)
    printf 'https://x-access-token:%s@github.com\n' "$TOKEN" > /root/.git-credentials
    chmod 600 /root/.git-credentials
    git config --global credential.helper store
    echo "[entrypoint] token git configurato: sync completo abilitato"
else
    echo "[entrypoint] nessun token git: il pulsante sync fara' solo commit locali"
fi

exec node /app/server.js
