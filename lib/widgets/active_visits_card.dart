import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/visit_provider.dart';

class ActiveVisitsCard extends StatelessWidget {
  const ActiveVisitsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_car, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Visitas Activas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to full visits list
                  },
                  child: const Text('Ver todas'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Consumer<VisitProvider>(
              builder: (context, visitProvider, child) {
                final activeVisits = visitProvider.activeVisits;

                if (activeVisits.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No hay visitas activas',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeVisits.length > 3 ? 3 : activeVisits.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final visit = activeVisits[index];
                    final entryTime = DateTime.parse(visit['entry_time']);
                    final duration = DateTime.now().difference(entryTime);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.withOpacity(0.1),
                        child: Text(
                          visit['license_plate'].substring(0, 2),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      title: Text(
                        '${visit['license_plate']} - Casa ${visit['house_number']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Propietario: ${visit['owner_name']}\n'
                            'Tiempo: ${_formatDuration(duration)}',
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: const Text('Finalizar Visita'),
                            onTap: () => _endVisit(context, visit['id']),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
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

  void _endVisit(BuildContext context, int visitId) {
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
}
