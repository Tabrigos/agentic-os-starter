# Dashboard one-click dell'agentic OS — servizio compose universale (Fase 3).
# Claude Code gira DENTRO il container: stessa immagine e stesso comportamento
# su Windows e Linux; l'host serve solo per podman e per le credenziali.
FROM docker.io/library/node:22-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Versione della CLI dichiarata, non implicita (principio 9: "nessun default
# implicito nelle automazioni"). Senza pin il layer resta in cache e un build
# normale non aggiorna nulla: il container e' rimasto a 2.1.201 dal 2026-07-26
# al 2026-09-04 mentre a monte si arrivava a 2.1.260 (~57 versioni di divario),
# e il principio 11 regge solo se il motore che blocca i comandi e' aggiornato.
# Aggiornare = cambiare questa riga: gesto esplicito, tracciato da git.
# tests/test-deterministico.ps1 confronta questo valore con la CLI installata
# nel container: se divergono, il test fallisce.
ARG CLAUDE_CODE_VERSION=2.1.260
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} \
    && claude --version

WORKDIR /app
COPY server.js indice.js entrypoint.sh sync-repo.sh evolvi.sh install-staging.sh ./
RUN chmod +x entrypoint.sh sync-repo.sh evolvi.sh install-staging.sh

EXPOSE 3210
ENTRYPOINT ["/app/entrypoint.sh"]
