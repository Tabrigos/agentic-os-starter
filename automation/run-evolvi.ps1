# Colla Windows per il ciclo /evolvi — lancio MANUALE: la task pianificata
# AgenticOS-Evolvi e' in pausa dal 2026-07-06 (riattivare con Enable-ScheduledTask).
# La logica canonica vive nel container dashboard (dashboard/evolvi.sh:
# claude headless + install-staging governato + indice) ed è identica su
# Linux, dove al posto di questo file basta una riga di cron:
#   0 9 * * 1  podman exec agentic-dashboard sh /app/evolvi.sh >> log 2>&1
$proj = Split-Path -Parent $PSScriptRoot   # radice del repo: questo file sta in automation/
$logDir = Join-Path $proj "automation\logs"
New-Item -ItemType Directory -Force $logDir | Out-Null
$log = Join-Path $logDir ("evolvi-{0:yyyy-MM-dd-HHmm}.log" -f (Get-Date))

Set-Location $proj
"[glue] avvio $(Get-Date -Format s)" | Out-File $log -Encoding utf8
podman machine start 2>$null | Out-Null          # idempotente: innocuo se già attiva
podman compose up -d dashboard 2>&1 | Out-Null   # idempotente: innocuo se già su
podman exec agentic-dashboard sh /app/evolvi.sh 2>&1 |
    Out-File $log -Append -Encoding utf8
"[glue] fine $(Get-Date -Format s), exit code $LASTEXITCODE" | Out-File $log -Append -Encoding utf8
