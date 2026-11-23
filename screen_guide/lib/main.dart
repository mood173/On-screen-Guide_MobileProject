import 'dart:async';

import 'package:flutter/material.dart';

import 'package:screen_guide/app/app.dart';
import 'package:screen_guide/app/bootstrap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final deps = bootstrap();
  final flow = deps.createFlow()..start(); // 준비 단계: 남은 복사본 청소, 맵 갱신 확인
  runApp(ScreenGuideApp(flow: flow));
  // 앱이 내려가면 DB 연결을 닫는다 (E-10). 강제 종료면 OS가 회수한다.
  AppLifecycleListener(onDetach: () => unawaited(deps.dispose()));
}
