# Lucchetto del sync: il file .sync-lock alla radice del repo significa
# "c'e' qualcuno che sta scrivendo, non committare adesso".
#
# Perche' esiste (pendenza aperta dalla weekly review del 2026-07-27, applicata
# il 2026-09-04): automation\sync.ps1 gira ogni ora da Task Scheduler e fa
# git add -A + commit con messaggio generico. Se scatta a meta' sessione si
# porta via un lavoro incompleto sotto un messaggio che non dice niente - ed e'
# successo davvero il 2026-09-04 alle 10:48, inghiottendo 21 file di una
# sessione in corso e costringendo a riscrivere la storia gia' pushata.
#
# Chi crea il lock: le sessioni interattive via hook SessionStart/SessionEnd
# (.claude\settings.json), le run headless via dashboard\evolvi.sh e
# dashboard\server.js. Il sync NON lo crea mai: lo legge e basta, altrimenti il
# pulsante "Sync repo" inciamperebbe nel proprio lucchetto.
#
# Il lock SCADE (4 ore): i docs di Claude Code non garantiscono che SessionEnd
# venga eseguito, quindi un lock orfano e' un caso normale, non un incidente -
# e un backup orario non puo' restare bloccato per sempre da un file dimenticato.
#
# Limite noto, misurato il 2026-09-04: il lucchetto e' UN file solo, non uno per
# sessione. Con due sessioni interattive aperte insieme, la prima che si chiude
# toglie il lock anche all'altra - verificato quel giorno, con due sessioni
# contemporanee. Il buco lo copre il secondo guardiano dentro i due sync (niente
# commit se qualcosa e' stato toccato negli ultimi 5 minuti), che di una sessione
# davvero attiva si accorge comunque. La versione per-sessione - un file per
# session_id, che l'hook riceve nel JSON su stdin - e' il passo successivo, da
# fare se il caso si dimostra reale e non solo possibile.
#
# Uso: powershell -File automation\sync-lock.ps1 -Azione crea|rimuovi|stato
# (dal prefisso ! di Claude Code: automation/sync-lock.ps1, con barre normali)

param(
    [ValidateSet('crea', 'rimuovi', 'stato')] [string]$Azione = 'stato',
    [string]$Chi = ''
)

$Proj = Split-Path -Parent $PSScriptRoot
$lock = Join-Path $Proj '.sync-lock'

if ($Azione -eq 'crea') {
    if (-not $Chi) { $Chi = "sessione interattiva su $env:COMPUTERNAME" }
    $riga = "{0} {1}" -f (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'), $Chi
    [IO.File]::WriteAllText($lock, $riga, (New-Object Text.UTF8Encoding($false)))
    Write-Host "[sync-lock] creato - $Chi"
} elseif ($Azione -eq 'rimuovi') {
    if (Test-Path $lock) {
        Remove-Item $lock -Force -ErrorAction SilentlyContinue
        Write-Host "[sync-lock] rimosso"
    } else {
        Write-Host "[sync-lock] gia' assente"
    }
} else {
    if (Test-Path $lock) {
        $eta = (Get-Date) - (Get-Item $lock).LastWriteTime
        $chiLo = (Get-Content $lock -Raw -ErrorAction SilentlyContinue)
        Write-Host ("[sync-lock] presente da {0} min - {1}" -f [int]$eta.TotalMinutes, "$chiLo".Trim())
        if ($eta.TotalHours -ge 4) { Write-Host "[sync-lock] ATTENZIONE: scaduto, il prossimo sync lo ignora" }
    } else {
        Write-Host "[sync-lock] assente: il sync e' libero di girare"
    }
}
