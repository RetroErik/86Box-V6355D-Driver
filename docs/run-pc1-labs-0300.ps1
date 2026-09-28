# Register once with: powershell -NoProfile -ExecutionPolicy Bypass -File .\run-pc1-labs-0300.ps1 -Register
# Check prerequisites with: powershell -NoProfile -ExecutionPolicy Bypass -File .\run-pc1-labs-0300.ps1 -CheckOnly
param(
    [switch]$Register,
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'
$taskName = 'PC1-Labs-86Box-0300'
$promptPath = Join-Path $PSScriptRoot 'next-session-prompt-pc1-labs.md'
$workspace = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$projectRoot = Join-Path $workspace 'PC1-Labs'
$demosPath = Join-Path $projectRoot 'demos\04-Bitmap-stuff'
$codex = (Get-Command codex.exe -ErrorAction Stop).Source

if (-not (Test-Path -LiteralPath $promptPath -PathType Leaf)) {
    throw "Promptfilen finnes ikke: $promptPath"
}
if (-not (Test-Path -LiteralPath $demosPath -PathType Container)) {
    throw "Demomappen finnes ikke: $demosPath"
}
if (-not (Get-Command nasm.exe -ErrorAction SilentlyContinue)) {
    throw 'NASM finnes ikke i PATH.'
}

if ($CheckOnly) {
    Write-Host "Codex: $codex"
    Write-Host "Prompt: $promptPath"
    Write-Host "Arbeidsmappe: $projectRoot"
    & $codex login status
    if ($LASTEXITCODE -ne 0) { throw 'Codex er ikke innlogget.' }
    exit 0
}

if ($Register) {
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        throw "Oppgaven finnes allerede: $taskName"
    }

    $start = (Get-Date).Date.AddHours(3)
    if ($start -le (Get-Date)) { $start = $start.AddDays(1) }
    $scriptPath = $MyInvocation.MyCommand.Path
    $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $scriptPath
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $arguments -WorkingDirectory $projectRoot
    $trigger = New-ScheduledTaskTrigger -Once -At $start
    $principal = New-ScheduledTaskPrincipal -UserId ([Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Limited
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -WakeToRun -ExecutionTimeLimit (New-TimeSpan -Hours 12) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description 'Kjør PC1-Labs-prompten én gang klokken 03:00 med Codex CLI.' | Out-Null
    Write-Host ("Registrert {0} for {1:yyyy-MM-dd HH:mm:ss} ({2})." -f $taskName, $start, [TimeZoneInfo]::Local.Id)
    exit 0
}

$logDir = Join-Path $PSScriptRoot 'pc1-labs-runs'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$stdoutPath = Join-Path $logDir "$stamp-stdout.log"
$stderrPath = Join-Path $logDir "$stamp-progress.log"
$finalPath = Join-Path $logDir "$stamp-final.md"
$statusPath = Join-Path $logDir "$stamp-status.txt"

$instruction = @"
Les hele promptfilen på denne absolutte stien og utfør oppgaven den beskriver: $promptPath

Dette er en planlagt engangskjøring fra Codex CLI. Følg alle kontrollpunkter i filen. Kontroller først at forutsetningen om publisering av 86Box-forken og PR #8135 faktisk er oppfylt. Hvis den ikke er oppfylt, rapporter det og stopp før demoer endres.

Når 86Box viser testbildet, la emulatoren og bildet stå urørt. Stopp arbeidet der og skriv i sluttrapporten at brukeren må beskrive bildet i den vanlige chatten før videre feilsøking eller dokumentasjonsendringer. Denne separate CLI-kjøringen kan ikke stille et spørsmål i den eksisterende chatten. Ikke lukk emulatoren eller påstå at den visuelle testen er bekreftet uten brukerens svar.
"@

Set-Location -LiteralPath $projectRoot
try {
    & $codex exec -C $projectRoot --sandbox danger-full-access -c 'approval_policy="never"' --output-last-message $finalPath $instruction 1> $stdoutPath 2> $stderrPath
    $exitCode = $LASTEXITCODE
    "Avsluttet: $(Get-Date -Format o)`r`nExitCode: $exitCode`r`nSluttrapport: $finalPath`r`nFremdrift: $stderrPath" |
        Set-Content -LiteralPath $statusPath -Encoding UTF8
    exit $exitCode
}
catch {
    "Feilet: $(Get-Date -Format o)`r`n$($_.Exception.Message)" |
        Set-Content -LiteralPath $statusPath -Encoding UTF8
    throw
}
