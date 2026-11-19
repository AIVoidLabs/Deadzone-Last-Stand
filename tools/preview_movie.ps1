# Animasyon/sahne önizleme filmi: kare dizisi + kontak sayfası (AI için) + mp4 (ffmpeg varsa) veya avi (insan için).
# Kullanım: powershell -File tools/preview_movie.ps1 -Name tongue -Seconds 8 -GameArgs "--capture-spawn=40 --capture-kind=tongue --god --capture-near=7"
# -Scene verilmezse ana sahne; ana sahnede oyun argümanları yalnız --capture ile çalışır (otomatik eklenir, süre -Seconds).
param(
    [Parameter(Mandatory = $true)][string]$Name,
    [double]$Seconds = 6,
    [int]$Fps = 30,
    [string]$Scene = "",
    [string]$GameArgs = "",
    [int]$Cols = 4,
    [int]$Rows = 3,
    [double]$Skip = 0
)
$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent $PSScriptRoot)
$dir = "build/movies/$Name"
if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }
New-Item -ItemType Directory -Force $dir | Out-Null
$frames = [int][math]::Ceiling($Seconds * $Fps)
$shot = "build/movies/_$Name.last.png"
# Capture süresi film süresinden biraz uzun: kare sınırı --quit-after ile gelir.
$capSec = $Seconds + 2
$cap = "--capture=$shot --capture-seconds=$capSec"
$extra = @()
if ($GameArgs -ne "") { $extra = $GameArgs -split "\s+" | Where-Object { $_ -ne "" } }
$sceneArg = @()
if ($Scene -ne "") { $sceneArg = @($Scene) }

function Invoke-Movie([string]$target) {
    $a = @("--path", ".", "--write-movie", $target, "--fixed-fps", $Fps, "--quit-after", $frames) + $sceneArg + @("--") + ($cap -split " ") + $extra
    & godot @a | Out-Null
}

Invoke-Movie "$dir/f.png"
$n = (Get-ChildItem $dir -Filter *.png).Count
if ($n -eq 0) { throw "Kare uretilmedi (Movie Maker basarisiz)." }

$sheet = "build/movies/${Name}_sheet.png"
& godot --headless --path . -s res://tools/godot/contact_sheet.gd -- --dir=$dir --out=$sheet --cols=$Cols --rows=$Rows --fps=$Fps --skip=$Skip

$video = ""
if (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
    $video = "build/movies/$Name.mp4"
    & ffmpeg -y -loglevel error -framerate $Fps -start_number 0 -i "$dir/f%08d.png" -c:v libx264 -pix_fmt yuv420p -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2" $video
} else {
    $video = "build/movies/$Name.avi"
    Invoke-Movie $video
}
Write-Host "FRAMES $n"
Write-Host "SHEET  $sheet"
Write-Host "VIDEO  $video"
