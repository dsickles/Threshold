# Error-checks, exports the web build and uploads it to the private itch.io page.
. (Join-Path $PSScriptRoot "paths.ps1")

& (Join-Path $PSScriptRoot "check.ps1")
if ($LASTEXITCODE -ne 0) { exit 1 }

$out = Join-Path $ProjectDir "build\web"
New-Item -ItemType Directory -Force $out | Out-Null
& $Godot --headless --path $ProjectDir --export-release "Web" (Join-Path $out "index.html")
if ($LASTEXITCODE -ne 0 -or -not (Test-Path (Join-Path $out "index.html"))) { Write-Host "Export failed."; exit 1 }

& $Butler push $out $ItchTarget
exit $LASTEXITCODE
