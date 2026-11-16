import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/features/capture/data/app_copy_files.dart';

// 앱 복사본 규칙: sg_ 폴더에만 만들고, 지울 때는 그 모양인지 확인한 뒤에만 지운다.

void main() {
  late Directory base;
  late Directory temp;
  late AppCopyFiles files;

  setUp(() async {
    base = await Directory.systemTemp.createTemp('copy_test_');
    temp = await Directory('${base.path}/code_cache').create();
    files = AppCopyFiles(root: temp);
  });

  tearDown(() async {
    if (await base.exists()) await base.delete(recursive: true);
  });

  Future<File> userFile([String name = 'original.png']) async {
    final f = File('${base.path}/$name');
    await f.writeAsBytes([1, 2, 3]);
    return f;
  }

  test('복사본은 root 바로 아래 sg_ 폴더에 생기고 원본은 그대로', () async {
    final src = await userFile();
    final copy = await files.copyFrom(src.path);

    final dir = File(copy).parent;
    expect(dir.path.split(RegExp(r'[\\/]')).last, startsWith('sg_'));
    expect(files.isAppCopy(copy), isTrue);
    expect(await File(copy).readAsBytes(), [1, 2, 3]);
    expect(await src.exists(), isTrue);
  });

  test('없는 파일·빈 파일은 FileSystemException', () async {
    expect(
      () => files.copyFrom('${base.path}/missing.png'),
      throwsA(isA<FileSystemException>()),
    );
    final empty = File('${base.path}/empty.png');
    await empty.writeAsBytes(const []);
    expect(
      () => files.copyFrom(empty.path),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('release는 앱 복사본 폴더만 지운다', () async {
    final src = await userFile();
    final copy = await files.copyFrom(src.path);

    await files.release(copy);

    expect(await File(copy).parent.exists(), isFalse);
    expect(await src.exists(), isTrue);
  });

  test('release에 사용자 원본 경로를 주면 아무것도 지우지 않는다', () async {
    final src = await userFile();
    await files.release(src.path);
    expect(await src.exists(), isTrue);
  });

  test('root 밖에 있는 sg_ 폴더는 앱 복사본이 아니다', () async {
    final outside = await Directory('${base.path}/sg_fake').create();
    final f = File('${outside.path}/x.png');
    await f.writeAsBytes([1]);

    expect(files.isAppCopy(f.path), isFalse);
    await files.release(f.path);
    expect(await f.exists(), isTrue);
  });

  test('이름이 없는 경로·빈 경로를 넘겨도 예외 없음', () async {
    for (final p in ['/', '', r'C:\', '//']) {
      expect(files.isAppCopy(p), isFalse, reason: p);
      await files.release(p);
    }
  });

  test('이미 지운 복사본을 다시 release해도 예외 없음', () async {
    final copy = await files.copyFrom((await userFile()).path);
    await files.release(copy);
    await files.release(copy);
  });

  test('clearLeftovers는 root 아래 sg_ 폴더만 지운다', () async {
    final src = await userFile();
    await files.copyFrom(src.path);
    await files.copyFrom(src.path);
    await Directory('${temp.path}/other').create();

    await files.clearLeftovers();

    // 경로 구분자가 OS마다 달라 폴더 이름만 비교한다
    final left = await temp
        .list()
        .map((e) => e.path.split(RegExp(r'[\\/]')).last)
        .toList();
    expect(left, ['other']);
    expect(await src.exists(), isTrue);
  });

  test('isInsideAppData: 앱 데이터 폴더 아래만 true', () async {
    expect(files.isInsideAppData('${base.path}/cache/a.jpg'), isTrue);
    expect(files.isInsideAppData('/storage/emulated/0/DCIM/a.jpg'), isFalse);
    expect(files.isInsideAppData('${base.path}/../x/a.jpg'), isFalse);
  });
}
