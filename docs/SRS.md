# Papa Caliente 2D: Especificación de Requerimientos

Motor: Godot 4.x + GDScript. Exportación: HTML5 (Chrome).
Los valores marcados **[param]** son valores de partida ajustables, no decisiones cerradas. Los marcados **[asumido]** son suposiciones por confirmar.

---

## Constantes globales (`constantes.gd`)

| Constante | Valor |
|---|---|
| `TIEMPO_BOMBA` | 60 s |
| `COOLDOWN_TRANSFERENCIA` | 1.5 s [param] |
| `DURACION_EFECTO` | 10 s [param] |
| `MAX_LUCKY_BLOCKS` | 4 [param] |
| `RESPAWN_BLOCK` | 15 s [param] |
| `VELOCIDAD_BASE` | [param] |
| `INTERVALO_IA` | 0.2 a 0.5 s [param] |

## Señales (contrato entre módulos)

| Señal | Emite |
|---|---|
| `partida_iniciada` | Gestión de partidas |
| `partida_terminada(ganador)` | Gestión de partidas |
| `bomba_transferida(de, a)` | Gestión de la bomba |
| `bomba_explotó(jugador)` | Gestión de la bomba |
| `jugador_eliminado(jugador)` | Gestión de la bomba |
| `lucky_block_recogido(tipo, efecto)` | Lucky Blocks |
| `efecto_aplicado(efecto, objetivo)` | Efectos |
| `efecto_terminado(efecto, objetivo)` | Efectos |

## Reglas globales de juego

- **Impostor = portador de la bomba** (humano o bot).
- **Victoria:** ser el único sobreviviente. **Derrota:** ser eliminado por la explosión.
- **Portador:** ve y recoge Lucky Blocks. No ve a los demás en el minimapa salvo con el efecto de marcado. No puede usar pasadizos.
- **No portadores:** no ven Lucky Blocks (ni en mapa ni en minimapa), no ven al portador en el minimapa, no reciben efectos de bloques. Sí ven a otros no portadores. Pueden usar pasadizos.
- **Fantasma:** el humano eliminado observa la partida hasta que termina. No es objetivo de los bots ni recibe la bomba.

## Orden de implementación

1. Control de jugadores · 2. Mapas · 3. Bomba · 4. Partidas · 5. IA (**Fase 1: núcleo jugable**)
6. Interfaz · 7. Lucky Blocks · 8. Efectos · 9. Minimapa (**Fase 2**)
10. Audio · Pulido (**Fase 3**)

RF-10 (web) es transversal: se exporta y prueba desde la Fase 1.

---

## 1. RF-03 Control de jugadores

Base compartida (`CharacterBody2D`) para el humano y los 9 bots.

### Movimiento con teclado (detalle de RF-03.1)

- **RF-03.1.1 Acciones del Input Map.** Se definen 4 acciones: `mover_arriba`, `mover_abajo`, `mover_izquierda`, `mover_derecha`. Cada una tiene **dos teclas asignadas**:
  - Arriba: `W` y `↑`
  - Abajo: `S` y `↓`
  - Izquierda: `A` y `←`
  - Derecha: `D` y `→`
  - Las letras se asignan por **tecla física** (physical keycode) para que WASD funcione igual en teclados no QWERTY.
- **RF-03.1.2 Equivalencia.** WASD y las flechas son equivalentes y se pueden usar de forma indistinta o combinada.
- **RF-03.1.3 Dirección en 8 sentidos.** La dirección se obtiene con `Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")`, que devuelve un vector **normalizado**. La velocidad diagonal es igual a la ortogonal (el error típico es sumar los ejes sin normalizar, lo que hace la diagonal ~41 % más rápida).
- **RF-03.1.4 Teclas opuestas.** Si se pulsan dos teclas opuestas (A+D o W+S), se cancelan y el jugador no se mueve en ese eje.
- **RF-03.1.5 Velocidad.** `velocity = direccion * VELOCIDAD_BASE * multiplicador_velocidad`, aplicada con `move_and_slide()` dentro de `_physics_process`. Vista cenital (top-down), sin gravedad.
- **RF-03.1.6 Respuesta.** El movimiento es inmediato (sin aceleración ni inercia) **[param]**. Al soltar las teclas, el jugador se detiene en el mismo frame.
- **RF-03.1.7 Deslizamiento.** Al chocar con un obstáculo, el jugador desliza a lo largo de la pared en lugar de quedarse frenado.
- **RF-03.1.8 Estados de entrada.** El teclado solo mueve al personaje en estado `JUGANDO`. En `MENÚ` y `TERMINADA` la entrada de movimiento se ignora. El humano en modo fantasma sigue pudiendo moverse (RF-03.6).
- **RF-03.1.9 Navegador.**
  - Si la pestaña pierde el foco, se reinicia la entrada (el jugador se detiene) para evitar movimiento "pegado".
  - Las flechas no deben hacer scroll de la página mientras el canvas tiene el foco.
  - La orientación o animación del sprite según la dirección es **[param]**.

