# AI_TRACE.md – Registro de trazabilidad del uso de IA

- **Evento:** AI GAME JAM
- **Equipo (TEAM_ID):** FantasticFour
- **Participantes:** Albert Valencia Escobar, Anderson Olave Ibargüen, Santiago Gomez Otalvaro, Harol Arias Rendon
- **Repositorio:** https://github.com/OI22A/gaming-jam-fantastic-four
- **Motor:** Godot 4.x (GDScript)

## Reglas de este archivo

1. Es un registro **incremental**: se agregan entradas nuevas **al final**; las entradas anteriores no se reescriben ni se borran.
2. Cada entrada corresponde a un cambio relevante hecho con ayuda de IA (o a una decisión de diseño/depuración/pruebas apoyada en IA).
3. La fecha y hora son las **reales** del momento en que se registra la entrada (idealmente la misma del commit). No se alteran timestamps.
4. Si algo fue generado rápidamente y en gran volumen por IA está permitido: solo debe quedar explicado qué se pidió y qué cambió.
5. Si se corrige algo de una entrada anterior, se agrega una entrada **nueva** que la referencie (por ejemplo "corrige AI-001").

## Valores de `Tipo`

`AI_GENERATED` · `AI_ASSISTED` · `DEBUGGING` · `DESIGN` · `DOCUMENTATION` · `TESTING`

## Plantilla para nuevas entradas

```markdown
### AI-XXX – <título breve>
- **Fecha/hora:** <fecha y hora reales del registro>
- **Participante:** <nombre o PARTICIPANT_ID>
- **Herramienta IA:** <asistente / modelo>
- **Tipo:** <AI_GENERATED | AI_ASSISTED | DEBUGGING | DESIGN | DOCUMENTATION | TESTING>
- **Solicitud (resumen):** <qué se le pidió a la IA>
- **Archivos:** <creados / modificados>
- **Cambio realizado:** <1-3 líneas>
- **Verificación:** <qué se ejecutó/probó y resultado>
- **Commit:** <hash o mensaje de commit>
```

---

## Entradas

### AI-001 – Base del proyecto "Papa Caliente 2D" (esqueleto completo en Godot 4.3)
- **Fecha/hora:** `[COMPLETAR: fecha y hora reales en que se agrega esta entrada al repositorio]`
- **Participante:** `[COMPLETAR: nombre o PARTICIPANT_ID de quien registra]`
- **Herramienta IA:** Claude (Anthropic) – Claude Sonnet 5.5, vía interfaz de chat. Asistente oficial de desarrollo del AI GAME JAM.
- **Tipo:** AI_GENERATED
- **Solicitud (resumen):** Generar la base del proyecto Papa Caliente 2D a partir del contexto y los requisitos RF-01…RF-10: estructura de carpetas, módulos, dependencias, trazabilidad (este archivo) y un README con la instalación y configuración local.
- **Archivos (creados):**
  - Configuración: `project.godot`, `export_presets.cfg`, `.gutconfig.json`, `icon.svg`, `icon.svg.import` (generado por Godot), `.gitignore`, `.gitattributes`, `.editorconfig`, `requirements-dev.txt`, `.github/pull_request_template.md`
  - Documentación: `README.md`, `AI_TRACE.md`, `docs/ARCHITECTURE.md`
  - Escenas: `scenes/main.tscn`, `scenes/maps/park_map.tscn`, `scenes/maps/city_map.tscn`
  - Autoloads: `scripts/autoload/{game_events,game_manager,audio_manager}.gd`
  - Juego: `scripts/main.gd`, `scripts/match/match_controller.gd`, `scripts/characters/{character,player_character}.gd`, `scripts/ai/bot_character.gd`, `scripts/bomb/bomb_manager.gd`, `scripts/lucky_blocks/{reward_table,lucky_block,lucky_block_spawner}.gd`, `scripts/effects/effect_manager.gd`, `scripts/maps/{game_map,park_map,city_map,minimap}.gd`, `scripts/ui/{hud,main_menu}.gd`, `scripts/fx/explosion_fx.gd`
  - Herramientas: `scripts/tools/{run_tests,export_web,lint}.sh`, `scripts/tools/{run_tests,export_web}.ps1`, `scripts/tools/serve_web.py`
  - Pruebas: `tests/unit/test_{reward_table,bomb_manager,effect_manager,game_manager,input_map,maps,match_smoke}.gd`
  - Dependencia incluida (tercero): `addons/gut/` (GUT 9.3.0, framework de pruebas, licencia MIT, sin modificar)
