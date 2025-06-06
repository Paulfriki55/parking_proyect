import 'package:flutter/material.dart';
import '../models/house.dart';
import '../services/database_service.dart';

class HouseProvider with ChangeNotifier {
  List<House> _houses = [];
  bool _isLoading = false;

  List<House> get houses => _houses;
  bool get isLoading => _isLoading;

  Future<void> loadHouses() async {
    _isLoading = true;
    notifyListeners();

    try {
      _houses = await DatabaseService.instance.getAllHouses();
    } catch (e) {
      print('Error loading houses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addHouse(House house) async {
    try {
      await DatabaseService.instance.insertHouse(house);
      await loadHouses();
      return true;
    } catch (e) {
      print('Error adding house: $e');
      return false;
    }
  }

  Future<bool> updateHouse(House house) async {
    try {
      await DatabaseService.instance.updateHouse(house);
      await loadHouses();
      return true;
    } catch (e) {
      print('Error updating house: $e');
      return false;
    }
  }

  Future<bool> deleteHouse(int id) async {
    try {
      await DatabaseService.instance.deleteHouse(id);
      await loadHouses();
      return true;
    } catch (e) {
      print('Error deleting house: $e');
      return false;
    }
  }

  House? getHouseByNumber(String houseNumber) {
    try {
      return _houses.firstWhere((house) => house.houseNumber == houseNumber);
    } catch (e) {
      return null;
    }
  }
}
