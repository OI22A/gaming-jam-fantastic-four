extends Node
## Bus global de eventos (autoload "GameEvents").
##
## Desacopla los módulos del juego: quien emite no conoce a quien escucha.
## Ejemplo: BombManager emite `bomb_exploded` y tanto MatchController (gestión
## de partidas), Hud (interfaz) como AudioManager (audio) reaccionan.
##
## Regla del equipo: si se agrega una señal nueva, documentarla aquí y en
## docs/ARCHITECTURE.md.

# --- Flujo de aplicación / partida (RF-01) -----------------------------------
signal match_requested(map_id: String)
signal menu_requested
signal state_changed(new_state: int, old_state: int)
signal countdown_tick(seconds_left: int)
signal round_started(round_number: int, holder: Node)
signal character_eliminated(character: Node)
signal match_ended(player_won: bool)

# --- Bomba (RF-05) ------------------------------------------------------------
signal bomb_time_changed(time_left: float, duration: float)
signal bomb_transferred(from_holder: Node, to_holder: Node)
signal bomb_exploded(holder: Node)
signal bomb_time_bonus_requested(seconds: float)
signal bomb_transfer_random_requested

# --- Lucky Blocks y efectos (RF-06, RF-07) -----------------------------------
signal lucky_block_collected(collector: Node, reward: Dictionary)
signal effect_applied(target: Node, effect_id: String, duration: float)
enum MotivoRetiro { EXPIRACION, TRANSFERENCIA, ELIMINACION, FIN_PARTIDA }
signal effect_expired(target: Node, effect_id: String, reason: int)

# --- Audio (RF-09) ------------------------------------------------------------
signal sfx_requested(sfx_name: String)
