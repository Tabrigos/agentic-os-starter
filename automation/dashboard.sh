#!/bin/sh
# Avvia lo stack (Obsidian + dashboard) e apre la dashboard one-click.
# La logica vive nel container "dashboard" (vedi compose.yaml): questo file è solo colla per Linux.
cd "$(dirname "$0")/.." || exit 1
podman compose up -d
xdg-open http://localhost:3210 2>/dev/null || echo "Dashboard su http://localhost:3210"
