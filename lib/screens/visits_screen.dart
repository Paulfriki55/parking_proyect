import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../providers/visit_provider.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<VisitProvider>().loadVisits();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Activas'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveVisits(),
          _buildVisitHistory(),
        ],
      ),
    );
  }

  Widget _buildActiveVisits() {
    return Consumer<VisitProvider>(
      builder: (context, visitProvider, child) {
        final activeVisits = visitProvider.activeVisits;

        if (activeVisits.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hay visitas activas',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => visitProvider.loadVisits(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeVisits.length,
            itemBuilder: (context, index) {
              final visit = activeVisits[index];
              return _buildVisitCard(visit, true);
            },
          ),
        );
      },
    );
  }

  Widget _buildVisitHistory() {
    return Consumer<VisitProvider>(
      builder: (context, visitProvider, child) {
        final allVisits = visitProvider.visits;
        final completedVisits = allVisits.where((visit) => visit['exit_time'] != null).toList();

        if (completedVisits.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hay historial de visitas',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => visitProvider.loadVisits(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: completedVisits.length,
            itemBuilder: (context, index) {
              final visit = completedVisits[index];
              return _buildVisitCard(visit, false);
            },
          ),
        );
      },
    );
  }

  Widget _buildVisitCard(Map<String, dynamic> visit, bool isActive) {
    final entryTime = DateTime.parse(visit['entry_time']);
    final exitTime = visit['exit_time'] != null ? DateTime.parse(visit['exit_time']) : null;
    final duration = exitTime?.difference(entryTime) ?? DateTime.now().difference(entryTime);
    final amount = visit['amount']?.toDouble() ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          child: Text(
            visit['license_plate'].substring(0, 2),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.green : Colors.grey,
            ),
          ),
        ),
        title: Text(
          '${visit['license_plate']} - Casa ${visit['house_number']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Propietario: ${visit['owner_name']}'),
            Text('Entrada: ${DateFormat('dd/MM/yyyy HH:mm').format(entryTime)}'),
            if (!isActive && exitTime != null)
              Text('Salida: ${DateFormat('dd/MM/yyyy HH:mm').format(exitTime)}'),
            Text('Duración: ${_formatDuration(duration)}'),
            if (amount > 0)
              Text(
                'Monto: \$${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: visit['is_paid'] == 1 ? Colors.green : Colors.orange,
                ),
              ),
          ],
        ),
        trailing: isActive
            ? IconButton(
          icon: const Icon(Icons.stop_circle, color: Colors.red),
          onPressed: () => _endVisit(visit['id']),
        )
            : Icon(
          visit['is_paid'] == 1 ? Icons.check_circle : Icons.pending,
          color: visit['is_paid'] == 1 ? Colors.green : Colors.orange,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (visit['brand'] != null || visit['model'] != null || visit['color'] != null)
                  Text(
                    'Vehículo: ${[visit['brand'], visit['model'], visit['color']].where((e) => e != null).join(' ')}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                if (visit['agent_name'] != null)
                  Text('Agente: ${visit['agent_name']}'),
                if (visit['notes'] != null)
                  Text('Notas: ${visit['notes']}'),
                if (visit['photo_path'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GestureDetector(
                      onTap: () => _showPhotoDialog(visit['photo_path']),
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(visit['photo_path'])),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: const Icon(
                          Icons.zoom_in,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                if (!isActive && amount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: visit['is_paid'] == 1 ? null : () => _markAsPaid(visit['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: visit['is_paid'] == 1 ? Colors.green : Colors.orange,
                          ),
                          child: Text(visit['is_paid'] == 1 ? 'Pagado' : 'Marcar como Pagado'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  void _endVisit(int visitId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Visita'),
        content: const Text('¿Está seguro de que desea finalizar esta visita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<VisitProvider>().endVisit(visitId);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Visita finalizada exitosamente')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al finalizar la visita')),
                );
              }
            },
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }

  void _markAsPaid(int visitId) async {
    // This would update the visit's paid status
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidad de pago en desarrollo')),
    );
  }

  void _showPhotoDialog(String photoPath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Fotografía del Vehículo'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: Image.file(
                  File(photoPath),
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
