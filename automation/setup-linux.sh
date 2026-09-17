#!/bin/sh
# Bootstrap di un host Linux per l'agentic OS — gemello di setup-pc.ps1.
# ⚠ DA COLLAUDARE al primo host Linux reale: scritto a tavolino il 2026-07-05.
#
# Prerequisiti (da installare col package manager della distro):
#   git, podman (con provider compose: podman-compose o docker-compose)
#   claude (Claude Code CLI) — poi eseguire una volta `claude` per il login:
#   crea ~/.claude/.credentials.json, il token store che i container montano
#
# Uso:  sh setup-linux.sh [--primario]
#   --primario  marca il PC primario (il cron di /evolvi è in pausa dal
#               2026-07-06: quando si riattiva, va aggiunto solo qui)

set -e
REPO="https://github.com/Tabrigos/agentic-os-starter.git"
# Se lo script gira da dentro un clone (c'e' compose.yaml accanto), quel clone
# E' la destinazione: chi ha gia' scaricato il repo non si ritrova un secondo
# clone in ~/lavoro/agentic-os senza accorgersene.
QUI=$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)
if [ -n "$QUI" ] && [ -f "$QUI/compose.yaml" ]; then DEST="$QUI"; else DEST="$HOME/lavoro/agentic-os"; fi

if [ ! -d "$DEST" ]; then
    mkdir -p "$(dirname "$DEST")"
    git clone "$REPO" "$DEST"
    echo "[setup] repo clonato in $DEST"
fi
cd "$DEST"

# Cartella per il token git opzionale del pulsante sync (vedi Guida all'uso)
mkdir -p "$HOME/.agentic-os"

# Stack su (Obsidian :3000 + dashboard :3210)
podman compose up -d
echo "[setup] stack avviato: Obsidian http://localhost:3000 - Dashboard http://localhost:3210"

# Cron: sync orario (logica nel container). Il cron di /evolvi è IN PAUSA dal
# 2026-07-06 (decisione dell'utente: solo esecuzione manuale) — la riga resta qui
# pronta, da aggiungere al crontab del solo PC primario quando si riattiva.
CRON_SYNC="17 * * * * podman exec agentic-dashboard sh /app/sync-repo.sh >> $DEST/automation/logs/sync-cron.log 2>&1"
CRON_EVOLVI="0 9 * * 1 podman exec agentic-dashboard sh /app/evolvi.sh >> $DEST/automation/logs/evolvi-cron.log 2>&1"

( crontab -l 2>/dev/null | grep -v 'agentic-dashboard' ; \
  echo "$CRON_SYNC" ) | crontab -
echo "[setup] cron registrato (sync orario; evolvi in pausa: solo manuale)"
echo "[setup] NOTA: il push del sync dal container richiede il token in ~/.agentic-os/git-token"
echo "[setup] fatto. Da collaudare: questo script non è ancora girato su un Linux reale."
