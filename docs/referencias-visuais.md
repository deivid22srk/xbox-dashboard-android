# Pesquisa visual — referências reais do dashboard Xbox Series X/S

**Mandatório do projeto:** nenhuma tela desenhada "de memória". As referências abaixo foram
coletadas por busca de imagens na web (fase de design, 2026-09) e usadas como validação
ativa de layout, espaçamento, hierarquia e comportamento de foco.

## Referências coletadas (buscas realizadas)

| Busca | Achado principal | Uso no projeto |
|---|---|---|
| "Xbox Series X home screen dashboard UI screenshot 2023" | Captura real da home com fundo ambiente full-bleed (The Elder Scrolls), fileira de tiles quadrados com foco verde, barra superior com avatar/gamertag/relógio | **Home** — estrutura inteira |
| "Xbox console Microsoft Store screen UI screenshot" | Captura da home/store com row "Jump back in", faixa de título sob o tile focado, pílula "GAME PASS" nos tiles, barra de dicas de botões no rodapé, busca no topo | **Loja** — tiles, badges, hint bar |
| "Xbox guide menu console overlay UI" | Referências parciais (overlay escuro translúcido) | **Guia lateral** (acrylic) |
| "Donkey Kong 64 box art" | Key art landscape + box art portrait do jogo original | **Hero/capa do item DK64** |
| "Donkey Kong 64 gameplay screenshot" | Frames reais de gameplay | **Screenshots na tela de detalhes** |

## Tokens de design extraídos das capturas (aplicados em `AppTheme.gd`)

- **Fundo:** o dashboard real NÃO usa preto chapado — a arte do conteúdo em foco vira
  ambiente full-bleed escurecido (~70%) atrás da UI. → shader `ambient_blur.gdshader`.
- **Verde Xbox:** `#107C10` (marca), borda de foco verde vivo `#61B74E`.
- **Superfícies:** cartões `#1E1E1E`→`#252525`, radius ~10px, sem sombras duras.
- **Tipografia:** Segoe UI Bold/Regular (sentence case). No projeto: **Inter** (SIL OFL),
  a substituta livre mais próxima disponível; Display SemiBold/Bold para títulos.
- **Barra superior:** avatar circular + gamertag + score à esquerda; ícones de contexto ao
  centro; relógio `hh:mm am/pm` à direita. Altura ~72px @1080p.
- **Tiles:** quadrados ~150px @1080p, gap ~16px, radius 10px; badges canto inferior
  ("X\|S", pílula "GAME PASS" branca com texto preto).
- **Foco (assinatura do console):** borda verde ~3px + escala ~1.12 + **título do jogo em
  faixa abaixo do tile focado**; easing cubic-out ~0.16s; som de tick na navegação.
- **Fileiras:** título de seção ~26px semibold à esquerda; scroll horizontal suave que
  "acompanha" o foco.
- **Rodapé de contexto:** dicas de botões ("A Selecionar · B Voltar · Y Buscar") no canto.
- **Transições:** fade/slide curto entre abas; hero com crossfade + leve Ken Burns.

## Descisões derivadas

1. A Home replica o modelo 2.0: ambiente = arte do hero, tiles começam abaixo da barra
   superior, primeira fileira = "Continuar jogando/Recomendados".
2. A Loja segue o padrão de fileiras + cartões largos coloridos para categorias.
3. O guia lateral usa acrylic blur real (screen texture) como no Fluent Design.
4. Todo texto de UI em pt-BR (o console simula região do usuário), formatos de hora 24h.

*Capturas de tela das referências ficam fora do repositório (diretórios locais) por
respeito a direitos autorais; os tokens acima são a destilação delas.*
