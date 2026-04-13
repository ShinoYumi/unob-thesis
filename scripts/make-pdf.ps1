param(
  [ValidateSet("check", "compile", "watch", "output")]
  [string]$Action = "compile",
  [string]$Typst = "typst",
  [string]$Root = ".",
  [string]$Src = "template/thesis.typ",
  [string]$Cfg = "template/thesis.toml",
  [string]$OutDir = "build",
  [string]$FontPath = "resources/fonts",
  [string]$Type = "auto",
  [string]$Open = "0"
)

$ErrorActionPreference = "Stop"

function Fail([string]$Message, [int]$Code = 2) {
  Write-Error $Message
  exit $Code
}

function Check-Inputs {
  try {
    Get-Command $Typst -ErrorAction Stop | Out-Null
  } catch {
    Fail "typst není dostupný v PATH" 127
  }

  if (-not (Test-Path -LiteralPath $Src -PathType Leaf)) {
    Fail "Chybí vstupní soubor $Src"
  }
  if (-not (Test-Path -LiteralPath $Cfg -PathType Leaf)) {
    Fail "Chybí konfigurační soubor $Cfg"
  }
  New-Item -ItemType Directory -Force -Path $FontPath | Out-Null
}

function Get-TitleFromToml([string[]]$Lines) {
  $inThesis = $false
  foreach ($line in $Lines) {
    if ($line -match '^\s*\[thesis\]\s*$') {
      $inThesis = $true
      continue
    }
    if ($line -match '^\s*\[[^]]+\]\s*$') {
      if ($inThesis) { break }
      $inThesis = $false
      continue
    }
    if ($inThesis -and $line -match '^\s*title\s*=\s*"(.*)"\s*(#.*)?$') {
      return $Matches[1]
    }
  }
  return ""
}

function Get-RootDraftFromToml([string[]]$Lines) {
  foreach ($line in $Lines) {
    if ($line -match '^\s*\[[^]]+\]\s*$') {
      break
    }
    if ($line -match '^\s*draft\s*=\s*([A-Za-z]+)\s*(#.*)?$') {
      return $Matches[1].ToLowerInvariant()
    }
  }
  return ""
}

function Resolve-Meta {
  $lines = Get-Content -LiteralPath $Cfg
  $title = Get-TitleFromToml $lines
  if ([string]::IsNullOrWhiteSpace($title)) {
    Fail "V $Cfg chybí [thesis].title"
  }

  $cfgDraft = Get-RootDraftFromToml $lines
  if ([string]::IsNullOrWhiteSpace($cfgDraft)) {
    Fail "V $Cfg chybí root hodnota draft = true|false"
  }

  $mode = $Type.ToLowerInvariant()
  switch ($mode) {
    { $_ -eq "" -or $_ -eq "auto" } {
      if ($cfgDraft -eq "true") {
        $state = "Draft"
        $draftValue = "true"
      } elseif ($cfgDraft -eq "false") {
        $state = "Final"
        $draftValue = "false"
      } else {
        Fail "Neplatná hodnota draft v $Cfg, použij true nebo false"
      }
      $overrideMode = $false
    }
    "draft" {
      $state = "Draft"
      $draftValue = "true"
      $overrideMode = $true
    }
    "final" {
      $state = "Final"
      $draftValue = "false"
      $overrideMode = $true
    }
    default {
      Fail "Neplatný TYPE='$Type'. Použij: auto | draft | final"
    }
  }

  $today = Get-Date -Format "yyyy-MM-dd"
  $safeTitle = ($title -replace '[\\/:*?"<>|]', '-') -replace '\s+', ' '
  $safeTitle = $safeTitle.Trim()
  $out = Join-Path $OutDir "$today - $safeTitle - $state.pdf"
  $latest = Join-Path $OutDir ("latest-" + $state.ToLowerInvariant() + ".pdf")

  [PSCustomObject]@{
    State = $state
    DraftValue = $draftValue
    OverrideMode = $overrideMode
    Out = $out
    Latest = $latest
  }
}

function Write-OverrideCfg([string]$TargetCfg, [string]$DraftValue) {
  $lines = Get-Content -LiteralPath $Cfg
  $result = New-Object System.Collections.Generic.List[string]
  $inRoot = $true
  $done = $false

  foreach ($line in $lines) {
    if ($inRoot -and $line -match '^\s*\[[^]]+\]\s*$') {
      if (-not $done) {
        $result.Add("draft = $DraftValue")
        $done = $true
      }
      $inRoot = $false
    }

    if ($inRoot -and $line -match '^\s*draft\s*=') {
      if (-not $done) {
        $result.Add("draft = $DraftValue")
        $done = $true
      }
      continue
    }

    $result.Add($line)
  }

  if (-not $done) {
    $result.Add("draft = $DraftValue")
  }

  Set-Content -LiteralPath $TargetCfg -Value $result -Encoding UTF8
}

