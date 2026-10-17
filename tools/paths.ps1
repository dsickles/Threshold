# Where Godot and butler live. Default: the DASSoft\Tools folder next to this repo.
# Override with the GODOT and BUTLER environment variables.
$ToolsDir = Join-Path $PSScriptRoot "..\..\Tools"
$Godot = if ($env:GODOT) { $env:GODOT } else { Join-Path $ToolsDir "Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" }
$Butler = if ($env:BUTLER) { $env:BUTLER } else { Join-Path $ToolsDir "butler-windows-amd64\butler.exe" }
$ProjectDir = Resolve-Path (Join-Path $PSScriptRoot "..\game")
$ItchTarget = "dsickles/threshold:html5"
