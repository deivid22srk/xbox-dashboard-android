class_name InstallBridge
## Ponte GDScript -> plugin Android minimo (cascão permitido: instalador/permissões).
## No desktop todas as chamadas viram no-op seguros para desenvolvimento/QA.

static func available() -> bool:
	return OS.has_feature("android") and Engine.has_singleton("InstallBridge")

static func install_apk(path: String) -> void:
	if available():
		Engine.get_singleton("InstallBridge").install_apk(path)

static func can_install_packages() -> bool:
	if available():
		return Engine.get_singleton("InstallBridge").can_install_packages()
	return true # desktop: assume permitido (fluxo simulado)

static func open_install_permission_settings() -> void:
	if available():
		Engine.get_singleton("InstallBridge").open_install_permission_settings()

static func is_package_installed(pkg: String) -> bool:
	if available() and pkg != "":
		return Engine.get_singleton("InstallBridge").is_package_installed(pkg)
	return false

static func launch_app(pkg: String) -> void:
	if available():
		Engine.get_singleton("InstallBridge").launch_app(pkg)
