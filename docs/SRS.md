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
| `VELOCIDAD_BASE` | 230 px/s |
| `INTERVALO_IA` | 0.25 s (con variación aleatoria de actualización) |
| `DURACION_ATAJO` | 3.2 s [param] |
| `TAMANO_MAPA` | 2400 × 1350 px (layout ampliado 1.25×) |

## Señales (contrato entre módulos)

| Señal | Emite |
|---|---|
| `match_requested(map_id)` / `menu_requested` | GameManager |
| `state_changed(new_state, old_state)` / `match_ended(player_won)` | GameManager |
| `countdown_tick(seconds_left)` / `round_started(round_number, holder)` / `character_eliminated(character)` | MatchController |
| `bomb_time_changed(time_left, duration)` / `bomb_transferred(from_holder, to_holder)` / `bomb_exploded(holder)` | BombManager |
| `lucky_block_collected(collector, reward)` | LuckyBlockSpawner |
| `effect_applied(target, effect_id, duration)` / `effect_expired(target, effect_id, reason)` | EffectManager |
| `bomb_time_bonus_requested(seconds)` / `bomb_transfer_random_requested` | EffectManager |
| `sfx_requested(sfx_name)` | Cualquier módulo |

## Reglas globales de juego

- **Impostor = portador de la bomba** (humano o bot).
- **Victoria:** ser el único sobreviviente. **Derrota:** el humano es eliminado por la explosión y la partida termina inmediatamente.
- El número de bots se conserva ajustable desde el menú (1–5 bots; un humano, valor inicial 3 bots).
- **Portador humano:** puede recoger Lucky Blocks. El minimapa, en la esquina superior derecha, solo aparece durante Radar y entonces muestra todos los personajes vivos. No puede usar atajos.
- **No portador:** no recoge Lucky Blocks y puede usar los atajos. Los bots pueden recoger bloques cuando llevan la bomba.
- No existe modo fantasma: si el humano muere, se muestran los resultados y no observa rondas posteriores. *(En el modo 2 jugadores esto aplica cuando mueren ambos humanos; ver RF-11.)*
- **Modos de juego:** 1 jugador (por defecto) y 2 jugadores locales en un mismo teclado (RF-11). El menú ofrece un botón para cada modo; el número de bots es común a ambos.

## Orden de implementación

1. Control de jugadores · 2. Mapas · 3. Bomba · 4. Partidas · 5. IA (**Fase 1: núcleo jugable**)
6. Interfaz · 7. Lucky Blocks · 8. Efectos · 9. Minimapa (**Fase 2**)
10. Audio · Pulido (**Fase 3**)

RF-10 (web) es transversal: se exporta y prueba desde la Fase 1.
RF-11 (modo 2 jugadores) se construye sobre las Fases 1 y 2 ya existentes y no cambia el modo de 1 jugador.

---

## 1. RF-03 Control de jugadores

Base compartida (`CharacterBody2D`) para el humano y el número de bots configurado en el menú.

### Movimiento con teclado (detalle de RF-03.1)

- **RF-03.1.1 Acciones del Input Map.** Se definen 4 acciones: `move_up`, `move_down`, `move_left`, `move_right`. Cada una tiene **dos teclas asignadas**:
  - Arriba: `W` y `↑`
  - Abajo: `S` y `↓`
  - Izquierda: `A` y `←`
  - Derecha: `D` y `→`
  - Las letras se asignan por **tecla física** (physical keycode) para que WASD funcione igual en teclados no QWERTY.
