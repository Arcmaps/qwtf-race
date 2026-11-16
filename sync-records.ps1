<#
  Watches the server's fortress folder for race_top10_*.json files, copies new or
  changed ones into data\, rebuilds data\index.json, then commits and pushes.
  Run from the repo folder:
    powershell -ExecutionPolicy Bypass -File .\sync-records.ps1
#>
param(
  [string]$FortressDir = "C:\Quake\FortressOne\server-race\fortress",
  [string]$RepoDir = $PSScriptRoot,
  [int]$PollSeconds = 3600,
  [int]$MinPushSeconds = 3600
)

$dataDir = Join-Path $RepoDir "data"
New-Item -ItemType Directory -Force -Path $dataDir | Out-Null
$utf8 = New-Object System.Text.UTF8Encoding($false)
$script:warned = @{}
$pending = $false
$lastPush = [datetime]::MinValue

function Read-Records($path) {
  try { return (Get-Content -Raw -Encoding UTF8 $path | ConvertFrom-Json) } catch { return $null }
}

function Sync-Files {
  $changed = $false
  foreach ($f in Get-ChildItem $FortressDir -Filter "race_top10_*.json" -ErrorAction SilentlyContinue) {
    $dest = Join-Path $dataDir $f.Name
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
  foreach ($f in Get-ChildItem $dataDir -Filter "race_top10_*.json") {
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
  [System.IO.File]::WriteAllText((Join-Path $dataDir "index.json"), $json, $utf8)
}

function Push-Changes {
  Push-Location $RepoDir
  try {
    git add data | Out-Null
    git diff --cached --quiet
    if ($LASTEXITCODE -eq 0) { return $true }
    git commit -m "Update race records $(Get-Date -Format s)" | Out-Null
    git pull --rebase --autostash --quiet
    git push --quiet
    return ($LASTEXITCODE -eq 0)
  } finally { Pop-Location }
}

Write-Host "Watching $FortressDir (checks every $PollSeconds s, pushes at most every $MinPushSeconds s)"
while ($true) {
  if (Sync-Files) { Build-Index; $pending = $true }
  if ($pending -and ((Get-Date) - $lastPush).TotalSeconds -ge $MinPushSeconds) {
    if (Push-Changes) { Write-Host "Pushed to GitHub at $(Get-Date -Format T)"; $pending = $false }
    else { Write-Warning "Push failed. Will retry in $MinPushSeconds s." }
    $lastPush = Get-Date
  }
  Start-Sleep -Seconds $PollSeconds
}
