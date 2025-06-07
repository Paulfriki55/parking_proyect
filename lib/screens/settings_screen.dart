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
  final _dailyRateController = TextEditingController();
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
    _dailyRateController.dispose();
    _freeMinutesController.dispose();
    _minimumChargeController.dispose();
    _maximumChargeController.dispose();
    super.dispose();
  }

  Future<void> _loadPricingConfig() async {
    final config = context.read<VisitProvider>().pricingConfig;
    if (config != null) {
      _hourlyRateController.text = config.hourlyRate.toString();
      _dailyRateController.text = config.dailyRate.toString();
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
                      
                      // Minutos gratis
                      TextFormField(
                        controller: _freeMinutesController,
                        decoration: const InputDecoration(
                          labelText: 'Minutos Gratis',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.timer),
                          helperText: 'Tiempo gratuito antes de empezar a cobrar',
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
                      
                      // Tarifa por hora
                      TextFormField(
                        controller: _hourlyRateController,
                        decoration: const InputDecoration(
                          labelText: 'Tarifa por Hora (\$)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                          helperText: 'Costo por cada hora (menos de 24h)',
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
                      
                      // Tarifa por día
                      TextFormField(
                        controller: _dailyRateController,
                        decoration: const InputDecoration(
                          labelText: 'Tarifa por Día (\$)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                          helperText: 'Costo por cada día completo (24 horas)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La tarifa por día es requerida';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Ingrese un número válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
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
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
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
                          ),
                        ],
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

              // Simulador de cálculo
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Simulador de Tarifas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCalculationExample(),
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
                          _showHelpDialog();
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

  Widget _buildCalculationExample() {
    final config = context.watch<VisitProvider>().pricingConfig;
    if (config == null) return const Text('Cargando...');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExampleRow('30 minutos', Duration(minutes: 30), config),
        _buildExampleRow('2 horas', Duration(hours: 2), config),
        _buildExampleRow('12 horas', Duration(hours: 12), config),
        _buildExampleRow('24 horas (1 día)', Duration(hours: 24), config),
        _buildExampleRow('30 horas', Duration(hours: 30), config),
        _buildExampleRow('48 horas (2 días)', Duration(hours: 48), config),
      ],
    );
  }

  Widget _buildExampleRow(String timeText, Duration duration, PricingConfig config) {
    final amount = config.calculateAmount(duration);
    final details = config.getCalculationDetails(duration);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(timeText),
          Text(
            '\$${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: amount > 0 ? Colors.green : Colors.grey,
            ),
          ),
        ],
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
        dailyRate: double.parse(_dailyRateController.text),
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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cómo Funciona el Sistema de Tarifas'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🕐 Minutos Gratis:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Tiempo inicial sin costo (ej: 15 minutos)'),
              SizedBox(height: 12),
              Text(
                '⏰ Tarifa por Hora:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Se aplica cuando la estadía es menor a 24 horas'),
              SizedBox(height: 12),
              Text(
                '📅 Tarifa por Día:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Se aplica por cada día completo (24 horas)'),
              SizedBox(height: 12),
              Text(
                '💰 Ejemplo:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• 30 horas = 1 día + 6 horas\n• Costo = (1 × tarifa diaria) + (6 × tarifa por hora)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