- **Cambio realizado:** Se creó el esqueleto jugable de punta a punta: menú, 2 mapas, jugador, bots con IA, bomba con transferencia y explosión por rondas de eliminación, Lucky Blocks con rarezas, efectos temporales, minimapa, HUD, audio sintético y configuración de exportación Web. Todo el arte es procedural (placeholder) y debe reemplazarse más adelante.
- **Verificación (ejecutada al generar la base, con Godot 4.3-stable headless en Linux):**
  - Importación del proyecto sin errores de scripts.
  - 39 pruebas GUT en verde (7 archivos).
  - `gdformat --check` y `gdlint` sin hallazgos.
  - Simulación headless del juego completo (menú → partida en ambos mapas → rondas → derrota → reinicio → pausa → menú) sin errores.
  - Exportación Web en modo release generada correctamente (`index.html`, `.wasm`, `.pck`). **No** se probó todavía en un navegador real.
- **Notas / supuestos:** La IA no tiene acceso al repositorio: no hizo commits ni guardó archivos en él; el equipo debe copiar la base, revisarla y hacer el commit. Interpretación de reglas ambiguas del contexto: la partida es por rondas de eliminación (explota → el portador sale; gana el humano si es el último; pierde si explota en sus manos); el "marcado" lo implementa la recompensa *Radar*.
- **Commit:** `feat: base del proyecto Papa Caliente 2D (Godot 4.3) con módulos, pruebas y trazabilidad` *(sugerido; completar con el hash real al hacer el commit)*

### AI-002 – Alineación de SRS e implementación de Papa Caliente 2D
- **Fecha/hora:** 2026-10-10 03:14:46 (America/Bogota)
- **Participante:** [PENDIENTE: el equipo debe indicar su PARTICIPANT_ID]
- **Herramienta IA:** Codex, asistente de desarrollo del AI GAME JAM.
- **Tipo:** AI_ASSISTED
- **Solicitud (resumen):** Revisar `docs/SRS.md` contra el proyecto actual, implementar los requisitos restantes y aplicar los cambios solicitados por el equipo: conteo de jugadores y POV existentes conservados, minimapa exclusivo de Radar, sin penalizaciones, derrota inmediata del humano y mapas ampliados con atajos animados.
- **Archivos:** `docs/SRS.md`, `project.godot`, `scripts/ai/bot_character.gd`, `scripts/autoload/{audio_manager,game_events}.gd`, `scripts/bomb/bomb_manager.gd`, `scripts/characters/{character,player_character}.gd`, `scripts/effects/effect_manager.gd`, `scripts/lucky_blocks/{lucky_block,lucky_block_spawner,reward_table}.gd`, `scripts/maps/{city_map,game_map,minimap,park_map}.gd`, `scripts/match/match_controller.gd`, `scripts/tools/export_web.{ps1,sh}`, `scripts/ui/{hud,main_menu}.gd`, `tests/unit/{test_bomb_manager,test_effect_manager,test_input_map,test_maps,test_match_smoke,test_reward_table}.gd`.
- **Cambio realizado:** Se documentaron las decisiones actuales y se añadieron mapas 1.25×, 10 puntos de aparición, regiones de navegación, atajos de ida y vuelta bloqueados durante animación de 1.2 s y restringidos al no portador, bombas de 60 s, Radar temporal que muestra a todos en minimapa, recompensas sin penalización, rarezas 74/25/1, bloques limitados a cuatro, audio con música/volumen y limpieza de efectos al transferir o terminar. Se ampliaron las pruebas y los scripts de exportación ahora ejecutan la suite antes de exportar.
- **Verificación:** `git diff --check` pasó. No fue posible ejecutar Godot/GUT ni exportar Web porque Godot no está disponible en PATH. La ejecución del script de pruebas quedó bloqueada por la política de firma de PowerShell; no se cambió ni eludió esa política. `gdformat`/`gdlint` no están instalados. No se probó en navegador real.
- **Commit:** Pendiente de revisión y commit real por el equipo. Sugerido: `feat: align gameplay with SRS and add animated shortcuts`

