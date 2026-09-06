class_name HeroCarousel
extends Control
## Hero banner rotativo: crossfade entre artes, Ken Burns sutil, gradient de
## legibilidade, CTA e indicadores — padrao do dashboard Xbox Series S.

signal details_requested(id: String)
signal hero_changed(game: Dictionary)

const HOLD := 7.0
const FADE := 0.9

var items: Array = []
var index := 0
var _art_a: TextureRect
var _art_b: TextureRect
var _using_a := true
var _info_title: Label
var _info_sub: Label
var _btn_primary: Button
var _btn_secondary: Button
var _dots: Array = []
var _dots_box: HBoxContainer
var _timer: Timer
var _rot_tween: Tween

func setup(heroes: Array) -> void:
	items = heroes
	custom_minimum_size = Vector2(0, 460)
	clip_contents = false

	_art_a = UiLib.tex_rect("")
	_art_b = UiLib.tex_rect("")
	for art in [_art_a, _art_b]:
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(art)
	_art_b.modulate.a = 0.0

	var grad := UiLib.v_gradient(0.0, 0.82, 400)
	grad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grad.offset_top = 60
	add_child(grad)

	_info_title = AppTheme.label("", 46, AppTheme.WHITE, true, true)
	_info_sub = AppTheme.label("", 18, Color(1, 1, 1, 0.78))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 14)
	_btn_primary = UiLib.action_button("Ver detalhes", true)
	_btn_secondary = UiLib.action_button("Loja", false)
	buttons.add_child(_btn_primary)
	buttons.add_child(_btn_secondary)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 8)
	info.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	info.offset_left = 44
	info.offset_right = -44
	info.offset_bottom = -36
	info.offset_top = -190
	info.alignment = BoxContainer.ALIGNMENT_END
	info.add_child(_info_sub)
	info.add_child(_info_title)
	info.add_child(UiLib.spacer(0, 4))
	info.add_child(buttons)
	add_child(info)

	_dots_box = HBoxContainer.new()
	_dots_box.add_theme_constant_override("separation", 8)
	_dots_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_dots_box.offset_left = -180
	_dots_box.offset_right = -44
	_dots_box.offset_bottom = -18
	_dots_box.offset_top = -34
	_dots_box.alignment = BoxContainer.ALIGNMENT_END
	add_child(_dots_box)

	_btn_primary.pressed.connect(func(): details_requested.emit(String(items[index].get("id", ""))))
	_btn_secondary.pressed.connect(func(): details_requested.emit("__store__"))

	_timer = Timer.new()
	_timer.wait_time = HOLD
	_timer.one_shot = false
	_timer.timeout.connect(next)
	add_child(_timer)

	if not items.is_empty():
		_apply(0, true)
		_timer.start()

func set_heroes(heroes: Array) -> void:
	items = heroes
	index = 0
	for d in _dots:
		d.queue_free()
	_dots.clear()
	for i in items.size():
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(22 if i == 0 else 8, 8)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.add_theme_stylebox_override("panel", AppTheme.sb_flat(AppTheme.GREEN_BRIGHT if i == 0 else Color(1, 1, 1, 0.35), 4))
		_dots_box.add_child(dot)
		_dots.append(dot)
	if not items.is_empty():
		_apply(0, true)
		_timer.start()

func next() -> void:
	if items.size() < 2:
		return
	_apply((index + 1) % items.size(), false)

func current() -> Dictionary:
	return items[index] if index < items.size() else {}

func _apply(i: int, instant: bool) -> void:
	index = i
	var g: Dictionary = items[i]
	var incoming := _art_a if _using_a else _art_b
	var outgoing := _art_b if _using_a else _art_a
	_using_a = not _using_a
	incoming.texture = load(String(g["art"]["hero"]))

	_info_title.text = String(g.get("title", ""))
	var sub := String(g.get("subtitle", ""))
	if g.get("coming_soon", false):
		sub += "   ·   EM BREVE"
	_info_sub.text = sub
	_btn_primary.text = "Ver detalhes"
	_btn_secondary.text = "Loja"

	for d_i in _dots.size():
		var dot: Panel = _dots[d_i]
		dot.custom_minimum_size.x = 22 if d_i == i else 8
		dot.add_theme_stylebox_override("panel", AppTheme.sb_flat(AppTheme.GREEN_BRIGHT if d_i == i else Color(1, 1, 1, 0.35), 4))

	if _rot_tween != null and _rot_tween.is_valid():
		_rot_tween.kill()

	if instant:
		incoming.modulate.a = 1.0
		outgoing.modulate.a = 0.0
	else:
		_rot_tween = create_tween().set_parallel(true)
		_rot_tween.tween_property(incoming, "modulate:a", 1.0, FADE * AppTheme.m()).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_rot_tween.tween_property(outgoing, "modulate:a", 0.0, FADE * AppTheme.m()).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# Ken Burns: leve zoom-out durante a exibicao
	incoming.pivot_offset = size / 2.0
	incoming.scale = Vector2(1.06, 1.06)
	var kb := create_tween()
	kb.tween_property(incoming, "scale", Vector2.ONE, HOLD * 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	hero_changed.emit(g)
