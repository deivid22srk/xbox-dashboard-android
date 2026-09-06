#!/usr/bin/env python3
"""Prepara o gradle build template do Godot para o export Android do SeriesDash.

1. Extrai android_source.zip dos export templates -> android/build/
2. Injeta no manifest: permissoes INTERNET + REQUEST_INSTALL_PACKAGES e o
   FileProvider (necessario para o plugin InstallBridge acionar o instalador).
3. Copia tools/file_paths.xml -> android/build/res/xml/
4. Garante a dependencia androidx.core no build.gradle do template.

Idempotente: pode rodar varias vezes. Requer export templates 4.4.1 instalados.
"""
import os
import re
import sys
import zipfile

VERSION_DIR = "4.4.1.stable"
TEMPLATES_DIR = os.environ.get(
    "GODOT_TEMPLATES_DIR",
    os.path.expanduser("~/.local/share/godot/export_templates"),
)
PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUILD_DIR = os.path.join(PROJECT, "android", "build")


def fail(msg: str) -> None:
    print(f"[setup_android_template] ERRO: {msg}")
    sys.exit(1)


def main() -> None:
    src = os.path.join(TEMPLATES_DIR, VERSION_DIR, "android_source.zip")
    if not os.path.exists(src):
        fail(f"android_source.zip nao encontrado em {src}. Instale os export templates 4.4.1.")

    os.makedirs(BUILD_DIR, exist_ok=True)
    with zipfile.ZipFile(src) as z:
        z.extractall(BUILD_DIR)
    print(f"[setup_android_template] template extraido em {BUILD_DIR}")

    manifest_path = os.path.join(BUILD_DIR, "AndroidManifest.xml")
    if not os.path.exists(manifest_path):
        fail(f"AndroidManifest.xml ausente apos extracao: {manifest_path}")
    with open(manifest_path, "r", encoding="utf-8") as f:
        manifest = f.read()

    perms = ""
    if "android.permission.INTERNET" not in manifest:
        perms += '<uses-permission android:name="android.permission.INTERNET"/>\n'
    if "android.permission.REQUEST_INSTALL_PACKAGES" not in manifest:
        perms += '<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>\n'
    if perms:
        # insere logo apos a tag <manifest ...> de abertura
        m = re.search(r"<manifest[^>]*>", manifest)
        if not m:
            fail("tag <manifest> nao encontrada")
        end = m.end()
        manifest = manifest[:end] + "\n    " + perms + manifest[end:]
        print("[setup_android_template] permissoes inseridas")

    if "androidx.core.content.FileProvider" not in manifest:
        provider = (
            '<provider\n'
            '            android:name="androidx.core.content.FileProvider"\n'
            '            android:authorities="${applicationId}.fileprovider"\n'
            '            android:exported="false"\n'
            '            android:grantUriPermissions="true">\n'
            '            <meta-data\n'
            '                android:name="android.support.FILE_PROVIDER_PATHS"\n'
            '                android:resource="@xml/file_paths"/>\n'
            '        </provider>\n\n    '
        )
        if "</application>" not in manifest:
            fail("tag </application> nao encontrada")
        manifest = manifest.replace("</application>", provider + "</application>", 1)
        print("[setup_android_template] FileProvider inserido")

    with open(manifest_path, "w", encoding="utf-8") as f:
        f.write(manifest)

    # file_paths.xml
    xml_dir = os.path.join(BUILD_DIR, "res", "xml")
    os.makedirs(xml_dir, exist_ok=True)
    with open(os.path.join(PROJECT, "tools", "file_paths.xml"), "r", encoding="utf-8") as f:
        file_paths = f.read()
    with open(os.path.join(xml_dir, "file_paths.xml"), "w", encoding="utf-8") as f:
        f.write(file_paths)
    print("[setup_android_template] res/xml/file_paths.xml garantido")

    # androidx.core no build.gradle
    gradle_path = os.path.join(BUILD_DIR, "build.gradle")
    with open(gradle_path, "r", encoding="utf-8") as f:
        gradle = f.read()
    if "androidx.core:core" not in gradle:
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

    print("[setup_android_template] OK")


if __name__ == "__main__":
    main()