### Resto de RF-03

- **RF-03.2** Humano y bots usan la misma escena y la misma velocidad base. Solo cambia la fuente de la dirección (teclado o IA).
- **RF-03.3** Los jugadores colisionan con los obstáculos del mapa y no los atraviesan.
- **RF-03.4** Al escuchar `bomba_transferida`, se cambia la capa y máscara de colisión del jugador según su rol. El portador no puede entrar a los pasadizos.
- **RF-03.5** El no portador cerca de un pasadizo pulsa la tecla de acción **[param: E o Espacio]** y avanza automáticamente hasta atravesarlo. Durante el cruce no puede recibir la bomba **[asumido]**.
- **RF-03.6** El estado fantasma (humano eliminado) no tiene colisiones, no interactúa con nadie y se mueve libremente o sigue la cámara **[param]**.
- **RF-03.7** La velocidad es modificable por el sistema de efectos mediante un multiplicador, sin tocar `VELOCIDAD_BASE`.

**Aceptación**
- Los 4 pares de teclas mueven al personaje en su dirección.
- En diagonal, la velocidad es igual a la ortogonal.
- A+D pulsadas a la vez no mueven al jugador.
- El jugador no atraviesa obstáculos y desliza por las paredes.
- Al cambiar de pestaña y volver, el jugador no sigue moviéndose solo.
- El portador no entra al pasadizo y el no portador sí. El fantasma atraviesa todo sin afectar a nadie.

---

## 2. RF-02 Mapas

- **RF-02.1** Existen 2 escenarios 2D con ambientación de ciudad (parque), cada uno con obstáculos, zonas de pasadizo y puntos de aparición.
- **RF-02.2** Cada mapa tiene 10 puntos de aparición (uno por jugador).
- **RF-02.3** Cada mapa tiene zonas de pasadizo cuya entrada bloquea al portador y se activa con la tecla de acción (RF-03.5).
- **RF-02.4** Cada mapa define puntos de aparición de Lucky Blocks (≥ `MAX_LUCKY_BLOCKS`).
- **RF-02.5** Cada mapa define zonas de navegación para los bots (`NavigationRegion2D`), con capas distintas para portador y no portador.
- **RF-02.6** Los dos mapas son visualmente distintos.
- **RF-02.7** Al iniciar una partida se elige un mapa (aleatorio o por selección) **[param]**.

**Aceptación:** todos los puntos de aparición son alcanzables y ningún bot nace atrapado.

---

## 3. RF-05 Gestión de la bomba

- **RF-05.1** Temporizador **global** de 60 s. No se reinicia al transferir; solo se reinicia a 60 s tras una explosión.
- **RF-05.2** Al iniciar, el portador se elige al azar entre los 10 jugadores (humano o bot).
- **RF-05.3** La transferencia ocurre por colisión, y solo si uno de los dos jugadores es el portador. Si dos no portadores chocan, no pasa nada.
- **RF-05.4** Cooldown global entre transferencias (`COOLDOWN_TRANSFERENCIA`) con una única variable `ultimo_cambio_ms`.
- **RF-05.5** Al terminar el cooldown, se revisa `get_overlapping_bodies()` del portador. Si hay jugadores encima, se transfiere al **más cercano**.
- **RF-05.6** Al llegar a 0, el portador explota: emite `bomba_explotó` y `jugador_eliminado`.
- **RF-05.7** Tras la explosión, la bomba pasa a un jugador vivo al azar con 60 s nuevos. Si solo queda un vivo, no hay nueva bomba.
- **RF-05.8** El fantasma nunca recibe la bomba.
- **RF-05.9** El módulo expone `agregar_tiempo(s)` y `transferir_a_azar()` para el sistema de efectos.

