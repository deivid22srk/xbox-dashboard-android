extends Control
## SeriesDash — bootstrap e orquestracao: ambiente, abas, transicoes de tela,
## guia lateral, toasts, sons, clock e navegacao (toque/mouse/gamepad).

const TABS := [
	["home", "Home"],
	["store", "Loja"],
	["collection", "Minha Coleção"],
	["settings", "Configurações"],
]

var booted := false
var current := ""
var stack: Array = []  # telas empilháveis (details)
var screens := {}
var screen_root: Control
var ambient: ColorRect
var ambient_mat: ShaderMaterial
var ambient_id := ""
var guide: GuidePanel
var tab_buttons := {}
var tab_underlines := {}
var _clock: Label
var _toast_layer: Control
var _boot_layer: Control
var _transitioning := false
var _last_focus := {}   # tela -> Control
var _stick_cd := 0.0
var _stick_dir := Vector2.ZERO

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	ambient = ColorRect.new()
	ambient.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ambient_mat = ShaderMaterial.new()
	ambient_mat.shader = load("res://shaders/ambient_blur.gdshader")
	ambient.material = ambient_mat
	ambient.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ambient)
	set_ambient("res://assets/art/hero_dk64.webp", "dk64-recomp")

	# camada de telas (abaixo da barra superior)
	screen_root = Control.new()
	screen_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_root.offset_top = 122
	screen_root.offset_bottom = -34
	add_child(screen_root)

	_build_topbar()
	_build_footer()

	_toast_layer = Control.new()
	_toast_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_toast_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast_layer)

	var svc := StoreService.new()
	svc.name = "StoreService"
	add_child(svc)
	var dm := DownloadManager.new()
	dm.name = "Downloads"
	add_child(dm)

	guide = GuidePanel.new()
	guide.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	guide.build(self)
	guide.shortcut.connect(func(target):
		if target == "home":
			stack.clear()
		go(target, false))
	add_child(guide)

	_build_boot()

