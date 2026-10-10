#!/usr/bin/env bash
# Exporta el juego a Web (build/web/index.html). RF-10.
# Requiere las plantillas de exportación de la MISMA versión de Godot instaladas
# (Editor > Gestionar plantillas de exportación > Descargar e instalar).
# Uso:  scripts/tools/export_web.sh
set -euo pipefail
cd "$(dirname "$0")/../.."

GODOT="${GODOT:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "No se encontró Godot ('$GODOT'). Define la variable GODOT con la ruta al ejecutable." >&2
  exit 1
fi

mkdir -p build/web
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . --export-release "Web" build/web/index.html

echo
echo "Exportación lista en build/web/. Pruébala con:  python scripts/tools/serve_web.py"
