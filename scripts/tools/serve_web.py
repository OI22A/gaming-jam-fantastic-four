#!/usr/bin/env python3
"""Sirve la exportación web local (build/web) para probarla en el navegador.

Uso:
    python scripts/tools/serve_web.py            # http://localhost:8060
    python scripts/tools/serve_web.py --port 9000
    python scripts/tools/serve_web.py --dir otra/carpeta

Por qué hace falta: los navegadores no ejecutan el juego abriendo index.html
con doble clic (file://); debe servirse por HTTP. Este servidor además envía el
tipo MIME correcto para .wasm y las cabeceras COOP/COEP, que permiten también
probar exportaciones con hilos.
"""

import argparse
import functools
import http.server
import pathlib
import sys

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
        ".js": "text/javascript",
        ".pck": "application/octet-stream",
    }

    def end_headers(self) -> None:
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--port", type=int, default=8060)
    parser.add_argument("--dir", default=str(REPO_ROOT / "build" / "web"))
    args = parser.parse_args()

    directory = pathlib.Path(args.dir)
    if not (directory / "index.html").exists():
        print(f"No se encontró {directory / 'index.html'}.")
        print("Primero exporta el juego: scripts/tools/export_web.sh (o export_web.ps1).")
        return 1

    handler = functools.partial(Handler, directory=str(directory))
    with http.server.ThreadingHTTPServer(("127.0.0.1", args.port), handler) as server:
        print(f"Sirviendo {directory}\nAbre http://localhost:{args.port}  (Ctrl+C para detener)")
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            print("\nServidor detenido.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