func _build_boot() -> void:
	_boot_layer = Control.new()
	_boot_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_boot_layer)
	var bg := ColorRect.new()
	bg.color = Color(0.043, 0.043, 0.045)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_boot_layer.add_child(bg)
	var icon := UiLib.tex_rect("res://icon_512.png", false)
	icon.custom_minimum_size = Vector2(180, 180)
	icon.size = Vector2(180, 180)
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.position = Vector2(-90, -110)
	icon.pivot_offset = Vector2(90, 90)
	icon.modulate.a = 0.0
	_boot_layer.add_child(icon)
	var word := AppTheme.label("SeriesDash", 28, AppTheme.TEXT, true, true)
	word.set_anchors_preset(Control.PRESET_CENTER)
	word.position = Vector2(-78, 96)
	word.modulate.a = 0.0
	_boot_layer.add_child(word)
	icon.size = Vector2(180, 180)

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(icon, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
	t.tween_property(icon, "scale", Vector2.ONE, 0.8).from(Vector2(0.86, 0.86)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(word, "modulate:a", 1.0, 0.4).set_delay(0.25)
	Sfx.play("boot", -6.0)
	t.chain().tween_interval(0.7)
	t.chain().tween_callback(_finish_boot)

func _finish_boot() -> void:
	if booted:
		return
	booted = true
	var t := create_tween()
	t.tween_property(_boot_layer, "modulate:a", 0.0, 0.45 * AppTheme.m()).set_trans(Tween.TRANS_SINE)
	t.tween_callback(func(): _boot_layer.queue_free())
	# home pre-construida para o boot ser instantaneo
	var home := _get_screen("home")
	go("home", false, true)
	(home as ScreenHome).hero._btn_primary.grab_focus()

func _build_topbar() -> void:
	var bar := Control.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 96
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)

	# perfil (esquerda)
	var prof := HBoxContainer.new()
	prof.position = Vector2(48, 14)
	prof.add_theme_constant_override("separation", 12)
	prof.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(prof)
	var av := UiLib.tex_rect("res://assets/art/avatar.webp")
	av.custom_minimum_size = Vector2(44, 44)
	UiLib.rounded_mat(av, 22.0)
	prof.add_child(av)
	prof.add_child(AppTheme.label("Jogador", 19, AppTheme.TEXT, true))
	var gchip := UiLib.chip("G 1 337", Color(0.063, 0.486, 0.063, 0.9))
	prof.add_child(gchip)

	# abas (centro-esquerda, sob o perfil)
	var tabs_box := HBoxContainer.new()
	tabs_box.position = Vector2(48, 58)
	tabs_box.add_theme_constant_override("separation", 4)
	bar.add_child(tabs_box)
	for tdef in TABS:
		var id := String(tdef[0])
		var b := Button.new()
		b.text = "  %s  " % String(tdef[1])
		b.flat = true
		b.focus_mode = Control.FOCUS_ALL
		b.add_theme_font_override("font", AppTheme.font("SemiBold"))
		b.add_theme_font_size_override("font_size", 19)
		b.add_theme_color_override("font_color", AppTheme.TEXT_DIM)
		b.add_theme_color_override("font_focus_color", AppTheme.WHITE)
		b.add_theme_color_override("font_hover_color", AppTheme.WHITE)
		b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.mouse_entered.connect(b.grab_focus)
		b.focus_entered.connect(func():
			Sfx.play("nav")
			_refresh_tabs(id))
		b.pressed.connect(func():
			Sfx.play("select")
			stack.clear()
			go(id, false))
		tabs_box.add_child(b)
		tab_buttons[id] = b
		var under := ColorRect.new()
		under.color = AppTheme.GREEN_BRIGHT
		under.custom_minimum_size = Vector2(0, 3)
		under.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		under.offset_top = -7
		under.offset_bottom = -4
		under.offset_left = 8
		under.offset_right = -8
		under.modulate.a = 0.0
		under.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(under)
		tab_underlines[id] = under

	# clock (direita)
	_clock = AppTheme.label("", 19, AppTheme.TEXT_DIM, true)
	_clock.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_clock.position = Vector2(-140, 24)
	_clock.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	bar.add_child(_clock)
	_update_clock()
	var ct := Timer.new()
	ct.wait_time = 10.0
	ct.timeout.connect(_update_clock)
	bar.add_child(ct)
	ct.start()

func _refresh_tabs(active_id: String) -> void:
	for id in tab_underlines:
		var u: ColorRect = tab_underlines[id]
		var active: bool = id == active_id or (current == id and get_viewport().gui_get_focus_owner() == null)
		u.modulate.a = 1.0 if active else 0.0
		var btn: Button = tab_buttons[id]
		btn.add_theme_color_override("font_color", AppTheme.WHITE if active else AppTheme.TEXT_DIM)

func _update_clock() -> void:
	var t := Time.get_time_dict_from_system()
	_clock.text = "%02d:%02d" % [int(t.hour), int(t.minute)]

func _build_footer() -> void:
	var f := HBoxContainer.new()
	f.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	f.offset_left = -560
	f.offset_top = -40
	f.offset_right = -48
	f.offset_bottom = -12
	f.alignment = BoxContainer.ALIGNMENT_END
	f.add_theme_constant_override("separation", 26)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(f)
	for h in [["A", "Selecionar"], ["B", "Voltar"], ["≡", "Guia"]]:
		var chip := PanelContainer.new()
		var sb := AppTheme.sb_flat(Color(1, 1, 1, 0.10), 5)
		sb.content_margin_left = 8.0
		sb.content_margin_right = 8.0
		sb.content_margin_top = 1.0
		sb.content_margin_bottom = 1.0
		chip.add_theme_stylebox_override("panel", sb)
		chip.add_child(AppTheme.label(String(h[0]), 14, AppTheme.TEXT, true))
		f.add_child(chip)
		f.add_child(AppTheme.label(String(h[1]), 14, AppTheme.TEXT_DIM))

## ------------------------------ navegacao ------------------------------

func _get_screen(id: String) -> Control:
	if screens.has(id):
		return screens[id]
	var s: Control
	match id:
		"home":
			s = ScreenHome.new()
		"store":
			s = ScreenStore.new()
		"collection":
			s = ScreenCollection.new()
		"settings":
			s = ScreenSettings.new()
	s.name = "Screen" + id
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	s.set("modulate:a", 0.0)
	screen_root.add_child(s)
	s.build(self)
	screens[id] = s
	return s

func go(id: String, push := false, instant := false) -> void:
	if not booted and id != "home":
		return
	if _transitioning or (current == id and not instant):
		return
	var incoming := _get_screen(id)
	if current != "" and current != id:
		_last_focus[current] = get_viewport().gui_get_focus_owner()
	var outgoing: Control = screens.get(current, null) if current != id else null
	current = id
	if push:
		stack.append(id)
	_refresh_tabs(id)
	if incoming is ScreenCollection:
		(incoming as ScreenCollection).refresh(self)
	if incoming.has_method("on_shown"):
		incoming.call("on_shown", self)

	if instant:
		incoming.set("modulate:a", 1.0)
		incoming.position.x = 0
		if outgoing != null and outgoing != incoming:
			outgoing.visible = false
		return

	_transitioning = true
	incoming.visible = true
	incoming.set("modulate:a", 0.0)
	incoming.position.x = 70
	var t := create_tween().set_parallel(true)
	t.tween_property(incoming, "modulate:a", 1.0, AppTheme.T_SCREEN * AppTheme.m()).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(incoming, "position:x", 0.0, AppTheme.T_SCREEN * AppTheme.m()).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if outgoing != null and outgoing != incoming:
		t.tween_property(outgoing, "modulate:a", 0.0, AppTheme.T_SCREEN * 0.7 * AppTheme.m())
		t.tween_property(outgoing, "position:x", -50.0, AppTheme.T_SCREEN * 0.7 * AppTheme.m()).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(func():
		if outgoing != null and outgoing != incoming:
			outgoing.visible = false
		_transitioning = false)

	# restaura foco
	var focus_target: Control = _last_focus.get(id, null)
	if focus_target == null or not focus_target.is_visible_in_tree():
		focus_target = incoming.call("default_focus") if incoming.has_method("default_focus") else null
	if focus_target != null:
		focus_target.call_deferred("grab_focus")

func open_details(id: String) -> void:
	if _transitioning:
		return
	# nova instancia por abertura (evita estados presos)
	if screens.has("__details__"):
		screens["__details__"].queue_free()
	var s := ScreenDetails.new()
	s.name = "ScreenDetails"
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	s.set("modulate:a", 0.0)
	screen_root.add_child(s)
	s.setup(self, id)
	s.build(self)
	screens["__details__"] = s
	_last_focus.erase("__details__")

	var outgoing: Control = screens.get(current, null)
	current = "__details__"
	stack.append("__details__")
	_refresh_tabs("")
	s.visible = true
	s.position.x = 70
	var t := create_tween().set_parallel(true)
	t.tween_property(s, "modulate:a", 1.0, AppTheme.T_SCREEN * AppTheme.m()).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(s, "position:x", 0.0, AppTheme.T_SCREEN * AppTheme.m()).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if outgoing != null and outgoing != s:
		t.tween_property(outgoing, "modulate:a", 0.0, AppTheme.T_SCREEN * 0.7 * AppTheme.m())
	t.chain().tween_callback(func():
		if outgoing != null and outgoing != s:
			outgoing.visible = false
		_transitioning = false)
	var target: Control = s.call("default_focus")
	if target != null:
		target.call_deferred("grab_focus")

func back() -> void:
	if guide.open:
		guide.close()
		Sfx.play("back")
		return
	if not stack.is_empty():
		stack.pop_back()
		var target := "home"
		if not stack.is_empty():
			var cand: String = stack[stack.size() - 1]
			if cand != "__details__":
				target = cand
			stack.pop_back()
		go(target, false)
		Sfx.play("back")
	elif current != "home":
		go("home", false)
		Sfx.play("back")

## ------------------------------ ambiente/toast ------------------------------

func set_ambient(path: String, id: String) -> void:
	if id == ambient_id:
		return
	ambient_id = id
	var tw := create_tween()
	tw.tween_property(ambient, "modulate:a", 0.35, 0.22 * AppTheme.m())
	tw.tween_callback(func(): ambient_mat.set_shader_parameter("art", load(path)))
	tw.tween_property(ambient, "modulate:a", 1.0, 0.4 * AppTheme.m())

func toast(text: String) -> void:
	var panel := PanelContainer.new()
	var sb := AppTheme.sb_flat(Color(0.09, 0.09, 0.1, 0.97), 10)
	sb.content_margin_left = 22.0
	sb.content_margin_right = 22.0
	sb.content_margin_top = 12.0
	sb.content_margin_bottom = 12.0
	sb.border_width_top = 2
	sb.border_color = AppTheme.GREEN_BRIGHT
	panel.add_theme_stylebox_override("panel", sb)
	panel.add_child(AppTheme.label(text, 17, AppTheme.TEXT, true))
	_toast_layer.add_child(panel)
	panel.reset_size()
	await panel.get_tree().process_frame
	panel.position = Vector2((size.x - panel.size.x) / 2.0, size.y + 10)
	var t := create_tween()
	t.tween_property(panel, "position:y", size.y - 110.0, 0.28 * AppTheme.m()).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_interval(2.0)
	t.tween_property(panel, "modulate:a", 0.0, 0.3)
	t.tween_callback(panel.queue_free)

## ------------------------------ input global ------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not booted:
		_finish_boot()
		return
	if event.is_action_pressed("menu_guide"):
		if guide.open:
			guide.close()
		else:
			guide.open_panel()
		Sfx.play("select")
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("nav_shoulder_l") or event.is_action_pressed("nav_shoulder_r"):
		var dir := -1 if event.is_action_pressed("nav_shoulder_l") else 1
		_cycle_tab(dir)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		back()
		get_viewport().set_input_as_handled()

func _cycle_tab(dir: int) -> void:
	var idx := 0
	for i in TABS.size():
		if String(TABS[i][0]) == current:
			idx = i
			break
	idx = clampi(idx + dir, 0, TABS.size() - 1)
	stack.clear()
	go(String(TABS[idx][0]), false)

## analógico esquerdo -> ui_* com auto-repeat (suporte a gamepad estilo console)
func _process(delta: float) -> void:
	if not booted:
		return
	var v := Vector2(
		Input.get_joy_axis(0, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	var dead := 0.55
	if v.length() < dead:
		_stick_dir = Vector2.ZERO
		_stick_cd = 0.0
		return
	if v == _stick_dir:
		_stick_cd -= delta
		if _stick_cd > 0.0:
			return
	else:
		_stick_dir = v.normalized()
		_stick_cd = 0.42
	var action := ""
	if absf(v.x) > absf(v.y):
		action = "ui_right" if v.x > 0 else "ui_left"
	else:
		action = "ui_down" if v.y > 0 else "ui_up"
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	_stick_cd = 0.16

## hooks de QA
func _focus_first_tile() -> void:
	var s: Control = screens.get(current if current != "" else "home", null)
	if s is ScreenHome:
		(s as ScreenHome).hero._btn_primary.grab_focus()
		return
	if s != null:
		var b := _find_tile(s)
		if b != null:
			b.grab_focus()

func _find_tile(n: Node) -> Control:
	if n is TileButton:
		return n
	for c in n.get_children():
		var r := _find_tile(c)
		if r != null:
			return r
	return null

func _press_primary_action() -> void:
	var s: Control = screens.get(current, null)
	if s != null and s.has_method("default_focus"):
		var b: Control = s.call("default_focus")
		if b is Button:
			(b as Button).grab_focus()
			(b as Button).pressed.emit()
