<#
  Local-only version: copies race_top10_*.json from the server's data folder into
  .\data next to this script, and rebuilds data\index.json. No Git, no upload.
  Upload index.html and the whole data folder to your site yourself.

  Keep it running (updates as records change):
    powershell -ExecutionPolicy Bypass -File .\sync-records-local.ps1 -FortressDir "C:\path\to\fortress\data"
  Run once and exit:
    add  -Once
#>
param(
  [string]$FortressDir = "C:\Quake\FortressOne\server-race\fortress\data",
  [string]$OutDir = (Join-Path $PSScriptRoot "data"),
  [int]$PollSeconds = 15,
  [switch]$Once
)

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$utf8 = New-Object System.Text.UTF8Encoding($false)
$script:warned = @{}

function Read-Records($path) {
  try { return (Get-Content -Raw -Encoding UTF8 $path | ConvertFrom-Json) } catch { return $null }
}

function Sync-Files {
  $changed = $false
  foreach ($f in Get-ChildItem $FortressDir -Filter "race_top10_*.json" -ErrorAction SilentlyContinue) {
    $dest = Join-Path $OutDir $f.Name
    if ((Test-Path $dest) -and ((Get-FileHash $f.FullName).Hash -eq (Get-FileHash $dest).Hash)) { continue }
    if ($null -eq (Read-Records $f.FullName)) {
      $key = "$($f.Name)|$($f.LastWriteTimeUtc.Ticks)"
      if (-not $script:warned[$key]) {
        Write-Warning "Skipped $($f.Name): not valid JSON (a racer name may contain a quote or backslash)."
        $script:warned[$key] = $true
      }
      continue
    }
    Copy-Item $f.FullName $dest -Force
    Write-Host "Updated $($f.Name)"
    $changed = $true
  }
  return $changed
}

function Build-Index {
  $maps = @()
  foreach ($f in Get-ChildItem $OutDir -Filter "race_top10_*.json") {
    $d = Read-Records $f.FullName
    if ($null -eq $d) { continue }
    $recs = @($d.records | Where-Object { $_ })
    $best = $recs | Select-Object -First 1
    $maps += [ordered]@{
      map     = $d.map
      file    = $f.Name
      records = $recs.Count
      best    = $(if ($best) { $best.time } else { $null })
      holder  = $(if ($best) { $best.racer } else { $null })
      updated = $f.LastWriteTimeUtc.ToString("o")
    }
  }
  $index = [ordered]@{ updated = (Get-Date).ToUniversalTime().ToString("o"); maps = $maps }
  $json = ConvertTo-Json -InputObject $index -Depth 5
  [System.IO.File]::WriteAllText((Join-Path $OutDir "index.json"), $json, $utf8)
  Write-Host "Rebuilt index.json ($($maps.Count) maps) at $(Get-Date -Format T)"
}

if (-not (Test-Path $FortressDir)) { Write-Warning "Folder not found: $FortressDir"; exit 1 }

$first = Sync-Files
if ($first -or -not (Test-Path (Join-Path $OutDir "index.json"))) { Build-Index }
if ($Once) { exit 0 }

Write-Host "Watching $FortressDir every $PollSeconds s. Press Ctrl+C to stop."
while ($true) {
  Start-Sleep -Seconds $PollSeconds
  if (Sync-Files) { Build-Index }
}