function Write-OverrideTyp([string]$TargetTyp, [string]$CfgRelPath) {
  $lines = Get-Content -LiteralPath $Src
  $result = New-Object System.Collections.Generic.List[string]
  $done = $false

  foreach ($line in $lines) {
    if (-not $done -and $line -match '^#show:\s*thesis\s*$') {
      $result.Add("#show: thesis.with(file: `"$CfgRelPath`")")
      $done = $true
      continue
    }
    $result.Add($line)
  }

  if (-not $done) {
    Fail "V $Src chybí řádek #show: thesis"
  }

  Set-Content -LiteralPath $TargetTyp -Value $result -Encoding UTF8
}

function Update-LatestAlias([string]$OutPath, [string]$LatestPath) {
  if (Test-Path -LiteralPath $OutPath -PathType Leaf) {
    Copy-Item -LiteralPath $OutPath -Destination $LatestPath -Force
  }
}

function Open-OutputIfRequested([string]$OutPath) {
  if ($Open -eq "1") {
    Start-Process -FilePath $OutPath | Out-Null
  }
}

function Run-Typst([string[]]$Args) {
  & $Typst @Args
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

function Invoke-Compile {
  Check-Inputs
  New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
  $meta = Resolve-Meta
  Write-Output ("-> " + $meta.Out)

  if (-not $meta.OverrideMode) {
    Run-Typst @("compile", "--root", $Root, "--font-path", $FontPath, $Src, $meta.Out)
  } else {
    $tmpCfgName = ".tmp-thesis-$PID-$($meta.State).toml"
    $tmpTypName = ".tmp-thesis-$PID-$($meta.State).typ"
    $tmpCfg = Join-Path $OutDir $tmpCfgName
    $tmpTyp = Join-Path $OutDir $tmpTypName
    $tmpCfgRel = "../$OutDir/$tmpCfgName"

    try {
      Write-OverrideCfg -TargetCfg $tmpCfg -DraftValue $meta.DraftValue
      Write-OverrideTyp -TargetTyp $tmpTyp -CfgRelPath $tmpCfgRel
      Run-Typst @("compile", "--root", $Root, "--font-path", $FontPath, $tmpTyp, $meta.Out)
    } finally {
      Remove-Item -LiteralPath $tmpCfg, $tmpTyp -Force -ErrorAction SilentlyContinue
    }
  }

  Update-LatestAlias -OutPath $meta.Out -LatestPath $meta.Latest
  Open-OutputIfRequested -OutPath $meta.Out
}

function Invoke-Watch {
  Check-Inputs
  New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
  $meta = Resolve-Meta
  Write-Output ("-> " + $meta.Out)
  Update-LatestAlias -OutPath $meta.Out -LatestPath $meta.Latest

  if (-not $meta.OverrideMode) {
    Run-Typst @("watch", "--root", $Root, "--font-path", $FontPath, $Src, $meta.Out)
  } else {
    $tmpCfgName = ".tmp-thesis-watch-$PID-$($meta.State).toml"
    $tmpTypName = ".tmp-thesis-watch-$PID-$($meta.State).typ"
    $tmpCfg = Join-Path $OutDir $tmpCfgName
    $tmpTyp = Join-Path $OutDir $tmpTypName
    $tmpCfgRel = "../$OutDir/$tmpCfgName"

    try {
      Write-OverrideCfg -TargetCfg $tmpCfg -DraftValue $meta.DraftValue
      Write-OverrideTyp -TargetTyp $tmpTyp -CfgRelPath $tmpCfgRel
      Run-Typst @("watch", "--root", $Root, "--font-path", $FontPath, $tmpTyp, $meta.Out)
    } finally {
      Remove-Item -LiteralPath $tmpCfg, $tmpTyp -Force -ErrorAction SilentlyContinue
    }
  }
}

function Show-OutputPath {
  Check-Inputs
  New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
  $meta = Resolve-Meta
  Write-Output $meta.Out
}

function Invoke-Check {
  Check-Inputs
  Write-Output "OK: check passed (TYPST=$Typst, SRC=$Src, CFG=$Cfg, FONT_PATH=$FontPath)"
}

switch ($Action) {
  "check" { Invoke-Check }
  "compile" { Invoke-Compile }
  "watch" { Invoke-Watch }
  "output" { Show-OutputPath }
  default { Fail "Neznámá action '$Action'" }
}
