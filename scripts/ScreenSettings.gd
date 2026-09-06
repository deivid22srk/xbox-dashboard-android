class_name ScreenSettings
extends Control
## Configuracoes: perfil, som, animacoes, permissao de instalacao, downloads e sobre.
## Todas as linhas sao focaveis (navegacao por gamepad).

var _col: VBoxContainer
var _built := false

func build(main) -> void:
	if _built:
		return
	_built = true

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(scroll)

	_col = VBoxContainer.new()
	_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_col.add_theme_constant_override("separation", 14)
	scroll.add_child(_col)

	_col.add_child(AppTheme.label("Configurações", 34, AppTheme.TEXT, true, true))

	# --- perfil ---
	_col.add_child(_section("Perfil"))
	var prof := _card()
	var pv := HBoxContainer.new()
	pv.add_theme_constant_override("separation", 18)
	prof.add_child(pv)
	var av := UiLib.tex_rect("res://assets/art/avatar.webp")
	av.custom_minimum_size = Vector2(72, 72)
	UiLib.rounded_mat(av, 36.0)
	pv.add_child(av)
	var pvcol := VBoxContainer.new()
	pvcol.add_theme_constant_override("separation", 2)
	pv.add_child(pvcol)
	pvcol.add_child(AppTheme.label("Jogador", 24, AppTheme.TEXT, true))
	pvcol.add_child(AppTheme.label("G 1 337   ·   Console SeriesDash", 15, AppTheme.TEXT_DIM))
	_col.add_child(prof)

	# --- geral ---
	_col.add_child(_section("Geral"))
	_col.add_child(_toggle_row(main, "Sons da interface", "Blips de navegação e feedback sonoro", "sound"))
	_col.add_child(_toggle_row(main, "Animações rápidas", "Reduz a duração das transições (acessibilidade)", "fast_anim"))

	# --- sistema ---
	_col.add_child(_section("Sistema"))
	var perm := _card()
	var perm_v := VBoxContainer.new()
	perm_v.add_theme_constant_override("separation", 8)
	perm.add_child(perm_v)
	perm_v.add_child(AppTheme.label("Instalação de apps de fontes desconhecidas", 20, AppTheme.TEXT, true))
	var st := AppTheme.label("", 15, AppTheme.TEXT_DIM)
	var perm_btn := UiLib.action_button("Verificar permissão", false, Vector2(260, 46))
	perm_btn.pressed.connect(func():
		if InstallBridge.available():
			var ok := InstallBridge.can_install_packages()
			st.text = "Permissão concedida" if ok else "Permissão pendente"
			if not ok:
				InstallBridge.open_install_permission_settings())
	perm_v.add_child(perm_btn)
	perm_v.add_child(st)
	st.text = ("Permissão concedida" if InstallBridge.can_install_packages() else "Permissão pendente") if InstallBridge.available() else "Verificação disponível no Android"
	_col.add_child(perm)

	var clear := _card()
	var cv := HBoxContainer.new()
	cv.add_theme_constant_override("separation", 14)
	clear.add_child(cv)
	var cvcol := VBoxContainer.new()
	cvcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cvcol.add_child(AppTheme.label("Limpar downloads", 20, AppTheme.TEXT, true))
	cvcol.add_child(AppTheme.label("Remove APKs baixados que ainda não foram instalados", 15, AppTheme.TEXT_DIM))
	cv.add_child(cvcol)
	var clear_btn := UiLib.action_button("Limpar", false, Vector2(160, 46))
	clear_btn.pressed.connect(func():
		var dir := ProjectSettings.globalize_path("user://apks")
		var n := 0
		if DirAccess.dir_exists_absolute(dir):
			for f in DirAccess.get_files_at(dir):
				if f.ends_with(".part"):
					DirAccess.remove_absolute(dir + "/" + f)
					n += 1
		main.toast("Nenhum download parcial pendente" if n == 0 else "%d download(s) parcial(is) removido(s)" % n))
	cv.add_child(clear_btn)
	_col.add_child(clear)

	# --- sobre ---
	_col.add_child(_section("Sobre"))
	var about := _card()
	var av_box := VBoxContainer.new()
	av_box.add_theme_constant_override("separation", 6)
	about.add_child(av_box)
	av_box.add_child(AppTheme.label("SeriesDash 1.0.0", 20, AppTheme.TEXT, true))
	var about_txt := AppTheme.label("Dashboard estilo console construído 100% em Godot 4.4 + GDScript — sem Java, Kotlin ou Dart na interface. O único código nativo é o plugin mínimo InstallBridge (instalador/permissões).\n\nProjeto de estudo/fã, sem afiliação com Microsoft, Xbox, Nintendo ou Rare. Todas as marcas e artes pertencem aos seus donos. Catálogo demonstrativo; o item Donkey Kong 64: Recompiled aponta para o port open-source real de deivid22srk (requer ROM própria).", 15, AppTheme.TEXT_DIM)
	about_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	av_box.add_child(about_txt)
	_col.add_child(about)
	_col.add_child(UiLib.spacer(0, 30))

func _section(t: String) -> Label:
	var l := AppTheme.label(t, 18, AppTheme.TEXT_DIM, true)
	l.modulate.a = 0.9
	return l

func _card() -> PanelContainer:
	var p := PanelContainer.new()
	var sb := AppTheme.sb_flat(Color(1, 1, 1, 0.05), AppTheme.RADIUS)
	sb.content_margin_left = 26.0
	sb.content_margin_right = 26.0
	sb.content_margin_top = 18.0
	sb.content_margin_bottom = 18.0
	p.add_theme_stylebox_override("panel", sb)
	return p

func _toggle_row(main, title: String, sub: String, key: String) -> PanelContainer:
	var card := _card()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	card.add_child(h)
	var c := VBoxContainer.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.add_child(AppTheme.label(title, 20, AppTheme.TEXT, true))
	c.add_child(AppTheme.label(sub, 15, AppTheme.TEXT_DIM))
	h.add_child(c)

	var b := Button.new()
	b.toggle_mode = true
	b.button_pressed = bool(GameState.settings.get(key, false))
	b.custom_minimum_size = Vector2(84, 42)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_stylebox_override("normal", AppTheme.sb_flat(Color(1, 1, 1, 0.14), 21))
	b.add_theme_stylebox_override("hover", AppTheme.sb_flat(Color(1, 1, 1, 0.2), 21))
	b.add_theme_stylebox_override("pressed", AppTheme.sb_flat(AppTheme.GREEN, 21))
	b.add_theme_stylebox_override("focus", AppTheme.sb_focus_border(3, AppTheme.WHITE, 21))
	b.add_theme_color_override("font_color", AppTheme.TEXT)
	b.add_theme_color_override("font_pressed_color", AppTheme.WHITE)
	b.text = ""
	b.toggled.connect(func(on: bool):
		GameState.settings[key] = on
		b.text = "LIGADO" if on else "DESLIGADO"
		GameState.save()
		Sfx.play("select"))
	b.text = "LIGADO" if b.button_pressed else "DESLIGADO"
	b.mouse_entered.connect(b.grab_focus)
	b.focus_entered.connect(func(): Sfx.play("nav"))
	h.add_child(b)
	return card

func default_focus() -> Control:
	for c in _col.get_children():
		if c is Button:
			return c
		for cc in c.get_children():
			if cc is Button:
				return cc
			for ccc in cc.get_children():
				if ccc is Button:
					return ccc
	return null

func on_shown(_main) -> void:
	pass