### AI-003 – Cierre de requisitos y verificación disponible
- **Fecha/hora:** 2026-10-10 03:16:33 (America/Bogota)
- **Participante:** [PENDIENTE: el equipo debe indicar su PARTICIPANT_ID]
- **Herramienta IA:** Codex, asistente de desarrollo del AI GAME JAM.
- **Tipo:** TESTING
- **Solicitud (resumen):** Completar la comparación de requisitos restantes y validar las pruebas funcionales y la posibilidad de ejecución/exportación en el entorno disponible.
- **Archivos:** `docs/SRS.md`, `scripts/ai/bot_character.gd`, `scripts/bomb/bomb_manager.gd`, `scripts/characters/character.gd`, `scripts/effects/effect_manager.gd`, `scripts/maps/{city_map,game_map}.gd`, `scripts/tools/export_web.{ps1,sh}`, `scripts/ui/hud.gd`, `tests/unit/{test_bomb_manager,test_effect_manager,test_maps,test_match_smoke}.gd`.
- **Cambio realizado:** Se alinearon navegación y prioridades de IA, bloqueo de portadores en atajos mediante capa de colisión, posiciones seguras en el mapa de ciudad y limpieza de todos los efectos de Radar al transferir la bomba. La exportación Web ejecuta primero la suite GUT.
- **Verificación:** `git diff --check` pasó. No se pudieron correr GUT, gdformat/gdlint ni la exportación: no están disponibles Godot ni gdtoolkit; la política de firma de PowerShell impide cargar `run_tests.ps1`. La versión Web no se probó en navegador.
- **Commit:** Pendiente; no se creó ningún commit.

### AI-004 – Corrección de compilación del AudioManager
- **Fecha/hora:** 2026-10-10 03:19:21 (America/Bogota)
- **Participante:** [PENDIENTE: el equipo debe indicar su PARTICIPANT_ID]
- **Herramienta IA:** Codex, asistente de desarrollo del AI GAME JAM.
- **Tipo:** DEBUGGING
- **Solicitud (resumen):** Corregir el error de análisis de GDScript reportado al iniciar el proyecto con Godot 4.3.
- **Archivos:** `scripts/autoload/audio_manager.gd`
- **Cambio realizado:** Se declaró `notes` como `Array[float]` y `note` como `float` para que Godot pueda inferir y compilar correctamente la generación de música.
- **Verificación:** `git diff --check` pendiente en este turno. No fue posible volver a iniciar Godot desde este entorno porque no se encontró el ejecutable ni la variable `GODOT`; la ruta solicitada al equipo está pendiente. El error de `MainMenu.set_master_volume` era consecuencia de que falló la carga del autoload.
- **Commit:** Pendiente; no se creó ningún commit.

### AI-005 – Validación estática del arreglo de AudioManager
- **Fecha/hora:** 2026-10-10 03:19:44 (America/Bogota)
- **Participante:** [PENDIENTE: el equipo debe indicar su PARTICIPANT_ID]
- **Herramienta IA:** Codex, asistente de desarrollo del AI GAME JAM.
- **Tipo:** TESTING
- **Solicitud (resumen):** Validar el parche que resuelve el error de inferencia de `note` reportado al arrancar Godot.
- **Archivos:** `scripts/autoload/audio_manager.gd`
- **Cambio realizado:** Se verificó que el arreglo tenga tipo explícito y que el parche esté limpio según `git diff --check`.
- **Verificación:** `git diff --check` pasó. No se pudieron ejecutar GUT ni el proyecto: `GODOT` no está definido en este entorno y no se encontró `godot` en PATH; la ruta de tu instalación está pendiente para validar el arranque real.
- **Commit:** Pendiente; no se creó ningún commit.