**Aceptación:** pasar la bomba con 5 s restantes deja 5 s. No hay rebotes durante el cooldown. Con 2 vivos y una explosión, la partida termina.

---

## 4. RF-01 Gestión de partidas

- **RF-01.1** Estados: `MENÚ → JUGANDO → TERMINADA`. La partida se inicia desde el menú.
- **RF-01.2** Al iniciar: carga el mapa, instancia 1 humano + 9 bots **[asumido]**, asigna puntos de aparición y arranca la bomba.
- **RF-01.3** Al recibir `jugador_eliminado`, se marca al jugador como fuera. Si es el humano, pasa a fantasma.
- **RF-01.4** La partida termina cuando queda 1 vivo y emite `partida_terminada(ganador)`.
- **RF-01.5** Victoria si el ganador es el humano. Derrota si fue eliminado; el fantasma observa hasta que termine la partida.
- **RF-01.6** Reiniciar limpia efectos, bloques y jugadores, y comienza una partida nueva.
- **RF-01.7 Máquina de Estados Global (`GameManager.State`):** El sistema debe regirse estrictamente por una máquina de estados centralizada que controle el flujo del juego, ignorando inputs no correspondientes al estado activo:
  - `MENU`: Estado inicial. Transiciona a `COUNTDOWN` mediante la señal `match_requested`.
  - `COUNTDOWN`: Cuenta regresiva de congelamiento (3 segundos). Transiciona a `PLAYING`.
  - `PLAYING`: Estado de juego activo. Puede pausarse (`PAUSED`) con la tecla `Esc` o transicionar a `ROUND_END` tras la explosión de la bomba.
  - `PAUSED`: Suspende temporalmente el procesamiento del juego. Devuelve a `PLAYING` con `Esc` o a `MENU` mediante `go_to_menu()`.
  - `ROUND_END`: Pausa técnica de 2 segundos tras una eliminación. Si quedan bots vivos, regresa a `COUNTDOWN` para la nueva ronda; si el humano muere o no quedan bots, avanza a `ENDED`.
  - `ENDED`: Pantalla de resultados finales. La tecla `R` transiciona de vuelta a `COUNTDOWN`.

**Aceptación:** la partida no termina antes de quedar un solo vivo. Reiniciar no deja estado de la partida anterior.

---

## 5. RF-04 Inteligencia artificial

- **RF-04.1** Los bots usan la misma escena de RF-03 y navegan con `NavigationAgent2D`, sin atravesar obstáculos.
- **RF-04.2** **Bot portador:** persigue al jugador vivo más cercano (humano o bot). Excluye al fantasma.
- **RF-04.3** Si hay un Lucky Block más cerca que ese jugador, va primero al bloque. Tras recogerlo, vuelve a elegir al jugador más cercano. Conoce todos los bloques, sin rango de visión.
- **RF-04.4** **Bot no portador:** huye del portador y usa los pasadizos con la tecla de acción.
- **RF-04.5** El bot cambia de comportamiento al instante al escuchar `bomba_transferida`.
- **RF-04.6** El objetivo se recalcula cada `INTERVALO_IA`, no cada frame.
- **RF-04.7** El bot portador trata los pasadizos como intransitables.
- **RF-04.8** Si el bot portador está pegado a un jugador durante el cooldown, espera. La resolución la hace RF-05.5.

**Aceptación:** con 9 bots a la vez en Chrome, el juego se mantiene fluido. El bot portador alcanza a sus objetivos y el que huye usa los pasadizos.

---

## 6. RF-09a Interfaz de usuario

- **RF-09a.1** HUD: temporizador de la bomba (mm:ss), jugadores vivos y rol actual del humano (portador o no).
- **RF-09a.2** Para el humano portador, un indicador "tienes la bomba". Los no portadores **no** ven un indicador sobre el portador (regla de visibilidad).
- **RF-09a.3** Feedback del cooldown de transferencia (parpadeo del nuevo portador).
- **RF-09a.4** Indicador de efectos activos y su tiempo restante.
- **RF-09a.5** Pantalla de resultados: victoria o derrota, con opciones de reiniciar y volver al menú.
- **RF-09a.6** Aviso de "modo fantasma" cuando el humano es eliminado.

