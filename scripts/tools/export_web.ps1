# Exporta el juego a Web (build\web\index.html). RF-10. Windows / PowerShell.
# Requiere las plantillas de exportación de la MISMA versión de Godot instaladas
# (Editor > Gestionar plantillas de exportación > Descargar e instalar).
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..\..")

$godot = if ($env:GODOT) { $env:GODOT } else { "godot" }
if (-not (Get-Command $godot -ErrorAction SilentlyContinue)) {
    Write-Error "No se encontró Godot ('$godot'). Defínelo con `$env:GODOT = 'ruta\al\ejecutable'."
    exit 1
}

New-Item -ItemType Directory -Force -Path "build\web" | Out-Null
& $godot --headless --path . --import *> $null
& $godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit
if ($LASTEXITCODE -ne 0) {
    Write-Error "Las pruebas funcionales fallaron; se cancela la exportación Web."
    exit $LASTEXITCODE
}
& $godot --headless --path . --export-release "Web" "build/web/index.html"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Exportación lista en build\web\. Pruébala con:  python scripts\tools\serve_web.py"
