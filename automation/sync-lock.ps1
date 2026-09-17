# Lucchetto del sync: un file dentro .sync-locks/ significa "c'e' qualcuno che
# sta scrivendo, non committare adesso". UN FILE PER TITOLARE, dal 2026-09-17.
#
# Perche' esiste (pendenza aperta dalla weekly review del 2026-07-27, applicata
# il 2026-09-04): automation\sync.ps1 gira ogni ora da Task Scheduler e fa
# git add -A + commit con messaggio generico. Se scatta a meta' sessione si
# porta via un lavoro incompleto sotto un messaggio che non dice niente - ed e'
# successo davvero il 2026-09-04 alle 10:48, inghiottendo 21 file di una
# sessione in corso e costringendo a riscrivere la storia gia' pushata.
#
# Perche' e' per-titolare (2026-09-17): fino a oggi era UN file solo, senza
# proprietario, e il SessionEnd di una sessione toglieva il lucchetto anche
# alle altre ancora aperte. Il limite era gia' scritto qui, con la condizione
# per chiuderlo: "da fare se il caso si dimostra reale e non solo possibile".
# Si e' dimostrato reale due volte. La seconda - 2026-09-17, commit 9321d77,
# 31 file di una sessione in corso - il secondo guardiano NON ha coperto,
# perche' nei 5 minuti prima quella sessione stava LEGGENDO e non scrivendo.
# Da cui la lezione, che vale oltre questo file: il guardiano delle scritture
# recenti vede le scritture, non le sessioni aperte, e una sessione di design
# passa meta' del tempo a leggere.
#
# Il protocollo, per chiunque lo implementi (qui, automation\sync.ps1,
# dashboard\sync-repo.sh, dashboard\evolvi.sh, dashboard\server.js):
#   - ogni titolare scrive .sync-locks\<id> con dentro "<data ISO> <chi>"
#   - il repo e' bloccato se esiste ALMENO UN file piu' giovane di 4 ore
#   - chi passa e trova un file scaduto lo cancella (raccolta dei lock orfani)
#   - ognuno cancella SOLO il proprio file, mai quello degli altri
#   - il vecchio .sync-lock singolo vale ancora in lettura, per non ignorare
#     una sessione rimasta aperta durante il passaggio alla nuova forma
#
# Il lock SCADE (4 ore): i docs di Claude Code non garantiscono che SessionEnd
# venga eseguito, quindi un lock orfano e' un caso normale, non un incidente -
# e un backup orario non puo' restare bloccato per sempre da un file dimenticato.
#
# Chi mette il lock: le sessioni interattive via hook SessionStart/SessionEnd
# (.claude\settings.json), le run headless via dashboard\evolvi.sh e
# dashboard\server.js. Il sync NON lo mette mai: lo legge e basta, altrimenti il
# pulsante "Sync repo" inciamperebbe nel proprio lucchetto.
#
# Uso: powershell -File automation\sync-lock.ps1 -Azione crea|rimuovi|stato
# (dal prefisso ! di Claude Code: automation/sync-lock.ps1, con barre normali)

param(
    [ValidateSet('crea', 'rimuovi', 'stato')] [string]$Azione = 'stato',
    [string]$Chi = '',
    [string]$Id = ''
)

$Proj = Split-Path -Parent $PSScriptRoot
$dir = Join-Path $Proj '.sync-locks'
$vecchio = Join-Path $Proj '.sync-lock'
$scadenzaOre = 4

# L'id di una sessione interattiva arriva nel JSON che Claude Code manda sullo
# stdin dell'hook. Senza id, 'crea' e 'rimuovi' non si possono appaiare: in quel
# caso si ricade su un id fisso, cioe' esattamente il comportamento di prima.
# Peggio di prima non si va mai; meglio si va appena l'id c'e'.
if (-not $Id) {
    $grezzo = ''
    # due strade perche' ci sono due modi di arrivare qui: l'hook lancia un
    # processo a se' (stdin del processo), una prova a mano o il prefisso ! di
    # Claude Code passano per la pipeline di PowerShell ($input).
    try { $grezzo = "$($input | Out-String)".Trim() } catch { }
    if (-not $grezzo -and [Console]::IsInputRedirected) {
        try { $grezzo = [Console]::In.ReadToEnd() } catch { }
    }
    if ($grezzo) {
        try { $Id = [string](ConvertFrom-Json $grezzo).session_id } catch { }
    }
}
if (-not $Id) { $Id = 'sconosciuta' }
$Id = ($Id -replace '[^A-Za-z0-9._-]', '_')
if ($Id.Length -gt 80) { $Id = $Id.Substring(0, 80) }
$mio = Join-Path $dir $Id

# Titolari vivi = file piu' giovani della scadenza. Gli scaduti si cancellano
# qui: la raccolta la fa chiunque passi, cosi' non deve ricordarsene nessuno.
function Get-Titolari {
    $ora = Get-Date
    $vivi = @()
    $tutti = @(Get-ChildItem -LiteralPath $dir -File -ErrorAction SilentlyContinue)
    if (Test-Path -LiteralPath $vecchio) { $tutti += @(Get-Item -LiteralPath $vecchio) }
    foreach ($f in $tutti) {
        if (($ora - $f.LastWriteTime).TotalHours -lt $scadenzaOre) { $vivi += $f }
        else { Remove-Item -LiteralPath $f.FullName -Force -ErrorAction SilentlyContinue }
    }
    return $vivi
}

if ($Azione -eq 'crea') {
    if (-not $Chi) { $Chi = "sessione interattiva su $env:COMPUTERNAME" }
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $riga = "{0} {1}" -f (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'), $Chi
    [IO.File]::WriteAllText($mio, $riga, (New-Object Text.UTF8Encoding($false)))
    Write-Host "[sync-lock] creato ($Id) - $Chi"
}
elseif ($Azione -eq 'rimuovi') {
    $tolto = $false
    if (Test-Path -LiteralPath $mio) {
        Remove-Item -LiteralPath $mio -Force -ErrorAction SilentlyContinue
        $tolto = $true
    }
    # Il file singolo di prima lo toglie SOLO chi non ha un id proprio: e' la
    # regola che impedisce a una sessione che si chiude di portare via il
    # lucchetto di un'altra, cioe' il difetto che questa versione ripara.
    if ($Id -eq 'sconosciuta' -and (Test-Path -LiteralPath $vecchio)) {
        Remove-Item -LiteralPath $vecchio -Force -ErrorAction SilentlyContinue
        $tolto = $true
    }
    $restano = @(Get-Titolari).Count
    if ($tolto) { Write-Host "[sync-lock] rimosso ($Id); restano $restano titolari" }
    else { Write-Host "[sync-lock] gia' assente ($Id); restano $restano titolari" }
}
else {
    $vivi = @(Get-Titolari)
    if ($vivi.Count -eq 0) {
        Write-Host "[sync-lock] nessun titolare: il sync e' libero di girare"
    }
    else {
        Write-Host ("[sync-lock] {0} titolare/i, il sync salta il giro:" -f $vivi.Count)
        foreach ($f in $vivi) {
            $eta = [int]((Get-Date) - $f.LastWriteTime).TotalMinutes
            $chiLo = "$(Get-Content -LiteralPath $f.FullName -Raw -ErrorAction SilentlyContinue)".Trim()
            Write-Host ("  - {0}  (da {1} min)  {2}" -f $f.Name, $eta, $chiLo)
        }
    }
}
