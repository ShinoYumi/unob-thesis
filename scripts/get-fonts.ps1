param(
  [string]$OutDir = "resources/fonts",
  [string]$UrlTermes = "https://www.gust.org.pl/projects/e-foundry/tex-gyre/termes/qtm2.004otf.zip",
  [string]$UrlMath = "https://www.gust.org.pl/projects/e-foundry/tg-math/download/texgyretermes-math-1543.zip",
  [string]$UrlCursor = "https://www.gust.org.pl/projects/e-foundry/tex-gyre/cursor/tg_cursor-otf-2_609-31_03_2026.zip"
)

$ErrorActionPreference = "Stop"

function Fail([string]$Message, [int]$Code = 2) {
  Write-Error $Message
  exit $Code
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$tmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("unob-fonts-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $tmpRoot | Out-Null

try {
  $termesZip = Join-Path $tmpRoot "termes.zip"
  $mathZip = Join-Path $tmpRoot "termes-math.zip"
  $cursorZip = Join-Path $tmpRoot "cursor.zip"
  $termesDir = Join-Path $tmpRoot "termes"
  $mathDir = Join-Path $tmpRoot "math"
  $cursorDir = Join-Path $tmpRoot "cursor"

  Write-Output "-> Download TeX Gyre Termes"
  Invoke-WebRequest -Uri $UrlTermes -OutFile $termesZip -UseBasicParsing

  Write-Output "-> Download TeX Gyre Termes Math"
  Invoke-WebRequest -Uri $UrlMath -OutFile $mathZip -UseBasicParsing

  Write-Output "-> Download TeX Gyre Cursor"
  Invoke-WebRequest -Uri $UrlCursor -OutFile $cursorZip -UseBasicParsing

  Expand-Archive -Path $termesZip -DestinationPath $termesDir -Force
  Expand-Archive -Path $mathZip -DestinationPath $mathDir -Force
  Expand-Archive -Path $cursorZip -DestinationPath $cursorDir -Force

  $copied = 0
  Get-ChildItem -Path $termesDir, $mathDir, $cursorDir -Recurse -File -Filter *.otf | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $OutDir -Force
    Write-Output ("   + " + $_.Name)
    $copied++
  }

  if ($copied -le 0) {
    Fail "Nepodařilo se nainstalovat žádný .otf font do $OutDir"
  }

  $installed = (Get-ChildItem -LiteralPath $OutDir -File -Filter *.otf | Measure-Object).Count
  Write-Output "OK: Fonts prepared in $OutDir ($installed .otf files found)."
} finally {
  Remove-Item -LiteralPath $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue
}
