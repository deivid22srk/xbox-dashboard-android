class_name InstallBridge
## Ponte GDScript -> plugin Android minimo (cascão permitido: instalador/permissões).
## No desktop todas as chamadas viram no-op seguros para desenvolvimento/QA.

static func available() -> bool:
        return OS.has_feature("android") and Engine.has_singleton("InstallBridge")

static func install_apk(path: String) -> void:
        if available():
                Engine.get_singleton("InstallBridge").installApk(path)

static func can_install_packages() -> bool:
        if available():
                return Engine.get_singleton("InstallBridge").canInstallPackages()
        return true # desktop: assume permitido (fluxo simulado)

static func open_install_permission_settings() -> void:
        if available():
                Engine.get_singleton("InstallBridge").openInstallPermissionSettings()

static func is_package_installed(pkg: String) -> bool:
        if available() and pkg != "":
                return Engine.get_singleton("InstallBridge").isPackageInstalled(pkg)
        return false

static func launch_app(pkg: String) -> void:
        if available():
                Engine.get_singleton("InstallBridge").launchApp(pkg)
