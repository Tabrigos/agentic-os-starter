# Bootstrap dell'agentic OS su un nuovo PC.
# Prerequisiti: git, Claude Code, gh (autenticato), Podman (opzionale, per Obsidian).
# Uso:  .\setup-pc.ps1                      → clona in C:\Users\<utente>\lavoro\agentic-os
#       .\setup-pc.ps1 -Primario           → registra anche le attività pianificate
#                                             (SOLO su un PC per volta: il primario)
param(
    # Se lo script gira da dentro un clone (c'e' compose.yaml accanto), quel
    # clone E' la destinazione. Senza questo, chi ha gia' clonato altrove si
    # ritrova un secondo clone in lavoro\agentic-os senza accorgersene - il
    # caso normale di chi installa per la prima volta seguendo il README.
    [string]$Dest = $(
        $qui = Split-Path -Parent $PSScriptRoot
        if ($qui -and (Test-Path (Join-Path $qui 'compose.yaml'))) { $qui }
        else { "$env:USERPROFILE\lavoro\agentic-os" }
    ),
    [string]$Repo = "Tabrigos/agentic-os-starter",
    [switch]$Primario
)

if (-not (Test-Path $Dest)) {
    Write-Host "[setup] clono $Repo in $Dest"
    gh repo clone $Repo $Dest
    if ($LASTEXITCODE -ne 0) { Write-Host "[setup] clone fallito (gh autenticato?)"; exit 1 }
} else {
    Write-Host "[setup] $Dest esiste gia', salto il clone"
}

# marca la cartella come trusted per le run headless di Claude Code
# (serve davvero solo sul PC primario; sui client basta accettare il trust
# dialog al primo avvio interattivo di claude nella cartella)
$destSlash = $Dest -replace '\\', '/'
if (Get-Command node -ErrorAction SilentlyContinue) {
    node -e "const fs=require('fs');const p=process.env.USERPROFILE.replace(/\\\\/g,'/')+'/.claude.json';let j={};try{j=JSON.parse(fs.readFileSync(p,'utf8'))}catch(e){};j.projects=j.projects||{};const k='$destSlash';j.projects[k]=Object.assign({},j.projects[k],{hasTrustDialogAccepted:true});fs.writeFileSync(p,JSON.stringify(j,null,2));console.log('[setup] workspace trusted')"
} else {
    Write-Host "[setup] node assente: apri 'claude' in $Dest e accetta il trust dialog al primo avvio"
}

# container Obsidian (se Podman è presente)
if (Get-Command podman -ErrorAction SilentlyContinue) {
    Set-Location $Dest
    podman compose up -d
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[setup] compose fallito: la podman machine e' inizializzata? Prova: podman machine init; podman machine start"
    } else {
        Write-Host "[setup] Obsidian su http://localhost:3000 (vault: /vault)"
    }
} else {
    Write-Host "[setup] Podman assente: salto il container (installalo per la UI Obsidian)"
}

# sync automatico ogni ora (su tutti i PC)
$sync = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$Dest\automation\sync.ps1`""
$trigSync = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1)
Register-ScheduledTask -TaskName "AgenticOS-Sync" -Action $sync -Trigger $trigSync -Settings (New-ScheduledTaskSettingsSet -StartWhenAvailable) -Force | Out-Null
Write-Host "[setup] attivita' AgenticOS-Sync registrata (ogni ora)"

# automazioni: SOLO sul PC primario
if ($Primario) {
    $evolvi = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$Dest\automation\run-evolvi.ps1`""
    $trigEvolvi = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 09:00
    Register-ScheduledTask -TaskName "AgenticOS-Evolvi" -Action $evolvi -Trigger $trigEvolvi -Settings (New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 2)) -Force | Out-Null
    # In pausa dal 2026-07-06 (decisione dell'utente: /evolvi solo manuale per ora).
    # La task resta registrata ma disabilitata; per riattivarla:
    #   Enable-ScheduledTask -TaskName "AgenticOS-Evolvi"
    Disable-ScheduledTask -TaskName "AgenticOS-Evolvi" | Out-Null
    Write-Host "[setup] attivita' AgenticOS-Evolvi registrata ma IN PAUSA (solo esecuzione manuale)"
} else {
    Write-Host "[setup] PC client: /evolvi NON registrata (gira solo sul primario)"
}

Write-Host "[setup] fatto. Apri claude in $Dest e lancia /brief"
