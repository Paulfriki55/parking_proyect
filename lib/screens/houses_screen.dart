import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/house.dart';
import '../providers/house_provider.dart';

class HousesScreen extends StatefulWidget {
  const HousesScreen({super.key});

  @override
  State<HousesScreen> createState() => _HousesScreenState();
}

class _HousesScreenState extends State<HousesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HouseProvider>().loadHouses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Casas del Conjunto'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<HouseProvider>(
        builder: (context, houseProvider, child) {
          if (houseProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final houses = houseProvider.houses;

          if (houses.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay casas registradas',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Toca el botón + para agregar una casa',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: houses.length,
            itemBuilder: (context, index) {
              final house = houses[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Text(
                      house.houseNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  title: Text(
                    house.ownerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Casa ${house.houseNumber}'),
                      if (house.ownerPhone != null)
                        Text('Tel: ${house.ownerPhone}'),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Editar'),
                        onTap: () => _showHouseDialog(house),
                      ),
                      PopupMenuItem(
                        child: const Text('Eliminar'),
                        onTap: () => _deleteHouse(house),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showHouseDialog(null),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showHouseDialog(House? house) {
    final isEditing = house != null;
    final houseNumberController = TextEditingController(text: house?.houseNumber ?? '');
    final ownerNameController = TextEditingController(text: house?.ownerName ?? '');
    final ownerPhoneController = TextEditingController(text: house?.ownerPhone ?? '');
    final ownerEmailController = TextEditingController(text: house?.ownerEmail ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Casa' : 'Nueva Casa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: houseNumberController,
                decoration: const InputDecoration(
                  labelText: 'Número de Casa *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ownerNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Propietario *',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ownerPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ownerEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (houseNumberController.text.isEmpty || ownerNameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Complete los campos requeridos')),
                );
                return;
              }

              final now = DateTime.now();
              final newHouse = House(
                id: house?.id,
                houseNumber: houseNumberController.text.trim(),
                ownerName: ownerNameController.text.trim(),
                ownerPhone: ownerPhoneController.text.trim().isEmpty ? null : ownerPhoneController.text.trim(),
                ownerEmail: ownerEmailController.text.trim().isEmpty ? null : ownerEmailController.text.trim(),
                createdAt: house?.createdAt ?? now,
                updatedAt: now,
              );

              bool success;
              if (isEditing) {
                success = await context.read<HouseProvider>().updateHouse(newHouse);
              } else {
                success = await context.read<HouseProvider>().addHouse(newHouse);
              }

              Navigator.pop(context);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Casa ${isEditing ? 'actualizada' : 'creada'} exitosamente')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al guardar la casa')),
                );
              }
            },
            child: Text(isEditing ? 'Actualizar' : 'Crear'),
          ),
        ],
      ),
    );
  }

  void _deleteHouse(House house) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Casa'),
        content: Text('¿Está seguro de que desea eliminar la casa ${house.houseNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<HouseProvider>().deleteHouse(house.id!);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Casa eliminada exitosamente')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al eliminar la casa')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
