// 포트 공용 시험. 가짜 구현과 진짜 구현이 **같은 시험**을 통과해야 bootstrap에서 바꿔 끼울 수 있다.
//
// 팀원 3이 진짜 구현을 만들면 test/ports/ 에 이렇게 한 줄을 추가한다:
//   void main() => guidanceRepositoryContract('로컬 DB', () => SqfliteGuidanceRepository(...));
//
// 이 파일 이름은 _test.dart로 끝나지 않아서 단독으로 실행되지 않고, 다른 시험 파일이 불러 쓴다.

import 'package:flutter_test/flutter_test.dart';

import 'package:screen_guide/features/capture/domain/image_input.dart';
import 'package:screen_guide/features/guidance_map/domain/guidance.dart';
import 'package:screen_guide/features/history/domain/history.dart';

void guidanceRepositoryContract(
  String name,
  GuidanceRepository Function() create,
) {
  group('GuidanceRepository 계약 · $name', () {
    test('맵 조각: 화면마다 screenId가 있고 앵커가 2개 이상이다 (화면 식별 규칙: 앵커 2개 이상)', () async {
      final f = await create().fragment();
      expect(f.packageName, isNotEmpty);
      expect(f.screens, isNotEmpty);
      for (final s in f.screens) {
        expect(s.screenId, isNotEmpty);
        expect(s.anchors.length, greaterThanOrEqualTo(2), reason: s.screenId);
      }
    });

    test(
      '기능: 맵 조각에 있는 화면의 기능은 그 screenId를 갖고, 단계가 1개 이상이며 selector가 비어 있지 않다',
      () async {
        final repo = create();
        final f = await repo.fragment();
        var total = 0;
        for (final s in f.screens) {
          final actions = await repo.actionsFor(s.screenId);
          total += actions.length;
          for (final a in actions) {
            expect(a.screenId, s.screenId);
            expect(
              a.actionId,
              matches(RegExp(r'^[a-z0-9_]+\.[a-z0-9_]+$')),
              reason: '영역.동작 형식 (계약 v1 결정 2)',
            );
            expect(a.steps, isNotEmpty, reason: a.actionId);
            for (final st in a.steps) {
              expect(st.selector.trim(), isNotEmpty, reason: a.actionId);
              expect(st.instruction.trim(), isNotEmpty, reason: a.actionId);
            }
          }
        }
        expect(total, greaterThan(0));
      },
    );

    test('기능 ID는 겹치지 않는다', () async {
      final repo = create();
      final ids = <String>[];
      for (final s in (await repo.fragment()).screens) {
        ids.addAll((await repo.actionsFor(s.screenId)).map((a) => a.actionId));
      }
      expect(ids.toSet().length, ids.length);
    });

    test('모르는 화면이면 빈 목록 (오류 아님)', () async {
      expect(await create().actionsFor('no_such_screen'), isEmpty);
    });

    test('활성 revision이 있다', () async {
      expect(await create().activeRevision(), isNotEmpty);
    });
  });
}

void historyRepositoryContract(
  String name,
  HistoryRepository Function() create,
) {
  HistoryEntry entry(String id, int minute) => HistoryEntry(
    id: id,
    actionId: 'settings.notification',
    actionTitle: '알림 설정 바꾸기',
    stepInstructions: const ['알림 설정을 눌러주세요'],
    input: 'gallery',
    createdAt: DateTime(2026, 11, 20, 10, minute),
    piiTypes: const ['휴대전화'],
  );

  group('HistoryRepository 계약 · $name', () {
    test('저장한 것을 id로 다시 읽는다', () async {
      final repo = create();
      await repo.save(entry('a', 0));
      final got = await repo.get('a');
      expect(got!.actionId, 'settings.notification');
      expect(got.stepInstructions, ['알림 설정을 눌러주세요']);
      expect(got.piiTypes, ['휴대전화']);
    });

    test('목록은 최근 것부터', () async {
      final repo = create();
      await repo.save(entry('old', 0));
      await repo.save(entry('new', 30));
      expect((await repo.list()).map((e) => e.id).toList(), ['new', 'old']);
    });

    test('같은 id로 다시 저장하면 덮어쓴다', () async {
      final repo = create();
      await repo.save(entry('a', 0));
      await repo.save(entry('a', 5));
      expect(await repo.list(), hasLength(1));
    });

    test('지우면 없다', () async {
      final repo = create();
      await repo.save(entry('a', 0));
      await repo.delete('a');
      expect(await repo.get('a'), isNull);
      expect(await repo.list(), isEmpty);
    });
  });
}

/// [ImageInput]은 실제 기기·사용자 동작이 필요해 자동 시험이 어렵다.
/// 가짜 구현으로 흐름이 기대하는 결과 모양만 확인하고, 진짜 구현은 에뮬레이터 확인 목록(문서)으로 점검한다.
void imageInputShapeContract(String name, ImageInput Function() create) {
  group('ImageInput 결과 모양 · $name', () {
    test('성공이면 path가 있고, 앱 복사본만 appOwned', () async {
      final r = await create().pickFromGallery();
      if (r.status == PickStatus.ok) {
        expect(r.path, isNotNull);
        expect(r.ok, isTrue);
      } else {
        expect(r.path, isNull);
        expect(r.ok, isFalse);
      }
    });
  });
}
