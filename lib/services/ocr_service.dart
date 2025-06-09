import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

class OCRService {
  static bool _isInitialized = false;
  static TextRecognizer? _textRecognizer;

  /// Inicializa el servicio OCR con Google ML Kit
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔄 Inicializando Google ML Kit OCR Service...');

      // Crear el reconocedor de texto para caracteres latinos
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      _isInitialized = true;
      debugPrint('🎉 Google ML Kit OCR Service inicializado correctamente');
    } catch (e) {
      debugPrint('❌ Error inicializando Google ML Kit OCR Service: $e');
      throw Exception('Error inicializando OCR: $e');
    }
  }

  /// Verifica el estado del servicio OCR
  static Future<Map<String, dynamic>> checkTessDataStatus() async {
    try {
      if (!_isInitialized || _textRecognizer == null) {
        return {'status': 'not_initialized', 'message': 'OCR no inicializado'};
      }

      return {
        'status': 'ready',
        'message': 'Google ML Kit listo para usar',
        'provider': 'Google ML Kit'
      };
    } catch (e) {
      return {'status': 'error', 'message': 'Error verificando estado: $e'};
    }
  }

  /// Fuerza la re-inicialización del servicio (para compatibilidad)
  static Future<bool> forceDownloadTessData() async {
    try {
      debugPrint('🔄 Re-inicializando Google ML Kit...');

      await dispose();
      await initialize();

      return true;
    } catch (e) {
      debugPrint('❌ Error en re-inicialización: $e');
      return false;
    }
  }

  /// Extrae texto de una imagen usando Google ML Kit
  static Future<String?> extractTextFromImage(String imagePath) async {
    try {
      await initialize();

      if (_textRecognizer == null) {
        throw Exception('Text recognizer no inicializado');
      }

      debugPrint('🔍 Extrayendo texto con Google ML Kit de: $imagePath');

      // Crear InputImage desde el archivo
      final inputImage = InputImage.fromFilePath(imagePath);

      // Procesar la imagen
      final RecognizedText recognizedText = await _textRecognizer!.processImage(inputImage);

      final text = recognizedText.text;
      debugPrint('📝 Texto extraído: "$text"');

      if (text.isEmpty) {
        debugPrint('⚠️ No se extrajo texto');
        return null;
      }

      // Buscar patrones de placa en el texto reconocido
      final plateText = _findLicensePlateInText(text);
      debugPrint('🚗 Placa encontrada: $plateText');
      return plateText;
    } catch (e) {
      debugPrint('❌ Error extracting text from image: $e');
      return null;
    }
  }

  /// Extrae texto de una imagen con información detallada usando Google ML Kit
  static Future<Map<String, dynamic>?> extractDetailedTextFromImage(String imagePath) async {
    try {
      await initialize();

      if (_textRecognizer == null) {
        throw Exception('Text recognizer no inicializado');
      }

      // Verificar estado del servicio
      final ocrStatus = await checkTessDataStatus();
      debugPrint('📊 Estado OCR: ${ocrStatus['message']}');

      // Crear múltiples versiones de la imagen para probar
      final imagePaths = await _createMultipleImageVersions(imagePath);

      List<String> allTexts = [];
      List<String> possiblePlates = [];
      List<Map<String, dynamic>> textBlocks = [];
      String? bestImagePath = imagePath;

      // Probar con cada versión de la imagen
      for (final imageInfo in imagePaths) {
        try {
          final imagePath = imageInfo['path'];
          final imageName = imageInfo['name'];

          if (imagePath == null || imageName == null) continue;

          debugPrint('🔍 Probando con imagen: $imageName');

          // Crear InputImage desde el archivo
          final inputImage = InputImage.fromFilePath(imagePath);

          // Procesar la imagen
          final RecognizedText recognizedText = await _textRecognizer!.processImage(inputImage);

          final text = recognizedText.text;
          debugPrint('📝 Texto con $imageName: "$text"');

          if (text.isNotEmpty) {
            allTexts.add(text);
            bestImagePath = imagePath;

            // Procesar bloques de texto para obtener información detallada
            for (TextBlock block in recognizedText.blocks) {
              final blockText = block.text;
              final confidence = _calculateBlockConfidence(block);

              textBlocks.add({
                'name': '$imageName - Bloque',
                'text': blockText,
                'confidence': confidence,
                'boundingBox': {
                  'left': block.boundingBox.left,
                  'top': block.boundingBox.top,
                  'right': block.boundingBox.right,
                  'bottom': block.boundingBox.bottom,
                }
              });

              // Procesar líneas dentro del bloque
              for (TextLine line in block.lines) {
                final lineText = line.text;
                final cleanedLine = cleanLicensePlate(lineText);

                if (isValidLicensePlate(cleanedLine)) {
                  final formattedPlate = formatPlateWithDash(cleanedLine);
                  if (!possiblePlates.contains(formattedPlate)) {
                    possiblePlates.add(formattedPlate);
                    debugPrint('🎯 Placa válida encontrada en línea: $formattedPlate');
                  }
                }

                // Procesar elementos dentro de la línea
                for (TextElement element in line.elements) {
                  final elementText = element.text;
                  final cleanedElement = cleanLicensePlate(elementText);

                  if (isValidLicensePlate(cleanedElement)) {
                    final formattedPlate = formatPlateWithDash(cleanedElement);
                    if (!possiblePlates.contains(formattedPlate)) {
                      possiblePlates.add(formattedPlate);
                      debugPrint('🎯 Placa válida encontrada en elemento: $formattedPlate');
                    }
                  }
                }
              }
            }

            // También procesar el texto completo línea por línea
            final lines = text.split('\n');
            for (String line in lines) {
              final cleanedLine = cleanLicensePlate(line);
              if (isValidLicensePlate(cleanedLine)) {
                final formattedPlate = formatPlateWithDash(cleanedLine);
                if (!possiblePlates.contains(formattedPlate)) {
                  possiblePlates.add(formattedPlate);
                  debugPrint('🎯 Placa válida encontrada: $formattedPlate');
                }
              }

              // También verificar palabras individuales
              final words = line.split(' ');
              for (String word in words) {
                final cleanedWord = cleanLicensePlate(word);
                if (isValidLicensePlate(cleanedWord)) {
                  final formattedPlate = formatPlateWithDash(cleanedWord);
                  if (!possiblePlates.contains(formattedPlate)) {
                    possiblePlates.add(formattedPlate);
                    debugPrint('🎯 Placa válida en palabra: $formattedPlate');
                  }
                }
              }
            }

            // Si encontramos placas, no necesitamos probar más imágenes
            if (possiblePlates.isNotEmpty) {
              break;
            }
          }
        } catch (e) {
          debugPrint('❌ Error con imagen ${imageInfo['name']}: $e');
          continue;
        }
      }

      // Si no se encontraron placas, buscar patrones más permisivos
      if (possiblePlates.isEmpty && allTexts.isNotEmpty) {
        debugPrint('🔍 Buscando patrones más permisivos...');

        final fullText = allTexts.join(' ');
        // Buscar cualquier secuencia de 6-7 caracteres que tenga letras y números
        final pattern = RegExp(r'[A-Z0-9]{6,7}');
        final matches = pattern.allMatches(cleanLicensePlate(fullText));

        for (final match in matches) {
          final candidate = match.group(0)!;
          if (isValidLicensePlate(candidate)) {
            final formattedPlate = formatPlateWithDash(candidate);
            if (!possiblePlates.contains(formattedPlate)) {
              possiblePlates.add(formattedPlate);
              debugPrint('🎯 Candidato permisivo: $formattedPlate');
            }
          }
        }
      }

      final fullText = allTexts.join('\n');
      debugPrint('📄 Texto completo: "$fullText"');
      debugPrint('🚗 Placas posibles encontradas: $possiblePlates');

      return {
        'fullText': fullText,
        'possiblePlates': possiblePlates,
        'bestPlate': possiblePlates.isNotEmpty ? possiblePlates.first : null,
        'processedImagePath': bestImagePath,
        'tessDataStatus': ocrStatus,
        'textBlocks': textBlocks,
      };
    } catch (e) {
      debugPrint('❌ Error extracting detailed text from image: $e');

      final ocrStatus = await checkTessDataStatus();

      return {
        'fullText': 'Error: $e',
        'possiblePlates': [],
        'bestPlate': null,
        'processedImagePath': imagePath,
        'tessDataStatus': ocrStatus,
        'textBlocks': [],
        'error': e.toString(),
      };
    }
  }

  /// Formatea una placa agregando un guión entre letras y números
  static String formatPlateWithDash(String plate) {
    if (plate.length < 6) return plate;

    // Para formato ABC123 -> ABC-123
    if (RegExp(r'^[A-Z]{3}[0-9]{3}$').hasMatch(plate)) {
      return '${plate.substring(0, 3)}-${plate.substring(3)}';
    }

    // Para formato ABC12D -> ABC-12D
    if (RegExp(r'^[A-Z]{3}[0-9]{2}[A-Z]$').hasMatch(plate)) {
      return '${plate.substring(0, 3)}-${plate.substring(3)}';
    }

    // Para formato ABC1234 -> ABC-1234
    if (RegExp(r'^[A-Z]{3}[0-9]{4}$').hasMatch(plate)) {
      return '${plate.substring(0, 3)}-${plate.substring(3)}';
    }

    // Si no coincide con ningún formato conocido, intentar separar en posición 3
    if (plate.length >= 6) {
      return '${plate.substring(0, 3)}-${plate.substring(3)}';
    }

    return plate;
  }

  /// Calcula la confianza promedio de un bloque de texto
  static double _calculateBlockConfidence(TextBlock block) {
    // Google ML Kit no proporciona confianza directamente,
    // pero podemos usar otros factores como el tamaño del bounding box
    // y la cantidad de texto para estimar la calidad

    final boundingBox = block.boundingBox;
    final area = (boundingBox.right - boundingBox.left) * (boundingBox.bottom - boundingBox.top);
    final textLength = block.text.length;

    // Estimación simple basada en área y longitud del texto
    double confidence = 0.5; // Base

    if (area > 1000) confidence += 0.2; // Área grande
    if (textLength > 3) confidence += 0.2; // Texto suficiente
    if (block.text.contains(RegExp(r'[A-Z0-9]{6,7}'))) confidence += 0.3; // Patrón de placa

    return confidence.clamp(0.0, 1.0);
  }

  /// Crea múltiples versiones de la imagen para probar diferentes procesamientos
  static Future<List<Map<String, String>>> _createMultipleImageVersions(String imagePath) async {
    List<Map<String, String>> versions = [];

    try {
      // 1. Imagen original
      versions.add({
        'name': 'Original',
        'path': imagePath,
      });

      // 2. Imagen en escala de grises simple
      final grayPath = await _createGrayscaleVersion(imagePath);
      if (grayPath != null) {
        versions.add({
          'name': 'Escala de grises',
          'path': grayPath,
        });
      }

      // 3. Imagen con contraste mejorado
      final contrastPath = await _createContrastVersion(imagePath);
      if (contrastPath != null) {
        versions.add({
          'name': 'Contraste mejorado',
          'path': contrastPath,
        });
      }

      // 4. Imagen redimensionada
      final resizedPath = await _createResizedVersion(imagePath);
      if (resizedPath != null) {
        versions.add({
          'name': 'Redimensionada',
          'path': resizedPath,
        });
      }

      // 5. Imagen con threshold
      final thresholdPath = await _createThresholdVersion(imagePath);
      if (thresholdPath != null) {
        versions.add({
          'name': 'Binarizada',
          'path': thresholdPath,
        });
      }

    } catch (e) {
      debugPrint('❌ Error creando versiones de imagen: $e');
    }

    return versions;
  }

  /// Crea una versión en escala de grises
  static Future<String?> _createGrayscaleVersion(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      var image = img.decodeImage(bytes);

      if (image == null) return null;

      // Solo convertir a escala de grises
      image = img.grayscale(image);

      final grayPath = imagePath.replaceAll(path.extension(imagePath), '_gray.jpg');
      await File(grayPath).writeAsBytes(img.encodeJpg(image, quality: 95));

      debugPrint('💾 Imagen en escala de grises creada: $grayPath');
      return grayPath;
    } catch (e) {
      debugPrint('❌ Error creando versión en escala de grises: $e');
      return null;
    }
  }

  /// Crea una versión con contraste mejorado
  static Future<String?> _createContrastVersion(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      var image = img.decodeImage(bytes);

      if (image == null) return null;

      // Convertir a escala de grises y mejorar contraste suavemente
      image = img.grayscale(image);
      image = img.adjustColor(image, contrast: 1.5, brightness: 0.1);

      final contrastPath = imagePath.replaceAll(path.extension(imagePath), '_contrast.jpg');
      await File(contrastPath).writeAsBytes(img.encodeJpg(image, quality: 95));

      debugPrint('💾 Imagen con contraste mejorado creada: $contrastPath');
      return contrastPath;
    } catch (e) {
      debugPrint('❌ Error creando versión con contraste: $e');
      return null;
    }
  }

  /// Crea una versión redimensionada
  static Future<String?> _createResizedVersion(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      var image = img.decodeImage(bytes);

      if (image == null) return null;

      // Redimensionar a un tamaño óptimo para OCR
      if (image.width < 800) {
        final scale = 800 / image.width;
        final newHeight = (image.height * scale).round();
        image = img.copyResize(image, width: 800, height: newHeight);
      }

      // Convertir a escala de grises
      image = img.grayscale(image);

      final resizedPath = imagePath.replaceAll(path.extension(imagePath), '_resized.jpg');
      await File(resizedPath).writeAsBytes(img.encodeJpg(image, quality: 95));

      debugPrint('💾 Imagen redimensionada creada: $resizedPath');
      return resizedPath;
    } catch (e) {
      debugPrint('❌ Error creando versión redimensionada: $e');
      return null;
    }
  }

  /// Crea una versión con threshold (binarizada)
  static Future<String?> _createThresholdVersion(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      var image = img.decodeImage(bytes);

      if (image == null) return null;

      // Convertir a escala de grises
      image = img.grayscale(image);

      // Aplicar threshold simple
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final gray = img.getLuminance(pixel);
          final newColor = gray > 128
              ? img.ColorRgb8(255, 255, 255)
              : img.ColorRgb8(0, 0, 0);
          image.setPixel(x, y, newColor);
        }
      }

      final thresholdPath = imagePath.replaceAll(path.extension(imagePath), '_threshold.jpg');
      await File(thresholdPath).writeAsBytes(img.encodeJpg(image, quality: 95));

      debugPrint('💾 Imagen binarizada creada: $thresholdPath');
      return thresholdPath;
    } catch (e) {
      debugPrint('❌ Error creando versión binarizada: $e');
      return null;
    }
  }

  /// Busca patrones de placa en el texto completo
  static String? _findLicensePlateInText(String text) {
    final lines = text.split('\n');

    for (String line in lines) {
      final cleanedLine = cleanLicensePlate(line);
      if (isValidLicensePlate(cleanedLine)) {
        return formatPlateWithDash(cleanedLine);
      }

      // Buscar patrones dentro de la línea
      final words = line.split(' ');
      for (String word in words) {
        final cleanedWord = cleanLicensePlate(word);
        if (isValidLicensePlate(cleanedWord)) {
          return formatPlateWithDash(cleanedWord);
        }
      }
    }

    // Si no encuentra una placa válida, intentar con todo el texto
    final cleanedFullText = cleanLicensePlate(text);
    if (isValidLicensePlate(cleanedFullText)) {
      return formatPlateWithDash(cleanedFullText);
    }

    return null;
  }

  /// Limpia y formatea el texto extraído para obtener una placa
  static String cleanLicensePlate(String text) {
    // Remover espacios, caracteres especiales y convertir a mayúsculas
    String cleaned = text
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .trim();

    // Intentar corregir caracteres comúnmente mal reconocidos
    cleaned = _correctCommonOCRErrors(cleaned);

    return cleaned;
  }

  /// Corrige errores comunes del OCR
  static String _correctCommonOCRErrors(String text) {
    String corrected = text;

    // Aplicar correcciones basadas en posición (primeras 3 posiciones deberían ser letras)
    if (corrected.length >= 6) {
      String letters = corrected.substring(0, 3);
      String numbers = corrected.substring(3);

      // Corregir letras (primeras 3 posiciones)
      letters = letters.replaceAllMapped(RegExp(r'[0-9]'), (match) {
        switch (match.group(0)) {
          case '0': return 'O';
          case '1': return 'I';
          case '5': return 'S';
          case '8': return 'B';
          case '6': return 'G';
          default: return match.group(0)!;
        }
      });

      // Corregir números (últimas 3 posiciones)
      numbers = numbers.replaceAllMapped(RegExp(r'[A-Z]'), (match) {
        switch (match.group(0)) {
          case 'O': return '0';
          case 'I': return '1';
          case 'S': return '5';
          case 'B': return '8';
          case 'G': return '6';
          default: return match.group(0)!;
        }
      });

      corrected = letters + numbers;
    }

    return corrected;
  }

  /// Valida si el texto corresponde a una placa colombiana válida (sin guión)
  static bool isValidLicensePlate(String plate) {
    if (plate.length < 6 || plate.length > 7) {
      return false;
    }

    // Formatos válidos para Colombia (sin guión):
    // ABC123 (formato antiguo)
    // ABC12D (formato nuevo)
    // ABC1234 (algunos casos especiales)
    final validFormats = [
      RegExp(r'^[A-Z]{3}[0-9]{3}$'),        // ABC123
      RegExp(r'^[A-Z]{3}[0-9]{2}[A-Z]$'),   // ABC12D
      RegExp(r'^[A-Z]{3}[0-9]{4}$'),        // ABC1234 (casos especiales)
    ];

    return validFormats.any((regex) => regex.hasMatch(plate));
  }

  /// Obtiene múltiples candidatos de placa de una imagen
  static Future<List<String>> getPlateCandidate(String imagePath) async {
    try {
      final result = await extractDetailedTextFromImage(imagePath);
      if (result != null && result['possiblePlates'] != null) {
        return List<String>.from(result['possiblePlates']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error getting plate candidates: $e');
      return [];
    }
  }

  /// Libera los recursos del OCR
  static Future<void> dispose() async {
    try {
      await _textRecognizer?.close();
      _textRecognizer = null;
      _isInitialized = false;
      debugPrint('🔄 Google ML Kit OCR Service disposed');
    } catch (e) {
      debugPrint('❌ Error disposing OCR service: $e');
    }
  }

  /// Verifica si el servicio está inicializado
  static bool get isInitialized => _isInitialized;

  /// Obtiene información del proveedor OCR
  static String get provider => 'Google ML Kit';
}