### AI-006 – Validación funcional tras corregir arranque y navegación
- **Fecha/hora:** 2026-10-10 03:22:24 (America/Bogota)
- **Participante:** [PENDIENTE: el equipo debe indicar su PARTICIPANT_ID]
- **Herramienta IA:** Codex, asistente de desarrollo del AI GAME JAM.
- **Tipo:** DEBUGGING
- **Solicitud (resumen):** Resolver el error de arranque reportado por el equipo y confirmar pruebas funcionales y ejecución del proyecto.
- **Archivos:** `scripts/autoload/audio_manager.gd`, `scripts/maps/game_map.gd`, `scripts/ai/bot_character.gd`, `docs/SRS.md`, `AI_TRACE.md`.
- **Cambio realizado:** Se tipó explícitamente la nota de la música. Se sustituyeron las dos zonas de navegación superpuestas por una zona compartida que evita los accesos de atajo; se actualizó el requisito RF-02.5 para reflejar ese diseño. Los bots sin bomba siguen buscando y usando las entradas animadas, mientras las barreras físicas restringen a los portadores.
- **Verificación:** Godot 4.3 importó el proyecto; GUT pasó 44/44 pruebas y 481 aserciones. El error de sincronización de navegación desapareció. El proyecto arrancó en headless durante 120 frames con código 0 y sin errores de script. Permanecen avisos deprecados de `make_polygons_from_outlines()`, un aviso de comparación float/int y el aviso del almacén de certificados raíz de este entorno; no bloquearon las pruebas ni el arranque. No se probó ventana gráfica ni navegador real.
- **Commit:** Pendiente; no se creó ningún commit.

### AI-007 – Atajos cerrados y activación visible de Radar
- **Fecha/hora:** 2026-10-10 09:17:49 (America/Bogota)
- **Participante:** [PENDIENTE: el equipo debe indicar su PARTICIPANT_ID]
- **Herramienta IA:** Codex, asistente de desarrollo del AI GAME JAM.
- **Tipo:** AI_ASSISTED
- **Solicitud (resumen):** Rediseñar los atajos como zonas cerradas de sentido único y asegurar que el minimapa aparezca durante Radar solo para el humano portador; no modificar el comportamiento de los bots.
- **Archivos:** `scripts/maps/game_map.gd`, `scripts/ui/hud.gd`, `tests/unit/test_maps.gd`, `tests/unit/test_match_smoke.gd`, `docs/SRS.md`, `AI_TRACE.md`.
- **Cambio realizado:** Se dibujaron corredores cerrados con entrada y salida rotuladas, perímetro y puertas físicas que bloquean a todos los personajes. Solo la entrada inicia el recorrido de animación de 3.2 s; el jugador queda inmóvil, no puede recibir ni transferir la bomba durante el trayecto y la salida no permite reingresar. `BotCharacter` no fue editado; se conserva su uso automático al llegar a una entrada. El HUD actualiza el minimapa por eventos de Radar y transferencia, lo coloca explícitamente en la esquina superior derecha y lo oculta al expirar el efecto o pasar la bomba. El SRS se actualizó.
- **Verificación:** Godot 4.3 importó el proyecto; GUT pasó 46/46 pruebas y 487 aserciones, incluidas pruebas de salida unidireccional, perímetro cerrado, visibilidad de Radar y ocultamiento inmediato al transferir. `git diff --check` pendiente. Se observaron avisos conocidos de `make_polygons_from_outlines()` obsoleto y del almacén de certificados raíz del entorno; no bloquearon las pruebas. No se probó en navegador real.
- **Commit:** Pendiente; no se creó ningún commit.

### AI-008 – Cierre de validación
- **Fecha/hora:** 2026-10-10 09:18:04 (America/Bogota)
- **Participante:** [PENDIENTE: el equipo debe indicar su PARTICIPANT_ID]
- **Herramienta IA:** Codex, asistente de desarrollo del AI GAME JAM.
- **Tipo:** TESTING
- **Solicitud (resumen):** Cerrar la validación de los cambios de atajos y minimapa.
- **Archivos:** `AI_TRACE.md`.
- **Cambio realizado:** Se registró el resultado de la revisión estática final.
- **Verificación:** `git diff --check` pasó; se retiró el directorio temporal de configuración usado para correr Godot. GUT permanece en 46/46 pruebas.
- **Commit:** Pendiente; no se creó ningún commit.

