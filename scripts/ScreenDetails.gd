class_name ScreenDetails
extends Control
## Detalhes do jogo: arte grande, metadados, screenshots, e a maquina de estados
## completa do fluxo de download + instalacao real do APK.

enum Dl { IDLE, RESOLVING, AVAILABLE, DOWNLOADING, PAUSED, FINISHED, INSTALLING, INSTALLED, UNAVAILABLE }

var game: Dictionary
var game_id := ""
var main_ref: Control

var _dl_state: int = Dl.IDLE
var _release: Dictionary = {}
var _action_box: VBoxContainer
var _progress: ProgressBar
var _progress_label: Label
var _btn_row: HBoxContainer
var _version_label: Label
var _resume_check_done := false

func setup(main, id: String) -> void:
        main_ref = main
        game_id = id
        game = GameState.game_by_id(id)

func build(main) -> void:
        main_ref = main_ref if main_ref != null else main
        var scroll := ScrollContainer.new()
        scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
        scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
        add_child(scroll)

        var col := VBoxContainer.new()
        col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        col.size_flags_vertical = Control.SIZE_EXPAND_FILL
        col.add_theme_constant_override("separation", 18)
        scroll.add_child(col)

        # --- arte hero ---
        if game.get("art", {}).has("hero"):
                var art := UiLib.tex_rect(String(game["art"]["hero"]))
                art.custom_minimum_size = Vector2(0, 320)
                art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                UiLib.rounded_mat(art, AppTheme.RADIUS_BIG)
                col.add_child(art)

        var head := VBoxContainer.new()
        head.add_theme_constant_override("separation", 6)
        col.add_child(head)

        var title := AppTheme.label(String(game.get("title", "")), 40, AppTheme.TEXT, true, true)
        head.add_child(title)
        var subtitle := AppTheme.label(String(game.get("subtitle", "")) + "   ·   " + String(game.get("developer", "")), 17, AppTheme.TEXT_DIM)
        head.add_child(subtitle)

        var chips := HBoxContainer.new()
        chips.add_theme_constant_override("separation", 8)
        for gnr in game.get("genre", []):
                chips.add_child(UiLib.chip(String(gnr)))
        head.add_child(chips)
        _version_label = AppTheme.label("", 16, AppTheme.TEXT_DIM)
        head.add_child(_version_label)

        # --- acao / download ---
        _action_box = VBoxContainer.new()
        _action_box.add_theme_constant_override("separation", 10)
        col.add_child(_action_box)

        # --- descricao ---
        var desc_title := AppTheme.label("Sobre este jogo", 22, AppTheme.TEXT, true)
        col.add_child(desc_title)
        var desc := AppTheme.label(String(game.get("description", "")), 18, Color(0.88, 0.88, 0.9))
        desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        desc.custom_minimum_size = Vector2(1200, 0)
        desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        col.add_child(desc)

        # --- screenshots ---
        var shots: Array = game.get("art", {}).get("screenshots", [])
        if not shots.is_empty():
                var s_title := AppTheme.label("Capturas de tela", 22, AppTheme.TEXT, true)
                col.add_child(s_title)
                var row := HBoxContainer.new()
                row.add_theme_constant_override("separation", 14)
                for s in shots:
                        var im := UiLib.tex_rect(String(s))
                        im.custom_minimum_size = Vector2(330, 186)
                        im.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
                        UiLib.rounded_mat(im, 8)
                        row.add_child(im)
                col.add_child(row)
        col.add_child(UiLib.spacer(0, 30))

        _set_state(Dl.RESOLVING)
        _resolve_release()

func _exit_tree() -> void:
        if main_ref != null and main_ref.has_node("Downloads"):
                main_ref.get_node("Downloads").cancel(game_id, true)

## ----------------------- maquina de estados do fluxo -----------------------

func _resolve_release() -> void:
        if game.get("coming_soon", false):
                _set_state(Dl.UNAVAILABLE)
                return
        var svc: StoreService = main_ref.get_node("StoreService")
        svc.release_resolved.connect(_on_release, CONNECT_ONE_SHOT)
        svc.release_unavailable.connect(_on_no_release, CONNECT_ONE_SHOT)
        svc.resolve(game_id)

func _on_release(id: String, info: Dictionary) -> void:
        if id != game_id:
                return
        _release = info
        _version_label.text = "Versão %s   ·   %s   ·   atualizado em %s" % [
                info.get("version", "--"), GameState.fmt_size(float(info.get("size", 0))),
                String(info.get("published", "--")).substr(0, 10)]
        _set_state(Dl.INSTALLED if _is_installed() else Dl.AVAILABLE)

func _on_no_release(id: String, _reason: String) -> void:
        if id != game_id:
                return
        _release = {}
        _version_label.text = ""
        _set_state(Dl.UNAVAILABLE)

func _is_installed() -> bool:
        var pkg := String(game.get("package_name", ""))
        if pkg != "" and InstallBridge.is_package_installed(pkg):
                if not GameState.is_installed(game_id):
                        GameState.mark_installed(game_id, pkg, "confirmado")
                return true
        return GameState.is_installed(game_id)

