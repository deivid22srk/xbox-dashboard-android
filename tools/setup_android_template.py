#!/usr/bin/env python3
"""Prepara o gradle build template do Godot para o export Android do SeriesDash.

1. Extrai android_source.zip dos export templates -> android/build/ (com
   .build_version e .gdignore, como o "Install Android Build Template" do editor).
2. Injeta no manifest as permissoes INTERNET + REQUEST_INSTALL_PACKAGES.
3. Copia o fonte InstallBridge.java para dentro do modulo app do template
   (compilado junto do app pelo gradle — sem gdap/AAR externo).
4. Registra o InstallBridge via meta-data org.godotengine.plugin.v2.*
   no <application> (GodotPluginRegistry descobre por reflexao em runtime).
5. Garante a dependencia androidx.core no build.gradle do template (para o
   FileProvider importado pelo InstallBridge.java; o provider em si JA EXISTE
   no godot-lib com autoridade ${applicationId}.fileprovider e files-path
   cobrindo o user:// — nao adicionamos outro).
6. Escreve local.properties com sdk.dir quando ANDROID_HOME esta definido.
7. GODOT_GRADLE_XMX opcional: reduz o heap do daemon gradle em maquinas pequenas.

Idempotente: pode rodar varias vezes. Requer export templates 4.4.1 instalados.
"""
import os
import re
import shutil
import sys
import zipfile

VERSION_DIR = "4.4.1.stable"
TEMPLATES_DIR = os.environ.get(
    "GODOT_TEMPLATES_DIR",
    os.path.expanduser("~/.local/share/godot/export_templates"),
)
PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUILD_DIR = os.path.join(PROJECT, "android", "build")
PLUGIN_PKG = "org/godotengine/plugin/installbridge"
PLUGIN_CLASS = "org.godotengine.plugin.installbridge.InstallBridge"


def fail(msg: str) -> None:
    print(f"[setup_android_template] ERRO: {msg}")
    sys.exit(1)


