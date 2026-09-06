class_name ScreenHome
extends Control
## Home do dashboard: hero rotativo + fileiras horizontais + cartoes largos,
## fiel as referencias do Xbox Series S.

var hero: HeroCarousel
var _rows_box: VBoxContainer
var _built := false

const ACTION_COLORS := {
        "store": Color("2d4a2f"),
        "collection": Color("3a2d4a"),
        "settings": Color("2d354a"),
}

func build(main) -> void:
        if _built:
                return
        _built = true

        var scroll := ScrollContainer.new()
        scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
        scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
        add_child(scroll)

        var col := VBoxContainer.new()
        col.add_theme_constant_override("separation", 18)
        col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        col.size_flags_vertical = Control.SIZE_EXPAND_FILL
        scroll.add_child(col)

        hero = HeroCarousel.new()
        hero.custom_minimum_size = Vector2(0, 440)
        hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        col.add_child(hero)
        var heroes: Array = []
        for hid in GameState.catalog.get("hero_order", []):
                var hg := GameState.game_by_id(String(hid))
                if not hg.is_empty() and hg.get("art", {}).has("hero"):
                        heroes.append(hg)
        hero.setup(heroes)
        hero.details_requested.connect(func(id: String):
                if id == "__store__":
                        main.go("store")
                else:
                        main.open_details(id))
        hero.hero_changed.connect(func(g): main.set_ambient(String(g["art"]["hero"]), String(g.get("id", ""))))

        _rows_box = VBoxContainer.new()
        _rows_box.add_theme_constant_override("separation", 16)
        col.add_child(_rows_box)

        var home_rows: Dictionary = GameState.catalog.get("home_rows", {})

        # Continuar jogando (so aparece se houver algo instalado)
        var installed_ids: Array = GameState.installed.keys()
        if not installed_ids.is_empty():
                var row_play := TileRow.new()
                row_play.setup("Continuar jogando")
                for id in installed_ids:
                        var g := GameState.game_by_id(String(id))
                        if not g.is_empty():
                                row_play.add_game(g, 1.0, func(game): main.open_details(String(game["id"])))
                _rows_box.add_child(row_play)

        var row_rec := TileRow.new()
        row_rec.setup("Recomendados para você" if installed_ids.is_empty() else "Você também pode gostar")
        for id in home_rows.get("recomendados", []):
                var g := GameState.game_by_id(String(id))
                if not g.is_empty():
                        row_rec.add_game(g, 1.0, func(game): main.open_details(String(game["id"])))
        _rows_box.add_child(row_rec)

        # Cartoes largos de exploracao (padrao "Browse the store" da referencia)
        var row_wide := TileRow.new()
        row_wide.setup("Explorar")
        row_wide.add_action("__store__", "Ir para a Loja", "Novos jogos esperando por você", ACTION_COLORS["store"], func(): main.go("store"))
        row_wide.add_action("__collection__", "Minha Coleção", "Jogos instalados no aparelho", ACTION_COLORS["collection"], func(): main.go("collection"))
        row_wide.add_action("__settings__", "Configurações", "Perfil, som e sistema", ACTION_COLORS["settings"], func(): main.go("settings"))
        _rows_box.add_child(row_wide)

        var row_new := TileRow.new()
        row_new.setup("Novo na loja")
        for id in home_rows.get("novidades", []):
                var g := GameState.game_by_id(String(id))
                if not g.is_empty():
                        row_new.add_game(g, 1.0, func(game): main.open_details(String(game["id"])))
        _rows_box.add_child(row_new)
        _rows_box.add_child(UiLib.spacer(0, 28))

func default_focus() -> Control:
        return hero._btn_primary

func on_shown(main) -> void:
        pass
