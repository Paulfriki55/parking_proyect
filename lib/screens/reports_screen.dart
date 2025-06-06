import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/visit_provider.dart';
import '../services/export_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date range selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rango de Fechas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _selectDate(true),
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              'Desde: ${DateFormat('dd/MM/yyyy').format(_startDate)}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _selectDate(false),
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              'Hasta: ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Summary stats
            Consumer<VisitProvider>(
              builder: (context, visitProvider, child) {
                final visits = visitProvider.visits;
                final filteredVisits = visits.where((visit) {
                  final entryTime = DateTime.parse(visit['entry_time']);
                  return entryTime.isAfter(_startDate) && entryTime.isBefore(_endDate.add(const Duration(days: 1)));
                }).toList();

                final totalVisits = filteredVisits.length;
                final totalAmount = filteredVisits
                    .where((visit) => visit['amount'] != null)
                    .fold(0.0, (sum, visit) => sum + (visit['amount'] as double));
                final paidAmount = filteredVisits
                    .where((visit) => visit['is_paid'] == 1 && visit['amount'] != null)
                    .fold(0.0, (sum, visit) => sum + (visit['amount'] as double));
                final pendingAmount = totalAmount - paidAmount;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Visitas',
                            totalVisits.toString(),
                            Icons.directions_car,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Total a Cobrar',
                            '\$${totalAmount.toStringAsFixed(0)}',
                            Icons.attach_money,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Cobrado',
                            '\$${paidAmount.toStringAsFixed(0)}',
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Pendiente',
                            '\$${pendingAmount.toStringAsFixed(0)}',
                            Icons.pending,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Export options
            const Text(
              'Exportar Datos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : () => _exportData('excel'),
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Exportar a Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : () => _exportData('pdf'),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Exportar a PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (_isExporting)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _exportData(String format) async {
    setState(() {
      _isExporting = true;
    });

    try {
      final visits = context.read<VisitProvider>().visits;
      final filteredVisits = visits.where((visit) {
        final entryTime = DateTime.parse(visit['entry_time']);
        return entryTime.isAfter(_startDate) && entryTime.isBefore(_endDate.add(const Duration(days: 1)));
      }).toList();

      final exportService = ExportService();
      String? filePath;

      if (format == 'excel') {
        filePath = await exportService.exportToExcel(filteredVisits, _startDate, _endDate);
      } else if (format == 'pdf') {
        filePath = await exportService.exportToPDF(filteredVisits, _startDate, _endDate);
      }

      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Archivo exportado exitosamente'),
            action: SnackBarAction(
              label: 'Abrir',
              onPressed: () => exportService.openFile(filePath!),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al exportar el archivo')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }
}
