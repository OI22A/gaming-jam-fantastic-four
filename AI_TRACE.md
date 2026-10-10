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
