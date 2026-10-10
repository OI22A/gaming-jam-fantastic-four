# Arquitectura – Papa Caliente 2D

Godot 4.3 + GDScript. Todo el contenido visual de la base se dibuja por código
(`_draw()`), por lo que el proyecto corre sin ningún asset externo. Cuando haya
arte real se reemplaza el dibujo conservando las mismas APIs.

## 1. Módulos del proyecto → código → requisitos

| Módulo | Código | Requisitos |
|---|---|---|
| Gestión de partidas | `autoload/game_manager.gd`, `match/match_controller.gd`, `main.gd` | RF-01 |
| Control de jugadores | `characters/character.gd`, `characters/player_character.gd` | RF-03 |
| Inteligencia artificial | `ai/bot_character.gd` | RF-04 |
| Gestión de la bomba | `bomb/bomb_manager.gd` | RF-05 |
| Sistema de Lucky Blocks | `lucky_blocks/lucky_block.gd`, `lucky_block_spawner.gd`, `reward_table.gd` | RF-06 |
| Gestión de efectos | `effects/effect_manager.gd` | RF-07 |
| Mapas y minimapa | `maps/game_map.gd`, `park_map.gd`, `city_map.gd`, `minimap.gd` | RF-02, RF-08 |
| Interfaz de usuario | `ui/hud.gd`, `ui/main_menu.gd` | RF-09 |
| Audio | `autoload/audio_manager.gd` | RF-09 |
| Compatibilidad web | `export_presets.cfg`, `scripts/tools/export_web.*`, `serve_web.py` | RF-10 |

(Rutas relativas a `scripts/`.)

## 2. Estado de la base por requisito

| RF | Estado en la base | Pendiente / siguiente paso |
|---|---|---|
| RF-01 | Menú → cuenta regresiva → rondas por eliminación → victoria/derrota → reinicio (R / botón) → menú. Pausa con Esc. | Pulir flujo, pantalla de puntuaciones |
| RF-02 | 2 mapas jugables (Parque Central, Calles del Centro) con colisiones, 6 puntos de aparición y 6 Lucky Blocks cada uno | Arte real / TileMap, más decoración |
| RF-03 | Movimiento con WASD o flechas, colisión con obstáculos y entre personajes | Animaciones / sprites |
| RF-04 | Bots con 4 modos (deambular, perseguir, huir, ir a Lucky Block) y esquive de obstáculos con rayos | Navegación avanzada (NavigationAgent2D), dificultad por ronda |
| RF-05 | Temporizador, transferencia por contacto con enfriamiento, explosión que elimina al portador | Balance de duración/velocidades |
| RF-06 | 9 recompensas, 4 rarezas con probabilidad 70/20/9/1 %, solo las recoge el portador de la bomba, reaparición a los 8 s | Balance, iconos por rareza |
| RF-07 | Velocidad (mejora y penalización), marcado de rivales, tiempo adicional (+/-); se retiran solos al expirar | Más efectos |
| RF-08 | Minimapa con jugador (azul), portador (rojo), marcados (anillo amarillo) y rivales (gris) | Estilo visual final |
| RF-09 | HUD (temporizador, ronda, portador, efectos, avisos, resultados). Sonidos sintéticos para los eventos principales | Sonidos y música reales (ver §6) |
| RF-10 | Preset "Web" (sin hilos) probado: la exportación se genera. | Probar en navegadores reales y publicar (itch.io / GitHub Pages) |

## 3. Máquina de estados (`GameManager.State`)

```
MENU ──start_match──▶ COUNTDOWN ──(3 s)──▶ PLAYING ──explosión──▶ ROUND_END ──(2 s)──▶ COUNTDOWN (nueva ronda)
                          ▲  ▲                 │                      
                          │  └──── PAUSED ◀────┘ (Esc)               
                          │                    └─ explota el jugador / no quedan bots ─▶ ENDED ──R──▶ COUNTDOWN
                          └──────────── go_to_menu() ◀────────────────────────────────────────────────┘
```

## 4. Bus de eventos (`GameEvents`)

Los módulos no se llaman entre sí: se comunican por señales del autoload `GameEvents`.

| Señal | Emite | Escuchan |
|---|---|---|
| `match_requested(map_id)` / `menu_requested` | GameManager | Main |
| `state_changed(new, old)` | GameManager | Hud |
| `countdown_tick(s)` | MatchController | Hud, AudioManager |
| `round_started(n, holder)` | MatchController | Hud, AudioManager |
| `bomb_time_changed(left, duration)` | BombManager | AudioManager |
| `bomb_transferred(from, to)` | BombManager | AudioManager |
| `bomb_exploded(holder)` | BombManager | MatchController, Hud, AudioManager |
| `bomb_time_bonus_requested(s)` | EffectManager | BombManager |
| `character_eliminated(c)` | MatchController | (libre) |
| `match_ended(player_won)` | GameManager | Hud, AudioManager |
| `lucky_block_collected(c, reward)` | LuckyBlockSpawner | Hud, AudioManager |
| `effect_applied(t, id, dur)` / `effect_expired(t, id)` | EffectManager | AudioManager |
| `sfx_requested(name)` | cualquiera | AudioManager |

## 5. Convenciones técnicas

- **Capas de colisión:** 1 = mundo (paredes/obstáculos), 2 = personajes, 3 = Lucky Blocks.
- **Efectos:** nunca modifican `base_speed`; escriben en `Character.speed_modifiers` y
  `Character.marks`, y `EffectManager` los retira al expirar.
- **Probabilidades de Lucky Blocks:** `weight` = porcentaje; los pesos deben sumar 100
  (hay una prueba que lo verifica en `tests/unit/test_reward_table.gd`).
- **Estilo:** `gdformat` + `gdlint` (`scripts/tools/lint.sh`), tabulaciones, tipado estático cuando sea posible.
- **Pruebas:** GUT en `tests/unit/`. Toda lógica nueva de reglas (bomba, efectos, recompensas) debe llevar prueba.

## 6. Recetas rápidas

**Agregar una recompensa:** añadir un diccionario a `RewardTable.REWARDS` (ajustar pesos para que sumen 100 y
actualizar `test_rarity_distribution_matches_design`). Si usa un tipo de efecto nuevo, implementarlo en
`EffectManager.apply_effect()`.

**Agregar un mapa:** crear `scripts/maps/<id>_map.gd` (`extends GameMap`, sobrescribir `_define_layout()`),
una escena `scenes/maps/<id>_map.tscn` con ese script y registrarlo en `GameManager.MAPS`.
La prueba `test_maps.gd` valida que los puntos de aparición y de Lucky Blocks no caigan en obstáculos.

**Cambiar un sonido:** copiar `res://assets/audio/sfx/<nombre>.ogg` (o `.wav`). Nombres: `countdown`, `go`,
`bomb_tick`, `bomb_transfer`, `bomb_explode`, `lucky_block`, `effect_on`, `effect_off`, `win`, `lose`.

**Ajustar dificultad de la IA:** `BotCharacter.base_speed`, `decision_interval`, `sight_range`, `block_seek_chance`.
