import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:camera/camera.dart';

late List<CameraDescription> camerass;

class YoloVideo extends StatefulWidget {
  const YoloVideo({Key? key}) : super(key: key);

  @override
  State<YoloVideo> createState() => _YoloVideoState();
}

class _YoloVideoState extends State<YoloVideo> {
  late CameraController controller;
  late FlutterVision vision;
  late List<Map<String, dynamic>> yoloResults;

  CameraImage? cameraImage;
  bool isLoaded = false;
  bool isDetecting = false;
  double confidenceThreshold = 0.5;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    camerass = await availableCameras();
    vision = FlutterVision();
    controller = CameraController(camerass[0], ResolutionPreset.high);
    await controller.initialize();
    await loadYoloModel();
    setState(() {
      isLoaded = true;
      yoloResults = [];
    });
  }

  @override
  void dispose() async {
    controller.dispose();
    await vision.closeYoloModel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    if (!isLoaded) {
      return const Scaffold(
        body: Center(
          child: Text("Model not loaded, waiting for it"),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
          ...displayBoxesAroundRecognizedObjects(size),
          Positioned(
            bottom: 75,
            width: MediaQuery.of(context).size.width,
            child: Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    width: 5, color: Colors.white, style: BorderStyle.solid),
              ),
              child: isDetecting
                  ? IconButton(
                      onPressed: stopDetection,
                      icon: const Icon(Icons.stop, color: Colors.red),
                      iconSize: 50,
                    )
                  : IconButton(
                      onPressed: startDetection,
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      iconSize: 50,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> loadYoloModel() async {
    await vision.loadYoloModel(
      labels: 'assets/labels.txt',
      modelPath: 'assets/RockPaperScissors_alldata_20231129-tflite.tflite',
      // labels: 'assets/labels.txt',
      // modelPath: 'assets/yolov8n.tflite',

      /// ,[modelVersion] - yolov5, yolov8
      modelVersion: "yolov5",
      numThreads: 1,
      useGpu: false,
    );
    setState(() {
      isLoaded = true;
    });
  }

  Future<void> yoloOnFrame(CameraImage cameraImage) async {
    Stopwatch stopwatch = Stopwatch()..start();

    final result = await vision.yoloOnFrame(
      bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
      imageHeight: cameraImage.height,
      imageWidth: cameraImage.width,
      iouThreshold: 0.4,
      confThreshold: 0.4,
      classThreshold: 0.5,
    );

    stopwatch.stop();

    if (result.isNotEmpty) {
      setState(() {
        yoloResults = result;
        print('stopwatch123: ${stopwatch.elapsedMilliseconds}');
      });
    }
  }

  Future<void> startDetection() async {
    setState(() {
      isDetecting = true;
    });

    if (controller.value.isStreamingImages) {
      return;
    }

    await controller.startImageStream((image) async {
      if (isDetecting) {
        // Stopwatch stopwatch = Stopwatch()..start(); // 開始計時

        cameraImage = image;
        await yoloOnFrame(image);

        // stopwatch.stop(); // 停止計時
        // print('stopwatch123: ${stopwatch.elapsedMilliseconds} 毫秒');
      }
    });
  }

  Future<void> stopDetection() async {
    setState(() {
      isDetecting = false;
      yoloResults.clear();
    });
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty) return [];

    double factorX = screen.width / (cameraImage?.height ?? 1);
    double factorY = screen.height / (cameraImage?.width ?? 1);

    return yoloResults.map((result) {
      double objectX = result["box"][0] * factorX;
      double objectY = result["box"][1] * factorY;
      double objectWidth = (result["box"][2] - result["box"][0]) * factorX;
      double objectHeight = (result["box"][3] - result["box"][1]) * factorY;

      print('objectX: $objectX');
      print('objectY: $objectY');
      print('objectWidth: $objectWidth');
      print('objectHeight: $objectHeight');

      return Positioned(
        left: objectX,
        top: objectY,
        width: objectWidth,
        height: objectHeight,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.pink, width: 2.0),
          ),
          child: Text(
            "${result['tag']} ${(result['box'][4] * 100)}",
            style: TextStyle(
              background: Paint()
                ..color = const Color.fromARGB(255, 50, 233, 30),
              color: const Color.fromARGB(255, 115, 0, 255),
              fontSize: 18.0,
            ),
          ),
        ),
      );
    }).toList();
  }
}