func _set_state(s: int) -> void:
        _dl_state = s
        _render_action()

func _render_action() -> void:
        if _action_box == null:
                return
        for c in _action_box.get_children():
                c.queue_free()

        match _dl_state:
                Dl.RESOLVING:
                        var sk := UiLib.skeleton(360, 54, 8)
                        _action_box.add_child(sk)
                Dl.UNAVAILABLE:
                        var p := PanelContainer.new()
                        p.add_theme_stylebox_override("panel", AppTheme.sb_flat(Color(1, 1, 1, 0.06), 10))
                        var v := VBoxContainer.new()
                        v.add_theme_constant_override("separation", 4)
                        var mc := MarginContainer.new()
                        mc.add_child(v)
                        p.add_child(mc)
                        v.add_child(AppTheme.label("Em breve", 24, AppTheme.TEXT, true))
                        v.add_child(AppTheme.label("Este item ainda não está disponível para download. A loja será atualizada automaticamente quando houver release.", 16, AppTheme.TEXT_DIM))
                        _action_box.add_child(p)
                Dl.AVAILABLE:
                        var size_note := ""
                        if _release.has("size"):
                                size_note = "   ·   " + GameState.fmt_size(float(_release["size"]))
                        var b := UiLib.action_button("Baixar" + ("  ·  " + String(_release.get("version", "")) if _release.has("version") else "") + size_note, true, Vector2(420, 58))
                        b.pressed.connect(_start_download)
                        _action_box.add_child(b)
                        _add_disclaimer()
                Dl.DOWNLOADING, Dl.PAUSED:
                        _render_progress()
                Dl.FINISHED:
                        _render_install_prompt()
                Dl.INSTALLED:
                        _render_installed()

func _add_disclaimer() -> void:
        var l := AppTheme.label("O instalador do Android solicitará permissão de \"apps de fontes desconhecidas\" na primeira instalação.", 14, AppTheme.TEXT_DIM)
        l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        l.custom_minimum_size = Vector2(700, 0)
        _action_box.add_child(l)

func _render_progress() -> void:
        _progress = ProgressBar.new()
        _progress.custom_minimum_size = Vector2(560, 14)
        _progress.show_percentage = false
        var bg := AppTheme.sb_flat(Color(1, 1, 1, 0.10), 7)
        var fg := AppTheme.sb_flat(AppTheme.GREEN_BRIGHT, 7)
        _progress.add_theme_stylebox_override("background", bg)
        _progress.add_theme_stylebox_override("fill", fg)
        _action_box.add_child(_progress)

        _progress_label = AppTheme.label("Preparando download…", 16, AppTheme.TEXT_DIM)
        _action_box.add_child(_progress_label)
        var snap: Dictionary = (main_ref.get_node("Downloads") as DownloadManager).snapshot(game_id)
        if not snap.is_empty() and int(snap["have"]) > 0:
                _on_progress(game_id, int(snap["have"]), int(snap["total"]), float(snap["speed"]), 0.0)
                if _dl_state == Dl.PAUSED:
                        _progress_label.text += "   (pausado)"

        var btns := HBoxContainer.new()
        btns.add_theme_constant_override("separation", 12)
        _action_box.add_child(btns)

        if _dl_state == Dl.DOWNLOADING:
                var bp := UiLib.action_button("Pausar", false, Vector2(150, 46))
                bp.pressed.connect(func():
                        main_ref.get_node("Downloads").pause(game_id)
                        main_ref.toast("Download pausado"))
                btns.add_child(bp)
        else:
                var br := UiLib.action_button("Retomar", true, Vector2(150, 46))
                br.pressed.connect(func():
                        main_ref.get_node("Downloads").resume(game_id)
                        main_ref.toast("Retomando…"))
                btns.add_child(br)

        var bc := UiLib.action_button("Cancelar", false, Vector2(150, 46))
        bc.add_theme_color_override("font_color", AppTheme.DANGER)
        bc.pressed.connect(func():
                main_ref.get_node("Downloads").cancel(game_id)
                main_ref.toast("Download cancelado")
                _set_state(Dl.AVAILABLE))
        btns.add_child(bc)

        var dm: DownloadManager = main_ref.get_node("Downloads")
        dm.progress.connect(_on_progress)
        dm.state_changed.connect(_on_dl_state)

func _start_download() -> void:
        if _release.is_empty() or not _release.has("url"):
                main_ref.toast("Release indisponível no momento")
                Sfx.play("error")
                return
        if not InstallBridge.can_install_packages():
                var b := UiLib.action_button("Permitir instalação de apps", false, Vector2(420, 46))
                b.pressed.connect(func(): InstallBridge.open_install_permission_settings())
                _action_box.add_child(b)
        var dest := "user://apks/%s.apk" % game_id
        main_ref.get_node("Downloads").start(game_id, String(_release["url"]), dest)
        main_ref.toast("Baixando " + String(_release.get("name", "APK")))
        _set_state(Dl.DOWNLOADING)

