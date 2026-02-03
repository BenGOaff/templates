$ErrorActionPreference = "Stop"

function Slugify([string]$s) {
  $t = $s.ToLowerInvariant()
  $t = $t -replace "é|è|ê|ë","e"
  $t = $t -replace "à|â|ä","a"
  $t = $t -replace "î|ï","i"
  $t = $t -replace "ô|ö","o"
  $t = $t -replace "ù|û|ü","u"
  $t = $t -replace "ç","c"
  $t = $t -replace "[ _]+","-"
  $t = $t -replace "[^a-z0-9\-]+",""
  $t = $t -replace "\-+","-"
  $t = $t.Trim("-")
  return $t
}

# Nettoyage des dossiers de travail
if (Test-Path "cleaned") { Remove-Item "cleaned" -Recurse -Force }
mkdir "cleaned" -Force | Out-Null

# Copie structurée
robocopy raw cleaned /E | Out-Null

# Renommage kebab-case dans cleaned
Get-ChildItem -Path "cleaned" -Recurse -File -Filter *.html | ForEach-Object {
  $dir = $_.DirectoryName
  $base = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
  $slug = Slugify $base
  $newName = "$slug.html"
  $newPath = Join-Path $dir $newName

  if ($_.FullName -ne $newPath) {
    if (Test-Path $newPath) {
      Write-Host "SKIP conflict: $($_.Name) -> $newName" -ForegroundColor Yellow
    } else {
      Rename-Item -Path $_.FullName -NewName $newName
      Write-Host "OK: $($_.Name) -> $newName"
    }
  }
}

Write-Host "Done copy+rename." -ForegroundColor Green
