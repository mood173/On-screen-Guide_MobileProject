package com.example.screen_guide_test

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// 보고서 4.8 방식 B: Flutter는 경로만 넘기고, 분석은 Kotlin 모듈에서 끝낸다.
class MainActivity : FlutterActivity() {
    private lateinit var analyzer: Analyzer

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        analyzer = Analyzer(applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "screen_guide/analyze")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "analyzeOcr" -> {
                        val path = call.argument<String>("path")
                        if (path == null) { result.error("no_path", null, null); return@setMethodCallHandler }
                        analyzer.analyzeOcr(path,
                            onDone = { result.success(it) },
                            onError = { code -> result.error(code, null, null) })
                    }
                    "analyze" -> {
                        val path = call.argument<String>("path")
                        val selector = call.argument<String>("selector") ?: ""
                        if (path == null) { result.error("no_path", null, null); return@setMethodCallHandler }
                        analyzer.analyze(path, selector,
                            onDone = { result.success(it) },
                            onError = { code -> result.error(code, null, null) })
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "screen_guide/settings")
            .setMethodCallHandler { call, result ->
                if (call.method == "openAppSettings") {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.parse("package:$packageName"))
                    startActivity(intent)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
