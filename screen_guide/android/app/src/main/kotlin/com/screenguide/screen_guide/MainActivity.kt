package com.screenguide.screen_guide

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// 보고서 4.8 방식 B: Flutter는 경로와 맵 조각만 넘기고, 분석은 Kotlin 모듈에서 끝낸다.
// 실패도 result.error가 아니라 result.success(오류 응답 본문)로 알린다 (협업규격_최종 3.3).
class MainActivity : FlutterActivity() {
    private lateinit var analyzer: Analyzer

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        analyzer = Analyzer(applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "screen_guide/analyze")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "analyze" -> {
                        val req = ChannelCodec.decode(call.arguments)
                        if (req == null) {
                            result.success(ChannelCodec.error(ChannelCodec.requestIdOf(call.arguments), ChannelCodec.NO_PATH))
                        } else {
                            analyzer.analyze(req) { result.success(it) }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
