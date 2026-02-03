# scripts/02-extract.ps1
# Generates *.summary.md next to each cleaned HTML file
# Safe for PowerShell string parsing (no "$var:" issues)

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$cleanedDir = Join-Path $repoRoot "cleaned"

if (!(Test-Path $cleanedDir)) {
  Write-Host "ERROR: cleaned/ folder not found." -ForegroundColor Red
  exit 1
}

$files = Get-ChildItem -Path $cleanedDir -Recurse -Filter *.html -File
if (!$files -or $files.Count -eq 0) {
  Write-Host "No HTML files found in cleaned/." -ForegroundColor Yellow
  exit 0
}

foreach ($f in $files) {
  try {
    $txt = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Stop

    # colors
    $hex  = [regex]::Matches($txt, "#[0-9a-fA-F]{3,8}") | ForEach-Object { $_.Value.ToLower() }
    $rgb  = [regex]::Matches($txt, "rgba?\(\s*\d+\s*,\s*\d+\s*,\s*\d+(\s*,\s*[\d\.]+\s*)?\)") | ForEach-Object { $_.Value.ToLower() }

    # fonts (font-family: ...)
    $fonts = [regex]::Matches($txt, "font-family\s*:\s*[^;]+;") | ForEach-Object { $_.Value.Trim() }

    # asset URLs (only likely assets)
    $assets = [regex]::Matches($txt, "https?://[^\s'""\)\>]+") | ForEach-Object { $_.Value }
    $assets = $assets | Where-Object { $_ -match "\.(png|jpg|jpeg|webp|gif|svg|mp4|mov|woff2?|ttf|otf)($|\?)" }

    # Headings preview (h1/h2/h3)
    $headPreview = @()
    foreach ($m in [regex]::Matches($txt, "(?is)<(h1|h2|h3)[^>]*>(.*?)</\1>")) {
      $tag = $m.Groups[1].Value.ToLower()
      $content = ($m.Groups[2].Value -replace "<[^>]+>", " " -replace "\s+", " ").Trim()
      if ($content.Length -gt 140) { $content = $content.Substring(0, 140) + "…" }
      # IMPORTANT: no "$tag:" interpolation bug
      $headPreview += ("{0}: {1}" -f $tag, $content)
      if ($headPreview.Count -ge 12) { break }
    }

    # unique + sort
    $hexU    = $hex    | Sort-Object -Unique
    $rgbU    = $rgb    | Sort-Object -Unique
    $fontsU  = $fonts  | Sort-Object -Unique
    $assetsU = $assets | Sort-Object -Unique

    $outPath = Join-Path $f.DirectoryName ("{0}.summary.md" -f [System.IO.Path]::GetFileNameWithoutExtension($f.Name))

    $md = @()
    $md += ("# Summary - {0}" -f $f.Name)
    $md += ""
    $md += ("Path: {0}" -f (($f.FullName) -replace "\\","/"))
    $md += ""

    $md += "## Headings preview"
    if ($headPreview.Count) { $md += ($headPreview | ForEach-Object { "- " + $_ }) } else { $md += "- (none detected)" }
    $md += ""

    $md += "## Colors (hex)"
    if ($hexU.Count) { $md += ($hexU | ForEach-Object { "- " + $_ }) } else { $md += "- (none detected)" }
    $md += ""

    $md += "## Colors (rgb/rgba)"
    if ($rgbU.Count) { $md += ($rgbU | ForEach-Object { "- " + $_ }) } else { $md += "- (none detected)" }
    $md += ""

    $md += "## Fonts"
    if ($fontsU.Count) { $md += ($fontsU | ForEach-Object { "- " + $_ }) } else { $md += "- (none detected)" }
    $md += ""

    $md += "## Asset URLs (images/videos/fonts)"
    if ($assetsU.Count) { $md += ($assetsU | ForEach-Object { "- " + $_ }) } else { $md += "- (none detected)" }
    $md += ""

    $md -join "`n" | Out-File -LiteralPath $outPath -Encoding utf8
    Write-Host ("OK summary: {0}" -f ($outPath -replace "\\","/")) -ForegroundColor Green
  }
  catch {
    Write-Host ("ERROR summary for {0}: {1}" -f $f.FullName, $_.Exception.Message) -ForegroundColor Red
  }
}

Write-Host "Done extracted." -ForegroundColor Green
