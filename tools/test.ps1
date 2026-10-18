# Runs the headless tests in game/tests/ (Windows). check.ps1 runs this after
# the error check, so publish.ps1 never uploads a build with a failing test.
#   powershell -ExecutionPolicy Bypass -File tools/test.ps1          # every test
#   powershell -ExecutionPolicy Bypass -File tools/test.ps1 rhythm   # only matching tests
. (Join-Path $PSScriptRoot "paths.ps1")

$importOutput = & $Godot --headless --path $ProjectDir --import 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) { Write-Host "Import failed:"; Write-Host $importOutput; exit 1 }

$failed = 0
Write-Host "Running tests in game/tests/..."
& $Godot --headless --path $ProjectDir --script "res://tests/run_tests.gd" -- @args
if ($LASTEXITCODE -ne 0) { $failed = 1 }

# Older stand-alone checks (game/tests/*_check.gd) run one by one.
if ($args.Count -eq 0) {
    Get-ChildItem -Path (Join-Path $ProjectDir "tests") -Filter *_check.gd | Where-Object { $_.Name -notlike "test_*" } | Sort-Object Name | ForEach-Object {
        $res = "res://tests/" + $_.Name
        $output = & $Godot --headless --path $ProjectDir --script $res 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) { Write-Host "FAIL $res"; Write-Host $output; $failed = 1 }
        else { Write-Host "ok   $res" }
    }
}

if ($failed -ne 0) { Write-Host "Tests failed."; exit 1 }
Write-Host "All tests passed."
