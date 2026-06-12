extends Node
## Todas as strings visíveis ao jogador (pt-BR), centralizadas.
## Trocar este arquivo (ou o dicionário) = traduzir o jogo.

const _TEXTS: Dictionary = {
	&"GAME_TITLE": "Maze Defense",
	&"UI_GOLD": "Ouro",
	&"UI_LIVES": "Vidas",
	&"UI_WAVE": "Onda %d/%d",
	&"UI_NEXT_WAVE": "Próxima onda",
	&"UI_EARLY_BONUS": "+%d ouro",
	&"UI_SPEED": "%dx",
	&"UI_UPGRADE": "Melhorar (%d)",
	&"UI_SELL": "Vender (%d)",
	&"UI_LEVEL": "Nível %d",
	&"UI_DAMAGE": "Dano",
	&"UI_RANGE": "Alcance",
	&"UI_FIRE_RATE": "Cadência",
	&"UI_PLAY": "Jogar",
	&"UI_SETTINGS": "Opções",
	&"UI_QUIT": "Sair",
	&"UI_BACK": "Voltar",
	&"UI_CONTINUE": "Continuar",
	&"UI_RESTART": "Reiniciar",
	&"UI_NEXT_MAP": "Próximo mapa",
	&"UI_MAIN_MENU": "Menu principal",
	&"UI_ABANDON": "Abandonar partida",
	&"UI_MUSIC_VOLUME": "Música",
	&"UI_SFX_VOLUME": "Efeitos",
	&"UI_PAUSED": "Pausado",
	&"UI_VICTORY": "Vitória!",
	&"UI_DEFEAT": "Derrota",
	&"UI_BEST_WAVE": "Melhor onda: %d",
	&"UI_MAP_SELECT": "Escolha o mapa",
	&"UI_LOCKED": "Bloqueado",
	&"MSG_BLOCKED": "Não pode bloquear o caminho!",
	&"MSG_NO_GOLD": "Ouro insuficiente",
	&"MSG_ENEMY_ON_CELL": "Há um inimigo nesta célula",
	&"MSG_CELL_OCCUPIED": "Célula ocupada",
	&"TOWER_ARCHER": "Arqueira",
	&"TOWER_CANNON": "Canhão",
	&"TOWER_ICE": "Gelo",
	&"TOWER_SNIPER": "Sniper",
	&"ENEMY_NORMAL": "Normal",
	&"ENEMY_FAST": "Rápido",
	&"ENEMY_TANK": "Tanque",
	&"ENEMY_ARMORED": "Blindado",
	&"ENEMY_BOSS": "Chefe",
	&"MAP_01": "Campo Aberto",
	&"MAP_02": "Desfiladeiro",
	&"MAP_03": "Fortaleza",
}


func get_text(key: StringName) -> String:
	assert(_TEXTS.has(key), "String não cadastrada: %s" % key)
	return _TEXTS.get(key, str(key))
