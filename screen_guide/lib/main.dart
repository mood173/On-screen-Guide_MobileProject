import 'package:flutter/material.dart';

import 'package:screen_guide/app/app.dart';
import 'package:screen_guide/app/bootstrap.dart';

void main() {
  runApp(ScreenGuideApp(flow: bootstrap().createFlow()));
}
