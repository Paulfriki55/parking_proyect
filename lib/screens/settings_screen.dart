import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pricing_config.dart';
import '../providers/visit_provider.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hourlyRateController = TextEditingController();
  final _freeMinutesController = TextEditingController();
  final _minimumChargeController = TextEditingController();
  final _maximumChargeController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPricingConfig();
  }

  @override
  void dispose() {
    _hourlyRateController.dispose();
    _freeMinutesController.dispose();
    _minimumChargeController.dispose();
    _maximumChargeController.dispose();
    super.dispose();
  }

  Future<void> _loadPricingConfig() async {
    final config = context.read<VisitProvider>().pricingConfig;
    if (config != null) {
      _hourlyRateController.text = config.hourlyRate.toString();
      _freeMinutesController.text = config.freeMinutes.toString();
      _minimumChargeController.text = config.minimumCharge.toString();
      _maximumChargeController.text = config.maximumCharge.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configuración de Tarifas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _hourlyRateController,
                        decoration: const InputDecoration(
                          labelText: 'Tarifa por Hora (\$)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La tarifa por hora es requerida';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Ingrese un número válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _freeMinutesController,
                        decoration: const InputDecoration(
                          labelText: 'Minutos Gratis',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.timer),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Los minutos gratis son requeridos';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Ingrese un número válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _minimumChargeController,
                        decoration: const InputDecoration(
                          labelText: 'Cobro Mínimo (\$)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.money),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El cobro mínimo es requerido';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Ingrese un número válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _maximumChargeController,
                        decoration: const InputDecoration(
                          labelText: 'Cobro Máximo (\$)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.money_off),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El cobro máximo es requerido';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Ingrese un número válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _savePricingConfig,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Guardar Configuración'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // App info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información de la Aplicación',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const ListTile(
                        leading: Icon(Icons.info),
                        title: Text('Versión'),
                        subtitle: Text('1.0.0'),
                      ),
                      const ListTile(
                        leading: Icon(Icons.developer_mode),
                        title: Text('Desarrollado por'),
                        subtitle: Text('Tu Empresa'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.help),
                        title: const Text('Ayuda y Soporte'),
                        onTap: () {
                          // Show help dialog or navigate to help screen
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePricingConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentConfig = context.read<VisitProvider>().pricingConfig;
      final now = DateTime.now();

      final newConfig = PricingConfig(
        id: currentConfig?.id ?? 1,
        hourlyRate: double.parse(_hourlyRateController.text),
        freeMinutes: int.parse(_freeMinutesController.text),
        minimumCharge: double.parse(_minimumChargeController.text),
        maximumCharge: double.parse(_maximumChargeController.text),
        createdAt: currentConfig?.createdAt ?? now,
        updatedAt: now,
      );

      await DatabaseService.instance.updatePricingConfig(newConfig);
      await context.read<VisitProvider>().loadPricingConfig();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración guardada exitosamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
