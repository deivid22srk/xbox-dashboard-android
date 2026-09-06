class_name TileButton
extends Button
## Tile de jogo no padrao Xbox: capa arredondada, borda de foco verde, escala
## animada com easing, faixa de titulo sob o tile focado e badge tipo pílula.

signal activated(game: Dictionary)

const COVER_W := 150.0
const COVER_H := 150.0
const STRIP_H := 30.0
const WIDE_SIZE := Vector2(340.0, 150.0)

var game: Dictionary
var kind := "cover"  # cover | wide
var cover_ratio := 1.0  # 1.0 quadrado (Xbox), 0.75 portrait (3:4)

var _cover: TextureRect
var _border: Panel
var _strip: Label
var _tween: Tween

static func for_game(g: Dictionary, ratio: float = 1.0) -> TileButton:
        var t := TileButton.new()
        t.game = g
        t.kind = "cover"
        t.cover_ratio = ratio
        return t

static func for_action(id: String, title: String, subtitle: String, bg: Color) -> TileButton:
        var t := TileButton.new()
        t.game = {"id": id, "title": title, "subtitle": subtitle, "color": bg, "action": true}
        t.kind = "wide"
        return t

func _ready() -> void:
        focus_mode = Control.FOCUS_ALL
        text = ""
        flat = true
        var is_wide := kind == "wide"
        var cover_h := COVER_H
        var cover_w := COVER_W * cover_ratio if not is_wide else WIDE_SIZE.x
        custom_minimum_size = Vector2(cover_w, cover_h + STRIP_H)
        add_theme_stylebox_override("normal", StyleBoxEmpty.new())
        add_theme_stylebox_override("hover", StyleBoxEmpty.new())
        add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
        add_theme_stylebox_override("focus", StyleBoxEmpty.new())
        resized.connect(func(): pivot_offset = Vector2(size.x / 2.0, cover_h / 2.0))

        if is_wide:
                _build_wide()
        else:
                _build_cover()

        _border = Panel.new()
        _border.add_theme_stylebox_override("panel", AppTheme.sb_focus_border(3, AppTheme.GREEN_BRIGHT, AppTheme.RADIUS + 2))
        _border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        _border.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _border.modulate.a = 0.0
        add_child(_border)

        _strip = AppTheme.label(String(game.get("title", "")), 16, AppTheme.TEXT, true)
        _strip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _strip.position = Vector2(-20, cover_h + 4)
        _strip.size = Vector2(custom_minimum_size.x + 40, STRIP_H)
        _strip.modulate.a = 0.0
        add_child(_strip)

        focus_entered.connect(_on_focus)
        focus_exited.connect(_on_unfocus)
        mouse_entered.connect(grab_focus)
        pressed.connect(func():
                Sfx.play("select")
                activated.emit(game))

func _build_cover() -> void:
        _cover = UiLib.tex_rect(String(game["art"]["cover"]))
        _cover.custom_minimum_size = Vector2(COVER_W * cover_ratio, COVER_H)
        _cover.size = _cover.custom_minimum_size
        UiLib.rounded_mat(_cover, AppTheme.RADIUS)
        add_child(_cover)
        if game.get("coming_soon", false):
                var pill := UiLib.pill("EM BREVE")
                pill.position = Vector2(8, COVER_H - 30)
                _cover.add_child(pill)
        elif String(game.get("id", "")) == "dk64-recomp":
                var pill := UiLib.pill("ANDROID")
                pill.position = Vector2(8, COVER_H - 30)
                _cover.add_child(pill)

func _build_wide() -> void:
        var panel := Panel.new()
        panel.custom_minimum_size = WIDE_SIZE
        panel.size = WIDE_SIZE
        panel.add_theme_stylebox_override("panel", AppTheme.sb_flat(game.get("color", AppTheme.CARD), AppTheme.RADIUS))
        add_child(panel)
        var v := VBoxContainer.new()
        v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        v.add_theme_constant_override("separation", 4)
        v.offset_left = 24
        v.offset_bottom = -18
        v.offset_top = 18
        v.alignment = BoxContainer.ALIGNMENT_END
        panel.add_child(v)
        var big := AppTheme.label(String(game.get("title", "")), 24, AppTheme.WHITE, true)
        v.add_child(big)
        var sub := AppTheme.label(String(game.get("subtitle", "")), 15, Color(1, 1, 1, 0.72))
        v.add_child(sub)
        var arrow := AppTheme.label("›", 30, Color(1, 1, 1, 0.5), true)
        arrow.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
        arrow.position = Vector2(WIDE_SIZE.x - 44, WIDE_SIZE.y / 2 - 24)
        panel.add_child(arrow)

func _on_focus() -> void:
        _kill_tween()
        _tween = create_tween().set_parallel(true)
        _tween.tween_property(self, "scale", Vector2(1.12, 1.12), AppTheme.T_FOCUS * AppTheme.m()).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
        _tween.tween_property(_border, "modulate:a", 1.0, AppTheme.T_FOCUS * AppTheme.m())
        _tween.tween_property(_strip, "modulate:a", 1.0, 0.18 * AppTheme.m())
        Sfx.play("nav")
        _row_ensure_visible()

func _on_unfocus() -> void:
        _kill_tween()
        _tween = create_tween().set_parallel(true)
        _tween.tween_property(self, "scale", Vector2.ONE, AppTheme.T_FOCUS * AppTheme.m()).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
        _tween.tween_property(_border, "modulate:a", 0.0, AppTheme.T_FOCUS * AppTheme.m())
        _tween.tween_property(_strip, "modulate:a", 0.0, 0.12 * AppTheme.m())

func _kill_tween() -> void:
        if _tween != null and _tween.is_valid():
                _tween.kill()

func _row_ensure_visible() -> void:
        var p := get_parent()
        while p != null and not (p is ScrollContainer):
                p = p.get_parent()
        if p is ScrollContainer:
                var sc := p as ScrollContainer
                var target := clampf(position.x + size.x * 0.5 - sc.size.x * 0.5, 0.0, maxf(get_parent().size.x - sc.size.x, 0.0))
                var tw := create_tween()
                tw.tween_property(sc, "scroll_horizontal", int(target), 0.22 * AppTheme.m()).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
