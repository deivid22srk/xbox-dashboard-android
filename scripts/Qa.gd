extends Node
## Harness de QA visual: roda com `godot -- --qa --qa-out <dir>` e captura
## screenshots de todas as telas (usados pelo Agente Critico e pelo README).

var out_dir := "/tmp/seriesdash_qa"
var enabled := false

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	enabled = args.has("--qa")
	for i in args.size():
		if args[i] == "--qa-out" and i + 1 < args.size():
			out_dir = args[i + 1]
	if not enabled:
		set_process(false)
		return
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run()

func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir + "/" + shot_name + ".png")
	print("[QA] shot: ", shot_name)

func _main() -> Node:
	return get_tree().root.get_node_or_null("Main")

func _run() -> void:
	# espera o boot terminar
	var deadline := Time.get_ticks_msec() + 15000
	while _main() == null or not _main().get("booted"):
		if Time.get_ticks_msec() > deadline:
			break
		await get_tree().create_timer(0.1).timeout
	var main := _main()
	if main == null:
		print("[QA] Main nao encontrado")
		get_tree().quit(1)
		return

	await get_tree().create_timer(1.6).timeout
	await _shot("01_home")

	# foco na primeira fileira de tiles
	main._focus_first_tile()
	await get_tree().create_timer(0.5).timeout
	await _shot("02_home_tiles_foco")

	main.go("store", false)
	await get_tree().create_timer(0.5).timeout
	await _shot("03_store_skeleton")
	await get_tree().create_timer(1.4).timeout
	await _shot("04_store")

	main.open_details("dk64-recomp")
	await get_tree().create_timer(1.8).timeout
	await _shot("05_detalhes")

	# download real (release v1.0.3 do dk64) com progresso visivel
	var dm: DownloadManager = main.get_node("Downloads")
	dm.state_changed.connect(func(id, st): print("[QA] download estado: ", id, " -> ", st))
	dm.progress.connect(func(id, have, total, sp, eta):
		if int(have) % 900000 < 200000:
			print("[QA] progresso: %d/%d (%.1f MB/s)" % [have, total, sp / 1048576.0]))
	main.open_details("dk64-recomp")
	await get_tree().create_timer(1.5).timeout
	main._press_primary_action()
	await get_tree().create_timer(2.2).timeout
	await _shot("06_detalhes_baixando")

	main.get_node("Downloads").pause("dk64-recomp")
	await get_tree().create_timer(0.4).timeout
	await _shot("07_detalhes_pausado")
	main.get_node("Downloads").cancel("dk64-recomp")

	main.go("collection", false)
	await get_tree().create_timer(0.5).timeout
	await _shot("08_colecao")

	main.go("settings", false)
	await get_tree().create_timer(0.5).timeout
	await _shot("09_config")

	main.guide.open_panel()
	await get_tree().create_timer(0.6).timeout
	await _shot("10_guia")
	main.guide.close()

	print("[QA] concluido")
	await get_tree().create_timer(0.3).timeout
	get_tree().quit(0)
