class_name ScreenCollection
extends Control
## Minha Coleção: jogos instalados. Estado vazio caprichado com CTA para a loja.

var _content: VBoxContainer
var _built := false

func build(main) -> void:
	if _built:
		return
	_built = true

	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 64
	col.offset_right = -64
	col.offset_top = 8
	col.add_theme_constant_override("separation", 18)
	add_child(col)

	col.add_child(AppTheme.label("Minha Coleção", 34, AppTheme.TEXT, true, true))
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 18)
	col.add_child(_content)

func refresh(main) -> void:
	if _content == null:
		return
	for c in _content.get_children():
		c.queue_free()

	var installed_ids: Array = GameState.installed.keys()
	if installed_ids.is_empty():
		var empty := VBoxContainer.new()
		empty.add_theme_constant_override("separation", 10)
		var card := PanelContainer.new()
		var sb := AppTheme.sb_flat(Color(1, 1, 1, 0.05), AppTheme.RADIUS_BIG)
		sb.content_margin_left = 40.0
		sb.content_margin_right = 40.0
		sb.content_margin_top = 36.0
		sb.content_margin_bottom = 36.0
		card.add_theme_stylebox_override("panel", sb)
		empty.add_child(card)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 10)
		card.add_child(v)
		v.add_child(AppTheme.label("Sua coleção está vazia", 26, AppTheme.TEXT, true))
		v.add_child(AppTheme.label("Baixe um jogo na Loja e ele aparecerá aqui, pronto para abrir.", 17, AppTheme.TEXT_DIM))
		var b := UiLib.action_button("Ir para a Loja", true, Vector2(240, 52))
		b.pressed.connect(func(): main.go("store"))
		v.add_child(UiLib.spacer(0, 6))
		v.add_child(b)
		_content.add_child(empty)
		return

	var row := TileRow.new()
	row.setup("Instalados")
	for id in installed_ids:
		var g := GameState.game_by_id(String(id))
		if not g.is_empty():
			row.add_game(g, 1.0, func(game): main.open_details(String(game["id"])))
	_content.add_child(row)
	_content.add_child(UiLib.spacer(0, 20))

func default_focus() -> Control:
	var rows := _content.get_children() if _content != null else []
	for r in rows:
		if r is TileRow and (r as TileRow).first_tile() != null:
			return (r as TileRow).first_tile()
		for c in r.get_children():
			if c is Button:
				return c
	return null

func on_shown(main) -> void:
	refresh(main)
