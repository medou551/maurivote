import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CniOcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<CniData> extractFromImage(String imagePath) async {
    final inputImage = InputImage.fromFile(File(imagePath));
    final recognized = await _recognizer.processImage(inputImage);
    final text = recognized.text.toUpperCase();
    return CniData(
      nniTrouve:  _extractNni(text),
      nomTrouve:  _extractNom(text),
      texteComplet: text,
    );
  }

  String? _extractNni(String text) {
    final regex = RegExp(r'\b\d{10}\b');
    final match = regex.firstMatch(text);
    return match?.group(0);
  }

  String? _extractNom(String text) {
    final lines = text.split('\n');
    for (final line in lines) {
      if (line.contains('NOM') || line.contains('NAME')) {
        return line.replaceAll(RegExp(r'NOM[:\s]*|NAME[:\s]*'), '').trim();
      }
    }
    return null;
  }

  Future<bool> verifierNni(String nniSaisi, String imagePath) async {
    final data = await extractFromImage(imagePath);
    if (data.nniTrouve == null) return true; // Si OCR rate, on accepte
    return data.nniTrouve == nniSaisi;
  }

  void dispose() => _recognizer.close();
}

class CniData {
  final String? nniTrouve;
  final String? nomTrouve;
  final String texteComplet;
  const CniData({this.nniTrouve, this.nomTrouve, required this.texteComplet});
  bool get nniDetecte => nniTrouve != null;
}