- **RF-03.1.2 Equivalencia.** En el modo de 1 jugador, WASD y las flechas son equivalentes y se pueden usar de forma indistinta o combinada. En el modo de 2 jugadores **dejan de ser equivalentes** y se reparten entre P1 y P2 (RF-11.2).
- **RF-03.1.3 Dirección en 8 sentidos.** La dirección se obtiene con `Input.get_vector("move_left", "move_right", "move_up", "move_down")`, que devuelve un vector **normalizado**. La velocidad diagonal es igual a la ortogonal.
- **RF-03.1.4 Teclas opuestas.** Si se pulsan dos teclas opuestas (A+D o W+S), se cancelan y el jugador no se mueve en ese eje.
- **RF-03.1.5 Velocidad.** `velocity = direccion * VELOCIDAD_BASE * multiplicador_velocidad`, aplicada con `move_and_slide()` dentro de `_physics_process`. Vista cenital (top-down), sin gravedad.
- **RF-03.1.6 Respuesta.** El movimiento es inmediato (sin aceleración ni inercia) **[param]**. Al soltar las teclas, el jugador se detiene en el mismo frame.
- **RF-03.1.7 Deslizamiento.** Al chocar con un obstáculo, el jugador desliza a lo largo de la pared en lugar de quedarse frenado.
- **RF-03.1.8 Estados de entrada.** El teclado solo mueve al personaje en estado de juego. En menú, pausa y partida terminada la entrada de movimiento se ignora.
- **RF-03.1.9 Navegador.**
  - Si la pestaña pierde el foco, se reinicia la entrada (el jugador se detiene) para evitar movimiento "pegado".
  - Las flechas no deben hacer scroll de la página mientras el canvas tiene el foco.
  - La orientación o animación del sprite según la dirección es **[param]**.

### Resto de RF-03

- **RF-03.2** Humano y bots usan la misma escena y velocidad base (230 px/s). Solo cambia la fuente de dirección (teclado o IA).
- **RF-03.3** Los jugadores colisionan con los obstáculos del mapa y no los atraviesan.
- **RF-03.4** Al escuchar `bomb_transferred`, se actualiza el rol y la capacidad de usar atajos. El portador no puede activarlos.
- **RF-03.5** El humano no portador debe pulsar su tecla de atajo (E o Espacio en 1 jugador; E para P1 y Espacio para P2 en 2 jugadores) al estar junto a la entrada marcada; estar encima no activa el atajo. Los bots conservan su activación automática al alcanzar esa entrada. Cada atajo es una zona cerrada, con una única entrada y una salida de sentido único. Solo la animación controlada de 3.2 s atraviesa la zona: no hay movimiento libre dentro de ella. Ningún personaje puede entrar caminando; el portador choca con el perímetro y no puede activar el acceso. El atajo queda bloqueado durante todo el cruce y el personaje no puede recibir ni transferir la bomba hasta salir. La salida no permite volver a entrar. Sonido del atajo: ver RF-09b.8.
- **RF-03.6** Al ser eliminado, el humano termina la partida inmediatamente; no existe modo fantasma. *(En 2 jugadores la partida solo termina cuando mueren los dos; ver RF-11.5.)*
- **RF-03.8** `PlayerCharacter` tiene un `player_index` (0 = jugador único, 1 = P1, 2 = P2) que decide qué acciones del Input Map lee (`move_*`/`shortcut`, `p1_*` o `p2_*`). La petición de atajo se expone con el método virtual `Character.wants_shortcut()` (los bots no lo usan: entran solos).
- **RF-03.7** La velocidad es modificable por el sistema de efectos mediante multiplicadores positivos, sin tocar `VELOCIDAD_BASE`.

**Aceptación**
- Los 4 pares de teclas mueven al personaje en su dirección.
- En diagonal, la velocidad es igual a la ortogonal.
- A+D pulsadas a la vez no mueven al jugador.
- El jugador no atraviesa obstáculos y desliza por las paredes.
- Al cambiar de pestaña y volver, el jugador no sigue moviéndose solo.
- El portador no entra a la zona cerrada; el no portador debe interactuar con la entrada para iniciar el cruce de 3.2 s. No se puede entrar caminando, volver a entrar por la salida ni moverse libremente durante el cruce. Mientras un personaje lo usa, nadie más puede iniciar ese atajo y no puede recibir ni transferir la bomba.
- El humano eliminado pasa directamente a resultados, sin observar a los bots.

