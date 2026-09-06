class_name AppTheme
## Tokens de design destilados das referencias reais do dashboard Xbox Series X/S
## (docs/referencias-visuais.md). Unica fonte de verdade visual do app.

const BG_CLEAR := Color("0b0b0d")
const CARD := Color("1d1d1f")
const CARD_HI := Color("2a2a2e")
const TEXT := Color("f2f2f2")
const TEXT_DIM := Color("9a9a9e")
const GREEN := Color("107c10")
const GREEN_BRIGHT := Color("61b74e")
const GREEN_DEEP := Color("0c5e0c")
const WHITE := Color("ffffff")
const SCRIM := Color(0.0, 0.0, 0.0, 0.55)
const DANGER := Color("c4382f")
const PILL_TEXT := Color("101010")

const RADIUS := 10.0
const RADIUS_BIG := 14.0

# Tipografia (Inter = substituta livre mais proxima do Segoe UI, ver docs)
static var _fonts := {}

static func font(weight: String) -> Font:
        if not _fonts.has(weight):
                _fonts[weight] = load("res://assets/fonts/Inter-%s.ttf" % weight)
        return _fonts[weight]

static func font_display(weight: String = "Bold") -> Font:
        if not _fonts.has("Display" + weight):
                _fonts["Display" + weight] = load("res://assets/fonts/InterDisplay-%s.ttf" % weight)
        return _fonts["Display" + weight]

# Movimento (easing consistente em todo o app; fator reduzido em "animacoes rapidas")
static func m() -> float:
        return 0.6 if GameState.settings.get("fast_anim", false) else 1.0

const T_FOCUS := 0.16
const T_SCREEN := 0.34
const T_HERO := 0.9
const T_PANEL := 0.28

## ---- fabricas de estilos ----

static func sb_flat(bg: Color, radius: float = RADIUS) -> StyleBoxFlat:
        var sb := StyleBoxFlat.new()
        sb.bg_color = bg
        sb.set_corner_radius_all(int(radius))
        return sb

static func sb_card() -> StyleBoxFlat:
        var sb := sb_flat(CARD)
        sb.border_width_bottom = 1
        sb.border_color = Color(1, 1, 1, 0.04)
        return sb

static func sb_focus_border(width: int = 3, color: Color = GREEN_BRIGHT, radius: float = RADIUS + 2.0) -> StyleBoxFlat:
        var sb := StyleBoxFlat.new()
        sb.bg_color = Color(0, 0, 0, 0)
        sb.draw_center = false
        sb.set_border_width_all(width)
        sb.border_color = color
        sb.set_corner_radius_all(int(radius))
        return sb

static func sb_panel(bg: Color = Color(1, 1, 1, 0.06), radius: float = RADIUS) -> StyleBoxFlat:
        return sb_flat(bg, radius)

static func label(text: String, size: int, color: Color = TEXT, bold: bool = false, display: bool = false) -> Label:
        var l := Label.new()
        l.text = text
        var f: Font
        if display:
                f = font_display("Bold" if bold else "SemiBold")
        else:
                f = font("Bold" if bold else "Regular")
        l.add_theme_font_override("font", f)
        l.add_theme_font_size_override("font_size", size)
        l.add_theme_color_override("font_color", color)
        l.mouse_filter = Control.MOUSE_FILTER_IGNORE
        return l
