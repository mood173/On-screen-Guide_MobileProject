import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

// 화면길잡이 시험 앱: Flutter 화면 → MethodChannel → Kotlin(ML Kit + 보고서 로직) → 결과 표시
void main() => runApp(const ScreenGuideTestApp());

class ScreenGuideTestApp extends StatelessWidget {
  const ScreenGuideTestApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '화면길잡이 시험',
        theme: ThemeData(colorSchemeSeed: const Color(0xFF1F3A5F), useMaterial3: true,
            textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 16))),
        home: const HomePage(),
      );
}

const _channel = MethodChannel('screen_guide/analyze');

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _selector = TextEditingController(text: '알림 설정');
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<String?> Function() getPath) async {
    setState(() { _busy = true; _error = null; });
    try {
      final path = await getPath();
      if (path == null) return;                       // 사용자 취소
      final res = await _channel.invokeMapMethod<String, dynamic>(
          'analyze', {'path': path, 'selector': _selector.text});
      debugPrint('[ScreenGuide] ocr=${res?['ocrMs']}ms total=${res?['totalMs']}ms '
          'screen=${res?['screenId']} target=${res?['target']} '
          'privacy=${(res?['privacy'] as List?)?.length} entity=${res?['entityStatus']}');
      if (!mounted || res == null) return;
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResultPage(path: path, res: res)));
    } on PlatformException catch (e) {
      setState(() => _error = '분석하지 못했어요 (${e.code}). 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _sample(String name) async {
    final data = await rootBundle.load('assets/samples/$name');
    final f = File('${Directory.systemTemp.path}/$name');
    await f.writeAsBytes(data.buffer.asUint8List());
    return f.path;
  }

  Future<String?> _gallery() async =>
      (await ImagePicker().pickImage(source: ImageSource.gallery, requestFullMetadata: false))?.path;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('화면길잡이 시험')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          TextField(controller: _selector,
              decoration: const InputDecoration(labelText: '찾을 기능(선택자)', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          FilledButton(onPressed: _busy ? null : () => _run(() => _sample('sample_settings.png')),
              child: const Text('샘플 1: 설정 화면 분석')),
          const SizedBox(height: 10),
          FilledButton(onPressed: _busy ? null : () => _run(() => _sample('sample_chat.png')),
              child: const Text('샘플 2: 메시지 화면 분석')),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: _busy ? null : () => _run(_gallery), child: const Text('갤러리에서 선택')),
          const SizedBox(height: 20),
          if (_busy) const Center(child: CircularProgressIndicator()),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 20),
          const Text('이미지는 휴대폰 안에서만 분석하고 외부로 보내지 않습니다.',
              style: TextStyle(fontSize: 14, color: Colors.black54)),
        ]),
      );
}

class ResultPage extends StatelessWidget {
  final String path;
  final Map<String, dynamic> res;
  const ResultPage({super.key, required this.path, required this.res});

  @override
  Widget build(BuildContext context) {
    final els = (res['elements'] as List).cast<Map>();
    final privacy = (res['privacy'] as List).cast<Map>();
    final w = (res['imageWidth'] as num).toDouble(), h = (res['imageHeight'] as num).toDouble();
    return Scaffold(
      appBar: AppBar(title: const Text('분석 결과')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        AspectRatio(aspectRatio: w / h, child: LayoutBuilder(builder: (_, c) {
          final s = c.maxWidth / w;
          return Stack(children: [
            Positioned.fill(child: Image.file(File(path), fit: BoxFit.fill)),
            for (final e in els)
              Positioned(
                left: (e['l'] as num) * s, top: (e['t'] as num) * s,
                width: ((e['r'] as num) - (e['l'] as num)) * s, height: ((e['b'] as num) - (e['t'] as num)) * s,
                child: DecoratedBox(decoration: BoxDecoration(border: Border.all(
                    color: e['isTarget'] == true ? const Color(0xFFF08C00) : const Color(0x991C7ED6),
                    width: e['isTarget'] == true ? 3 : 1))),
              ),
          ]);
        })),
        const SizedBox(height: 12),
        _row('식별된 화면', '${res['screenId'] ?? '없음'}'),
        _row('찾을 기능', '${res['selector']} → ${res['target'] ?? '찾지 못함 (다시 촬영 안내)'}'),
        _row('인식한 줄', '${els.length}개 (파란 테두리), 목표는 주황 테두리'),
        _row('처리 시간', 'OCR ${res['ocrMs']}ms · 전체 ${res['totalMs']}ms (에뮬레이터 기준)'),
        _row('개체 추출', '${res['entityStatus']}'),
        const Divider(),
        Text('개인정보 후보 ${privacy.length}건', style: const TextStyle(fontWeight: FontWeight.bold)),
        for (final p in privacy) Text('• ${p['types']}  ${p['masked']}'),
        if (privacy.isEmpty) const Text('후보 없음 (개인정보가 없음을 보증하지 않습니다)'),
      ]),
    );
  }

  Widget _row(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 90, child: Text(k, style: const TextStyle(color: Colors.black54))),
        Expanded(child: Text(v)),
      ]));
}
