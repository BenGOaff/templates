$ErrorActionPreference = "Stop"

# ATTENTION: touche seulement cleaned/, jamais raw/
$files = Get-ChildItem -Path "cleaned" -Recurse -File -Filter *.html

foreach ($f in $files) {
  $txt = Get-Content $f.FullName -Raw

  # Supprime les énormes data: favicons/images inline (garde le reste)
  # 1) <link rel="icon" href="data:image/...base64,...">
  $txt2 = [regex]::Replace($txt, "(?is)<link[^>]+rel=['""]icon['""][^>]+href=['""]data:image/[^'""]+['""][^>]*>", "<!-- removed inline favicon (data:) -->")

  # 2) <img src="data:image/...base64,..."> très lourd
  $txt2 = [regex]::Replace($txt2, "(?is)<img([^>]+)src=['""]data:image/[^'""]+['""]([^>]*)>", "<img$1src=`"__INLINE_IMAGE_REMOVED__`"$2>")

  if ($txt2 -ne $txt) {
    [System.IO.File]::WriteAllText($f.FullName, $txt2, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Lite cleaned: $($f.FullName)"
  }
}

Write-Host "Done lite clean." -ForegroundColor Green
