import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/database_service.dart';

class VehicleProvider with ChangeNotifier {
  List<Vehicle> _vehicles = [];
  bool _isLoading = false;

  List<Vehicle> get vehicles => _vehicles;
  bool get isLoading => _isLoading;

  Future<void> loadVehicles() async {
    _isLoading = true;
    notifyListeners();

    try {
      _vehicles = await DatabaseService.instance.getAllVehicles();
    } catch (e) {
      print('Error loading vehicles: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addVehicle(Vehicle vehicle) async {
    try {
      await DatabaseService.instance.insertVehicle(vehicle);
      await loadVehicles();
      return true;
    } catch (e) {
      print('Error adding vehicle: $e');
      return false;
    }
  }

  Future<bool> updateVehicle(Vehicle vehicle) async {
    try {
      await DatabaseService.instance.updateVehicle(vehicle);
      await loadVehicles();
      return true;
    } catch (e) {
      print('Error updating vehicle: $e');
      return false;
    }
  }

  Future<bool> deleteVehicle(int id) async {
    try {
      await DatabaseService.instance.deleteVehicle(id);
      await loadVehicles();
      return true;
    } catch (e) {
      print('Error deleting vehicle: $e');
      return false;
    }
  }

  Vehicle? getVehicleByPlate(String licensePlate) {
    try {
      return _vehicles.firstWhere((vehicle) => vehicle.licensePlate == licensePlate);
    } catch (e) {
      return null;
    }
  }
}