**Aceptación:** el HUD refleja el estado real en todo momento y se actualiza solo por señales.

---

## 7. RF-06 Lucky Blocks

| Block | Rareza | Probabilidad | Efectos |
|---|---|---|---|
| Cobre | Común | 74 % | Velocidad +25 % · Marcar jugadores · +30 s |
| Plateado | Especial | 25 % | Velocidad +50 % · Velocidad -25 % a los demás |
| Dorado | Legendario | 1 % | Pasar la bomba a otro jugador al azar |

- **RF-06.1** Cada bloque generado tiene un tipo según las probabilidades de la tabla.
- **RF-06.2** Al recogerlo, se elige uno de los efectos de ese tipo al azar con igual probabilidad **[asumido]**.
- **RF-06.3** Aparecen hasta `MAX_LUCKY_BLOCKS` a la vez en los puntos de aparición del mapa y reaparecen tras `RESPAWN_BLOCK`.
- **RF-06.4** Solo el portador los ve (mundo y minimapa) y los recoge **[asumido: también en el mundo]**.
- **RF-06.5** Al cambiar el portador, la visibilidad de los bloques cambia de inmediato.
- **RF-06.6** Emite `lucky_block_recogido(tipo, efecto)`.

**Aceptación:** una simulación de ≥1000 bloques se acerca a 74/25/1. Un no portador no puede ver ni recoger bloques.

---

## 8. RF-07 Efectos temporales

| Efecto | Origen | Objetivo | Duración |
|---|---|---|---|
| Velocidad +25 % | Cobre | Portador | `DURACION_EFECTO` |
| Marcar jugadores | Cobre | Minimapa del portador | `DURACION_EFECTO` |
| +30 s | Cobre | Temporizador | Instantáneo |
| Velocidad +50 % | Plateado | Portador | `DURACION_EFECTO` |
| Velocidad -25 % | Plateado | Todos los vivos menos el portador | `DURACION_EFECTO` |
| Bomba a otro al azar | Dorado | Bomba | Instantáneo |

- **RF-07.1** Aplicar un efecto emite `efecto_aplicado`; retirarlo emite `efecto_terminado`.
- **RF-07.2** Los efectos de velocidad se aplican como multiplicadores y se retiran restaurando el valor base, sin acumular errores.
- **RF-07.3** Si se repite el mismo efecto, se reinicia su duración (no se acumula) **[asumido]**.
- **RF-07.4** Los efectos ligados al portador se retiran al transferir la bomba **[asumido]**.
- **RF-07.5** "Bomba a otro al azar" elige a un jugador vivo distinto del portador y del fantasma, sin reiniciar el temporizador.
- **RF-07.6** Al eliminar a un jugador o terminar la partida, se limpian sus efectos.
- **RF-07.7** El +30 s se suma al tiempo restante, sin tope **[asumido]**.

**Aceptación:** tras cada efecto, la velocidad vuelve exactamente al valor base. El +30 s no reinicia el tiempo.

---

## 9. RF-08 Minimapa

- **RF-08.1** El minimapa muestra el mapa y los puntos de los jugadores.
- **RF-08.2** **No portador:** ve a los otros no portadores. No ve al portador ni los Lucky Blocks.
- **RF-08.3** **Portador:** ve los Lucky Blocks. No ve a los demás, salvo con el efecto "Marcar jugadores".
- **RF-08.4** Con el marcado activo, el portador ve a todos los no portadores vivos durante `DURACION_EFECTO`.
- **RF-08.5** El estado se actualiza al escuchar `bomba_transferida`, `efecto_aplicado` y `efecto_terminado`.
- **RF-08.6** El jugador humano se distingue visualmente de los demás.
- **RF-08.7** El fantasma ve a todos los jugadores **[asumido]**.

**Aceptación:** al transferirse la bomba, el minimapa del humano cambia en el mismo frame.

---

## 10. RF-09b Audio

