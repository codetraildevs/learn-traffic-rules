package com.rw.drivingprep

import android.os.Bundle
import android.view.WindowManager
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.rw.drivingprep/security"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Enable edge-to-edge display for Android 15+ (API 35+)
        // This is required for apps targeting SDK 35 and addresses Play Store warnings
        // FlutterActivity doesn't extend ComponentActivity, so we manually configure edge-to-edge
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        // Handle system bars using ONLY modern WindowInsetsController API
        // DO NOT use deprecated APIs: setStatusBarColor, setNavigationBarColor, 
        // setNavigationBarDividerColor - these are deprecated in Android 15 (API 35)
        val windowInsetsController = ViewCompat.getWindowInsetsController(window.decorView)
        windowInsetsController?.let { controller ->
            // Configure system bars appearance using modern API only
            controller.isAppearanceLightStatusBars = true
            controller.isAppearanceLightNavigationBars = true
            
            // Ensure system bars are visible
            controller.show(WindowInsetsCompat.Type.systemBars())
            
            // Note: We intentionally do NOT set window.statusBarColor or window.navigationBarColor
            // as these are deprecated in Android 15. The WindowInsetsController handles
            // all system bar styling through the modern API.
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "disableScreenshots" -> {
                    disableScreenshots()
                    result.success(true)
                }
                "enableScreenshots" -> {
                    enableScreenshots()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun disableScreenshots() {
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    private fun enableScreenshots() {
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
