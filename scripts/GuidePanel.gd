class_name GuidePanel
extends Control
## Guia lateral estilo Xbox: painel com acrylic blur real (screen texture),
## scrim, perfil e atalhos de navegacao. Abre com botao Guide/gamepad ou G.

signal shortcut(screen: String)

var _scrim: ColorRect
var _panel: Control
var _buttons: Array = []
var open := false
var _tween: Tween

const W := 460.0

func build(main) -> void:
        visible = false
        mouse_filter = Control.MOUSE_FILTER_STOP

        _scrim = ColorRect.new()
        _scrim.color = AppTheme.SCRIM
        _scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        _scrim.gui_input.connect(func(ev):
                if ev is InputEventMouseButton and ev.pressed:
                        close())
        add_child(_scrim)

        _panel = Control.new()
        _panel.custom_minimum_size = Vector2(W, 0)
        _panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
        _panel.offset_right = W
        add_child(_panel)
        var solid := ColorRect.new()
        solid.color = Color(0.085, 0.088, 0.095, 0.97)
        solid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        solid.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _panel.add_child(solid)
        var acrylic := Panel.new()
        acrylic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        var m := ShaderMaterial.new()
        m.shader = load("res://shaders/acrylic.gdshader")
        m.set_shader_parameter("tint", Color(0.07, 0.075, 0.08, 0.72))
        acrylic.material = m
        acrylic.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _panel.add_child(acrylic)

        var col := VBoxContainer.new()
        col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        col.offset_left = 40
        col.offset_right = -32
        col.offset_top = 48
        col.offset_bottom = -40
        col.add_theme_constant_override("separation", 6)
        _panel.add_child(col)

        var profile := HBoxContainer.new()
        profile.add_theme_constant_override("separation", 16)
        col.add_child(profile)
        var av := UiLib.tex_rect("res://assets/art/avatar.webp")
        av.custom_minimum_size = Vector2(64, 64)
        UiLib.rounded_mat(av, 32.0)
        profile.add_child(av)
        var pcol := VBoxContainer.new()
        pcol.add_theme_constant_override("separation", 0)
        profile.add_child(pcol)
        pcol.add_child(AppTheme.label("Jogador", 22, AppTheme.TEXT, true))
        pcol.add_child(AppTheme.label("G 1 337", 14, AppTheme.TEXT_DIM))
        col.add_child(UiLib.spacer(0, 16))

        var items := [
                ["home", "Home"],
                ["store", "Loja"],
                ["collection", "Minha Coleção"],
                ["settings", "Configurações"],
        ]
        for it in items:
                var b := Button.new()
                b.text = "   " + String(it[1])
                b.custom_minimum_size = Vector2(0, 56)
                b.focus_mode = Control.FOCUS_ALL
                b.alignment = HORIZONTAL_ALIGNMENT_LEFT
                b.add_theme_font_override("font", AppTheme.font("SemiBold"))
                b.add_theme_font_size_override("font_size", 20)
                b.add_theme_color_override("font_color", AppTheme.TEXT)
                b.add_theme_color_override("font_focus_color", AppTheme.WHITE)
                b.add_theme_color_override("font_hover_color", AppTheme.WHITE)
                b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
                b.add_theme_stylebox_override("hover", AppTheme.sb_flat(Color(1, 1, 1, 0.08), 8))
                b.add_theme_stylebox_override("pressed", AppTheme.sb_flat(Color(1, 1, 1, 0.12), 8))
                b.add_theme_stylebox_override("focus", AppTheme.sb_focus_border(3, AppTheme.GREEN_BRIGHT, 8))
                b.mouse_entered.connect(b.grab_focus)
                b.focus_entered.connect(func(): Sfx.play("nav"))
                var target := String(it[0])
                b.pressed.connect(func():
                        Sfx.play("select")
                        close()
                        shortcut.emit(target))
                _buttons.append(b)
                col.add_child(b)

        col.add_child(UiLib.spacer(0, 14))
        var off := Button.new()
        off.text = "   Desligar"
        off.custom_minimum_size = Vector2(0, 52)
        off.alignment = HORIZONTAL_ALIGNMENT_LEFT
        off.focus_mode = Control.FOCUS_ALL
        off.add_theme_font_override("font", AppTheme.font("SemiBold"))
        off.add_theme_font_size_override("font_size", 18)
        off.add_theme_color_override("font_color", AppTheme.DANGER)
        off.add_theme_color_override("font_focus_color", AppTheme.DANGER)
        off.add_theme_color_override("font_hover_color", AppTheme.DANGER)
        off.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
        off.add_theme_stylebox_override("hover", AppTheme.sb_flat(AppTheme.DANGER.darkened(0.7), 8))
        off.add_theme_stylebox_override("pressed", AppTheme.sb_flat(AppTheme.DANGER.darkened(0.6), 8))
        off.add_theme_stylebox_override("focus", AppTheme.sb_focus_border(3, AppTheme.DANGER, 8))
        off.mouse_entered.connect(off.grab_focus)
        off.pressed.connect(func():
                Sfx.play("back")
                close()
                main.toast("Até logo! (demo — nada foi desligado)"))
        col.add_child(off)
        col.add_child(UiLib.spacer(0, 8))
        col.add_child(AppTheme.label("SeriesDash 1.0 · Godot + GDScript", 12, AppTheme.TEXT_DIM))

func open_panel() -> void:
        if open:
                return
        open = true
        visible = true
        _scrim.modulate.a = 0.0
        _panel.position.x = -W
        if _tween != null and _tween.is_valid():
                _tween.kill()
        _tween = create_tween().set_parallel(true)
        _tween.tween_property(_scrim, "modulate:a", 1.0, 0.22 * AppTheme.m()).set_trans(Tween.TRANS_SINE)
        _tween.tween_property(_panel, "position:x", 0.0, AppTheme.T_PANEL * AppTheme.m()).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
        if not _buttons.is_empty():
                _buttons[0].grab_focus()

func close() -> void:
        if not open:
                return
        open = false
        if _tween != null and _tween.is_valid():
                _tween.kill()
        _tween = create_tween().set_parallel(true)
        _tween.tween_property(_scrim, "modulate:a", 0.0, 0.18 * AppTheme.m())
        _tween.tween_property(_panel, "position:x", -W, 0.2 * AppTheme.m()).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
        _tween.chain().tween_callback(func(): visible = false)