---

## 2. RF-02 Mapas

- **RF-02.1** Existen 2 escenarios 2D distintos y ampliados (2400 × 1350 px), con obstáculos, zonas de atajo y puntos de aparición.
- **RF-02.2** Cada mapa tiene 10 puntos de aparición; se usan tantos como jugadores indique el menú.
- **RF-02.3** Cada mapa contiene al menos dos zonas cerradas de atajo, cada una con entrada y salida únicas y en un solo sentido. Solo un no portador puede activar el traslado al interactuar con la entrada según RF-03.5.
- **RF-02.4** Cada mapa define puntos de aparición de Lucky Blocks (≥ `MAX_LUCKY_BLOCKS`).
- **RF-02.5** Cada mapa genera una zona navegable (`NavigationRegion2D`) que excluye obstáculos y entradas de atajo. Los bots sin bomba pueden buscar una entrada y usar la animación del atajo; los portadores quedan impedidos por las barreras físicas.
- **RF-02.6** Los dos mapas son visualmente distintos.
- **RF-02.7** Al iniciar una partida se elige un mapa (aleatorio o por selección) **[param]**.

**Aceptación:** todos los puntos de aparición son alcanzables y ningún bot nace atrapado.

---

## 3. RF-05 Gestión de la bomba

- **RF-05.1** Temporizador **global** de 60 s. No se reinicia al transferir; solo se reinicia a 60 s tras una explosión.
- **RF-05.2** Al iniciar cada ronda, el portador se elige al azar entre los jugadores vivos configurados.
- **RF-05.3** La transferencia ocurre por colisión, y solo si uno de los dos jugadores es el portador. Si dos no portadores chocan, no pasa nada.
- **RF-05.4** Cooldown global de 1.5 s entre transferencias, administrado por el gestor de bomba.
- **RF-05.5** Al terminar el cooldown, se comprueba la proximidad al portador. Si hay jugadores en contacto, se transfiere al **más cercano** que no esté cruzando un atajo.
- **RF-05.6** Al llegar a 0, el portador explota y emite `bomb_exploded`; el controlador elimina al portador y emite `character_eliminated`.
- **RF-05.7** Si la explosión no termina la partida, se inicia otra ronda con un jugador vivo al azar y 60 s nuevos. La muerte del humano termina la partida inmediatamente.
- **RF-05.8** Un jugador eliminado o que esté cruzando un atajo nunca recibe la bomba.
- **RF-05.9** El módulo expone `add_time(s)` y `transfer_to_random()` para efectos. La transferencia aleatoria no reinicia el temporizador.

**Aceptación:** pasar la bomba con 5 s restantes deja 5 s. No hay rebotes durante el cooldown. Con 2 vivos y una explosión, la partida termina.

---

## 4. RF-01 Gestión de partidas

