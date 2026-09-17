# Eval suite dell'agentic OS.
# Per ogni caso: ricrea il testbed (copia isolata di fixture + skill), lancia la
# skill in headless, verifica fatti deterministici. Il punteggio finisce in
# tests/results/ per il confronto con la baseline dopo ogni run di /evolvi.
# Il vault reale non viene mai toccato.

$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot   # radice del repo: questo file sta in tests/
$testbed = "$root-testbed"                 # copia usa-e-getta accanto al repo
$claude = (Get-Command claude -ErrorAction SilentlyContinue).Source
if (-not $claude) { $claude = Join-Path $env:USERPROFILE ".local\bin\claude.exe" }
$resultsDir = Join-Path $root "tests\results"
New-Item -ItemType Directory -Force $resultsDir | Out-Null
# Modello fissato: le eval misurano le skill, non il modello del giorno.
# Sonnet 5 fa da "pavimento": se una skill passa qui, regge anche sui modelli top.
# I report pre-pin (2026-07-03-0032 e -1739) giravano sul default globale (Fable 5).
$evalModel = "claude-sonnet-5"
$stamp = Get-Date -Format 'yyyy-MM-dd-HHmm'
$today = Get-Date -Format 'yyyy-MM-dd'
$commit = git -C $root rev-parse --short HEAD

# Frasi distintive delle note fixture: dopo ogni skill devono esistere ancora
# da qualche parte nel vault (le note possono muoversi, mai perdere contenuto).
$sentinels = @(
    'guanciale croccante e pecorino romano',
    'pubblicare il primo articolo entro settembre',
    'tre sedute a settimana',
    'Consegnate le chiavi del vecchio appartamento',
    'Revisione del portafoglio ogni primo weekend',
    'i bind mount riflettono',
    'comprare il dominio definitivo prima del lancio',
    'libera spazio eliminando le immagini appese'
)

$script:results = @()
function Check($case, $name, $ok) {
    $esito = if ($ok) { 'PASS' } else { 'FAIL' }
    $script:results += [pscustomobject]@{ Caso = $case; Verifica = $name; Esito = $esito }
    Write-Host ("  [{0}] {1}" -f $esito, $name)
}

function Reset-Testbed {
    if (Test-Path $testbed) { Remove-Item $testbed -Recurse -Force }
    New-Item -ItemType Directory $testbed | Out-Null
    Copy-Item "$root\.claude" "$testbed\.claude" -Recurse
    # automation/ serve perche' .claude/settings.json dichiara gli hook
    # SessionStart/SessionEnd (dal 2026-09-04) e quelli invocano
    # automation/sync-lock.ps1: senza, ogni caso stampa un errore di hook.
    # Innocuo per i punteggi (SessionEnd scatta a lavoro finito) ma e' rumore in
    # ogni log, ed e' rimasto invisibile fino al 2026-09-16 perche' la run del
    # 09-04 e' delle 10:28 e gli hook sono nati nel pomeriggio. Il .sync-lock che
    # ne nasce vive nel testbed, che viene cancellato a ogni caso.
    Copy-Item "$root\automation" "$testbed\automation" -Recurse
    Copy-Item "$root\CLAUDE.md" "$testbed\CLAUDE.md"
    Copy-Item "$root\tests\fixtures\vault-base" "$testbed\vault" -Recurse
    # Solo nel testbed: permesso di spostare/cancellare file del vault sintetico,
    # altrimenti in headless "sposta in cartella PARA" degenera in "copia + stub"
    # (visto nelle run del 2026-07-03). Il vault reale mantiene il regime normale.
    #
    # ATTENZIONE - eccezione deliberata alla regola "allow-list stretta, sempre"
    # del CLAUDE.md di progetto (difesa contro l'injection da repository).
    # NON stringere queste quattro regole per coerenza con quella: qui servono a
    # misurare le skill, e senza si torna al copia+stub, cioe' la suite misura il
    # regime dei permessi invece delle skill. L'eccezione regge perche' nel
    # testbed manca ogni condizione del principio 10 (Lethal Trifecta): nessun
    # umano che approva, nessun contenuto non fidato (fixture nostre, nessun caso
    # tocca il web), nessun dato da proteggere (albero ricreato a ogni caso).
    # Se cambia una di queste tre premesse - p.es. un caso che scarica dal web -
    # allora questa eccezione va rivista.
    $testbedPerms = @'
{
  "permissions": {
    "allow": [
      "Bash(mv:*)",
      "Bash(rm:*)",
      "PowerShell(Move-Item *)",
      "PowerShell(Remove-Item *)"
    ]
  }
}
'@
    [System.IO.File]::WriteAllText("$testbed\.claude\settings.local.json", $testbedPerms, [System.Text.UTF8Encoding]::new($false))
}

