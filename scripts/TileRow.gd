class_name TileRow
extends VBoxContainer
## Fileira horizontal de tiles com titulo de secao, scroll suave que acompanha
## o foco e espacamento no padrao das referencias do dashboard.

var _scroll: ScrollContainer
var _hbox: HBoxContainer
var tiles: Array = []

func setup(title: String, tile_height: float = TileButton.COVER_H + TileButton.STRIP_H) -> void:
	add_theme_constant_override("separation", 6)
	var head := AppTheme.label(title, 24, AppTheme.TEXT, true)
	add_child(head)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(0, tile_height + 8)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_hbox = HBoxContainer.new()
	_hbox.add_theme_constant_override("separation", 16)
	_scroll.add_child(_hbox)

func add_tile(t: Control) -> void:
	tiles.append(t)
	_hbox.add_child(t)

func add_game(g: Dictionary, ratio: float = 1.0, on_activate: Callable = Callable()) -> TileButton:
	var t := TileButton.for_game(g, ratio)
	if on_activate.is_valid():
		t.activated.connect(on_activate)
	add_tile(t)
	return t

func add_action(id: String, title: String, subtitle: String, color: Color, on_activate: Callable) -> TileButton:
	var t := TileButton.for_action(id, title, subtitle, color)
	t.activated.connect(func(_g): on_activate.call())
	add_tile(t)
	return t

func first_tile() -> TileButton:
	return tiles[0] if not tiles.is_empty() else null

func empty_message(msg: String) -> void:
	var c := AppTheme.label(msg, 18, AppTheme.TEXT_DIM)
	c.custom_minimum_size = Vector2(0, 40)
	_hbox.add_child(c)
