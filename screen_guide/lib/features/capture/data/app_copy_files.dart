// ignore_for_file: prefer_initializing_formals

import 'dart:io';

/// 앱 복사본(`sg_` 폴더) 만들기·지우기. 카메라·갤러리 진짜 구현이 안쪽에서 함께 쓴다.
/// 포트가 아니다 (협업규격_최종 3장 공통규칙 4: 구현이 하나뿐인 도구는 인터페이스로 만들지 않는다).
///
/// 규칙 (기능별_검토_결론 1-1 ①, 협업규격_최종 4.3):
/// - 가져온 사진은 앱 임시 폴더 아래 `sg_*` 폴더에 복사하고, 그 복사본 경로를 분석 요청 imagePath로 쓴다.
/// - 사용자 원본은 읽기만 한다. 수정·삭제하지 않는다.
/// - 지울 때는 "임시 폴더 바로 아래의 `sg_*` 폴더 안 파일"인지 확인한 뒤에만 그 폴더를 지운다.
///
/// 골격의 체험용 `CacheImageFiles`와 같은 위치·접두사를 쓰므로, 어느 쪽 정리 코드든 서로의 복사본을 지울 수 있다.
class AppCopyFiles {
  AppCopyFiles({Directory? root}) : _root = root;

  /// 시험에서만 바꾼다. 기본은 [Directory.systemTemp] (Android에서는 앱 전용 `code_cache`).
  final Directory? _root;

  static const prefix = 'sg_';

  Directory get root => _root ?? Directory.systemTemp;

  /// [sourcePath]의 파일을 새 `sg_` 폴더에 복사하고 복사본 경로를 돌려준다.
  ///
  /// 원본이 없거나 비어 있으면 [FileSystemException]을 던진다. 포트 구현이 잡아서
  /// `PickStatus.readFailed`로 바꾼다 (이 도구는 포트가 아니라서 던져도 된다).
  Future<String> copyFrom(String sourcePath) async {
    final src = File(sourcePath);
    if (!await src.exists()) {
      throw FileSystemException('원본 파일이 없다', sourcePath);
    }
    if (await src.length() == 0) {
      throw FileSystemException('원본 파일이 비어 있다', sourcePath);
    }
    final dir = await root.createTemp(prefix);
    try {
      final copy = await src.copy(
        '${dir.path}${Platform.pathSeparator}${_fileName(sourcePath)}',
      );
      return copy.path;
    } catch (_) {
      await _deleteQuietly(dir);
      rethrow;
    }
  }

  /// 바이트를 새 `sg_` 폴더에 [name] 파일로 저장하고 경로를 돌려준다 (갤러리 사진처럼 파일 경로가 없는 원본).
  ///
  /// 바이트가 비어 있으면 [FileSystemException]. 이름은 영문·숫자·`._-`만 남긴다.
  Future<String> saveBytes(String name, List<int> bytes) async {
    if (bytes.isEmpty) throw FileSystemException('사진 내용이 비어 있다', name);
    final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final dir = await root.createTemp(prefix);
    try {
      final file = File(
        '${dir.path}${Platform.pathSeparator}'
        '${safe.isEmpty || safe.startsWith('.') ? 'image$safe' : safe}',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      await _deleteQuietly(dir);
      rethrow;
    }
  }

  /// [path]가 이 도구가 만든 복사본인가: `root/sg_*/파일` 모양일 때만 true.
  bool isAppCopy(String path) {
    final parent = File(path).parent;
    return _fileName(parent.path).startsWith(prefix) &&
        _same(parent.parent.path, root.path);
  }

  /// [path]가 앱 전용 데이터 폴더(임시 폴더의 상위 폴더) 아래인가.
  /// 카메라가 앱 캐시에 남긴 파일처럼 "앱이 만든 파일"인지 확인할 때 쓴다. 사용자 원본은 통과하지 못한다.
  bool isInsideAppData(String path) {
    final base = '${_norm(root.parent.path)}/';
    return _norm(path).startsWith(base) && !path.contains('..');
  }

  /// 앱 복사본이면 그 `sg_` 폴더를 지운다. 사용자 원본 경로·이미 지워진 경로는 아무것도 하지 않는다.
  Future<void> release(String path) async {
    if (!isAppCopy(path)) return;
    await _deleteQuietly(File(path).parent);
  }

  /// 앱 시작 때: 임시 폴더 바로 아래의 `sg_*` 폴더를 모두 지운다.
  /// 읽거나 지우지 못한 것은 다음 시작 때 다시 시도한다.
  Future<void> clearLeftovers() async {
    try {
      await for (final e in root.list()) {
        if (e is Directory && _fileName(e.path).startsWith(prefix)) {
          await _deleteQuietly(e);
        }
      }
    } on FileSystemException {
      // 임시 폴더를 읽지 못함 → 다음 시작 때 다시
    }
  }

  /// 경로의 마지막 이름. `/`처럼 이름이 없는 경로면 빈 문자열 (예외를 던지지 않는다).
  static String _fileName(String path) =>
      path.split(RegExp(r'[\\/]')).where((p) => p.isNotEmpty).lastOrNull ?? '';

  static bool _same(String a, String b) => _norm(a) == _norm(b);

  static String _norm(String p) {
    var s = p.replaceAll('\\', '/');
    while (s.length > 1 && s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return Platform.isWindows ? s.toLowerCase() : s;
  }

  static Future<void> _deleteQuietly(FileSystemEntity e) async {
    try {
      await e.delete(recursive: true);
    } on FileSystemException {
      // 이미 없거나 지우지 못함 → clearLeftovers가 다음에 다시 시도
    }
  }
}
