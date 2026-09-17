@echo off
rem Avvia lo stack (Obsidian + dashboard) e apre la dashboard one-click.
rem La logica vive nel container "dashboard" (vedi compose.yaml): questo file e' solo colla per Windows.
cd /d "%~dp0.."
podman compose up -d
start "" http://localhost:3210
