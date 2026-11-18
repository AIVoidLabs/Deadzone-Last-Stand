# Botla tam turu birkaç kez oynar ve dalga başına raporları yazar (denge ölçümü, 6.6).
# Kullanım: powershell -File tools/autoplay_runs.ps1 [-Runs 5] [-Weapons 4]
param([int]$Runs = 5, [int]$Weapons = 4)
for ($i = 1; $i -le $Runs; $i++) {
    Write-Output "--- Çalıştırma $i ---"
    godot --headless --path . --fixed-fps 60 -- --autoplay --autoplay-weapons=$Weapons 2>&1 | Select-String "AUTOPLAY" | ForEach-Object { $_.Line -replace "^AUTOPLAY ", "" }
}