### AI-009 – Modo 2 jugadores con cámara compartida (P1 / P2)
- **Fecha/hora:** 2026-10-10 (fecha de la sesión; `[COMPLETAR: hora real al hacer el commit]`)
- **Participante:** Albert Valencia Escobar (PARTICIPANT_ID: A00407443)
- **Herramienta IA:** Claude (Anthropic) – Claude Sonnet 5.5, vía interfaz de chat. Asistente oficial de desarrollo del AI GAME JAM.
- **Tipo:** AI_GENERATED
- **Solicitud (resumen):** Añadir una opción de menú para dos jugadores. Una sola pantalla (no dividida) cuya cámara enfoca el punto medio entre ambos y se amplía/mueve para que los dos siempre se vean. Jugadores identificados como P1 (WASD + E) y P2 (flechas + Espacio) con pantalla emergente que explique los controles. Si muere uno, desde la ronda siguiente la cámara solo enfoca al vivo; si mueren los dos, fin de juego con las opciones de siempre. Mensajes de victoria "Ganó P1" / "Ganó P2". Quien no tiene la bomba ve los Lucky Blocks y habilidades pero no recibe buffs. Actualizar `docs/SRS.md`, `AI_TRACE.md` y la documentación.
- **Archivos (creados):** `scripts/camera/dual_camera.gd`, `tests/unit/test_two_players.gd`.
- **Archivos (modificados):** `project.godot` (10 acciones nuevas `p1_*` / `p2_*`), `scripts/autoload/game_manager.gd`, `scripts/characters/{character,player_character}.gd`, `scripts/match/match_controller.gd`, `scripts/ui/{main_menu,rules_screen,hud}.gd`, `scripts/maps/minimap.gd`, `tests/unit/test_input_map.gd`, `docs/SRS.md` (nuevo RF-11 y ajustes en RF-01, RF-03, RF-08, RF-09a y reglas globales), `README.md`, `AI_TRACE.md`.
- **Cambio realizado:**
  - Menú: botón "2 Jugadores" ("Jugar" sigue siendo 1 jugador). Ambos pasan por la pantalla de reglas; en 2 jugadores esa pantalla emergente lista los controles de P1 y P2.
  - `PlayerCharacter.player_index` (0/1/2) elige las acciones del Input Map; nuevo método virtual `Character.wants_shortcut()` sustituye la comprobación fija de la tecla de atajo.
  - `DualCamera`: se centra en el punto medio de los jugadores enfocados y calcula el zoom para que quepan con margen; suavizado dependiente de `delta`; respeta límites del mapa. `MatchController` le cambia los objetivos al empezar cada ronda, de modo que el jugador muerto sale del foco en la ronda siguiente.
  - Fin de partida: derrota si no queda ningún humano; victoria si no quedan bots y queda un solo humano (se guarda `GameManager.winner_label`). La firma de `match_ended(player_won)` no cambió.
  - HUD: mensajes "¡GANÓ P1!" / "¡GANÓ P2!", efectos con prefijo de jugador, recordatorio de teclas y minimapa Radar para cualquiera de los dos humanos con bomba.
  - Lucky Blocks y efectos no se modificaron: ya solo los recoge/recibe quien lleva la bomba y se ven mientras cualquier humano la lleva.
- **Verificación:** **No se pudo ejecutar** Godot/GUT en el entorno de la IA (no hay ejecutable). Solo se revisó el código de forma estática. Se agregaron pruebas GUT (`test_two_players.gd` y casos en `test_input_map.gd`) que **el equipo debe ejecutar**. Pasos manuales: abrir el proyecto, "2 Jugadores", comprobar controles, alejar/juntar a P1 y P2, dejar morir a uno y ver la cámara en la ronda siguiente, y comprobar los mensajes finales.
- **Notas / supuestos:** (1) Los bots se mantienen en el modo 2 jugadores. (2) Si no quedan bots y siguen vivos P1 y P2, las rondas continúan hasta que quede uno (decisión asumida; confirmar con el equipo). (3) La IA no tiene acceso al repositorio: no hizo commits; el equipo debe revisar el diff y hacer el commit. (4) Riesgo conocido: algunos teclados no registran todas las combinaciones cuando dos personas pulsan muchas teclas a la vez.
- **Commit:** `feat: add two-player mode with shared auto-zoom camera` *(sugerido; completar con el hash real al hacer el commit)*

