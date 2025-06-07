import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/vehicle.dart';
import '../models/house.dart';
import '../models/visit.dart';
import '../models/parking_zone.dart';
import '../providers/vehicle_provider.dart';
import '../providers/house_provider.dart';
import '../providers/visit_provider.dart';
import '../providers/auth_provider.dart';
import '../main.dart';
import '../services/camera_service.dart';
import '../services/ocr_service.dart';
import '../services/database_service.dart';
import '../utils/vehicle_colors.dart';
import '../widgets/ocr_result_dialog.dart';

class VehicleRegistrationScreen extends StatefulWidget {
  const VehicleRegistrationScreen({super.key});

  @override
  State<VehicleRegistrationScreen> createState() => _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licensePlateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedVehicleType;
  String? _selectedColor;
  House? _selectedHouse;
  ParkingZone? _selectedZone;
  String? _photoPath;
  String? _processedPhotoPath;
  bool _isLoading = false;
  bool _isProcessingOCR = false;
  bool _isWeekendParking = false;
  bool _isCommunalParking = false;

  final List<String> _vehicleTypes = [
    'Automóvil',
    'Motocicleta',
    'Camioneta',
    'Furgón',
    'Otro',
  ];

  List<ParkingZone> _availableZones = [];
  List<Map<String, dynamic>> _houseVehicles = [];

  @override
  void initState() {
    super.initState();
    _loadParkingZones();
    _checkWeekendParking();
    OCRService.initialize();
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _notesController.dispose();
    // Dispose OCR resources when the screen is disposed
    OCRService.dispose();
    super.dispose();
  }

  void _loadParkingZones() async {
    try {
      final zones = await DatabaseService.instance.getVisitorZones();
      setState(() {
        _availableZones = zones;
      });
    } catch (e) {
      print('Error loading parking zones: $e');
    }
  }

  void _checkWeekendParking() {
    final now = DateTime.now();
    final isWeekend = now.weekday == DateTime.sunday ||
        (now.weekday == DateTime.monday && now.hour < 8);
    setState(() {
      _isWeekendParking = isWeekend;
    });
  }