- **RF-01.1** Estados: `MENÚ → JUGANDO → TERMINADA`. La partida se inicia desde el menú.
- **RF-01.2** Al iniciar: carga el mapa seleccionado, instancia 1 humano (2 en modo 2 jugadores) + 1–10 bots (inicial 3; en 2 jugadores el máximo efectivo es 10 porque el mapa tiene 12 puntos de aparición), asigna puntos de aparición y arranca la bomba.
- **RF-01.3** Al recibir `character_eliminated`, se marca al jugador fuera. Si es el humano, la partida termina y se muestran resultados.
- **RF-01.4** La partida termina al morir el humano o cuando no quedan bots vivos; emite `match_ended(player_won)`. *(En 2 jugadores: ver RF-11.5.)*
- **RF-01.5** Victoria si el ganador es el humano. Derrota y fin inmediato si fue eliminado.
- **RF-01.8** `GameManager` guarda el modo elegido (`two_players`) y, al terminar, quién ganó (`winner_label`: `"P1"`, `"P2"` o vacío). La señal `match_ended(player_won)` **no cambia** de firma. Reiniciar (`R` o "Jugar de nuevo") conserva el modo.
- **RF-01.6** Reiniciar limpia efectos, bloques y jugadores, y comienza una partida nueva.
- **RF-01.7 Máquina de Estados Global (`GameManager.State`):** El sistema debe regirse estrictamente por una máquina de estados centralizada que controle el flujo del juego, ignorando inputs no correspondientes al estado activo:
  - `MENU`: Estado inicial. Transiciona a `COUNTDOWN` mediante la señal `match_requested`.
  - `COUNTDOWN`: Cuenta regresiva de congelamiento (3 segundos). Transiciona a `PLAYING`.
  - `PLAYING`: Estado de juego activo. Puede pausarse (`PAUSED`) con la tecla `Esc` o transicionar a `ROUND_END` tras la explosión de la bomba.
  - `PAUSED`: Suspende temporalmente el procesamiento del juego. Devuelve a `PLAYING` con `Esc` o a `MENU` mediante `go_to_menu()`.
  - `ROUND_END`: Pausa técnica de 2 segundos tras eliminar un bot. Si quedan bots vivos, regresa a `COUNTDOWN`; si el humano muere o no quedan rivales, avanza a `ENDED`.
  - `ENDED`: Pantalla de resultados finales. La tecla `R` transiciona de vuelta a `COUNTDOWN`.

**Aceptación:** la derrota termina cuando explota la bomba en el humano; la victoria ocurre cuando ya no quedan bots. Reiniciar no deja estado de la partida anterior.

---

## 5. RF-04 Inteligencia artificial

- **RF-04.1** Los bots usan la misma escena de RF-03 y navegan con `NavigationAgent2D` sobre el mapa generado, con evasión física de obstáculos.
- **RF-04.2** **Bot portador:** persigue al jugador vivo más cercano (humano o bot). Excluye a los eliminados.
- **RF-04.3** Si hay un Lucky Block más cerca que ese jugador, va primero al bloque. Tras recogerlo, vuelve a elegir al jugador más cercano. Conoce todos los bloques, sin rango de visión.
- **RF-04.4** **Bot no portador:** huye del portador y puede dirigirse a un atajo seguro para cambiar de zona.
- **RF-04.5** El bot cambia de comportamiento al detectar el cambio de rol en `bomb_transferred`.
- **RF-04.6** El objetivo se recalcula cada `INTERVALO_IA`, no cada frame.
- **RF-04.7** El bot portador no activa ni atraviesa atajos.
- **RF-04.8** Si el bot portador está pegado a un jugador durante el cooldown, espera. La resolución la hace RF-05.5.

**Aceptación:** con 5 bots a la vez, el juego se mantiene fluido. El bot portador alcanza objetivos y el que huye puede usar atajos.

---

## 6. RF-09a Interfaz de usuario

- **RF-09a.1** HUD: temporizador de la bomba (mm:ss), jugadores vivos y ronda actual; indica quién tiene la bomba.
- **RF-09a.2** El personaje portador muestra un icono de bomba encima.
- **RF-09a.3** Feedback del cooldown de transferencia (parpadeo del nuevo portador).
- **RF-09a.4** Indicador de efectos activos y su tiempo restante.
- **RF-09a.5** Pantalla de resultados: victoria o derrota, con opciones de reiniciar y volver al menú.
- **RF-09a.6** Al morir el humano, se muestra derrota sin modo fantasma.
- **RF-09a.7** El menú principal tiene el botón **"Jugar"** (1 jugador) y el botón **"2 Jugadores"**. Ambos abren primero la pantalla de reglas; en 2 jugadores esa pantalla emergente explica los controles (RF-11.3).
- **RF-09a.8** Indicador de efectos activos: en 2 jugadores cada línea lleva el prefijo del jugador (`P1:` / `P2:`). En 2 jugadores se muestra además, abajo, un recordatorio de teclas de P1 y P2.