### AI-010 – Cámara del modo 2 jugadores: ver ambos jugadores en esquinas opuestas
- **Fecha/hora:** 2026-10-10 (fecha de la sesión; `[COMPLETAR: hora real al hacer el commit]`)
- **Participante:** Albert Valencia Escobar (PARTICIPANT_ID: A00407443)
- **Herramienta IA:** Claude (Anthropic) – Claude Sonnet 5.5, vía interfaz de chat. Asistente oficial de desarrollo del AI GAME JAM.
- **Tipo:** AI_ASSISTED
- **Solicitud (resumen):** En el modo 2 jugadores, cuando cada jugador está en una esquina opuesta del mapa, la cámara debe alejarse lo suficiente para que ambos aparezcan en pantalla. Se deben ignorar los márgenes/límites del mapa y pintar de negro todo lo que quede fuera de él. Los jugadores no pueden salir del mapa.
- **Archivos (modificados):** `scripts/camera/dual_camera.gd`, `scripts/maps/tiled_map.gd`, `tests/unit/test_two_players.gd`, `docs/SRS.md` (RF-11.4 y aceptación), `README.md`, `AI_TRACE.md`.
- **Cambio realizado:**
  - Causa: `DualCamera.set_bounds()` fijaba `limit_*` de Camera2D al tamaño del mapa y un zoom mínimo que hacía que el mapa *cubriera* la pantalla (0,8 con vista 1280×720 y mapa 1600×1600). Con jugadores en esquinas opuestas hacía falta ≈0,36, así que uno quedaba fuera de pantalla.
  - `DualCamera`: ya no se establecen límites de cámara. El zoom mínimo pasa a ser el que muestra el mapa completo más el margen (`min_zoom_for()`), calculado con el tamaño de vista actual. `set_bounds()` conserva su firma y solo guarda el rectángulo; `zoom_for_rect()` mantiene su firma.
  - `TiledMap`: `_draw()` ya no pinta el margen verde de 400 px alrededor del mapa; se añade `OutsideMask` (cuatro rectángulos negros alrededor del mapa, `z_index` 1) que además tapa un tile de la capa "Decoración" que sobresale 64 px por el borde superior. Queda por debajo de personajes (z 2) y techos (z 3).
  - No se tocó nada de colisiones: las paredes perimetrales ya existentes (`WALL_THICKNESS`, comprobadas en `test_maps.gd`) impiden que los jugadores salgan del mapa. Modo 1 jugador sin cambios (su cámara conserva `limit_*`).
  - Pruebas nuevas en `test_two_players.gd`: cámara sin límites, ambos jugadores visibles en las dos diagonales de esquinas opuestas (respetando el margen) y existencia de la máscara negra.
- **Verificación:** **No se pudo ejecutar** Godot/GUT en el entorno de la IA (no hay ejecutable). Solo revisión estática y un cálculo numérico independiente de la fórmula de zoom (esquinas opuestas → zoom ≈0,358, ambos jugadores dentro de pantalla con ≈78 px de margen). **El equipo debe ejecutar GUT** y probar a mano: "2 Jugadores", llevar a P1 y P2 a esquinas opuestas y comprobar que se ven ambos con el exterior en negro.
- **Notas / supuestos:** (1) Se interpretó "ignora los márgenes del mapa" como quitar los límites de cámara en el borde del mapa (se sigue usando el margen de 220 px entre jugadores y borde de pantalla). (2) Riesgo conocido: con mejoras de velocidad el suavizado del zoom (`zoom_speed`) puede ir un instante por detrás de dos jugadores que se separan rápido; el margen de 220 px lo absorbe en las pruebas de cálculo, pero conviene comprobarlo jugando. (3) La IA no tiene acceso al repositorio: no hizo commits; el equipo debe revisar el diff y hacer el commit.
- **Commit:** `feat: show both players at opposite corners with no camera limits and black outside the map` *(sugerido; completar con el hash real al hacer el commit)*
