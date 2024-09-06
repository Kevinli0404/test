import 'package:flutter/material.dart';
import 'package:flutter_realtime_detection_flutter_vision/yoloVideo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      home: YoloVideo(),
    ),
  );
}
