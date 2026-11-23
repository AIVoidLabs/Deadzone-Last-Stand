# Botla tam turu birkaç kez oynar, dalga başına raporları ve sonda SUMMARY özetini yazar (denge ölçümü).
# Kullanım: powershell -File tools/autoplay_runs.ps1 [-Runs 5] [-Weapons 4] [-Strategy default|guns|melee|tank] [-Parallel 1]
# Çıktı dosyaları strateji + ms zaman + sıra + PID ile adlanır; aynı anda birden çok ps1 çalışabilir.
param([int]$Runs = 5, [int]$Weapons = 4, [string]$Strategy = "default", [int]$Parallel = 1)
if ($Parallel -lt 1) { $Parallel = 1 }
$dir = "build/autoplay"
New-Item -ItemType Directory -Force $dir | Out-Null
$stamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$files = @()
$pending = @()
for ($i = 1; $i -le $Runs; $i++) {
    $tag = "$($Strategy)_$($stamp)_$($PID)_$i"
    $out = Join-Path $dir "run_$tag.txt"
    $gameArgs = "--headless --path . --fixed-fps 60 -- --autoplay --autoplay-weapons=$Weapons --autoplay-strategy=$Strategy --autoplay-out=run_$tag"
    $files += $out
    $p = Start-Process godot -ArgumentList $gameArgs -RedirectStandardOutput $out -RedirectStandardError "$out.err" -NoNewWindow -PassThru
    $pending += $p
    while (@($pending | Where-Object { -not $_.HasExited }).Count -ge $Parallel) { Start-Sleep -Milliseconds 200 }
}
$pending | ForEach-Object { $_.WaitForExit() }

$deaths = @{}; $wins = 0; $losses = 0; $stuck = 0; $crashed = 0; $deathWaves = @(); $times = @(); $minHp = @{}
for ($i = 0; $i -lt $files.Count; $i++) {
    Write-Output "--- Calistirma $($i + 1) ($($files[$i])) ---"
    $lines = @()
    if (Test-Path $files[$i]) { $lines = @(Get-Content $files[$i] | Where-Object { $_ -match "^AUTOPLAY " } | ForEach-Object { $_ -replace "^AUTOPLAY ", "" }) }
    $lines
    $hasResult = $false
    foreach ($l in $lines) {
        if ($l -match "^WAVE (\d+) .* min_hp_pct (\d+)") {
            $w = [int]$Matches[1]
            if (-not $minHp.ContainsKey($w)) { $minHp[$w] = @() }
            $minHp[$w] += [int]$Matches[2]
        }
        if ($l -match "^RESULT (WIN|LOSS|STUCK)\s+wave (\d+)/\d+.* time (\d+)s") {
            $hasResult = $true
            $times += [int]$Matches[3]
            if ($Matches[1] -eq "WIN") { $wins++ }
            elseif ($Matches[1] -eq "STUCK") { $stuck++ }
            else { $losses++; $deathWaves += [int]$Matches[2]; $deaths[[int]$Matches[2]] = 1 + [int]$deaths[[int]$Matches[2]] }
        }
    }
    if (-not $hasResult) {
        $crashed++
        Write-Output "CRASHED (RESULT satiri yok): $($files[$i])"
        $err = "$($files[$i]).err"
        if ((Test-Path $err) -and (Get-Item $err).Length -gt 0) { Get-Content $err -Tail 5 | ForEach-Object { Write-Output "  ERR $_" } }
    }
}
$found = $wins + $losses + $stuck
$decided = $wins + $losses
Write-Output "--- OZET ---"
Write-Output "SUMMARY strategy $Strategy  expected_runs $Runs  results $found"
Write-Output "SUMMARY win $wins  loss $losses  stuck $stuck  crashed $crashed"
if ($decided -gt 0) {
    Write-Output ("SUMMARY win_rate {0:N0}%  ({1}/{2})" -f (100.0 * $wins / $decided), $wins, $decided)
    if ($deathWaves.Count -gt 0) {
        $sorted = $deathWaves | Sort-Object
        $mid = [math]::Floor($sorted.Count / 2)
        $median = if ($sorted.Count % 2) { $sorted[$mid] } else { ($sorted[$mid - 1] + $sorted[$mid]) / 2 }
        Write-Output ("SUMMARY death_wave avg {0:N1}  median {1}" -f ($deathWaves | Measure-Object -Average).Average, $median)
        Write-Output ("SUMMARY death_dist " + (($deaths.Keys | Sort-Object | ForEach-Object { "w$($_):$($deaths[$_])" }) -join " "))
    } else { Write-Output "SUMMARY death_wave none" }
}
if ($minHp.Count -gt 0) {
    Write-Output ("SUMMARY min_hp_pct_by_wave " + (($minHp.Keys | Sort-Object | ForEach-Object { "w$($_):{0:N0}" -f ($minHp[$_] | Measure-Object -Average).Average }) -join " "))
}
if ($times.Count -gt 0) { Write-Output ("SUMMARY avg_time {0:N0}s" -f ($times | Measure-Object -Average).Average) }
