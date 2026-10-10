#!/usr/bin/env bash
# Ejecuta las pruebas unitarias (GUT) en modo headless.
# Uso:  scripts/tools/run_tests.sh
# Si Godot no está en el PATH:  GODOT=/ruta/a/Godot scripts/tools/run_tests.sh
set -euo pipefail
cd "$(dirname "$0")/../.."

GODOT="${GODOT:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "No se encontró Godot ('$GODOT'). Instálalo o define la variable GODOT con la ruta al ejecutable." >&2
  exit 1
fi

# Imprescindible la primera vez: genera la caché de clases (class_name) y recursos.
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true

"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gexit
