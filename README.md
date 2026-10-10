# Papa Caliente 2D

Videojuego 2D inspirado en la "papa caliente": un jugador humano compite contra bots por no quedarse con la bomba
cuando se acaba el temporizador. En el parque (ambientación de ciudad) aparecen **Lucky Blocks** que dan efectos
aleatorios —de distinta rareza— a quien lleva la bomba.

- **Evento:** AI GAME JAM · **Equipo:** FantasticFour
- **Participantes:** Albert Valencia Escobar, Anderson Olave Ibargüen, Santiago Gomez Otalvaro, Harol Arias Rendon
- **Motor:** Godot Engine **4.3** (GDScript) · **Destino:** navegador web (HTML5/WebAssembly)
- **Repositorio:** https://github.com/OI22A/gaming-jam-fantastic-four

> Este repositorio incluye una **base jugable** (esqueleto completo de los módulos). El arte y los sonidos son
> provisionales (se generan por código) y están listos para reemplazarse. Detalle de módulos y requisitos en
> [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md). Trazabilidad del uso de IA en [`AI_TRACE.md`](AI_TRACE.md).

---

## 1. Qué necesitas instalar

| # | Herramienta | Versión | ¿Obligatoria? | Para qué |
|---|---|---|---|---|
| 1 | **Godot Engine** (versión *Standard*, **no** la `.NET`/C#) | **4.3.x** (todo el equipo la misma) | Sí | Editar, ejecutar y exportar el juego |
| 2 | **Git** | cualquiera reciente | Sí | Clonar el repo y versionar |
| 3 | **Plantillas de exportación de Godot** | **la misma versión del editor (4.3.x)** | Solo para exportar a web | Generar la versión de navegador |
| 4 | **Python** | 3.9 o superior | Opcional | Servidor local para probar la versión web y herramientas de estilo |
| 5 | **gdtoolkit** (`pip install -r requirements-dev.txt`) | 4.x | Opcional | `gdformat` / `gdlint` (formato y lint de GDScript) |
| 6 | Un navegador moderno (Chrome, Edge o Firefox) | actual | Para probar la web | RF-10 |

**Ya viene incluido en el repo (no hay que instalarlo):** el framework de pruebas **GUT 9.3.0** en `addons/gut/`.
El proyecto no usa ninguna otra librería ni asset externo.

> ⚠️ **Usen todos la misma versión de Godot (4.3.x).** Abrir el proyecto con una versión distinta puede reescribir
> `project.godot` y las escenas, y genera conflictos innecesarios en Git.

### 1.1 Instalar Godot 4.3

Descarga la versión **Standard** desde <https://godotengine.org/download/archive/4.3-stable/>.
Godot es portable: no tiene instalador, solo descomprimes y ejecutas.

- **Windows:** descomprime el `.zip` (por ejemplo en `C:\Godot\`). Verás dos ejecutables:
  `Godot_v4.3-stable_win64.exe` (editor con interfaz) y `Godot_v4.3-stable_win64_console.exe` (útil para la terminal).
- **macOS:** descomprime y arrastra `Godot.app` a *Aplicaciones*. La primera vez, clic derecho → *Abrir*
  (Gatekeeper puede bloquearlo si lo abres con doble clic).
- **Linux:** descomprime, dale permisos y ejecútalo:
  ```bash
  chmod +x Godot_v4.3-stable_linux.x86_64
  ./Godot_v4.3-stable_linux.x86_64
  ```

> Evita instalar Godot con gestores de paquetes (`brew`, `winget`, `snap`, `flatpak`) salvo que puedas fijar la
> versión 4.3.x: normalmente instalan la última, que puede ser distinta a la del equipo.

**(Opcional) Usar Godot desde la terminal.** Los scripts de `scripts/tools/` buscan `godot` en el `PATH` o leen la
variable de entorno `GODOT`:

```bash
# Linux
export GODOT=~/Godot/Godot_v4.3-stable_linux.x86_64
# macOS
export GODOT=/Applications/Godot.app/Contents/MacOS/Godot
```
```powershell
# Windows (PowerShell) – usa la versión *_console.exe*
$env:GODOT = "C:\Godot\Godot_v4.3-stable_win64_console.exe"
```

### 1.2 Instalar Git y (opcionalmente) Python

- Git: <https://git-scm.com/downloads> → comprueba con `git --version`.
- Python 3.9+: <https://www.python.org/downloads/> (en Windows marca *Add python.exe to PATH*) →
  comprueba con `python --version` (en Windows también sirve `py --version`).

### 1.3 Instalar las plantillas de exportación (solo para exportar a web)

1. Abre el editor de Godot (con cualquier proyecto abierto).
2. Menú **Editor → Administrar plantillas de exportación** (*Manage Export Templates*).
3. Pulsa **Descargar e instalar** y espera a que termine (≈ 1 GB; versión **4.3.stable**).

Sin conexión: descarga `Godot_v4.3-stable_export_templates.tpz` de la misma página del archivo y usa
**Instalar desde archivo**.

---

## 2. Obtener el proyecto y configurarlo en local

### 2.1 Traer la base al repositorio (una sola vez, la hace una persona del equipo)

Si recibiste la base como `papa-caliente-2d-base.zip`, descomprímela **en la raíz del repositorio clonado**:

```bash
git clone https://github.com/OI22A/gaming-jam-fantastic-four.git
cd gaming-jam-fantastic-four
unzip ../papa-caliente-2d-base.zip          # Windows: clic derecho → "Extraer todo…" dentro de esta carpeta
git status                                  # revisa lo que se agregó
```

El zip no incluye carpeta contenedora: `project.godot`, `README.md`, `AI_TRACE.md`, etc. quedan directamente en la
raíz del repo. Si el repo ya tenía un `README.md` o `.gitignore`, compara y fusiona a mano antes de sobrescribir.
Después, **agrega la entrada AI-001 de `AI_TRACE.md`** (completando fecha/hora y participante reales) y haz el commit:

```bash
git add .
git commit -m "feat: base del proyecto Papa Caliente 2D (Godot 4.3) con módulos, pruebas y trazabilidad"
git push
```

### 2.2 Para el resto del equipo (y para cada máquina nueva)

```bash
git clone https://github.com/OI22A/gaming-jam-fantastic-four.git
cd gaming-jam-fantastic-four
```

### 2.3 Abrir el proyecto en Godot

1. Abre Godot → en el *Project Manager* pulsa **Importar** (*Import*).
2. Selecciona el archivo `project.godot` de la carpeta del repo → **Importar y editar**.
3. **Espera a que termine la primera importación** (barra de progreso abajo a la derecha, unos segundos). Se crea la
   carpeta oculta `.godot/` (está en `.gitignore`; no se sube a Git).
4. Pulsa **F5** (▶ *Ejecutar proyecto*). Debe abrirse el menú del juego.

> Si Godot pregunta por **convertir** o **actualizar** el proyecto, es señal de que tu versión no es 4.3.x:
> cierra, instala la versión correcta y vuelve a abrir.

### 2.4 Verifica que todo funciona (recomendado)

```bash
# Linux / macOS
scripts/tools/run_tests.sh
```
```powershell
# Windows (PowerShell)
.\scripts\tools\run_tests.ps1
# Si PowerShell bloquea el script:  powershell -ExecutionPolicy Bypass -File .\scripts\tools\run_tests.ps1
```

Resultado esperado al final: `Tests 39 · Passing 39`. También puedes correr las pruebas desde el editor, en el panel
inferior **GUT** → *Run All*.

> **La primera vez** que se usa Godot por terminal se necesita importar el proyecto para que reconozca las clases
> (`class_name`). Los scripts ya lo hacen solos (`godot --headless --path . --import`). Un aviso sobre
> `gut_editor_config.json` durante ese paso es normal e inofensivo.

---

## 3. Cómo se juega

| Acción | Teclas |
|---|---|
| Mover | `W A S D` o flechas |
| Pausar / reanudar | `Esc` (o `P`) |
| Reiniciar la partida | `R` |

1. Elige el mapa y el número de bots en el menú.
2. Tras la cuenta regresiva, un personaje al azar recibe la bomba. **Tócalo a otro para pasársela**
   (hay un breve enfriamiento tras cada transferencia).
3. Quien tiene la bomba puede recoger **Lucky Blocks** (cuadros amarillos con `?`): dan efectos de distinta rareza
   (velocidad, penalizaciones, tiempo extra o menos, radar que marca a los rivales en el minimapa).
4. Cuando el temporizador llega a 0 la bomba explota y el portador **queda eliminado**. Si eres tú, pierdes; si eres
   el último en pie, ganas.

---

## 4. Exportar y probar la versión web (RF-10)

El proyecto ya trae un preset **Web** en `export_presets.cfg` (sin hilos, para que funcione en cualquier hosting sin
cabeceras especiales). Requiere haber instalado las plantillas de exportación (sección 1.3).

**Opción A – por terminal (recomendada):**
```bash
scripts/tools/export_web.sh          # Windows: .\scripts\tools\export_web.ps1
python scripts/tools/serve_web.py    # Windows: py scripts\tools\serve_web.py
```
Abre **http://localhost:8060** en el navegador.

**Opción B – desde el editor:** *Proyecto → Exportar…* → preset **Web** → *Exportar proyecto* → guarda en
`build/web/index.html`. Luego sirve la carpeta con `serve_web.py`. También puedes usar el botón ▶ del navegador
(arriba a la derecha del editor, *Ejecutar en el navegador*).

Notas importantes:
- **No abras `index.html` con doble clic** (`file://`): los navegadores bloquean el WebAssembly. Siempre por HTTP.
- El audio de los navegadores se activa tras el primer clic; el menú ya exige un clic para jugar.
- Para publicar (itch.io, GitHub Pages…) sube el **contenido** de `build/web/` (con `index.html` en la raíz).
- La carpeta `build/` no se versiona; se regenera cuando haga falta.

---

## 5. Estructura del proyecto

```
.
├── project.godot            Configuración (autoloads, input map, render GL Compatibility)
├── export_presets.cfg       Preset de exportación Web
├── README.md · AI_TRACE.md  Guía y registro de trazabilidad del uso de IA
├── docs/ARCHITECTURE.md     Módulos ↔ requisitos, señales, recetas
├── scenes/                  main.tscn y escenas de mapas
├── scripts/
│   ├── autoload/            GameEvents (bus), GameManager (estados), AudioManager
│   ├── match/               MatchController: rondas, eliminación, cámara, HUD
│   ├── characters/          Character (base) y PlayerCharacter
│   ├── ai/                  BotCharacter (IA)
│   ├── bomb/                BombManager (temporizador y transferencia)
│   ├── lucky_blocks/        LuckyBlock, spawner y RewardTable (rarezas y probabilidades)
│   ├── effects/             EffectManager (aplicar/retirar efectos)
│   ├── maps/                GameMap, ParkMap, CityMap, Minimap
│   ├── ui/                  Hud y MainMenu
│   ├── fx/                  Efecto de explosión
│   └── tools/               run_tests, export_web, serve_web, lint
├── tests/unit/              Pruebas GUT
├── assets/                  audio/sfx, art, fonts (vacíos: aquí va el material real)
└── addons/gut/              Framework de pruebas (incluido, sin modificar)
```

| Módulo del proyecto | Código principal | RF |
|---|---|---|
| Gestión de partidas | `autoload/game_manager.gd`, `match/match_controller.gd` | RF-01 |
| Mapas y minimapa | `maps/*` | RF-02, RF-08 |
| Control de jugadores | `characters/*` | RF-03 |
| Inteligencia artificial | `ai/bot_character.gd` | RF-04 |
| Gestión de la bomba | `bomb/bomb_manager.gd` | RF-05 |
| Lucky Blocks | `lucky_blocks/*` | RF-06 |
| Gestión de efectos | `effects/effect_manager.gd` | RF-07 |
| Interfaz y audio | `ui/*`, `autoload/audio_manager.gd` | RF-09 |
| Compatibilidad web | `export_presets.cfg`, `scripts/tools/*` | RF-10 |

**Sonidos:** si existe `assets/audio/sfx/<nombre>.ogg|wav` se usa; si no, se genera un tono provisional. Nombres:
`countdown, go, bomb_tick, bomb_transfer, bomb_explode, lucky_block, effect_on, effect_off, win, lose`.

---

## 6. Flujo de trabajo del equipo y trazabilidad

**Git**
- Una rama por tarea: `feature/<modulo>-<descripcion>` (ej. `feature/ia-evitar-esquinas`). Integren con *pull request*.
- Commits pequeños y frecuentes. Mensajes cortos tipo `feat:`, `fix:`, `test:`, `docs:`; si el cambio lo generó o
  ayudó la IA, añadan `[AI]` al final.
- **No reescriban el historial publicado** (nada de `push --force`, `rebase` de commits ya subidos ni cambios de fechas).
- Eviten que dos personas editen la misma escena `.tscn` a la vez (conflictos). El proyecto está pensado para
  que casi todo viva en scripts.
- Antes de subir: `scripts/tools/run_tests.sh` en verde y (opcional) `scripts/tools/lint.sh`.

**Uso de IA (permitido y parte de la competencia)**
- Cada cambio relevante hecho con IA se registra con una **entrada nueva al final de `AI_TRACE.md`**.
  El asistente del evento entrega al final de cada respuesta un bloque `[AUDIT_SUMMARY]` con el mensaje de commit
  sugerido y el texto de la entrada listo para pegar.
- `AI_TRACE.md` es **incremental**: no se editan ni se borran entradas anteriores; si hay un error se corrige con una
  entrada nueva que la referencie.
- Fecha y hora siempre las reales del momento del registro. El asistente **no** tiene acceso al repositorio: los
  commits y el guardado de archivos los hace el equipo.

**Herramientas de estilo (opcional)**
```bash
pip install -r requirements-dev.txt
scripts/tools/lint.sh           # comprueba formato y lint
scripts/tools/lint.sh --fix     # reformatea
```
Se usan tabulaciones en `.gd` (convención de Godot); `.editorconfig` lo configura en VS Code y otros editores.
Para VS Code se recomienda la extensión *godot-tools*.

---

## 7. Solución de problemas

| Síntoma | Causa probable / solución |
|---|---|
| `Identifier not found: GameEvents` o `Could not find type "Character"` | Faltó la importación inicial. Abre el proyecto en el editor una vez, o ejecuta `godot --headless --path . --import`. |
| El editor ofrece "convertir/actualizar el proyecto" | Estás usando una versión de Godot distinta a 4.3.x. Instala la correcta. |
| *No export template found* al exportar | Instala las plantillas de **la misma versión** del editor (sección 1.3). |
| La página web queda en blanco o dice que falta WebAssembly / SharedArrayBuffer | Abriste `index.html` por `file://`, o el preset no es el de **Web sin hilos**. Usa `serve_web.py` y no cambies *Thread Support*. |
| No hay sonido en la web | Los navegadores esperan una interacción del usuario; haz clic en la página. |
| PowerShell: *la ejecución de scripts está deshabilitada* | `powershell -ExecutionPolicy Bypass -File .\scripts\tools\run_tests.ps1` |
| `run_tests` dice que no encuentra Godot | Define la variable `GODOT` con la ruta al ejecutable (sección 1.1). En Windows usa el `_console.exe`. |
| macOS: *"Godot no se puede abrir"* | Clic derecho sobre `Godot.app` → *Abrir* → confirmar. |
| Linux: el ejecutable no abre | `chmod +x` al archivo; en servidores sin pantalla usa `--headless`. |
| Errores de recursos de GUT en el primer import por terminal | Normal en la primera pasada; vuelve a ejecutar el comando. |

---

## 8. Estado de la base y próximos pasos

Verificado al generar la base (Godot 4.3-stable, headless): importación sin errores, 39 pruebas en verde, lint
limpio, simulación del juego completo en ambos mapas y exportación Web generada. **Aún no se ha probado en un
navegador real ni con arte/sonido definitivos.** Pendientes sugeridos (ver tabla en `docs/ARCHITECTURE.md`):

1. Probar la exportación web en Chrome/Firefox/Edge y publicar una versión de prueba.
2. Reemplazar el dibujo por código por sprites/TileMaps y añadir sonidos reales.
3. Balancear velocidades, duración de la bomba, probabilidades de Lucky Blocks y dificultad de los bots.
4. Mejorar la IA de los bots (navegación avanzada) y pulir el flujo de partida/resultados.

## Licencias de terceros

- Godot Engine — MIT (<https://godotengine.org/license>)
- GUT (Godot Unit Test) 9.3.0 — MIT, incluido en `addons/gut/` (<https://github.com/bitwes/Gut>)
