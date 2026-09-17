# Test dello strato deterministico dell'agentic OS (lo strato "zero LLM").
# run-evals.ps1 misura le SKILL su un vault sintetico; qui si misura l'altro
# strato del principio 9 - indice, motore, sync - che fino al 2026-09-04 non
# aveva ne' test ne' monitoraggio. E' li' che sono caduti tutti e due gli item
# infrastrutturali di /evolvi: la regressione della CLI (radar 2026-08-05) e il
# guard dell'Indice mai funzionante (radar 2026-09-02, 315 commit vuoti su 342).
#
# Uso: powershell -ExecutionPolicy Bypass -File tests\test-deterministico.ps1
# Emette oggetti {Caso, Verifica, Esito} sulla pipeline: run-evals.ps1 li accoda
# al report in una tabella separata, cosi' il punteggio delle skill resta suo e
# non si gonfia aggiungendo casi (il termometro non si allarga di nascosto).
# Richiede il container dashboard acceso; il vault reale viene solo riletto.

$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
$script:results = @()

function Add-Result($verifica, $ok) {
    $esito = 'FAIL'
    if ($ok) { $esito = 'PASS' }
    Write-Host ("  [{0}] {1}" -f $esito, $verifica)
    $script:results += [pscustomobject]@{ Caso = 'deterministico'; Verifica = $verifica; Esito = $esito }
}

Write-Host "`n=== Strato deterministico (container dashboard) ==="

# 0. Il container c'e'? Senza, le verifiche sotto non misurano niente: meglio un
#    FAIL esplicito che un verde ottenuto per assenza di misura.
$acceso = @(podman ps --format "{{.Names}}" | Where-Object { $_ -eq 'agentic-dashboard' }).Count -eq 1
Add-Result 'container agentic-dashboard acceso' $acceso

if (-not $acceso) {
    Write-Host "  (container giu': 'podman compose up -d dashboard', poi rilancia)"
} else {
    # 1. Idempotenza dell'Indice: due run di fila, la seconda non deve riscrivere.
    #    E' il test che avrebbe smascherato il bug del BOM il giorno stesso: il
    #    guard confrontava un testo col BOM con uno senza, quindi era sempre
    #    "cambiato". Costa due secondi e copre tre call site (sync orario,
    #    pulsante sync, coda di ogni run di /evolvi).
    podman exec agentic-dashboard node /app/indice.js | Out-Null
    $secondo = @(podman exec agentic-dashboard node /app/indice.js) -join ' '
    $idem = $secondo -like '*allineato*'
    Add-Result 'indice.js idempotente (2a run consecutiva: nessuna riscrittura)' $idem
    if (-not $idem) { Write-Host "  output della 2a run: $secondo" }

    # 2. Il motore e' quello dichiarato? Il principio 11 (un comando suggerito da
    #    un repo non e' fidato) regge perche' il codice della CLI blocca il
    #    comando: se la CLI resta indietro senza che nessuno se ne accorga, il
    #    principio poggia su un assunto non verificato. Qui si verifica.
    $pin = ''
    $m = [regex]::Match((Get-Content "$root\dashboard\Dockerfile" -Raw), 'ARG CLAUDE_CODE_VERSION=([0-9.]+)')
    if ($m.Success) { $pin = $m.Groups[1].Value }
    $grezza = @(podman exec agentic-dashboard claude --version)[0]
    $installata = $grezza -replace '[^0-9.]', ''
    Write-Host "  CLI dichiarata nel Dockerfile: $pin - installata nel container: $installata"
    Add-Result "CLI del container allineata al pin del Dockerfile ($pin)" (($pin -ne '') -and ($installata -eq $pin))
}

$fail = @($script:results | Where-Object { $_.Esito -eq 'FAIL' }).Count
$tot = @($script:results).Count
Write-Host ("  --- strato deterministico: {0}/{1}" -f ($tot - $fail), $tot)
$script:results
if ($fail -gt 0) { exit 1 }