**Aceptación:** el HUD refleja el estado actual en todo momento.

---

## 7. RF-06 Lucky Blocks

| Block | Rareza | Probabilidad | Efectos |
|---|---|---|---|
| Cobre | Común | 74 % | Velocidad +25 % · Rastreo de jugadores · +30 s |
| Plateado | Especial | 25 % | Velocidad +50 % |
| Dorado | Legendario | 1 % | Pasar la bomba a otro jugador al azar |

- **RF-06.1** Cada bloque generado tiene un tipo según las probabilidades de la tabla.
- **RF-06.2** Al recogerlo, se elige uniformemente un efecto de esa rareza.
- **RF-06.3** Aparecen hasta `MAX_LUCKY_BLOCKS` (4) a la vez en los puntos del mapa y reaparecen tras `RESPAWN_BLOCK` (15 s).
- **RF-06.4** Solo el portador humano los ve en el mundo; cualquier bot portador puede recogerlos. Ningún bloque aparece en el minimapa. Audio de recogida: ver RF-09b.5 y RF-09b.7.
- **RF-06.5** Al cambiar el portador, la visibilidad de los bloques cambia de inmediato.
- **RF-06.6** Emite `lucky_block_collected(collector, reward)`.

**Aceptación:** una simulación de ≥1000 bloques se acerca a 74/25/1. Un no portador no puede ver ni recoger bloques.

---

## 8. RF-07 Efectos temporales

| Efecto | Origen | Objetivo | Duración |
|---|---|---|---|
| Velocidad +25 % | Cobre | Portador | `DURACION_EFECTO` |
| Rastreo de jugadores | Cobre | Minimapa del portador | `DURACION_EFECTO` |
| +30 s | Cobre | Temporizador | Instantáneo |
| Velocidad +50 % | Plateado | Portador | `DURACION_EFECTO` |
| Bomba a otro al azar | Dorado | Bomba | Instantáneo |

- **RF-07.1** Aplicar un efecto emite `effect_applied`; retirarlo emite `effect_expired`. Sonido de pérdida: ver RF-09b.6.
- **RF-07.2** Los efectos de velocidad se aplican como multiplicadores y se retiran restaurando el valor base, sin acumular errores.
- **RF-07.3** Si se repite el mismo efecto, se reinicia su duración (no se acumula) **[asumido]**.
- **RF-07.4** Los efectos ligados al portador se retiran al transferir la bomba.
- **RF-07.5** "Bomba a otro al azar" elige a un jugador vivo distinto del portador y de los eliminados, sin reiniciar el temporizador.
- **RF-07.6** Al eliminar a un jugador o terminar la partida, se limpian sus efectos.
- **RF-07.7** El +30 s se suma al tiempo restante, sin tope **[asumido]**.

**Aceptación:** tras cada efecto, la velocidad vuelve exactamente al valor base. El +30 s no reinicia el tiempo.

---

## 9. RF-08 Minimapa

- **RF-08.1** El minimapa se ubica arriba a la derecha, en una capa visible sobre el HUD, y permanece oculto excepto mientras el humano que lleva la bomba tenga activo el efecto Radar.
- **RF-08.2** Durante Radar muestra el mapa de referencia y la posición de todos los personajes vivos; el humano se distingue visualmente. En 2 jugadores el minimapa aparece si **cualquiera** de los dos humanos lleva la bomba y tiene Radar, y P1/P2 se dibujan con su propio color.
- **RF-08.3** Al vencer Radar o transferirse la bomba, el minimapa se oculta inmediatamente. Los Lucky Blocks no se dibujan en él.
- **RF-08.4** El rastreo y el minimapa duran `DURACION_EFECTO` (10 s).

**Aceptación:** al transferirse la bomba, el minimapa del humano cambia en el mismo frame.

---

## 10. RF-09b Audio

