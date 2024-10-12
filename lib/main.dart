import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'model_inference.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ImageUploadScreen(),
    );
  }
}

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  ImageUploadScreenState createState() => ImageUploadScreenState();
}

class ImageUploadScreenState extends State<ImageUploadScreen> {
  File? _image; // 선택한 이미지 파일
  final picker = ImagePicker(); // 이미지 선택기
  final inference = ModelInference();
  var _resultText = "";

  @override
  void initState() {
    super.initState();
  }

  // 권한 확인 및 요청
  Future<void> requestStoragePermission() async {
    PermissionStatus result = await Permission.storage.request();

    if (result.isGranted) {
      debugPrint("권한이 허용되었습니다!");
    } else if (result.isDenied) {
      // 권한이 거부된 경우 사용자에게 권한 요청 이유 설명
      showDialog(
        context: context,
        builder: (BuildContext context) =>
            AlertDialog(
              title: const Text("권한이 필요합니다."),
              content: const Text("이 기능을 사용하려면 저장소 권한이 필요합니다."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("닫기"),
                ),
                TextButton(
                  onPressed: () {
                    openAppSettings(); // 앱 설정 화면으로 이동
                  },
                  child: const Text("설정으로 가기"),
                ),
              ],
            ),
      );
    } else if (result.isPermanentlyDenied) {
      debugPrint("권한이 영구적으로 거부되었습니다.");
      openAppSettings(); // 앱 설정 화면으로 이동하여 사용자가 권한을 수동으로 활성화하도록 유도
    }
  }

  // 이미지 선택 함수
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        debugPrint('No image selected.');
      }
    });
  }

  // 이미지 업로드 함수
  Future<void> _inferenceImage() async {
    File? inner = _image;

    if(inner != null) {
      int res = await inference.inference(inner);
      setState(() {
        _resultText = 'res: $res';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Image Upload Example'),
      // ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image == null
                ? const Text('No image selected.')
                : Image.file(
              _image!,
              height: 200,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _inferenceImage,
              child: const Text('Inference Image'),
            ),
            const SizedBox(height: 20),
            Text(_resultText),
          ],
        ),
      ),
    );
  }
}