# Fixture retrodatate per l'igiene del tempo (solo caso weekly-review).
# Generate a runtime con date RELATIVE a oggi: date statiche nelle fixture
# marcirebbero (il file "recente da non toccare" prima o poi diventa vecchio
# e l'eval si guasta da sola). La skill legge l'eta' dal NOME del file e dal
# frontmatter `creata:`, mai dai metadati del filesystem — che nel testbed
# sarebbero comunque azzerati dalla copia di Reset-Testbed.
function Add-IgieneFixtures {
    $dailyDir = Join-Path $testbed 'vault\05-Daily'
    $evoDir = Join-Path $testbed 'vault\03-Risorse\Evoluzione'
    New-Item -ItemType Directory -Force $dailyDir | Out-Null
    New-Item -ItemType Directory -Force $evoDir | Out-Null
    $script:oldDailyDate = (Get-Date).AddDays(-35).ToString('yyyy-MM-dd')
    $script:freshDailyDate = (Get-Date).AddDays(-2).ToString('yyyy-MM-dd')
    $script:oldReviewDate = (Get-Date).AddDays(-100).ToString('yyyy-MM-dd')
    $script:oldRadarDate = (Get-Date).AddDays(-100).ToString('yyyy-MM-dd')
    $utf8 = [System.Text.UTF8Encoding]::new($false)

    [System.IO.File]::WriteAllText("$dailyDir\$($script:oldDailyDate).md", @"
# $($script:oldDailyDate)

## Focus
- [x] Rileggere gli appunti Docker
- [x] Verificare i bind mount del vault

Brief generato dall'agente: giornata tranquilla di collaudo alfa, nessuna scadenza.
"@, $utf8)

    [System.IO.File]::WriteAllText("$dailyDir\$($script:freshDailyDate).md", @"
# $($script:freshDailyDate)

## Focus
- [x] Sistemare il frontmatter delle note nuove

Brief generato dall'agente: nessuna scadenza in vista.
"@, $utf8)

    [System.IO.File]::WriteAllText("$dailyDir\$($script:oldReviewDate)-review.md", @"
# Review settimanale - $($script:oldReviewDate)

Avanzamenti: nessun rilievo nel giro di collaudo beta. Priorita: rodaggio del vault.
"@, $utf8)

    [System.IO.File]::WriteAllText("$evoDir\$($script:oldRadarDate) Tech radar.md", @"
---
tipo: risorsa
tag: [evoluzione]
creata: $($script:oldRadarDate)
descrizione: Tech radar del ciclo evolvi - verdetti tutti decisi
---

# Tech radar - $($script:oldRadarDate)

| Voce | Verdetto |
|---|---|
| Plugin ipotetico Alfa | Applicato nella run del $($script:oldRadarDate) |
| Framework Beta | Scartato: troppo immaturo per questo vault |
"@, $utf8)

    # Nel Changelog manca apposta la riga di "Framework Beta": la checklist
    # della skill impone di aggiungerla PRIMA di eliminare il radar.
    [System.IO.File]::WriteAllText("$testbed\vault\99-Sistema\Changelog evoluzione.md", @"
---
tipo: sistema
---

# Changelog evoluzione

Memoria compressa delle strade battute: una riga per voce valutata
(applicata, proposta o scartata) dal ciclo di evoluzione.

| Data | Applicato | Proposto | Scartato |
|---|---|---|---|
| $($script:oldRadarDate) | Plugin ipotetico Alfa | - | - |
"@, $utf8)
}

function Invoke-Skill($prompt) {
    Push-Location $testbed
    # --permission-mode come in produzione (dashboard/evolvi.sh, server.js):
    # le eval misurano le skill nelle stesse condizioni delle run headless vere.
    # L'output finisce in tests/results/logs/: senza, un caso a zero azioni
    # (run morta? skill che chiede invece di agire?) resta indiagnosticabile
    # (lezione del 2026-07-12: 9 FAIL su processa-inbox e nessuna evidenza)
    $logDir = Join-Path $resultsDir 'logs'
    New-Item -ItemType Directory -Force $logDir | Out-Null
    $logName = ($prompt -replace '[^\w-]', '_').Trim('_')
    & $claude -p $prompt --model $evalModel --permission-mode acceptEdits --output-format text |
        Out-File (Join-Path $logDir "$stamp-$logName.log") -Encoding utf8
    Pop-Location
}

function Find-InVault($text, $subdir = '') {
    $path = Join-Path $testbed "vault"
    if ($subdir) { $path = Join-Path $path $subdir }
    if (-not (Test-Path $path)) { return $false }
    $hits = Get-ChildItem $path -Recurse -Filter *.md | Select-String -SimpleMatch $text
    return (@($hits).Count -gt 0)
}

function Test-Sentinels($case) {
    $missing = @($sentinels | Where-Object { -not (Find-InVault $_) })
    Check $case 'nessun contenuto utente perso' ($missing.Count -eq 0)
    if ($missing.Count -gt 0) { Write-Host "    mancanti: $($missing -join ' | ')" }
}

# ── Caso 1: /processa-inbox ─────────────────────────────────────────────
Write-Host "`n=== Caso: processa-inbox ==="
Reset-Testbed
Invoke-Skill "/processa-inbox"
$inboxFiles = @(Get-ChildItem "$testbed\vault\00-Inbox" -Filter *.md -ErrorAction SilentlyContinue)
Check 'processa-inbox' 'inbox svuotata (6 note processate)' ($inboxFiles.Count -eq 0)
if ($inboxFiles.Count -gt 0) { Write-Host "    rimasti in inbox: $(($inboxFiles | Select-Object -ExpandProperty Name) -join ' | ')" }
Check 'processa-inbox' 'ricetta finita in 03-Risorse' (Find-InVault 'guanciale croccante' '03-Risorse')
Check 'processa-inbox' 'blog diventato progetto in 01-Progetti' (Find-InVault 'primo articolo entro settembre' '01-Progetti')
Check 'processa-inbox' 'palestra finita in 02-Aree' (Find-InVault 'tre sedute a settimana' '02-Aree')
Check 'processa-inbox' 'istruzione eseguita: task nel progetto Sito portfolio' ((Get-Content "$testbed\vault\01-Progetti\Sito portfolio.md" -Raw -ErrorAction SilentlyContinue) -match 'dominio definitivo')
Check 'processa-inbox' 'nota-fusione integrata nella casa naturale (Appunti Docker)' ((Get-Content "$testbed\vault\03-Risorse\Appunti Docker.md" -Raw -ErrorAction SilentlyContinue) -match 'immagini appese')
# Messaggio tra agenti (origine: agente ...): integrato nella scheda mittente,
# SENZA callout di conservazione (non sono parole dell'utente). La parafrasi
# sui messaggi-agente e' PERMESSA dalla costituzione: il check accetta uno
# qualsiasi dei fatti chiave del messaggio, non pretende la stringa esatta
$portfolioRaw = Get-Content "$testbed\vault\01-Progetti\Sito portfolio.md" -Raw -ErrorAction SilentlyContinue
$msgPattern = 'biennale|migrazione DNS|12 mesi'
Check 'processa-inbox' 'messaggio-agente integrato nella scheda mittente' ($portfolioRaw -match $msgPattern)
$rigaMsg = (($portfolioRaw -split "`r?`n") | Where-Object { $_ -match $msgPattern } | Select-Object -First 1)
Check 'processa-inbox' 'messaggio-agente integrato come contenuto, non in callout' ($null -ne $rigaMsg -and $rigaMsg -notmatch '^\s*>')
$blogNote = Get-ChildItem "$testbed\vault\01-Progetti" -Filter *.md | Select-String -SimpleMatch 'primo articolo entro settembre' -List | Select-Object -First 1
$hasFm = $false
if ($blogNote) { $hasFm = (Get-Content $blogNote.Path -Raw) -match '(?s)^---.*?tipo:.*?---' }
Check 'processa-inbox' 'frontmatter aggiunto alla nota smistata' $hasFm
Check 'processa-inbox' 'file non-markdown lasciato in inbox (fonte, non nota)' (Test-Path "$testbed\vault\00-Inbox\Guida rapida SQLite.txt")
Test-Sentinels 'processa-inbox'

# ── Caso 2: /brief ──────────────────────────────────────────────────────
Write-Host "`n=== Caso: brief ==="
Reset-Testbed
Invoke-Skill "/brief"
Check 'brief' 'daily note di oggi creata' (Test-Path "$testbed\vault\05-Daily\$today.md")
Check 'brief' 'Dashboard: sezione Ultimo brief aggiornata' (-not (Find-InVault 'Nessun brief ancora generato'))
$hostingSurfaced = (Find-InVault 'hosting' '05-Daily') -or ((Get-Content "$testbed\vault\Dashboard.md" -Raw) -match 'hosting')
Check 'brief' 'task scaduto (hosting, 2026-06-25) menzionato' $hostingSurfaced
Test-Sentinels 'brief'

# ── Caso 3: /nuovo-progetto ─────────────────────────────────────────────
Write-Host "`n=== Caso: nuovo-progetto ==="
Reset-Testbed
Invoke-Skill "/nuovo-progetto Vacanze in Grecia"
$greciaFile = Get-ChildItem "$testbed\vault\01-Progetti" -Filter '*Grecia*.md' -ErrorAction SilentlyContinue | Select-Object -First 1
Check 'nuovo-progetto' 'nota progetto creata in 01-Progetti' ($null -ne $greciaFile)
$fmOk = $false
if ($greciaFile) { $fmOk = (Get-Content $greciaFile.FullName -Raw) -match 'tipo: progetto' }
Check 'nuovo-progetto' 'frontmatter con tipo: progetto' $fmOk
# La Dashboard ha viste live (Bases): il progetto appare se il frontmatter è giusto,
# quindi si verifica quello — e che la skill non abbia riscritto la vista a mano.
$liveOk = $false
if ($greciaFile) { $liveOk = (Get-Content $greciaFile.FullName -Raw) -match 'stato: attivo' }
Check 'nuovo-progetto' 'frontmatter con stato: attivo (visibile nella vista live)' $liveOk
Check 'nuovo-progetto' 'vista live Bases intatta in Dashboard' ((Get-Content "$testbed\vault\Dashboard.md" -Raw) -match '```base')
Test-Sentinels 'nuovo-progetto'

# ── Caso 4: /weekly-review ──────────────────────────────────────────────
Write-Host "`n=== Caso: weekly-review ==="
Reset-Testbed
Add-IgieneFixtures
Invoke-Skill "/weekly-review"
# Filtro sul nome esatto: nel testbed c'e' anche la vecchia review retrodatata,
# un filtro generico '*review*' potrebbe pescare quella
$reviewFile = Get-ChildItem "$testbed\vault\05-Daily" -Filter "$today-review.md" -ErrorAction SilentlyContinue | Select-Object -First 1
Check 'weekly-review' 'nota di review creata in 05-Daily' ($null -ne $reviewFile)
$reviewText = ''
if ($reviewFile) { $reviewText = Get-Content $reviewFile.FullName -Raw }
Check 'weekly-review' 'propone archiviazione di Trasloco (task tutti chiusi)' ($reviewText -match 'Trasloco')
Check 'weekly-review' 'segnala il task scaduto (hosting)' ($reviewText -match 'hosting')
# Igiene del tempo: i vecchi si ELIMINANO (mai archiviati: il check e' su tutto
# il vault), i recenti restano, e il radar muore solo dopo che ogni suo
# verdetto ha la riga nel Changelog evoluzione
Check 'weekly-review' 'igiene: daily oltre 4 settimane eliminata (non archiviata)' (-not (Find-InVault 'collaudo alfa'))
Check 'weekly-review' 'igiene: daily recente intatta' (Test-Path "$testbed\vault\05-Daily\$($script:freshDailyDate).md")
Check 'weekly-review' 'igiene: review oltre 3 mesi eliminata (non archiviata)' (-not (Find-InVault 'collaudo beta'))
$radarLeft = @(Get-ChildItem "$testbed\vault" -Recurse -Filter '*Tech radar*' -ErrorAction SilentlyContinue)
Check 'weekly-review' 'igiene: Tech radar oltre 3 mesi eliminato' ($radarLeft.Count -eq 0)
Check 'weekly-review' 'igiene: verdetto mancante migrato nel Changelog prima di eliminare' ((Get-Content "$testbed\vault\99-Sistema\Changelog evoluzione.md" -Raw -ErrorAction SilentlyContinue) -match 'Framework Beta')
Test-Sentinels 'weekly-review'

# ── Caso 5: /distilla (documento) ───────────────────────────────────────
Write-Host "`n=== Caso: distilla-documento ==="
Reset-Testbed
Invoke-Skill "/distilla vault/00-Inbox/Guida rapida SQLite.txt"
$docNotes = @(Get-ChildItem "$testbed\vault\03-Risorse\Documenti" -Filter *.md -ErrorAction SilentlyContinue)
Check 'distilla-doc' 'nota creata in 03-Risorse/Documenti' ($docNotes.Count -ge 1)
$fonteOk = $false
if ($docNotes.Count -ge 1) { $fonteOk = (Get-Content $docNotes[0].FullName -Raw) -match 'fonte:.*SQLite' }
Check 'distilla-doc' 'frontmatter fonte: col nome del file' $fonteOk
Check 'distilla-doc' 'contenuto distillato in 03-Risorse' (Find-InVault 'SQLite' '03-Risorse')
Check 'distilla-doc' 'copia usa-e-getta eliminata dall''inbox' (-not (Test-Path "$testbed\vault\00-Inbox\Guida rapida SQLite.txt"))
Test-Sentinels 'distilla-doc'

# Nota: /impara è stata ritirata il 2026-07-26 (zero usi in 23 giorni, ora in
# .claude/skills-archivio/) e non ha mai avuto un caso qui: per progetto
# richiedeva una conversazione e una conferma interattiva (step 3), non
# esercitabile in headless. /evolvi non
# ha un caso perché dipende dal web e va valutata dal report, non da check fissi;
# in produzione il suo contratto "Fatto quando" è però verificato da un post-check
# deterministico in dashboard/evolvi.sh (radar del giorno, riga nel Changelog,
# commit) — verifier esterno all'agente, in codice (2026-07-08).
# /distilla ha il caso documento (offline); la via video dipende da YouTube
# (rete, rate-limit) e si collauda a mano con un video corto noto.

# ── Strato deterministico (indice, motore) ───────────────────
# Tabella e punteggio SEPARATI dai casi skill: questi non girano sul testbed
# sintetico ma sul container reale, e mescolarli gonfierebbe il totale delle
# skill senza che nessuna skill sia migliorata (aggiunto il 2026-09-04, dopo
# che due regressioni di fila sono cadute in questo strato senza test).
$det = @()
if (Test-Path "$root\tests\test-deterministico.ps1") {
    $det = @(& "$root\tests\test-deterministico.ps1")
}

# ── Punteggio e report ──────────────────────────────────────────────────
$passed = @($script:results | Where-Object { $_.Esito -eq 'PASS' }).Count
$total = @($script:results).Count

# Confronto con il risultato precedente
$prev = Get-ChildItem $resultsDir -Filter '*.md' -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -Last 1
$confronto = 'prima esecuzione (baseline)'
if ($prev) {
    $m = [regex]::Match((Get-Content $prev.FullName -Raw), 'TOTALE: (\d+)/(\d+)')
    if ($m.Success) {
        $prevScore = [int]$m.Groups[1].Value
        $delta = $passed - $prevScore
        $segno = if ($delta -gt 0) { "+$delta" } else { "$delta" }
        $confronto = "precedente $($prev.BaseName): $prevScore/$($m.Groups[2].Value) (delta: $segno)"
    }
}

$report = @()
$report += "# Eval run $stamp"
$report += ""
$report += "Commit: ``$commit`` - Modello: ``$evalModel`` - Confronto: $confronto"
$report += ""
$report += "| Caso | Verifica | Esito |"
$report += "|---|---|---|"
foreach ($r in $script:results) { $report += "| $($r.Caso) | $($r.Verifica) | $($r.Esito) |" }
$report += ""
$report += "TOTALE: $passed/$total"
if ($det.Count -gt 0) {
    $detPass = @($det | Where-Object { $_.Esito -eq 'PASS' }).Count
    $report += ""
    $report += "## Strato deterministico (fuori dal punteggio skill)"
    $report += ""
    $report += "| Verifica | Esito |"
    $report += "|---|---|"
    foreach ($d in $det) { $report += "| $($d.Verifica) | $($d.Esito) |" }
    $report += ""
    $report += "DETERMINISTICO: $detPass/$($det.Count)"
}
$reportPath = Join-Path $resultsDir "$stamp-$commit.md"
$report -join "`r`n" | Out-File $reportPath -Encoding utf8

Write-Host "`n=========================================="
Write-Host "TOTALE: $passed/$total  ($confronto)"
if ($det.Count -gt 0) {
    $detPass = @($det | Where-Object { $_.Esito -eq 'PASS' }).Count
    Write-Host "DETERMINISTICO: $detPass/$($det.Count)  (indice, motore - fuori dal punteggio skill)"
}
Write-Host "Report: $reportPath"
