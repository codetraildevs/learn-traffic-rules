package com.trafficrules.master

import android.os.Bundle
import android.view.WindowManager
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.trafficrules.master/security"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Enable edge-to-edge display for Android 15+ (API 35+)
        // This is required for apps targeting SDK 35 and addresses Play Store warnings
        // By enabling edge-to-edge, we avoid using deprecated APIs like setStatusBarColor
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        // Handle system bars appropriately for different Android versions
        val decorView = window.decorView
        val windowInsetsController = ViewCompat.getWindowInsetsController(decorView)
        windowInsetsController?.let { controller ->
            // Make navigation bar transparent and use light appearance
            controller.isAppearanceLightNavigationBars = true
            // Show system bars (status and navigation bars)
            controller.show(WindowInsetsCompat.Type.systemBars())
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