- **RF-09b.1** Sonidos para transferencia, explosión, recogida de bloque (uno por rareza), efecto activado, pérdida de efecto, atajo, cuenta final del temporizador (dura lo que dure el audio definitivo; el umbral de inicio es **[param]**), victoria y derrota.
- **RF-09b.2** Música procedural de fondo con control de volumen.
- **RF-09b.3** Los sonidos se reproducen en respuesta a señales, sin código de audio en otros módulos.
- **RF-09b.4** El audio se inicia tras la primera interacción del usuario (restricción de los navegadores).

### 10.1 SFX de Lucky Blocks

- **RF-09b.5** Existen tres sonidos de recogida distintos, uno por rareza: Cobre (Común), Plateado (Especial) y Dorado (Legendario). El sonido depende de la rareza del bloque, no del efecto obtenido (RF-06.2).

### 10.2 SFX de pérdida de efectos

- **RF-09b.6** Existe un sonido propio de pérdida de efecto temporal, distinto del sonido de efecto activado, asociado a `effect_expired` (RF-07.1). Los efectos instantáneos (+30 s y Bomba a otro al azar) no tienen duración, por lo que no generan este sonido. El sonido de pérdida se reproduce cuando un efecto temporal se retira durante la partida, ya sea por expiración natural de su duración o por retirada al transferirse la bomba (RF-07.4). No se reproduce en estos casos: (a) cuando el portador, humano o bot, es eliminado por la explosión con un efecto temporal activo, donde solo suena la explosión; (b) cuando los efectos se limpian por el fin de la partida (RF-07.6), incluido el reinicio de la partida (`R`, RF-01.7) y la salida al menú desde `PAUSED` mediante `go_to_menu()`.

### 10.3 Reglas de audibilidad según el portador

- **RF-09b.7** El sonido de recogida de un Lucky Block solo se reproduce cuando el humano es el portador de la bomba en el momento de la recogida. Si un bot portador recoge un bloque, el humano no escucha ese evento.
- **RF-09b.7.1** El filtro por portador lo aplica el AudioManager al recibir `lucky_block_collected`, sin código de audio en otros módulos (RF-09b.3).

### 10.4 SFX de atajos

- **RF-09b.8** Todos los atajos de todos los mapas comparten un único sonido tipo «whoosh». No existen sonidos distintos por atajo ni por tipo de atajo.

**Aceptación**
- Recoger un bloque de cada rareza (Cobre, Plateado, Dorado) produce tres sonidos distintos.
- Si el humano es el portador y recoge un bloque, se reproduce el sonido de recogida correspondiente a la rareza del bloque.
- Si un bot portador recoge un bloque, el humano no escucha el sonido de recogida.
- Todos los atajos de ambos mapas reproducen el mismo sonido.
- La pérdida de un efecto temporal suena distinto de su activación.
- Si un efecto temporal expira de forma natural durante la partida, se reproduce el SFX de pérdida.
- Si un efecto temporal se retira al transferirse la bomba, se reproduce el SFX de pérdida.
- Si el portador explota con un efecto temporal activo, solo se reproduce el sonido de explosión, sin SFX de pérdida de efecto.
- Al finalizar la partida (por resultados, reinicio con `R` o salida al menú desde `PAUSED`), no se reproduce el SFX de pérdida de efecto.
---

## 11. RF-10 Compatibilidad web (transversal)

- **RF-10.1** Exportación HTML5 con Godot 4.x, probada en Chrome.
- **RF-10.2** No requiere instalación: se abre desde una URL.
- **RF-10.3** Rendimiento estable con el máximo configurable actual (1 humano + 5 bots).
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
| *(sin señal nueva)* | El ganador de 2 jugadores se lee de `GameManager.winner_label` al recibir `match_ended`. | GameManager | HUD |
| **Bomba** | `bomb_time_changed(tiempo_restante, duracion)`| BombManager | AudioManager |
| **Bomba** | `bomb_transferred(from_player, to_player)` | BombManager | AudioManager, Minimapa |
| **Bomba** | `bomb_exploded(portador)` | BombManager | MatchController, HUD, AudioManager |
| **Bomba** | `bomb_time_bonus_requested(segundos)` | EffectManager | BombManager |
| **Bomba** | `bomb_transfer_random_requested` | EffectManager | BombManager |
| **Bloques** | `lucky_block_collected(collector, reward)` | LuckyBlockSpawner | HUD, AudioManager |
| **Efectos** | `effect_applied(tipo, id, duracion)` | EffectManager | AudioManager, HUD |
| **Efectos** | `effect_expired(tipo, id, motivo)` | EffectManager | AudioManager, HUD |
| **Audio** | `sfx_requested(sound_name)` | Cualquier Módulo | AudioManager |

