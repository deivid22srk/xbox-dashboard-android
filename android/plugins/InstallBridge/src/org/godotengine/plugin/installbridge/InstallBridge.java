package org.godotengine.plugin.installbridge;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import android.util.Log;

import androidx.core.content.FileProvider;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;

import java.io.File;

/**
 * Cascão mínimo do SeriesDash — EXCLUSIVO para empacotamento/permissões/instalador
 * (escopo explicitamente permitido). Nenhuma UI ou lógica de aplicativo vive aqui:
 * toda a interface e regras do app estão em GDScript.
 */
public class InstallBridge extends GodotPlugin {

    private static final String TAG = "InstallBridge";

    public InstallBridge(Godot godot) {
        super(godot);
    }

    @Override
    public String getPluginName() {
        return "InstallBridge";
    }

    /** Aciona o instalador do Android para o APK em path (storage interno do app). */
    @UsedByGodot
    public void installApk(final String path) {
        final Activity activity = getActivity();
        if (activity == null) {
            return;
        }
        activity.runOnUiThread(() -> {
            try {
                File apk = new File(path);
                Uri uri = FileProvider.getUriForFile(
                        activity,
                        activity.getPackageName() + ".fileprovider",
                        apk);
                Intent intent = new Intent(Intent.ACTION_VIEW);
                intent.setDataAndType(uri, "application/vnd.android.package-archive");
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION
                        | Intent.FLAG_ACTIVITY_NEW_TASK);
                activity.startActivity(intent);
            } catch (Exception e) {
                Log.e(TAG, "installApk falhou para " + path, e);
            }
        });
    }

    /** true se já podemos instalar pacotes (fontes desconhecidas). */
    @UsedByGodot
    public boolean canInstallPackages() {
        Activity activity = getActivity();
        if (activity == null) {
            return false;
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            return activity.getPackageManager().canRequestPackageInstalls();
        }
        return true;
    }

    /** Abre a tela de sistema "Instalar apps desconhecidos" para este app. */
    @UsedByGodot
    public void openInstallPermissionSettings() {
        final Activity activity = getActivity();
        if (activity == null) {
            return;
        }
        activity.runOnUiThread(() -> {
            try {
                Intent intent = new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES);
                intent.setData(Uri.parse("package:" + activity.getPackageName()));
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                activity.startActivity(intent);
            } catch (Exception e) {
                Log.e(TAG, "openInstallPermissionSettings falhou", e);
            }
        });
    }

    /** Checagem de coleção: o pacote já está instalado? */
    @UsedByGodot
    public boolean isPackageInstalled(String pkg) {
        Activity activity = getActivity();
        if (activity == null || pkg == null || pkg.isEmpty()) {
            return false;
        }
        try {
            activity.getPackageManager().getPackageInfo(pkg, 0);
            return true;
        } catch (PackageManager.NameNotFoundException e) {
            return false;
        }
    }

    /** Atalho "Abrir": lança a activity principal do pacote, se existir. */
    @UsedByGodot
    public void launchApp(String pkg) {
        final Activity activity = getActivity();
        if (activity == null || pkg == null || pkg.isEmpty()) {
            return;
        }
        activity.runOnUiThread(() -> {
            try {
                Intent intent = activity.getPackageManager().getLaunchIntentForPackage(pkg);
                if (intent != null) {
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    activity.startActivity(intent);
                }
            } catch (Exception e) {
                Log.e(TAG, "launchApp falhou para " + pkg, e);
            }
        });
    }
}
