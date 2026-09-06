class_name UiLib
## Fabricas de componentes visuais reutilizáveis (padrao Fluent-dark Xbox).

const SHADER_ROUNDED := "res://shaders/rounded_cover.gdshader"

## Material de cantos arredondados que acompanha o resize do no.
static func rounded_mat(target: TextureRect, radius: float = AppTheme.RADIUS) -> ShaderMaterial:
        var m := ShaderMaterial.new()
        m.shader = load(SHADER_ROUNDED)
        m.set_shader_parameter("radius_px", radius)
        m.set_shader_parameter("node_size", target.size)
        target.resized.connect(func(): m.set_shader_parameter("node_size", target.size))
        target.set_material(m)
        return m

static func tex_rect(tex_path: String, cover: bool = true) -> TextureRect:
        var t := TextureRect.new()
        if tex_path != "":
                t.texture = load(tex_path)
        t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        t.mouse_filter = Control.MOUSE_FILTER_IGNORE
        return t

## Overlay de gradiente (legibilidade sobre hero/cards)
static func v_gradient(from_alpha: float, to_alpha: float, height: int = 400) -> TextureRect:
        var g := Gradient.new()
        g.colors = PackedColorArray([Color(0, 0, 0, from_alpha), Color(0, 0, 0, to_alpha)])
        g.offsets = PackedFloat32Array([0.0, 1.0])
        var gt := GradientTexture2D.new()
        gt.gradient = g
        gt.fill_from = Vector2(0, 0)
        gt.fill_to = Vector2(0, 1)
        var t := TextureRect.new()
        t.texture = gt
        t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        t.stretch_mode = TextureRect.STRETCH_SCALE
        t.mouse_filter = Control.MOUSE_FILTER_IGNORE
        t.custom_minimum_size.y = height
        return t

static func chip(text: String, bg: Color = Color(1, 1, 1, 0.12), fg: Color = AppTheme.TEXT) -> PanelContainer:
        var pc := PanelContainer.new()
        var sb := AppTheme.sb_flat(bg, 6)
        sb.content_margin_left = 9.0
        sb.content_margin_right = 9.0
        sb.content_margin_top = 3.0
        sb.content_margin_bottom = 3.0
        pc.add_theme_stylebox_override("panel", sb)
        pc.add_child(AppTheme.label(text, 14, fg, true))
        pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
        return pc

static func pill(badge: String) -> PanelContainer:
        var pc := PanelContainer.new()
        var sb := AppTheme.sb_flat(AppTheme.WHITE, 4)
        sb.content_margin_left = 7.0
        sb.content_margin_right = 7.0
        sb.content_margin_top = 2.0
        sb.content_margin_bottom = 2.0
        pc.add_theme_stylebox_override("panel", sb)
        pc.add_child(AppTheme.label(badge, 13, AppTheme.PILL_TEXT, true))
        pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
        return pc

## Botao de acao principal/Secundario com visual de foco e som.
static func action_button(text: String, primary: bool = true, min_size: Vector2 = Vector2(220, 54)) -> Button:
        var b := Button.new()
        b.text = text
        b.custom_minimum_size = min_size
        b.focus_mode = Control.FOCUS_ALL
        var font_weight := "Bold"
        b.add_theme_font_override("font", AppTheme.font(font_weight))
        b.add_theme_font_size_override("font_size", 20)
        if primary:
                b.add_theme_stylebox_override("normal", AppTheme.sb_flat(AppTheme.GREEN, 8))
                b.add_theme_stylebox_override("hover", AppTheme.sb_flat(AppTheme.GREEN_BRIGHT, 8))
                b.add_theme_stylebox_override("pressed", AppTheme.sb_flat(AppTheme.GREEN_DEEP, 8))
                b.add_theme_color_override("font_color", AppTheme.WHITE)
        else:
                var nb := AppTheme.sb_flat(Color(1, 1, 1, 0.10), 8)
                b.add_theme_stylebox_override("normal", nb)
                b.add_theme_stylebox_override("hover", AppTheme.sb_flat(Color(1, 1, 1, 0.16), 8))
                b.add_theme_stylebox_override("pressed", AppTheme.sb_flat(Color(1, 1, 1, 0.22), 8))
                b.add_theme_color_override("font_color", AppTheme.TEXT)
        b.add_theme_color_override("font_hover_color", AppTheme.WHITE)
        b.add_theme_color_override("font_pressed_color", AppTheme.WHITE)
        b.add_theme_color_override("font_focus_color", AppTheme.WHITE)
        b.add_theme_stylebox_override("focus", AppTheme.sb_focus_border(3, AppTheme.WHITE, 8))
        b.mouse_entered.connect(func(): b.grab_focus())
        b.focus_entered.connect(func(): Sfx.play("nav"))
        b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        return b

static func skeleton(w: float, h: float, radius: float = AppTheme.RADIUS) -> Panel:
        var p := Panel.new()
        p.custom_minimum_size = Vector2(w, h)
        var m := ShaderMaterial.new()
        m.shader = load("res://shaders/shimmer.gdshader")
        m.set_shader_parameter("speed", randf_range(0.7, 1.1))
        p.material = m
        p.mouse_filter = Control.MOUSE_FILTER_IGNORE
        return p

static func spacer(w: float = 0.0, h: float = 0.0) -> Control:
        var c := Control.new()
        c.custom_minimum_size = Vector2(w, h)
        c.mouse_filter = Control.MOUSE_FILTER_IGNORE
        return c

static func hsep(color: Color = Color(1, 1, 1, 0.08)) -> ColorRect:
        var r := ColorRect.new()
        r.color = color
        r.custom_minimum_size.y = 1
        r.mouse_filter = Control.MOUSE_FILTER_IGNORE
        return r
