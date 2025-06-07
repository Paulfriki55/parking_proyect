import 'package:flutter/material.dart';
import '../models/visit.dart';
import '../models/pricing_config.dart';
import '../services/database_service.dart';

class VisitProvider with ChangeNotifier {
  List<Map<String, dynamic>> _visits = [];
  List<Map<String, dynamic>> _activeVisits = [];
  PricingConfig? _pricingConfig;
  bool _isLoading = false;

  List<Map<String, dynamic>> get visits => _visits;
  List<Map<String, dynamic>> get activeVisits => _activeVisits;
  PricingConfig? get pricingConfig => _pricingConfig;
  bool get isLoading => _isLoading;

  Future<void> loadVisits() async {
    _isLoading = true;
    notifyListeners();

    try {
      _visits = await DatabaseService.instance.getAllVisitsWithDetails();
      _activeVisits = await DatabaseService.instance.getActiveVisits();
    } catch (e) {
      print('Error loading visits: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPricingConfig() async {
    try {
      _pricingConfig = await DatabaseService.instance.getPricingConfig();
      notifyListeners();
    } catch (e) {
      print('Error loading pricing config: $e');
    }
  }

  Future<bool> addVisit(Visit visit) async {
    try {
      await DatabaseService.instance.insertVisit(visit);
      await loadVisits();
      return true;
    } catch (e) {
      print('Error adding visit: $e');
      return false;
    }
  }

  Future<bool> endVisit(int visitId) async {
    try {
      final visitData = _visits.firstWhere((v) => v['id'] == visitId);
      final visit = Visit.fromMap(visitData);
      
      final updatedVisit = visit.copyWith(
        exitTime: DateTime.now(),
        amount: _pricingConfig?.calculateAmount(
          DateTime.now().difference(visit.entryTime)
        ),
        updatedAt: DateTime.now(),
      );

      await DatabaseService.instance.updateVisit(updatedVisit);
      await loadVisits();
      return true;
    } catch (e) {
      print('Error ending visit: $e');
      return false;
    }
  }

  Future<bool> updateVisit(Visit visit) async {
    try {
      await DatabaseService.instance.updateVisit(visit);
      await loadVisits();
      return true;
    } catch (e) {
      print('Error updating visit: $e');
      return false;
    }
  }

  Future<bool> deleteVisit(int id) async {
    try {
      await DatabaseService.instance.deleteVisit(id);
      await loadVisits();
      return true;
    } catch (e) {
      print('Error deleting visit: $e');
      return false;
    }
  }

  double getTotalUnpaidAmount() {
    return _visits
        .where((visit) => visit['is_paid'] == 0 && visit['amount'] != null)
        .fold(0.0, (sum, visit) => sum + (visit['amount'] as double));
  }

  int getActiveVisitsCount() {
    return _activeVisits.length;
  }
}
