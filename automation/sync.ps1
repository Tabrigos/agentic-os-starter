# Sincronizza questo clone dell'agentic OS col remote condiviso.
# Uso: automation\sync.ps1            (sessione: pull + commit + push)
# Lanciato anche dall'attività pianificata "AgenticOS-Sync" (ogni ora).
# I markdown confliggono raramente; se succede, il rebase si ferma e lo
# segnala: apri claude nella cartella e chiedi di risolvere il conflitto.
param([string]$Proj = (Split-Path -Parent $PSScriptRoot))

Set-Location $Proj

# --- Sync-lock: non committare a meta' sessione -------------------------
# Se qualcuno sta scrivendo (sessione interattiva via hook, o run headless),
# salto il giro: il backup e' orario, riprova fra un'ora. Il lock scade a 4h
# perche' i docs di Claude Code non garantiscono SessionEnd, e un lock orfano
# non deve bloccare il backup per sempre. Il perche' completo, con la data in
# cui e' successo davvero, sta in automation/sync-lock.ps1.
# Un file per titolare in .sync-locks\ (sessione interattiva, run della
# dashboard, /evolvi): il repo e' bloccato se ne esiste almeno uno vivo, e
# ognuno cancella solo il proprio. Il sync legge e raccoglie gli scaduti,
# non crea mai un lucchetto.
$dirLock = Join-Path $Proj '.sync-locks'
$vecchioLock = Join-Path $Proj '.sync-lock'
$candidati = @(Get-ChildItem -LiteralPath $dirLock -File -ErrorAction SilentlyContinue)
if (Test-Path -LiteralPath $vecchioLock) { $candidati += @(Get-Item -LiteralPath $vecchioLock) }
$vivi = @()
foreach ($f in $candidati) {
    $eta = (Get-Date) - $f.LastWriteTime
    if ($eta.TotalHours -lt 4) { $vivi += $f }
    else {
        Write-Host ("[sync] lucchetto scaduto ({0}h) di '{1}': lo raccolgo" -f [int]$eta.TotalHours, $f.Name)
        Remove-Item -LiteralPath $f.FullName -Force -ErrorAction SilentlyContinue
    }
}
if ($vivi.Count -gt 0) {
    $piuRecente = $vivi | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $eta = [int]((Get-Date) - $piuRecente.LastWriteTime).TotalMinutes
    Write-Host ("[sync] {0} titolare/i del lucchetto (il piu' recente di {1} min fa): salto il giro" -f $vivi.Count, $eta)
    exit 0
}

# Rete di sicurezza che NON dipende dagli hook: se un file tracciato e' stato
# toccato negli ultimi 5 minuti, qualcuno sta scrivendo proprio adesso (Claude,
# Obsidian, un editor). Salto e riprovo. E' stateless e auto-limitante: bastano
# 5 minuti di quiete e il sync passa, senza che nessuno debba togliere niente.
$pendenti = @(git -c core.quotepath=false status --porcelain | ForEach-Object { $_.Substring(3) })
$ultimoTocco = $pendenti | ForEach-Object {
    $f = Join-Path $Proj $_
    if (Test-Path $f) { (Get-Item $f).LastWriteTime }
} | Sort-Object -Descending | Select-Object -First 1
if ($ultimoTocco -and ((Get-Date) - $ultimoTocco).TotalMinutes -lt 5) {
    Write-Host "[sync] modifiche di meno di 5 minuti fa: qualcuno sta scrivendo, salto il giro"
    exit 0
}

# Ripara le derive dell'Indice prima del commit (deterministico, zero LLM).
# Implementazione canonica nel container dashboard (dashboard/indice.js);
# se il container è giù la riparazione salta: la recupera la run successiva.
podman exec agentic-dashboard node /app/indice.js 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "[sync] container dashboard giu': riparazione indice saltata" }

# commit locale di eventuali modifiche pendenti (note scritte in Obsidian ecc.)
# Il messaggio elenca cosa entra davvero nel commit: il sync gira ogni ora e
# raccoglie anche il lavoro di sessioni in corso, quindi un messaggio generico
# (il vecchio "modifiche da <host>") rende il commit inservibile come punto di
# ripristino — ed è a questi commit che rimanda il Changelog evoluzione.
git add -A | Out-Null
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    $files = @(git -c core.quotepath=false diff --cached --name-only)
    $aree = @($files | ForEach-Object {
        $parti = $_ -split '/'
        if ($parti.Count -gt 1) { "$($parti[0])/$($parti[1])" } else { $parti[0] }
    } | Sort-Object -Unique)
    $sommario = $aree -join ', '
    if ($sommario.Length -gt 60) { $sommario = $sommario.Substring(0, 57) + '...' }
    $oggetto = "sync ($env:COMPUTERNAME): $($files.Count) file - $sommario"
    $corpo = ($files | Select-Object -First 20) -join "`n"
    if ($files.Count -gt 20) { $corpo = "$corpo`n... e altri $($files.Count - 20) file" }
    # -F da file: il messaggio e' multiriga e puo' contenere accenti
    $tmp = Join-Path $env:TEMP "agentic-os-sync-msg.txt"
    [IO.File]::WriteAllText($tmp, "$oggetto`n`n$corpo", (New-Object Text.UTF8Encoding($false)))
    git commit -F $tmp | Out-Null
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    Write-Host "[sync] commit: $oggetto"
}

# se non c'è un remote configurato, fermati senza errore
git remote get-url origin 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "[sync] nessun remote 'origin', salto"; exit 0 }

git pull --rebase origin master
if ($LASTEXITCODE -ne 0) {
    Write-Host "[sync] CONFLITTO: rebase interrotto. Apri claude in $Proj e chiedi di risolverlo."
    exit 1
}

git push origin master
if ($LASTEXITCODE -eq 0) { Write-Host "[sync] allineato col remote" }

# ── Igiene log tecnici (fuori dal vault: qui si pota davvero) ──────────
# automation/logs: oltre 30 giorni; media-work: transcript oltre 14 giorni
# (la conoscenza vive nelle note di 03-Risorse/Video, i transcript sono scarti).
$soglia = (Get-Date).AddDays(-30)
Get-ChildItem "$Proj\automation\logs" -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $soglia } |
    Remove-Item -Force -ErrorAction SilentlyContinue
$sogliaMedia = (Get-Date).AddDays(-14)
Get-ChildItem "$Proj\media-work" -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $sogliaMedia } |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
