import 'package:flutter/material.dart';
import 'package:flutter_realtime_detection_flutter_vision/yoloVideo.dart';

void main() async {
  print('啟動');
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      home: YoloVideo(),
    ),
  );
}
