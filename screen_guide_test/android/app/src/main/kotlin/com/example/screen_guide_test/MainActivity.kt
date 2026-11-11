package com.example.screen_guide_test

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// 보고서 4.8 방식 B: Flutter는 경로만 넘기고, 분석은 Kotlin 모듈에서 끝낸다.
class MainActivity : FlutterActivity() {
    private lateinit var analyzer: Analyzer
    private lateinit var history: HistoryStore

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        analyzer = Analyzer(applicationContext)
        history = HistoryStore(applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "screen_guide/analyze")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "analyzeOcr" -> {
                        val path = call.argument<String>("path")
                        if (path == null) { result.error("no_path", null, null); return@setMethodCallHandler }
                        analyzer.analyzeOcr(path,
                            onDone = { analysis ->
                                try {
                                    val lines = analysis["lines"] as? List<*> ?: emptyList<Any>()
                                    val text = lines.filterIsInstance<String>().joinToString("\n")
                                        .ifBlank { "글자를 찾지 못했어요" }
                                    val id = history.save(text)
                                    result.success(analysis + ("historyId" to id))
                                } catch (_: Exception) {
                                    result.error("history_save_failed", null, null)
                                }
                            },
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "screen_guide/history")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "list" -> result.success(history.list())
                        "delete" -> result.success(history.delete(call.argument<String>("id") ?: ""))
                        "shareText" -> {
                            val text = call.argument<String>("text") ?: ""
                            if (text.isBlank()) { result.error("empty_text", null, null); return@setMethodCallHandler }
                            val intent = Intent(Intent.ACTION_SEND).apply {
                                type = "text/plain"
                                putExtra(Intent.EXTRA_TEXT, text)
                            }
                            startActivity(Intent.createChooser(intent, "분석 결과 공유"))
                            result.success(null)
                        }
                        "releaseImage" -> {
                            val path = call.argument<String>("path") ?: ""
                            val target = File(path).canonicalFile
                            val roots = listOfNotNull(cacheDir, externalCacheDir).map { it.canonicalFile }
                            // Never delete the user's gallery original or any file outside app cache.
                            val owned = roots.any { target.path.startsWith(it.path + File.separator) }
                            result.success(owned && target.isFile && target.delete())
                        }
                        "purgeCachedImages" -> {
                            val keep = call.argument<String>("keepPath")
                            val extensions = setOf("jpg", "jpeg", "png", "webp", "heic", "heif")
                            var removed = 0
                            for (root in listOfNotNull(cacheDir, externalCacheDir)) {
                                root.walkTopDown().filter { it.isFile && it.extension.lowercase() in extensions }
                                    .forEach { file ->
                                        if (file.canonicalPath != keep && file.delete()) removed++
                                    }
                            }
                            result.success(removed)
                        }
                        else -> result.notImplemented()
                    }
                } catch (_: Exception) {
                    result.error("history_operation_failed", null, null)
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