### 12.2 Restricciones del Sistema de Física (Capas de Colisión)
El motor de física de Godot se debe parametrizar bajo la siguiente matriz de asignación estricta para evitar colisiones erróneas o traspasos de mapa no deseados:
- **Capa de Colisión 1 (Mundo):** Paredes, obstáculos estáticos del mapa y límites del escenario.
- **Capa de Colisión 2 (Personajes):** Cuerpo físico del humano y bots configurados.
- **Capa de Colisión 3 (Lucky Blocks):** Entidades interactivas de recompensa esparcidas por el mapa.
- **Capa de Colisión 4 (Atajos):** Barreras activas para portadores; los no portadores excluyen esa capa.

### 12.3 Regla de Consistencia de Datos para Modding/Balance
- **RN-06.7 Consistencia de Pesos:** En cualquier cambio a la tabla de recompensas, la suma de los pesos (`weight`) debe dar **exactamente 100**. La prueba unitaria falla si se rompe y el script de exportación Web cancela la exportación cuando falla cualquier prueba.

---

## 13. RF-11 Modo 2 jugadores

Modo local para dos personas en el mismo teclado y **la misma pantalla** (no hay pantalla dividida). Los bots siguen presentes (mismo ajuste de menú).

- **RF-11.1 Acceso.** El menú principal incluye el botón "2 Jugadores". Al pulsarlo se muestra la pantalla de reglas en versión 2 jugadores y, al confirmar con "¡Entendido!", empieza la partida con `GameManager.two_players = true`. "Jugar" sigue iniciando el modo de 1 jugador.
- **RF-11.2 Jugadores y controles.** Aparecen dos humanos identificados como **P1** (azul) y **P2** (turquesa); el nombre bajo cada personaje y los mensajes usan esas etiquetas. Cada uno tiene sus propias acciones del Input Map, definidas por tecla física:

| Jugador | Mover | Atajo | Acciones |
|---|---|---|---|
| P1 | `W` `A` `S` `D` | `E` | `p1_up/down/left/right`, `p1_shortcut` |
| P2 | `↑` `←` `↓` `→` | `Espacio` | `p2_up/down/left/right`, `p2_shortcut` |

  Las acciones del modo 1 jugador (`move_*`, `shortcut`) se conservan sin cambios.
- **RF-11.3 Pantalla emergente de controles.** Antes de empezar, la pantalla de reglas (título "CÓMO SE JUEGA · 2 JUGADORES") indica: P1 se mueve con W A S D y usa los atajos con E; P2 se mueve con las flechas y usa los atajos con Espacio. También explica la cámara compartida y la condición de victoria. "Volver" o `Esc` cancelan sin iniciar la partida.
- **RF-11.4 Cámara compartida (`DualCamera`).** Una única cámara se centra en el **punto medio** de los jugadores enfocados y ajusta el zoom para que todos aparezcan siempre (con un margen de 220 px **[param]**): si se separan se aleja, si se juntan se acerca hasta el zoom normal (1.0). La cámara **no tiene límites de mapa**: el zoom mínimo es el que muestra el mapa completo **más el margen**, de modo que con los jugadores en esquinas opuestas ambos siguen en pantalla. Todo lo que queda fuera de los bordes del mapa se ve **negro** (`TiledMap.OutsideMask`); los jugadores no pueden salir porque el mapa tiene paredes perimetrales. El suavizado de posición y de zoom depende de `delta`, no de frames.
- **RF-11.5 Muerte y fin de partida.**
  - Si un jugador muere y el otro sigue vivo, la partida continúa. La cámara pasa a enfocar **solo al jugador vivo a partir de la siguiente ronda** (durante el `ROUND_END` aún se ve la explosión).
  - Si mueren los dos, la partida termina como siempre (`ENDED`, derrota) con las mismas opciones: jugar de nuevo y menú.
  - **Victoria:** cuando no quedan bots y queda un solo jugador vivo, gana ese jugador. Si no quedan bots pero siguen vivos los dos, las rondas continúan hasta que quede uno **[asumido]**.
