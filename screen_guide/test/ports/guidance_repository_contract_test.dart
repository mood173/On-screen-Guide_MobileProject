import 'dart:io';

import 'package:screen_guide/features/guidance_map/data/asset_guidance_repository.dart';

import 'port_contracts.dart';

// 진짜 GuidanceRepository(AssetGuidanceRepository)가 맵 공용 시험(협업규격_최종 3.2 규칙)을 통과하는지.
// 앱에 들어가는 맵 파일을 그대로 읽는다. 맵 내용을 바꾸면 이 시험이 먼저 확인한다.
void main() {
  guidanceRepositoryContract(
    '앱에 든 JSON 맵',
    () => AssetGuidanceRepository(
      source: () => File(AssetGuidanceRepository.defaultAsset).readAsString(),
    ),
  );
}
