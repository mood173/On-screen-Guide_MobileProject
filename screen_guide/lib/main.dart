import 'package:flutter/material.dart';

import 'package:screen_guide/app/app.dart';
import 'package:screen_guide/app/bootstrap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final flow = bootstrap().createFlow()..start(); // 준비 단계: 남은 복사본 청소, 맵 갱신 확인
  runApp(ScreenGuideApp(flow: flow));
}
