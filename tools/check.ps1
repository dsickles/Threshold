# Checks every GDScript file for errors without opening the editor.
# Exits non-zero if any script fails.
. (Join-Path $PSScriptRoot "paths.ps1")

# Import first so new scripts get their .uid files and class names are known.
$importOutput = & $Godot --headless --path $ProjectDir --import 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) { Write-Host "Import failed:"; Write-Host $importOutput; exit 1 }

$failed = 0
$scripts = @(Get-ChildItem -Path $ProjectDir -Recurse -Filter *.gd |
    Where-Object { $_.FullName -notlike "*\.godot\*" })
if ($scripts.Count -eq 0) { Write-Host "No scripts found in $ProjectDir."; exit 1 }
$scripts | ForEach-Object {
        $res = "res://" + $_.FullName.Substring($ProjectDir.Path.Length + 1).Replace('\', '/')
        $output = & $Godot --headless --path $ProjectDir --check-only --script $res 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -or $output -match 'SCRIPT ERROR|Parse Error') {
            Write-Host "FAIL $res"
            Write-Host $output
            $failed++
        } else {
            Write-Host "ok   $res"
        }
    }

if ($failed -gt 0) { Write-Host "$failed script(s) failed."; exit 1 }
Write-Host "All scripts passed."
