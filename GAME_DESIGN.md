# Maze Defense — Documento de Design

Tower defense estilo labirinto (mazing), jogo completo single-player, sem login.

## Tecnologia

- **Engine:** Godot 4 (versão estável mais recente)
- **Linguagem:** GDScript com tipagem estática
- **Plataforma:** Desktop (Windows/Linux)
- **Arte:** Pixel art com assets CC0 (Kenney.nl — tower defense packs)
- **Áudio:** SFX + 1-2 trilhas de packs livres (Kenney Audio / OpenGameArt), volumes separados (música/SFX)
- **Idioma da UI:** Português (pt-BR), strings centralizadas para facilitar tradução futura

## Mecânica Central — Labirinto

- Grade aberta: inimigos vão do ponto de entrada à saída pelo caminho mais curto (A*)
- O jogador constrói torres em qualquer célula livre para formar labirintos
- **Regra anti-bloqueio:** construção que fecharia completamente o caminho é proibida (preview da célula fica vermelho)
- **Construção/venda permitida durante a onda**, com reroteamento imediato dos inimigos em rota
- Venda devolve 70% do valor investido (permite refazer o labirinto)

## Estrutura — 3 Mapas

Desbloqueados em sequência, variando:
- Tamanho da grade
- Posição de entrada/saída
- Obstáculos fixos (rochas/água — células não construíveis)
- ~15-20 ondas cada, dificuldade crescente
- Mapas definidos por dados (TileMap/JSON) para baratear criação

## Torres (4 tipos × 3 níveis)

| Torre | Perfil | Mira |
|-------|--------|------|
| Arqueira | Tiro rápido, dano baixo | Primeiro da fila |
| Canhão | Lento, dano em área | Primeiro da fila |
| Gelo | Aplica lentidão | Primeiro da fila |
| Sniper | Alcance longo, dano alto | Mais forte |

- 3 níveis de upgrade por torre (dano/alcance/velocidade), comprados com ouro
- Mira com comportamento fixo por torre (sem UI de seleção na v1)

## Inimigos (4 terrestres + boss)

| Tipo | Perfil |
|------|--------|
| Normal | Baseline |
| Rápido | Veloz, pouca vida |
| Tanque | Lento, muita vida |
| Blindado | Resiste a dano físico, fraco contra gelo/área |
| Boss | A cada 10 ondas; muita vida, tira 5 vidas se vazar |

- Todos terrestres (seguem o labirinto) — sem voadores na v1

## Economia e Ritmo

- Ouro por inimigo morto + bônus ao fim de cada onda
- 20 vidas; inimigo que vaza tira 1 (boss tira 5)
- Jogador inicia cada onda manualmente; chamar cedo dá bônus de ouro proporcional ao tempo restante
- Botão de velocidade 1x/2x/3x
- Tempo livre entre ondas para construir/vender

## Persistência (local, sem login)

- Arquivo JSON em `user://`: mapas desbloqueados, melhor onda/estrelas por mapa, preferências de áudio
- Sem save mid-game (sessões de 15-30min)

## Telas

Menu principal → Seleção de mapa → Jogo (HUD: ouro, vidas, onda, botões de torre, velocidade, próxima onda) → Pause → Vitória/Derrota

## Fora de escopo da v1 (candidatos a v1.1+)

- Inimigos voadores + torre anti-aérea
- Prioridade de mira selecionável por torre
- Upgrades ramificados de torre
- Juros sobre ouro guardado
- Save mid-game
- Tradução en
- Export web/mobile