def main() -> None:
    src = os.path.join(TEMPLATES_DIR, VERSION_DIR, "android_source.zip")
    if not os.path.exists(src):
        fail(f"android_source.zip nao encontrado em {src}. Instale os export templates 4.4.1.")

    # ------------------------------------------------------------------
    # 1. Extrai o template gradle
    # ------------------------------------------------------------------
    os.makedirs(BUILD_DIR, exist_ok=True)
    with zipfile.ZipFile(src) as z:
        z.extractall(BUILD_DIR)
    print(f"[setup_android_template] template extraido em {BUILD_DIR}")

    # ------------------------------------------------------------------
    # 1b. .build_version (no PAI de android/build) e .gdignore (dentro de
    #     android/build) — equivalente exato ao "Install Android Build
    #     Template" do editor: versiona o template e impede o scan/import.
    # ------------------------------------------------------------------
    parent_dir = os.path.dirname(BUILD_DIR)
    with open(os.path.join(parent_dir, ".build_version"), "w", encoding="utf-8") as f:
        f.write(VERSION_DIR + "\n")
    with open(os.path.join(BUILD_DIR, ".gdignore"), "w", encoding="utf-8") as f:
        f.write("\n")
    gradlew = os.path.join(BUILD_DIR, "gradlew")
    if os.path.exists(gradlew):
        os.chmod(gradlew, 0o755)  # extractall() nao preserva o bit de execucao do zip
    print(f"[setup_android_template] android/.build_version={VERSION_DIR} e android/build/.gdignore criados")

    manifest_path = os.path.join(BUILD_DIR, "AndroidManifest.xml")
    if not os.path.exists(manifest_path):
        fail(f"AndroidManifest.xml ausente apos extracao: {manifest_path}")
    with open(manifest_path, "r", encoding="utf-8") as f:
        manifest = f.read()

    # ------------------------------------------------------------------
    # 2. Permissoes
    # ------------------------------------------------------------------
    perms = ""
    if "android.permission.INTERNET" not in manifest:
        perms += '<uses-permission android:name="android.permission.INTERNET"/>\n    '
    if "android.permission.REQUEST_INSTALL_PACKAGES" not in manifest:
        perms += '<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>\n    '
    if perms:
        m = re.search(r"<manifest[^>]*>", manifest)
        if not m:
            fail("tag <manifest> nao encontrada")
        end = m.end()
        manifest = manifest[:end] + "\n    " + perms + manifest[end:]
        print("[setup_android_template] permissoes inseridas")

    # ------------------------------------------------------------------
    # 3. FileProvider: JA EXISTE no godot-lib (autoridade ${applicationId}.
    #    fileprovider + @xml/godot_provider_paths com files-path "/").
    #    Adicionar outro conflita no manifest merger — nada a fazer aqui.
    # ------------------------------------------------------------------

    # ------------------------------------------------------------------
    # 4. Meta-data de registro do plugin (dentro de <application>)
    # ------------------------------------------------------------------
    if "org.godotengine.plugin.v2.InstallBridge" not in manifest:
        meta = (
            '<meta-data\n'
            '            android:name="org.godotengine.plugin.v2.InstallBridge"\n'
            f'            android:value="{PLUGIN_CLASS}"/>\n\n    '
        )
        m = re.search(r"<application[^>]*>", manifest)
        if not m:
            fail("tag <application> nao encontrada")
        end = m.end()
        manifest = manifest[:end] + "\n    " + meta + manifest[end:]
        print("[setup_android_template] meta-data v2 do InstallBridge inserido")

    with open(manifest_path, "w", encoding="utf-8") as f:
        f.write(manifest)

    # ------------------------------------------------------------------
    # 6. InstallBridge.java -> modulo raiz do template (java.srcDirs = ['src'])
    # ------------------------------------------------------------------
    src_java = os.path.join(
        PROJECT, "android", "plugins", "InstallBridge", "src", PLUGIN_PKG, "InstallBridge.java"
    )
    dst_java = os.path.join(BUILD_DIR, "src", PLUGIN_PKG, "InstallBridge.java")
    if not os.path.exists(src_java):
        fail(f"fonte do InstallBridge ausente: {src_java}")
    os.makedirs(os.path.dirname(dst_java), exist_ok=True)
    shutil.copyfile(src_java, dst_java)
    print(f"[setup_android_template] InstallBridge.java copiado para {dst_java}")

    # ------------------------------------------------------------------
    # 5. androidx.core no build.gradle (FileProvider import do InstallBridge;
    #    o provider vem pronto do godot-lib)
    # ------------------------------------------------------------------
    gradle_path = os.path.join(BUILD_DIR, "build.gradle")
    if not os.path.exists(gradle_path):
        fail(f"build.gradle do template ausente: {gradle_path}")
    with open(gradle_path, "r", encoding="utf-8") as f:
        gradle = f.read()
    if not re.search(r"androidx\.core:core(?!-)", gradle):
        if re.search(r"dependencies\s*\{", gradle):
            gradle = re.sub(
                r"(dependencies\s*\{)",
                r"\1\n    implementation 'androidx.core:core:1.13.1'",
                gradle,
                count=1,
            )
        else:
            gradle += "\ndependencies {\n    implementation 'androidx.core:core:1.13.1'\n}\n"
        with open(gradle_path, "w", encoding="utf-8") as f:
            f.write(gradle)
        print("[setup_android_template] androidx.core adicionado ao build.gradle")
    else:
        print("[setup_android_template] androidx.core ja presente")

    # ------------------------------------------------------------------
    # 7b. Ajuste de memoria do gradle para maquinas pequenas (opcional).
    #     O template fixa -Xmx4536m; em maquinas com pouca RAM isso trava
    #     o daemon. GODOT_GRADLE_XMX=1536m reduz o heap e roda o Kotlin
    #     in-process. CI (runners grandes) pode omitir.
    # ------------------------------------------------------------------
    gradle_props_path = os.path.join(BUILD_DIR, "gradle.properties")
    with open(gradle_props_path, "r", encoding="utf-8") as f:
        gprops = f.read()
    gradle_xmx = os.environ.get("GODOT_GRADLE_XMX")
    if gradle_xmx and "org.gradle.jvmargs=" in gprops:
        gprops = re.sub(r"org\.gradle\.jvmargs=-Xmx\d+[mMgG]", f"org.gradle.jvmargs=-Xmx{gradle_xmx}", gprops)
        if "kotlin.compiler.execution.strategy" not in gprops:
            gprops += "\nkotlin.compiler.execution.strategy=in-process\norg.gradle.workers.max=2\n"
        with open(gradle_props_path, "w", encoding="utf-8") as f:
            f.write(gprops)
        print(f"[setup_android_template] gradle jvmargs ajustado para -Xmx{gradle_xmx}")

    # ------------------------------------------------------------------
    # 8. local.properties com sdk.dir (se ANDROID_HOME definido)
    # ------------------------------------------------------------------
    sdk_home = os.environ.get("GODOT_SDK_HOME") or os.environ.get("ANDROID_HOME")
    if sdk_home:
        with open(os.path.join(BUILD_DIR, "local.properties"), "w", encoding="utf-8") as f:
            f.write(f"sdk.dir={sdk_home}\n")
        print(f"[setup_android_template] local.properties -> sdk.dir={sdk_home}")
    else:
        print("[setup_android_template] ANDROID_HOME nao definido; local.properties omitido")

    print("[setup_android_template] OK")


if __name__ == "__main__":
    main()
