class_name ScreenStore
extends Control
## Loja: busca, fileiras de destaques/novidades/em breve e skeleton loading
## na primeira abertura (padrao Fluent).

var _content: VBoxContainer
var _search: LineEdit
var _built := false
var _tiles_by_id := {}

func build(main) -> void:
	if _built:
		return
	_built = true

	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 64
	col.offset_right = -64
	col.offset_top = 8
	col.add_theme_constant_override("separation", 16)
	add_child(col)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 20)
	col.add_child(head)
	head.add_child(AppTheme.label("Loja", 34, AppTheme.TEXT, true, true))

	_search = LineEdit.new()
	_search.placeholder_text = "Buscar na loja"
	_search.custom_minimum_size = Vector2(420, 46)
	_search.size_flags_horizontal = Control.SIZE_SHRINK_END
	_search.add_theme_font_override("font", AppTheme.font("Medium"))
	_search.add_theme_font_size_override("font_size", 18)
	_search.add_theme_color_override("font_color", AppTheme.TEXT)
	_search.add_theme_color_override("font_placeholder_color", AppTheme.TEXT_DIM)
	_search.add_theme_color_override("caret_color", AppTheme.GREEN_BRIGHT)
	_search.add_theme_stylebox_override("normal", AppTheme.sb_flat(Color(1, 1, 1, 0.08), 8))
	_search.add_theme_stylebox_override("focus", AppTheme.sb_focus_border(2, AppTheme.GREEN_BRIGHT, 8))
	_search.text_changed.connect(_filter)
	col.add_child(_search)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 18)
	col.add_child(_content)

	# skeleton loading (primeira abertura) — evita "placeholder cinza preguiçoso"
	var sk1 := TileRow.new()
	sk1.setup("  ")
	for i in 7:
		sk1.add_tile(_fake_skeleton_tile())
	_content.add_child(sk1)
	var sk2 := TileRow.new()
	sk2.setup("  ")
	for i in 4:
		sk2.add_tile(_fake_skeleton_tile(340, 150))
	_content.add_child(sk2)

	await get_tree().create_timer(0.9).timeout
	if not is_inside_tree():
		return
	sk1.queue_free()
	sk2.queue_free()
	_build_rows(main)

func _fake_skeleton_tile(w := 150, h := 150) -> Control:
	var c := UiLib.skeleton(w, h)
	return c

func _build_rows(main) -> void:
	_tiles_by_id.clear()
	var rows_cfg: Dictionary = GameState.catalog.get("rows", {})

	var row_dest := TileRow.new()
	row_dest.setup("Destaques")
	for id in rows_cfg.get("destaques", []):
		var g := GameState.game_by_id(String(id))
		if not g.is_empty():
			var t := row_dest.add_game(g, 1.0, func(game): main.open_details(String(game["id"])))
			_tiles_by_id[String(id)] = t
	_content.add_child(row_dest)

	var row_new := TileRow.new()
	row_new.setup("Recém-adicionados")
	for id in rows_cfg.get("novidades", []):
		var g := GameState.game_by_id(String(id))
		if not g.is_empty():
			var t := row_new.add_game(g, 1.0, func(game): main.open_details(String(game["id"])))
			_tiles_by_id[String(id)] = t
	_content.add_child(row_new)

	var row_soon := TileRow.new()
	row_soon.setup("Em breve")
	for id in rows_cfg.get("em_breve", []):
		var g := GameState.game_by_id(String(id))
		if not g.is_empty():
			var t := row_soon.add_game(g, 1.0, func(game): main.open_details(String(game["id"])))
			_tiles_by_id[String(id)] = t
	_content.add_child(row_soon)
	_content.add_child(UiLib.spacer(0, 24))

	if get_viewport().gui_get_focus_owner() == _search and not _tiles_by_id.is_empty():
		(_tiles_by_id.values()[0] as Control).call_deferred("grab_focus")

func _filter(q: String) -> void:
	q = q.strip_edges().to_lower()
	for id in _tiles_by_id:
		var t: TileButton = _tiles_by_id[id]
		var title := String(t.game.get("title", "")).to_lower()
		t.visible = q == "" or title.contains(q)

func default_focus() -> Control:
	if not _tiles_by_id.is_empty():
		return _tiles_by_id.values()[0]
	return _search

func on_shown(_main) -> void:
	pass