  void _onHouseSelected(House? house) async {
    setState(() {
      _selectedHouse = house;
      _houseVehicles = [];
    });

    if (house != null) {
      try {
        final vehicles = await DatabaseService.instance.getVehiclesByHouse(house.id!);
        setState(() {
          _houseVehicles = vehicles;
        });
      } catch (e) {
        print('Error loading house vehicles: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Vehículo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo section with OCR
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.camera_alt, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Fotografía del Vehículo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_photoPath != null)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _photoPath = null;
                                  _processedPhotoPath = null;
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_photoPath != null)
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(File(_photoPath!)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Tomar fotografía del vehículo'),
                              SizedBox(height: 4),
                              Text(
                                'Enfoque la placa para mejor reconocimiento',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _takePhoto,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Tomar Foto'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickFromGallery,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Galería'),
                            ),
                          ),
                        ],
                      ),
                      if (_photoPath != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isProcessingOCR ? null : _extractPlateFromPhoto,
                            icon: _isProcessingOCR
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : const Icon(Icons.text_fields),
                            label: Text(_isProcessingOCR ? 'Analizando imagen...' : 'Detectar Placa Automáticamente'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        if (_processedPhotoPath != null) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Imagen procesada para OCR:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 100,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(File(_processedPhotoPath!)),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Vehicle info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.directions_car, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Información del Vehículo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _licensePlateController,
                        decoration: const InputDecoration(
                          labelText: 'Placa *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.confirmation_number),
                          helperText: 'Ej: ABC123 o ABC12D',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La placa es requerida';
                          }
                          if (!OCRService.isValidLicensePlate(value)) {
                            return 'Formato de placa inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedVehicleType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Vehículo',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.directions_car),
                        ),
                        items: _vehicleTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedVehicleType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _brandController,
                              decoration: const InputDecoration(
                                labelText: 'Marca',
                                border: OutlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _modelController,
                              decoration: const InputDecoration(
                                labelText: 'Modelo',
                                border: OutlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedColor,
                        decoration: const InputDecoration(
                          labelText: 'Color',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.palette),
                        ),
                        items: VehicleColors.colors.map((color) {
                          return DropdownMenuItem(
                            value: color,
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: _getColorFromName(color),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(color),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedColor = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // House selection with vehicle list
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.home, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Casa que Visita',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Consumer<HouseProvider>(
                        builder: (context, houseProvider, child) {
                          return DropdownButtonFormField<House>(
                            value: _selectedHouse,
                            decoration: const InputDecoration(
                              labelText: 'Seleccionar Casa *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.home),
                            ),
                            items: houseProvider.houses.map((house) {
                              return DropdownMenuItem(
                                value: house,
                                child: Text('Casa ${house.houseNumber} - ${house.ownerName}'),
                              );
                            }).toList(),
                            onChanged: _onHouseSelected,
                            validator: (value) {
                              if (value == null) {
                                return 'Debe seleccionar una casa';
                              }
                              return null;
                            },
                          );
                        },
                      ),

                      // Mostrar vehículos de la casa
                      if (_houseVehicles.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Vehículos registrados en esta casa:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _houseVehicles.length,
                            itemBuilder: (context, index) {
                              final vehicle = _houseVehicles[index];
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  vehicle['is_owner_vehicle'] == 1
                                      ? Icons.home
                                      : Icons.directions_car,
                                  color: vehicle['is_owner_vehicle'] == 1
                                      ? Colors.blue
                                      : Colors.orange,
                                ),
                                title: Text(
                                  vehicle['license_plate'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                subtitle: Text(
                                  '${vehicle['brand'] ?? ''} ${vehicle['model'] ?? ''} - ${vehicle['color'] ?? ''}'
                                      .trim(),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: vehicle['is_owner_vehicle'] == 1
                                        ? Colors.blue.shade50
                                        : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: vehicle['is_owner_vehicle'] == 1
                                          ? Colors.blue
                                          : Colors.orange,
                                    ),
                                  ),
                                  child: Text(
                                    vehicle['is_owner_vehicle'] == 1 ? 'Propietario' : 'Visita',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: vehicle['is_owner_vehicle'] == 1
                                          ? Colors.blue
                                          : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (_houseVehicles.where((v) => v['is_owner_vehicle'] == 1).length >= 2)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              border: Border.all(color: Colors.orange),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Esta casa ya tiene 2+ vehículos. Vehículos adicionales deben ir a Zona 10.',
                                    style: TextStyle(color: Colors.orange.shade800),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Parking options
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_parking, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Opciones de Parqueo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      CheckboxListTile(
                        title: const Text('Parqueo de Casa Comunal'),
                        subtitle: const Text('Costo adicional: \$1,000'),
                        value: _isCommunalParking,
                        onChanged: (value) {
                          setState(() {
                            _isCommunalParking = value ?? false;
                          });
                        },
                      ),

                      if (_isWeekendParking)
                        CheckboxListTile(
                          title: const Text('Parqueo de Fin de Semana'),
                          subtitle: const Text('Domingo noche a viernes mañana - Sin restricción de tiempo'),
                          value: _isWeekendParking,
                          onChanged: null, // Auto-detectado
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.note, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Observaciones',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notas adicionales',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Registrar Visita',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blanco': return Colors.white;
      case 'negro': return Colors.black;
      case 'gris': return Colors.grey;
      case 'plata': return Colors.grey.shade300;
      case 'rojo': return Colors.red;
      case 'azul': return Colors.blue;
      case 'verde': return Colors.green;
      case 'amarillo': return Colors.yellow;
      case 'naranja': return Colors.orange;
      case 'morado': return Colors.purple;
      case 'café': return Colors.brown;
      case 'beige': return Colors.brown.shade200;
      case 'dorado': return Colors.amber;
      case 'rosa': return Colors.pink;
      case 'turquesa': return Colors.teal;
      case 'vino tinto': return Colors.red.shade900;
      default: return Colors.grey;
    }
  }

  Future<void> _takePhoto() async {
    if (cameras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cámaras disponibles')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraService(camera: cameras.first),
      ),
    );

    if (result != null) {
      setState(() {
        _photoPath = result;
        _processedPhotoPath = null; // Reset processed photo
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _photoPath = pickedFile.path;
        _processedPhotoPath = null; // Reset processed photo
      });
    }
  }

  Future<void> _extractPlateFromPhoto() async {
    if (_photoPath == null) return;

    setState(() {
      _isProcessingOCR = true;
    });

    try {
      debugPrint('Iniciando extracción OCR...');
      final ocrResult = await OCRService.extractDetailedTextFromImage(_photoPath!);

      // Capture the processed image path
      if (ocrResult != null && ocrResult['processedImagePath'] != null) {
        setState(() {
          _processedPhotoPath = ocrResult['processedImagePath'];
        });
      }

      if (ocrResult != null) {
        debugPrint('OCR completado. Placas encontradas: ${ocrResult['possiblePlates']}');

        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => OCRResultDialog(
              imagePath: _photoPath!,
              ocrResult: ocrResult,
              onPlateSelected: (plate) {
                setState(() {
                  _licensePlateController.text = plate;
                });
              },
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo detectar texto en la imagen. Verifique que la placa sea visible y esté bien iluminada.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error en OCR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar la imagen: $e'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingOCR = false;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe iniciar sesión primero')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();

      // Check if vehicle already exists
      Vehicle? existingVehicle = context
          .read<VehicleProvider>()
          .getVehicleByPlate(_licensePlateController.text.trim());

      int vehicleId;

      if (existingVehicle == null) {
        // Create new vehicle
        final vehicle = Vehicle(
          licensePlate: _licensePlateController.text.trim(),
          brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
          model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
          color: _selectedColor,
          vehicleType: _selectedVehicleType,
          createdAt: now,
          updatedAt: now,
        );

        final success = await context.read<VehicleProvider>().addVehicle(vehicle);
        if (!success) {
          throw Exception('Error al crear el vehículo');
        }

        existingVehicle = context
            .read<VehicleProvider>()
            .getVehicleByPlate(_licensePlateController.text.trim());
        vehicleId = existingVehicle!.id!;
      } else {
        vehicleId = existingVehicle.id!;
      }

      // Calculate amount based on parking type
      double? amount;
      if (_isCommunalParking) {
        amount = 1000.0; // $1 for communal parking
      }

      // Create visit
      final visit = Visit(
        vehicleId: vehicleId,
        houseId: _selectedHouse!.id!,
        zoneId: _selectedZone?.id,
        entryTime: now,
        photoPath: _photoPath,
        amount: amount,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        agentName: currentUser.name,
        isWeekendParking: _isWeekendParking,
        isCommunalParking: _isCommunalParking,
        createdAt: now,
        updatedAt: now,
      );

      final success = await context.read<VisitProvider>().addVisit(visit);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visita registrada exitosamente')),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Error al registrar la visita');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
