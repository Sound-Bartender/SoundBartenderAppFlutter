
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img; // For image processing


class ModelInference {
  Interpreter? interpreter;

  ModelInference() {
    loadModel('assets/resnet50.tflite');
  }

  // TensorFlow Lite 모델 로드
  Future<void> loadModel(modelName) async {
    try {
      interpreter = await Interpreter.fromAsset(modelName);
      debugPrint("TensorFlow Lite 모델 로드 완료");
    } catch (e) {
      debugPrint("모델 로드 에러: $e");
    }
  }

  // Run inference on an input image
  Future<int> inference(File imageFile) async {
    if (interpreter == null) {
      debugPrint("Interpreter is not initialized.");
      return -1;
    }

    // Preprocess the input image (resize and normalize)
    var inputImage = _preprocessImage(imageFile);

    // Define input and output tensor shapes
    var inputShape = interpreter!.getInputTensor(0).shape;
    var outputShape = interpreter!.getOutputTensor(0).shape;

    // Allocate input and output buffers
    var inputBuffer = List.generate(inputShape[1] * inputShape[2] * inputShape[3], (index) => 0.0).reshape(inputShape);
    var outputBuffer = [List.filled(outputShape[1], 0.0)];

    // Copy preprocessed image to input buffer
    inputBuffer = inputImage;

    // Run inference
    interpreter!.run(inputBuffer, outputBuffer);

    // Return the output (predictions)
    // return outputBuffer;

    // debugPrint(outputBuffer[0].toString());

    // 최대값 찾기
    double maxValue = outputBuffer[0].reduce((curr, next) => curr > next ? curr : next);

    // 최대값의 인덱스 찾기
    int maxIndex = outputBuffer[0].indexOf(maxValue);

    return maxIndex;
  }

  // Preprocess the input image: resize, normalize (ResNet-50 expects 224x224 images)
  List<List<List<List<double>>>> _preprocessImage(File imageFile) {
    img.Image image = img.decodeImage(imageFile.readAsBytesSync())!;
    img.Image resizedImage = img.copyResize(image, width: 224, height: 224);

    // Convert image to float32 and normalize it between [-1, 1]
    List<List<List<List<double>>>> input = List.generate(
      1, (batch) => List.generate(
        224, (y) => List.generate(
          224, (x) => List.generate(
            3, (c) => getPixel(resizedImage, x, y, c).toDouble() / 127.5 - 1.0,
          ),
        ),
      ),
    );

    return input;
  }

  // Helper method to get the pixel value for a specific channel
  num getPixel(img.Image image, int x, int y, int c) {
    Pixel pixel = image.getPixel(x, y);

    if (c == 0) return pixel.r;
    if (c == 1) return pixel.g;
    return pixel.b;
  }
}