- **RF-09b.1** Sonidos para: transferencia, explosión, recogida de bloque (uno por rareza), efecto activado, cuenta final del temporizador **[param: últimos 10 s]**, victoria y derrota.
- **RF-09b.2** Música de fondo con control de volumen.
- **RF-09b.3** Los sonidos se reproducen solo escuchando señales, sin código de audio en otros módulos.
- **RF-09b.4** El audio se inicia tras la primera interacción del usuario (restricción de los navegadores).

---

## 11. RF-10 Compatibilidad web (transversal)

- **RF-10.1** Exportación HTML5 con Godot 4.x, probada en Chrome.
- **RF-10.2** No requiere instalación: se abre desde una URL.
- **RF-10.3** Framerate estable con 10 jugadores (9 bots de IA).
- **RF-10.4** Se prueba una exportación en cada fase, empezando por la Fase 1.

---
## 12. Interfaces de Software y Restricciones Técnicas

### 12.1 Contrato del Bus de Eventos Global (`GameEvents`)
Para garantizar el desacoplamiento total de los módulos, el software debe implementar un patrón *Observer* (Autoload global `GameEvents`). Queda estrictamente prohibido el acoplamiento directo (llamadas a métodos) entre módulos transversales. El sistema se comunicará mediante las siguientes señales clave:

| Categoría | Señal | Origen / Emisor | Componentes que Escuchan |
|---|---|---|---|
| **Flujo** | `match_requested(map_id)` / `menu_requested` | GameManager | Main |
| **Flujo** | `state_changed(new_state, old_state)` | GameManager | HUD |
| **Partida** | `countdown_tick(segundos)` | MatchController | HUD, AudioManager |
| **Partida** | `round_started(ronda_num, portador)` | MatchController | HUD, AudioManager |
| **Partida** | `character_eliminated(personaje)` | MatchController | Core del sistema |
| **Partida** | `match_ended(player_won)` | GameManager | HUD, AudioManager |
| **Bomba** | `bomb_time_changed(tiempo_restante, duracion)`| BombManager | AudioManager |
| **Bomba** | `bomb_transferred(from_player, to_player)` | BombManager | AudioManager, Minimapa |
| **Bomba** | `bomb_exploded(portador)` | BombManager | MatchController, HUD, AudioManager |
| **Bomba** | `bomb_time_bonus_requested(segundos)` | EffectManager | BombManager |
| **Bloques** | `lucky_block_collected(bloque, recompensa)` | LuckyBlockSpawner | HUD, AudioManager |
| **Efectos** | `effect_applied(tipo, id, duracion)` | EffectManager | AudioManager, HUD |
| **Efectos** | `effect_expired(tipo, id)` | EffectManager | AudioManager, HUD |
| **Audio** | `sfx_requested(sound_name)` | Cualquier Módulo | AudioManager |

### 12.2 Restricciones del Sistema de Física (Capas de Colisión)
El motor de física de Godot se debe parametrizar bajo la siguiente matriz de asignación estricta para evitar colisiones erróneas o traspasos de mapa no deseados:
- **Capa de Colisión 1 (Mundo):** Paredes, obstáculos estáticos del mapa y límites del escenario.
- **Capa de Colisión 2 (Personajes):** Cuerpo físico del humano y de los 9 bots (alterable dinámicamente según el rol de portador/no portador para la gestión de pasadizos).
- **Capa de Colisión 3 (Lucky Blocks):** Entidades interactivas de recompensa esparcidas por el mapa.

### 12.3 Regla de Consistencia de Datos para Modding/Balance
- **RN-06.7 Consistencia de Pesos:** En cualquier mutación, actualización o adición a la tabla de recompensas de los `Lucky Blocks`, la sumatoria total de las probabilidades (`weight`) de todas las rarezas registradas debe dar **exactamente 100**. El sistema debe contar con una prueba unitaria automatizada que impida la compilación o exportación si esta regla se rompe.

---

## Pendiente

- Duración final de efectos y valores de `VELOCIDAD_BASE`, cantidad de bloques y reaparición (hoy son [param]).
- Reglamento de la jam (por ahora solo se entrega en GitHub).

## Recorte si falta tiempo (de menos a más crítico)

Audio (RF-09b) → segundo mapa → efecto dorado → marcado.
