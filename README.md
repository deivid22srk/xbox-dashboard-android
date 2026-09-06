# SeriesDash — Dashboard estilo Xbox Series S para Android

Launcher de console para Android que reproduz a experiência da home do **Xbox Series S/X**:
hero banner rotativo com parallax, fileiras horizontais de tiles, foco visual nítido
(toque, mouse e **gamepad físico Bluetooth/USB**), acrylic blur, micro-animações em toda
a navegação e uma **loja de jogos funcional** com download + instalação real de APK.

> Projeto de estudo/fã, sem qualquer afiliação com Microsoft, Xbox, Nintendo ou Rare.
> Marcas e artes de jogos pertencem aos seus respectivos donos e são usadas apenas como
> referência demonstrativa no catálogo de exemplo.

---

## 1. Escolha de stack (justificativa)

**Restrição do projeto:** nenhuma linha de Java, Kotlin ou Dart/Flutter na interface ou
na lógica do aplicativo. Zero HTML/WebView.

| Opção avaliada | Veredito | Motivo |
|---|---|---|
| **Godot 4 + GDScript** ✅ | **Escolhida** | Engine 2D madura com sistema de UI (Control), tweens, shaders canvas e input de gamepad nativo — exatamente o ferramental de um dashboard "AAA" (parallax, acrylic blur, foco animado). Export Android oficial e reprodutível em CI headless. Toda a UI e toda a lógica ficam em GDScript (não-Java, não-Kotlin, não-Dart). |
| Unity + C# | Descartada | Exige ativação de licença em CI (frágil/pago), build pesada para uma UI 2D e editor obrigatório (não headless-friendly). |
| C++/NDK + Skia | Descartada | Custo de engenharia desproporcional para UI 2D; nada de animação/tween/shader pronto; risco deperformance alto. |
| Web em WebView | Descartada pelo escopo | A qualidade de animação 60fps e o suporte a D-pad exigiriam muito trabalho manual; e o projeto proíbe HTML. |

### O "cascão" nativo (mínimo e permitido)

O APK exportado pelo Godot contém, por natureza, uma camada Java do próprio motor
(bootstrap de activity/audio/input). Além disso existe **um único arquivo Java do projeto**:
`android/plugins/InstallBridge/src/.../InstallBridge.java` (~100 linhas).

Ele existe **exclusivamente** para o escopo de "empacotamento/permissões/instalador"
explicitamente permitido como cascao, e não contém nenhuma UI nem lógica de aplicativo:

- `installApk(path)` — cria intent `ACTION_VIEW` (`application/vnd.android.package-archive`)
  via `FileProvider` para acionar o instalador do Android;
- `canInstallPackages()` / `openInstallPermissionSettings()` — consulta/abre a permissão
  "instalar apps desconhecidos";
- `isPackageInstalled(pkg)` / `launchApp(pkg)` — checagem de coleção e atalho "Abrir".

Toda a **UI, animações, navegação, catálogo, downloads, estados e regras** vivem em GDScript.

**Integração com o build**: o Godot 4.4 não compila fontes Java declarados em `.gdap` (esse
mecanismo exige AAR pré-compilado). Por isso o script `tools/setup_android_template.py`
(no CI e no setup local) copia o `InstallBridge.java` para dentro do módulo `app` do
template gradle (compilado junto do aplicativo) e o registra no manifest via
`<meta-data android:name="org.godotengine.plugin.v2.InstallBridge" .../>` — o
`GodotPluginRegistry` do Godot instancia a classe por reflexão em runtime, expondo-a
como singleton `InstallBridge` para o GDScript. Sem AAR, sem gdap, sem passo extra.

---

## 2. Arquitetura

