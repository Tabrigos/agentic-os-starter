#!/bin/sh
# Installa le skill depositate da /evolvi in staging/skills/ dentro .claude/skills/.
# Porting fedele di automation/install-staging.ps1 — vincoli tecnici NON negoziabili:
#   - massimo UNA skill nuova installata per invocazione
#   - aggiornamenti a skill esistenti ammessi, MAI alla skill 'evolvi'
#     (il governatore non si auto-modifica senza ok umano)
# Ciò che non viene installato resta in staging/ come proposta visibile.
cd /workspace || exit 1

STAGING="staging/skills"
SKILLS=".claude/skills"
[ -d "$STAGING" ] || { echo "[staging] nessuna staging presente, nulla da fare"; exit 0; }

nuova_installata=0
modifiche=0

for dir in "$STAGING"/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    src="$dir/SKILL.md"
    if [ ! -f "$src" ]; then
        echo "[staging] '$name' senza SKILL.md, ignorata"; continue
    fi
    if [ "$name" = "evolvi" ]; then
        echo "[staging] aggiornamento di 'evolvi' NON installato: resta in staging come proposta"
    elif [ -d "$SKILLS/$name" ]; then
        cp "$src" "$SKILLS/$name/SKILL.md"
        rm -rf "$dir"
        modifiche=1
        echo "[staging] aggiornata skill esistente '$name'"
    elif [ "$nuova_installata" = "0" ]; then
        mkdir -p "$SKILLS/$name"
        cp "$src" "$SKILLS/$name/SKILL.md"
        rm -rf "$dir"
        nuova_installata=1
        modifiche=1
        echo "[staging] installata nuova skill '$name'"
    else
        echo "[staging] '$name' lasciata in staging: tetto di 1 nuova skill per run raggiunto"
    fi
done

if [ "$modifiche" = "1" ]; then
    git add -A && git commit -m "evolvi: installazione skill dalla staging" >/dev/null \
        && echo "[staging] installazione committata"
fi
