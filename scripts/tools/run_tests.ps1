# Ejecuta las pruebas unitarias (GUT) en modo headless (Windows / PowerShell).
# Uso:  .\scripts\tools\run_tests.ps1
# Si Godot no está en el PATH:  $env:GODOT = "C:\ruta\Godot_v4.3-stable_win64_console.exe"
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..\..")

$godot = if ($env:GODOT) { $env:GODOT } else { "godot" }
if (-not (Get-Command $godot -ErrorAction SilentlyContinue)) {
    Write-Error "No se encontró Godot ('$godot'). Defínelo con `$env:GODOT = 'ruta\al\ejecutable'."
    exit 1
}

# Imprescindible la primera vez: genera la caché de clases (class_name) y recursos.
& $godot --headless --path . --import *> $null

& $godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit
exit $LASTEXITCODE
