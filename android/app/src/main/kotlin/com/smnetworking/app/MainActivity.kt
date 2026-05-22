package com.smnetworking.app

import android.os.Build
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.smnetworking.app/install_session"
        ).setMethodCallHandler { call, result ->
            if (call.method == "getInstallId") {
                try {
                    val installTime = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        packageManager.getPackageInfo(
                            packageName,
                            PackageManager.PackageInfoFlags.of(0)
                        ).firstInstallTime
                    } else {
                        @Suppress("DEPRECATION")
                        packageManager.getPackageInfo(packageName, 0).firstInstallTime
                    }
                    result.success(installTime.toString())
                } catch (e: Exception) {
                    result.error("INSTALL_ID_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
