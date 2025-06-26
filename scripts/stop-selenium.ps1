# stop-selenium.ps1

$seleniumProcesses = Get-WmiObject Win32_Process | Where-Object { $_.Name -eq 'java.exe' -and $_.CommandLine -like '*selenium-server-latest.jar*' }

# Stoppe alle gefundenen Prozesse
foreach ($process in $seleniumProcesses) {
    Stop-Process -Id $process.ProcessId -Force
    Write-Host "Prozess mit ID $($process.ProcessId) gestoppt."
}

Write-Host "Alle Selenium Server Prozesse wurden gestoppt."
