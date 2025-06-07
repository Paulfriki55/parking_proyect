import 'package:flutter/material.dart';
import 'dart:io';
import '../services/ocr_service.dart';

class OCRResultDialog extends StatefulWidget {
  final String imagePath;
  final Map<String, dynamic> ocrResult;
  final Function(String) onPlateSelected;

  const OCRResultDialog({
    super.key,
    required this.imagePath,
    required this.ocrResult,
    required this.onPlateSelected,
  });

  @override
  State<OCRResultDialog> createState() => _OCRResultDialogState();
}

class _OCRResultDialogState extends State<OCRResultDialog> {
  String? selectedPlate;
  TextEditingController manualPlateController = TextEditingController();
  bool _isRedownloading = false;

  @override
  void initState() {
    super.initState();
    selectedPlate = widget.ocrResult['bestPlate'];
    if (selectedPlate != null) {
      manualPlateController.text = selectedPlate!;
    }
  }

  @override
  void dispose() {
    manualPlateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final possiblePlates = List<String>.from(widget.ocrResult['possiblePlates'] ?? []);
    final textBlocks = List<Map<String, dynamic>>.from(widget.ocrResult['textBlocks'] ?? []);
    final fullText = widget.ocrResult['fullText'] ?? '';
    final processedImagePath = widget.ocrResult['processedImagePath'] ?? widget.imagePath;
    final tessDataStatus = widget.ocrResult['tessDataStatus'] ?? {};
    final hasError = widget.ocrResult['error'] != null;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 700, maxWidth: 450),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasError ? Colors.red : Colors.blue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                      hasError ? Icons.error : Icons.text_fields,
                      color: Colors.white
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasError ? 'Error en OCR' : 'Resultado OCR - Tesseract',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status de TessData
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(tessDataStatus['status']).withOpacity(0.1),
                        border: Border.all(color: _getStatusColor(tessDataStatus['status'])),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getStatusIcon(tessDataStatus['status']),
                                color: _getStatusColor(tessDataStatus['status']),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Estado de datos OCR: ${tessDataStatus['message'] ?? 'Desconocido'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(tessDataStatus['status']),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (tessDataStatus['status'] == 'minimal' || tessDataStatus['status'] == 'missing') ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isRedownloading ? null : _redownloadTessData,
                                icon: _isRedownloading
                                    ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2)
                                )
                                    : const Icon(Icons.download),
                                label: Text(_isRedownloading ? 'Descargando...' : 'Descargar Datos OCR'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Images comparison
                    Row(
                      children: [
                        // Original image
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'Imagen Original',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 100,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(File(widget.imagePath)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Processed image
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'Imagen Procesada',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 100,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(File(processedImagePath)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Possible plates section
                    if (possiblePlates.isNotEmpty) ...[
                      const Text(
                        'Placas Detectadas:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...possiblePlates.map((plate) => RadioListTile<String>(
                        title: Text(
                          plate,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        subtitle: Text('Formato: ${_getPlateFormat(plate)}'),
                        value: plate,
                        groupValue: selectedPlate,
                        onChanged: (value) {
                          setState(() {
                            selectedPlate = value;
                            if (value != null) {
                              manualPlateController.text = value;
                            }
                          });
                        },
                      )),
                      const SizedBox(height: 16),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 32),
                            SizedBox(height: 8),
                            Text(
                              'No se detectaron placas válidas',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Intente con mejor iluminación o ingrese manualmente',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Manual input option
                    const Text(
                      'Ingrese la placa manualmente:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: manualPlateController,
                      decoration: const InputDecoration(
                        labelText: 'Placa manual',
                        border: OutlineInputBorder(),
                        hintText: 'ABC123',
                        prefixIcon: Icon(Icons.edit),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (value) {
                        setState(() {
                          selectedPlate = value.toUpperCase();
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Debug information
                    ExpansionTile(
                      title: const Text(
                        'Información de Debug',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Texto completo detectado:',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fullText.isEmpty ? 'No se detectó texto' : fullText,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (textBlocks.isNotEmpty) ...[
                                Text(
                                  'Resultados por configuración PSM:',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                                ),
                                const SizedBox(height: 4),
                                ...textBlocks.map((block) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    '${block['name']}: "${block['text']}" (Confianza: ${(block['confidence'] * 100).toInt()}%)',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                )),
                              ],
                              if (hasError) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Error:',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.ocrResult['error'],
                                  style: TextStyle(fontSize: 11, color: Colors.red.shade600),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final plate = manualPlateController.text.toUpperCase();
                        if (plate.isNotEmpty) {
                          widget.onPlateSelected(plate);
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ingrese una placa válida')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Usar Placa'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'ready': return Colors.green;
      case 'minimal': return Colors.orange;
      case 'missing': return Colors.red;
      case 'error': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'ready': return Icons.check_circle;
      case 'minimal': return Icons.warning;
      case 'missing': return Icons.error;
      case 'error': return Icons.error;
      default: return Icons.help;
    }
  }

  Future<void> _redownloadTessData() async {
    setState(() {
      _isRedownloading = true;
    });

    try {
      final success = await OCRService.forceDownloadTessData();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos OCR descargados exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error descargando datos OCR. Verifique su conexión a internet.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isRedownloading = false;
      });
    }
  }

  String _getPlateFormat(String plate) {
    if (RegExp(r'^[A-Z]{3}[0-9]{3}$').hasMatch(plate)) {
      return 'Formato antiguo (ABC123)';
    } else if (RegExp(r'^[A-Z]{3}[0-9]{2}[A-Z]$').hasMatch(plate)) {
      return 'Formato nuevo (ABC12D)';
    } else if (RegExp(r'^[A-Z]{3}[0-9]{4}$').hasMatch(plate)) {
      return 'Formato especial (ABC1234)';
    } else {
      return 'Formato no reconocido';
    }
  }
}
