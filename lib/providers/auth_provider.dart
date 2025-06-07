import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  UserRole get currentUserRole => _currentUser?.role ?? UserRole.agent;

  bool canManageHouses() {
    return _currentUser?.canManageHouses() ?? false;
  }

  bool canViewReports() {
    return _currentUser?.canViewReports() ?? false;
  }

  bool canManageUsers() {
    return _currentUser?.canManageUsers() ?? false;
  }

  Future<bool> login(String email, String name) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Buscar usuario en la base de datos
      User? user = await DatabaseService.instance.getUserByEmail(email);
      
      if (user == null) {
        // Crear usuario por defecto como agente
        final now = DateTime.now();
        user = User(
          name: name,
          email: email,
          role: UserRole.agent,
          createdAt: now,
          updatedAt: now,
        );
        await DatabaseService.instance.insertUser(user);
        user = await DatabaseService.instance.getUserByEmail(email);
      }

      _currentUser = user;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error during login: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateUserRole(String email, UserRole role) async {
    if (!canManageUsers()) return;
    
    try {
      await DatabaseService.instance.updateUserRole(email, role);
      if (_currentUser?.email == email) {
        _currentUser = _currentUser!.copyWith(role: role);
        notifyListeners();
      }
    } catch (e) {
      print('Error updating user role: $e');
    }
  }
}

extension UserCopyWith on User {
  User copyWith({
    int? id,
    String? name,
    String? email,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
