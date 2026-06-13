# Vertical Slice 3D (branch `3d`)

Prova de conceito da camada de apresentação 3D, validando que o núcleo do jogo
é agnóstico de dimensão. **A lógica não foi duplicada** — `GridManager`,
`MapData`, os autoloads e os `.tres` de balanceamento são os mesmos do 2D.

## O que a slice já faz

- Tabuleiro 3D no plano XZ (câmera top-down inclinada, luz direcional, ambiente)
- Picking por raycast: clique coloca/remove blocos com a **mesma** validação
  anti-bloqueio do 2D (`GridManager.validate_placement`)
- Preview verde/vermelho da célula sob o mouse
- Inimigo 3D (`Enemy3D`) andando pelo caminho A* com **reroteamento ao vivo** —
  mesmo invariante anchor=next_cell do 2D
- Marcadores do caminho entrada→saída que se atualizam a cada mudança da grade

## Como rodar

```bash
GODOT=/mnt/c/Users/luis_/godot/Godot_v4.6.3-stable_win64_console.exe
"$GODOT" --path . scenes/game_level_3d.tscn      # roda só a slice 3D
"$GODOT" --path . -s tools/screenshot_3d.gd       # gera docs/screenshot_3d.png
```

Espaço gera um inimigo; clique esquerdo coloca/remove um bloco.

## Refatoração que habilitou o reuso

`GridManager` passou de `extends Node2D` para `extends Node` (agnóstico de
dimensão). O cache de caminhos agora guarda **células cruas**
(`get_cell_path`); cada camada converte com seu helper:
`cell_to_world` (2D) ou `cell_to_world_3d` / `get_world_path_3d` (3D).
Os 48 testes do 2D continuam passando.

## Próximos passos (port completo, fora da slice)

- Modelos GLB CC0 (Kenney "Tower Defense Kit") no lugar das malhas-placeholder
- Portar `Tower`/`Projectile` para Node3D (bala de canhão em parábola, partículas)
- `EnemyRegistry` genérico ou variante 3D; reusar `Economy`/`WaveManager` (já agnósticos)
- HUD permanece 2D (Control) — sem mudança