func _on_progress(_id: String, downloaded: int, total: int, speed: float, eta: float) -> void:
        if _progress == null or _progress_label == null:
                return
        var frac := 0.0 if total <= 0 else clampf(float(downloaded) / float(total), 0.0, 1.0)
        _progress.value = frac
        if total > 0:
                _progress_label.text = "%s de %s   ·   %s   ·   resta %s" % [
                        GameState.fmt_size(float(downloaded)), GameState.fmt_size(float(total)),
                        GameState.fmt_speed(speed), GameState.fmt_eta(eta)]
        else:
                _progress_label.text = "%s baixados   ·   %s" % [GameState.fmt_size(float(downloaded)), GameState.fmt_speed(speed)]

func _on_dl_state(id: String, st: String) -> void:
        if id != game_id:
                return
        match st:
                DownloadManager.STATE_PAUSED:
                        _set_state(Dl.PAUSED)
                DownloadManager.STATE_FINISHED:
                        Sfx.play("done")
                        _set_state(Dl.FINISHED)
                DownloadManager.STATE_FAILED:
                        main_ref.toast("Falha no download: " + _error_of())
                        Sfx.play("error")
                        _set_state(Dl.AVAILABLE)

func _error_of() -> String:
        var dm: DownloadManager = main_ref.get_node("Downloads")
        return dm.last_error(game_id)

func _render_install_prompt() -> void:
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 10)
        _action_box.add_child(v)
        v.add_child(AppTheme.label("Download concluído  ✓  " + GameState.fmt_size(float(_release.get("size", 0))), 20, AppTheme.GREEN_BRIGHT, true))
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 12)
        v.add_child(row)
        var bi := UiLib.action_button("Instalar agora", true, Vector2(240, 56))
        bi.pressed.connect(_do_install)
        row.add_child(bi)
        var bd := UiLib.action_button("Baixar de novo", false, Vector2(220, 56))
        bd.pressed.connect(_start_download)
        row.add_child(bd)
        _add_disclaimer()

func _do_install() -> void:
        var path := ProjectSettings.globalize_path("user://apks/%s.apk" % game_id)
        if not FileAccess.file_exists(path):
                main_ref.toast("APK não encontrado — baixe novamente")
                Sfx.play("error")
                _set_state(Dl.AVAILABLE)
                return
        if not InstallBridge.can_install_packages():
                InstallBridge.open_install_permission_settings()
                main_ref.toast("Conceda a permissão e toque em Instalar novamente")
                return
        InstallBridge.install_apk(path)
        main_ref.toast("Abrindo instalador do Android…")
        var pkg := String(game.get("package_name", ""))
        if pkg != "":
                GameState.mark_installed(game_id, pkg, "solicitado")
        _install_poll()

func _install_poll() -> void:
        # quando o usuario volta do instalador, confirma a instalacao
        for i in 60:
                await get_tree().create_timer(1.0).timeout
                if not is_inside_tree():
                        return
                var pkg := String(game.get("package_name", ""))
                if pkg != "" and InstallBridge.is_package_installed(pkg):
                        GameState.mark_installed(game_id, pkg, "confirmado")
                        main_ref.toast("Jogo instalado!")
                        Sfx.play("done")
                        _set_state(Dl.INSTALLED)
                        return
                if OS.has_feature("android"):
                        continue
                break
        # desktop/QA: simula confirmacao
        if not OS.has_feature("android") and GameState.is_installed(game_id) == false:
                var pkg := String(game.get("package_name", "demo"))
                GameState.mark_installed(game_id, pkg, "simulado")
                main_ref.toast("Instalado (simulação desktop)")
                _set_state(Dl.INSTALLED)

func _render_installed() -> void:
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 12)
        _action_box.add_child(row)
        var open_b := UiLib.action_button("Abrir jogo", true, Vector2(220, 56))
        open_b.pressed.connect(func():
                InstallBridge.launch_app(String(game.get("package_name", "")))
                if not InstallBridge.available():
                        main_ref.toast("Abrir está disponível no Android"))
        row.add_child(open_b)
        var meta := AppTheme.label("Instalado", 18, AppTheme.GREEN_BRIGHT, true)
        meta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        row.add_child(meta)
        var re := UiLib.action_button("Baixar novamente", false, Vector2(260, 56))
        re.pressed.connect(_start_download)
        row.add_child(re)

func default_focus() -> Control:
        if _action_box != null:
                var b := _find_first_button(_action_box)
                if b != null:
                        return b
        return null

func _find_first_button(n: Node) -> Button:
        if n is Button and (n as Button).focus_mode != Control.FOCUS_NONE:
                return n
        for c in n.get_children():
                var r := _find_first_button(c)
                if r != null:
                        return r
        return null

func on_shown(_main) -> void:
        # voltando do instalador do Android: re-checa status
        if _dl_state == Dl.INSTALLED or _dl_state == Dl.FINISHED:
                if _is_installed():
                        _set_state(Dl.INSTALLED)
