import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const ScreenGuideTestApp());

enum _Page { home, preview, display, denied, error }

class ScreenGuideTestApp extends StatelessWidget {
  const ScreenGuideTestApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '화면길잡이 · 이미지 입력',
    theme: ThemeData(
      colorSchemeSeed: const Color(0xFF254D70),
      useMaterial3: true,
    ),
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  static const MethodChannel _settings = MethodChannel('screen_guide/settings');
  _Page _page = _Page.home;
  ImageSource? _source;
  XFile? _picked;
  bool _busy = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    // Android가 사진 앱을 여는 동안 프로세스를 종료한 경우 결과를 복구한다.
    _recoverLostData();
  }

  Future<void> _recoverLostData() async {
    try {
      final response = await _picker.retrieveLostData();
      if (!mounted || response.isEmpty) return;
      final file = response.files?.firstOrNull;
      if (file != null) {
        await _showPreview(file, ImageSource.gallery);
      } else if (response.exception != null) {
        _handlePickerError(response.exception!);
      }
    } catch (_) {
      // 복구 결과가 없어도 새 이미지 입력은 계속 가능하다.
    }
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      final file = await _picker.pickImage(
        source: source,
        requestFullMetadata: false,
      );
      assert(() {
        debugPrint(
          '[Stage1] ${source.name} picker: ${file == null ? 'canceled' : 'file returned'}',
        );
        return true;
      }());
      if (file == null || !mounted) return; // 시스템 화면에서 사용자가 취소
      await _showPreview(file, source);
    } on PlatformException catch (e) {
      assert(() {
        debugPrint('[Stage1] picker error: ${e.code}');
        return true;
      }());
      _handlePickerError(e);
    } catch (_) {
      if (mounted) _showError('이미지를 가져오지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showPreview(XFile file, ImageSource source) async {
    try {
      if (!await File(file.path).exists() ||
          await File(file.path).length() == 0) {
        _showError('이미지 파일을 읽을 수 없어요. 다른 사진을 선택해 주세요.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _picked = file;
        _source = source;
        _page = _Page.preview;
      });
    } catch (_) {
      if (mounted) _showError('이미지 파일을 읽을 수 없어요. 다른 사진을 선택해 주세요.');
    }
  }

  void _handlePickerError(PlatformException e) {
    if (!mounted) return;
    if (e.code == 'camera_access_denied' ||
        e.code == 'camera_access_denied_without_prompt' ||
        e.code == 'photo_access_denied') {
      setState(() {
        _source = e.code.startsWith('camera')
            ? ImageSource.camera
            : ImageSource.gallery;
        _page = _Page.denied;
      });
    } else {
      _showError('이미지를 가져오지 못했어요 (${e.code}). 다시 시도해 주세요.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _page = _Page.error;
    });
  }

  void _home() => setState(() {
    _page = _Page.home;
    _picked = null;
    _error = '';
  });

  Future<void> _openSettings() async {
    try {
      await _settings.invokeMethod<void>('openAppSettings');
    } on PlatformException catch (_) {
      _showError('설정을 열지 못했어요. 휴대전화 설정에서 앱 권한을 확인해 주세요.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('화면길잡이 · 1단계'),
      leading: _page == _Page.home
          ? null
          : IconButton(
              onPressed: _home,
              icon: const Icon(Icons.arrow_back),
              tooltip: '처음으로',
            ),
    ),
    body: SafeArea(
      child: switch (_page) {
        _Page.home => _homeBody(),
        _Page.preview => _imageBody(preview: true),
        _Page.display => _imageBody(preview: false),
        _Page.denied => _deniedBody(),
        _Page.error => _errorBody(),
      },
    ),
  );

  Widget _homeBody() => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Icon(Icons.image_search, size: 72, color: Color(0xFF254D70)),
      const SizedBox(height: 18),
      Text('화면 사진을 가져오세요', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 10),
      const Text('다른 기기의 화면은 카메라로 촬영하고, 이 기기의 화면은 스크린샷을 갤러리에서 선택하세요.'),
      const SizedBox(height: 28),
      FilledButton.icon(
        onPressed: _busy ? null : () => _pick(ImageSource.camera),
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text('카메라로 촬영'),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: _busy ? null : () => _pick(ImageSource.gallery),
        icon: const Icon(Icons.photo_library_outlined),
        label: const Text('갤러리에서 선택'),
      ),
      if (_busy)
        const Padding(
          padding: EdgeInsets.only(top: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      const SizedBox(height: 20),
      const Text('이미지 한 장만 선택합니다. 선택한 이미지는 서버로 보내지 않습니다.'),
    ],
  );

  Widget _imageBody({required bool preview}) {
    final file = _picked;
    if (file == null) return _errorBody();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Text(
            preview ? '선택한 이미지 미리보기' : '이미지 표시',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Image.file(
              File(file.path),
              key: ValueKey(file.path),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  const Center(child: Text('이미지를 표시할 수 없어요. 다른 사진을 선택해 주세요.')),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (preview)
                FilledButton(
                  onPressed: () => setState(() => _page = _Page.display),
                  child: const Text('선택한 이미지 사용'),
                ),
              OutlinedButton(
                onPressed: () => _pick(_source ?? ImageSource.gallery),
                child: Text(
                  _source == ImageSource.camera ? '다시 촬영' : '다른 이미지 선택',
                ),
              ),
              TextButton(onPressed: _home, child: const Text('처음으로')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _deniedBody() => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Icon(Icons.no_photography_outlined, size: 64),
      const SizedBox(height: 18),
      Text('권한이 허용되지 않았어요', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 12),
      Text(
        _source == ImageSource.camera
            ? '카메라 촬영을 사용하려면 카메라 권한이 필요합니다. 앱 설정에서 허용하거나 갤러리에서 이미지를 선택해 주세요.'
            : '사진을 선택할 수 없어요. 앱 설정의 사진 권한을 확인하거나 카메라로 촬영해 주세요.',
      ),
      const SizedBox(height: 24),
      FilledButton(onPressed: _openSettings, child: const Text('앱 권한 설정 열기')),
      const SizedBox(height: 10),
      OutlinedButton(
        onPressed: () => _pick(
          _source == ImageSource.camera
              ? ImageSource.gallery
              : ImageSource.camera,
        ),
        child: Text(_source == ImageSource.camera ? '갤러리에서 선택' : '카메라로 촬영'),
      ),
      TextButton(onPressed: _home, child: const Text('처음으로')),
    ],
  );

  Widget _errorBody() => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Icon(Icons.error_outline, size: 64),
      const SizedBox(height: 18),
      Text('이미지를 표시하지 못했어요', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 12),
      Text(_error),
      const SizedBox(height: 24),
      FilledButton(onPressed: _home, child: const Text('다른 이미지 선택하기')),
    ],
  );
}