```
├── project.godot              # config do projeto (1920x1080, gl_compatibility, paisagem)
├── export_presets.cfg         # preset Android (gradle build, arm64, package com.deivid22srk.seriesdash)
├── data/catalog.json          # CATÁLOGO DA LOJA (edite aqui para adicionar jogos)
├── scenes/Main.tscn           # cena raiz mínima — toda a UI é construída em código
├── scripts/
│   ├── Main.gd                # bootstrap, abas, pilha de navegação, transições de tela
│   ├── AppTheme.gd            # tokens de design (cores/tipografia/estilos) — Fluent-dark
│   ├── UiLib.gd               # fábricas de componentes (tiles, chips, gradientes, skeletons)
│   ├── ScreenHome.gd          # hero rotativo + fileiras de tiles
│   ├── ScreenStore.gd         # loja (skeleton → catálogo)
│   ├── ScreenDetails.gd       # detalhes do jogo + fluxo de download/instalação
│   ├── ScreenCollection.gd    # minha coleção (instalados)
│   ├── ScreenSettings.gd      # configurações (sons, permissões, sobre)
│   ├── GuidePanel.gd          # "guia" lateral com acrylic blur
│   ├── HeroCarousel.gd        # banner rotativo com parallax e Ken Burns
│   ├── TileRow.gd/TileButton.gd  # fileiras horizontais + tiles com foco animado
│   ├── StoreService.gd        # catálogo local + GitHub API (release mais recente)
│   ├── DownloadManager.gd     # download HTTP streaming com pausa/retomada (Range) e progresso
│   ├── InstallBridge.gd       # ponte GDScript → plugin Android (no-op no desktop)
│   └── GameState.gd / Qa.gd   # estado persistente + harness de screenshots (QA)
├── shaders/                   # ambient blur, acrylic, shimmer, cantos arredondados
├── android/plugins/InstallBridge/  # fonte Java do casão (copiado p/ template gradle no build)
├── tools/setup_android_template.py # prepara o template gradle (manifest/perm/provider/fonte Java/meta-data)
└── .github/workflows/build.yml     # CI: exporta o APK e publica como artifact
```

### Fluxo da loja (download + instalação reais)

1. `data/catalog.json` descreve os itens; o item DK64 aponta para
   `deivid22srk/dk64-recomp-android` (`source.type: github_release`).
2. `StoreService` consulta a **GitHub API** em runtime (`/releases/latest`) e descobre o
   asset `.apk` real (nome, tamanho, URL, versão). Sem internet ou sem release → estado
   "Em breve" elegante, sem quebrar a loja.
3. `DownloadManager` baixa via `HTTPClient` streaming (segue redirects), com **barra de
   progresso, velocidade (MB/s), ETA, pausar/retomar (HTTP Range) e cancelar**.
4. Ao concluir, `InstallBridge.installApk()` aciona o instalador do sistema. Se necessário,
   o app direciona o usuário à permissão "Fontes desconhecidas".
5. Instalado → item aparece em **Minha Coleção** com atalho "Abrir".

### Como adicionar um jogo à loja

Edite `data/catalog.json` (autoexplicativo): `id`, `title`, `developer`, `description`,
`art.cover/hero/screenshots`, `size_estimate`, e `source` (`github_release` com `repo` +
`asset_pattern`, ou `coming_soon: true`). Nenhuma alteração de código é necessária.

---

## 3. Como compilar localmente

Requisitos: **Godot 4.4.1**, **JDK 17**, **Android SDK** (platform 34 + build-tools 34),
e o build template do Android (o CI faz isso automaticamente — veja
`tools/setup_android_template.py`).

```bash
# 1. preparar template gradle + patches de manifest (idempotente)
GODOT_TEMPLATES_DIR=~/.local/share/godot/export_templates python3 tools/setup_android_template.py

# 2. importar recursos
godot --headless --import .

# 3. exportar APK (debug-assinado)
godot --headless --export-debug "Android" build/SeriesDash.apk
```

**Nota sobre assinatura:** o CI exporta um APK **debug-assinado** (keystore de debug gerada
no pipeline), decisão documentada: um release de produção exigiria chaves privadas que não
devem viver no repositório. Para publicar em release: gere um keystore próprio e configure
os campos de keystore no preset.

### Desktop (desenvolvimento rápido)

```bash
godot --path .          # roda no desktop; InstallBridge vira no-op
godot --path . -- --qa --qa-out /tmp/qa   # gera screenshots de todas as telas (QA visual)
```

## 4. CI/CD

`.github/workflows/build.yml` dispara em push/PR/manual: instala Godot 4.4.1 + export
templates, prepara o gradle template, gera keystore de debug, importa recursos, exporta o
APK e publica como **artifact** da run. Gradle é cacheado entre execuções.

## 5. Referências visuais

O design foi validado contra capturas reais do dashboard do Xbox Series X/S —
tokens de cor, espaçamento, tipografia e comportamento de foco estão documentados em
[`docs/referencias-visuais.md`](docs/referencias-visuais.md) e aplicados em `AppTheme.gd`.
