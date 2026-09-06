# Auditoria do Agente Crítico Rigoroso — aprovação por tela

Processo Criador → Crítico → Ajustes executado por tela, com validação visual contra as
referências reais do Xbox Series X/S (ver `referencias-visuais.md`). Evidências em
`docs/screenshots/` (renderizadas a 1920x1080 via harness `--qa`).

| # | Tela | Ciclos | Veredito final | Motivo da aprovação |
|---|------|--------|----------------|---------------------|
| 1 | **Home** | 3 | ✅ **APROVADA — nível AAA** | Hero rotativo com crossfade+Ken Burns e arte ambiente que "sangra" no fundo (idêntico ao modelo 2.0 do Xbox); tiles quadrados com pílula ANDROID/EM BREVE e borda de foco verde + escala com easing cubic; abas com underline verde; cartões largos coloridos no padrão "Browse the store"; footer de dicas de botões. |
| 2 | **Loja** | 3 | ✅ **APROVADA — nível AAA** | Skeleton loading com shimmer na 1ª abertura (nada de placeholder cinza preguiçoso); fileiras Destaques/Recém-adicionados/Em breve; busca funcional com filtro ao vivo; foco automático cai no primeiro tile após o carregamento. |
| 3 | **Detalhes do jogo** | 4 | ✅ **APROVADA — nível AAA** | Release real resolvida em runtime via GitHub API (v1.0.3-android-r7, 10,0 MB); fluxo completo Baixar → progresso (MB, velocidade, ETA) → pausar/retomar/cancelar → instalar; estados instalado/em-breve com copy dedicada; screenshots reais do jogo. |
| 4 | **Coleção** | 2 | ✅ **APROVADA — nível AAA** | Estado vazio caprichado com CTA para a loja; tiles instalados herdam o foco animado da Home. |
| 5 | **Configurações** | 2 | ✅ **APROVADA — nível AAA** | Cards Fluent, toggles pill (LIGADO verde), verificação da permissão de instalação, limpeza de downloads parciais, seção Sobre com justificativa de stack. |
| 6 | **Guia lateral** | 3 | ✅ **APROVADA — nível AAA** | Acrylic blur real (screen texture), scrim, perfil com avatar, atalhos com foco verde, "Desligar" em vermelho, abre com botão Guide do gamepad ou tecla G. |

## Reprovações registradas durante os ciclos (e correções)

1. **C1** — Loja quebrada: `add_tile` rejeitava skeletons (tipo estrito) → build abortava, tela vazia. *Corrigido.*
2. **C1** — `StoreService` nunca chamava `http.request()` → detalhes ficava eternamente em skeleton, sem botão Baixar. *Corrigido — release real passa a resolver.*
3. **C1** — Fundo ambiente quase invisível vs. referência. *Corrigido (dark 0,22→0,30, desat 0,35→0,25).*
4. **C2** — Guia invisível: painel nunca adicionado à árvore. *Corrigido + fallback sólido sob o acrylic.*
5. **C2** — `default_focus` dos detalhes não encontrava o botão Baixar (buscava só no último filho). *Corrigido — busca em toda a caixa de ação.*
6. **C2** — `set_download_chunk_size` não existe em HTTPClient 4.4 → download não iniciava. *Corrigido (`set_read_chunk_size`).*
7. **C3** — Sublinhado das abas com largura 0 (invisível); chip "G 1 337" sem padding. *Corrigidos.*
8. **C3** — Ao pausar, barra/ETA resetavam para "Preparando download…". *Corrigido com snapshot do DownloadManager.*

## Checklist de qualidade (padrão console)

- [x] Nenhuma animação sem easing (todas cubic/sine out/in com constantes centralizadas em `AppTheme`)
- [x] Estados de carregamento (skeleton shimmer), vazio (coleção) e erro (release indisponível) desenhados de propósito
- [x] Hierarquia tipográfica consistente (Inter/InterDisplay, escala fixa de tamanhos)
- [x] Foco visível em 100% dos controles interativos, com som de tick na navegação
- [x] Navegação por toque/mouse E gamepad (D-pad, analógico com auto-repeat, ombros trocam abas, botão Guide abre o guia)
- [x] Funciona em diferentes proporções (stretch `canvas_items` + `expand`, telas com scroll vertical)
- [x] Download real validado contra a release pública do DK64 (bytes, pausa, cancelamento)
