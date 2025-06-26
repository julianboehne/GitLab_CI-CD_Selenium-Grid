param (
    [string]$SeleniumDir = "C:\Selenium",
    [string]$JarName = "selenium-server-latest.jar",
    [string]$DownloadApi = "https://api.github.com/repos/SeleniumHQ/selenium/releases/latest"
)

# Sicherstellen, dass das Selenium-Verzeichnis existiert
if (!(Test-Path -Path $SeleniumDir)) {
    New-Item -ItemType Directory -Path $SeleniumDir | Out-Null
}

$JarPath = Join-Path $SeleniumDir $JarName
$VersionFile = Join-Path $SeleniumDir "selenium-version.txt"

# Neueste Selenium-Version ermitteln
try {
    $release = Invoke-RestMethod -Uri $DownloadApi
    $latestVersion = $release.tag_name.TrimStart("selenium-")
    $downloadUrl = "https://github.com/SeleniumHQ/selenium/releases/download/selenium-$latestVersion/selenium-server-$latestVersion.jar"
    Write-Host "Neueste Selenium-Version: $latestVersion"
} catch {
    Write-Error "Fehler beim Abrufen der neuesten Selenium-Version: $_"
    exit 1
}

# Aktuelle Version ermitteln
$currentVersion = ""
if (Test-Path -Path $VersionFile) {
    $currentVersion = Get-Content -Path $VersionFile -ErrorAction SilentlyContinue
}

# Versionen vergleichen
$updateRequired = $true
if ($currentVersion) {
    try {
        if ([version]$latestVersion -le [version]$currentVersion) {
            Write-Host "Der Selenium-Server ist bereits auf dem neuesten Stand (Version $currentVersion)."
            $updateRequired = $false
        } else {
            Write-Host "Eine neuere Version ist verfügbar: $latestVersion (aktuell: $currentVersion)."
        }
    } catch {
        Write-Warning "Fehler beim Vergleichen der Versionen: $_"
    }
}

if ($updateRequired) {
    # Laufenden Selenium-Server beenden, falls vorhanden
    $procs = Get-WmiObject Win32_Process | Where-Object { $_.Name -eq 'java.exe' -and $_.CommandLine -like '*selenium-server-latest.jar*' }
    foreach ($proc in $procs) {
        Write-Host "Beende laufenden Selenium-Server (PID $($proc.ProcessId))..."
        Stop-Process -Id $proc.ProcessId -Force
        Start-Sleep -Seconds 5
    }

    # Vorhandene JAR-Datei löschen
    if (Test-Path -Path $JarPath) {
        Remove-Item -Path $JarPath -Force
    }

    # Neueste JAR herunterladen
    try {
        Write-Host "Lade Selenium-Server herunter..."
        Invoke-WebRequest -Uri $downloadUrl -OutFile $JarPath
        Write-Host "Download abgeschlossen."
        Set-Content -Path $VersionFile -Value $latestVersion
    } catch {
        Write-Error "Fehler beim Herunterladen der Selenium-Server-JAR: $_"
        exit 1
    }
}

# Selenium-Server starten (je nach Modus)
try {
    Write-Host "Starte Selenium-Server im Hintergrund..."

    if ($env:SELENIUM_HUB -eq "true") {
        Write-Host "Starte im Hub-Modus..."
        Start-Process -FilePath "java" -ArgumentList "-jar `"$JarPath`" hub" -WindowStyle Hidden
    }
    elseif ($env:SELENIUM_HUB_URL) {
        Write-Host "Starte als Node und registriere bei Hub: $($env:SELENIUM_HUB_URL)"
        Start-Process -FilePath "java" -ArgumentList "-jar `"$JarPath`" node --hub $env:SELENIUM_HUB_URL --selenium-manager true" -WindowStyle Hidden
    }
    else {
        Write-Host "Starte im Standalone-Modus."
        Start-Process -FilePath "java" -ArgumentList "-jar `"$JarPath`" standalone" -WindowStyle Hidden
    }

    Write-Host "Selenium-Server wurde gestartet."
} catch {
    Write-Error "Fehler beim Starten des Selenium-Servers: $_"
    exit 1
}