- **RF-11.6 Mensajes de resultado.** Victoria: "¡GANÓ P1!" o "¡GANÓ P2!" según el jugador que queda vivo, con las mismas opciones de siempre ("Jugar de nuevo (R)" y "Menú"). Derrota (mueren ambos): "¡DERROTA!" con el número de ronda. En 1 jugador los textos "¡VICTORIA!" / "¡DERROTA!" no cambian.
- **RF-11.7 Bomba, Lucky Blocks y habilidades.** Las reglas de RF-05, RF-06 y RF-07 no cambian: solo quien lleva la bomba recoge Lucky Blocks y solo a él se le aplican los efectos. Mientras **cualquiera** de los dos humanos lleve la bomba, los Lucky Blocks se ven en el mapa y las habilidades activas se listan en pantalla para ambos (con prefijo `P1:`/`P2:`); el jugador sin bomba puede verlos pero **no recibe ningún buff**. Los efectos que marcan a los rivales (Radar) pueden marcar también al otro jugador.
- **RF-11.8 Pausa y reinicio.** `Esc`/`P` y `R` funcionan igual en ambos modos; `R` reinicia en el mismo modo.

**Aceptación**
- Desde el menú se puede iniciar 1 jugador o 2 jugadores, y en 2 jugadores se ve la pantalla de controles de P1 y P2 antes de empezar.
- P1 solo responde a W A S D / E; P2 solo a las flechas / Espacio.
- Al separar o juntar a los jugadores, la cámara se aleja o acerca y ambos permanecen visibles; no hay pantalla dividida.
- Con P1 y P2 en esquinas opuestas del mapa, la cámara se aleja lo necesario y ambos permanecen visibles; lo que queda fuera del mapa se ve negro y los jugadores no pueden salir de él.
- Tras morir un jugador, en la ronda siguiente la cámara sigue únicamente al superviviente.
- Si mueren ambos: derrota con "Jugar de nuevo" y "Menú". Si queda uno sin bots: "¡GANÓ P1!" o "¡GANÓ P2!".
- El jugador sin bomba nunca recibe un buff de un Lucky Block.
- El modo de 1 jugador funciona exactamente como antes.

Pruebas automatizadas: `tests/unit/test_two_players.gd` y los casos nuevos de `tests/unit/test_input_map.gd`.

---

## Pendiente

- Pruebas funcionales de la exportación Web en un navegador Chrome real y publicación.
- Probar el modo 2 jugadores en una ventana real de Godot (la cámara y las pruebas GUT nuevas no se pudieron ejecutar al escribirlas) y en el navegador, incluido el ghosting de teclado cuando dos personas pulsan muchas teclas a la vez en un mismo teclado.
- Confirmar con el equipo las decisiones marcadas **[asumido]** de RF-11 (p. ej., el desempate entre P1 y P2 cuando no quedan bots).
- Balanceo de velocidad, bomba, probabilidades e IA con el equipo.
- Reglamento de la jam (por ahora solo se entrega en GitHub).

El arte y los sonidos pueden sustituirse por recursos finales sin cambiar el contrato funcional. Los RF anteriores se mantienen incluidos; la validación en Chrome real sigue pendiente.
