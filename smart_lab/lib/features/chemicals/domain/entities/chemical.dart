import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Chemical extends Equatable {
  final String id;
  final String labId;
  final String name;
  final String casNumber;
  final String cabinetId;
  final String shelfCode;
  final ChemicalHazardClass hazardClass;
  final ChemicalStatus status;
  final double quantity;
  final String unit;
  final DateTime expiryDate;
  final String? rfidTag;
  final String? notes;
  final List<ChemicalResponsibleUser> responsibleUsers;

  const Chemical({
    required this.id,
    required this.labId,
    required this.name,
    required this.casNumber,
    required this.cabinetId,
    required this.shelfCode,
    required this.hazardClass,
    required this.status,
    required this.quantity,
    required this.unit,
    required this.expiryDate,
    this.rfidTag,
    this.notes,
    this.responsibleUsers = const [],
  });

  factory Chemical.fromJson(Map<String, dynamic> json) {
    final quantityValue = json['quantity'];
    return Chemical(
      id: json['id'].toString(),
      labId: json['lab_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      casNumber: json['cas_number'] as String? ?? '',
      cabinetId: json['cabinet_id'] as String? ?? '',
      shelfCode: json['shelf_code'] as String? ?? '',
      hazardClass: ChemicalHazardClass.fromString(json['hazard_class'] as String?),
      status: ChemicalStatus.fromString(json['status'] as String?),
      quantity: quantityValue is num ? quantityValue.toDouble() : double.tryParse(quantityValue?.toString() ?? '') ?? 0,
      unit: json['unit'] as String? ?? 'bottle',
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'] as String) ?? DateTime.now()
          : DateTime.now().add(const Duration(days: 180)),
      rfidTag: json['rfid_tag'] as String?,
      notes: json['notes'] as String?,
      responsibleUsers: (json['responsible_users'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => ChemicalResponsibleUser.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  Chemical copyWith({
    String? id,
    String? labId,
    String? name,
    String? casNumber,
    String? cabinetId,
    String? shelfCode,
    ChemicalHazardClass? hazardClass,
    ChemicalStatus? status,
    double? quantity,
    String? unit,
    DateTime? expiryDate,
    String? rfidTag,
    String? notes,
    List<ChemicalResponsibleUser>? responsibleUsers,
  }) {
    return Chemical(
      id: id ?? this.id,
      labId: labId ?? this.labId,
      name: name ?? this.name,
      casNumber: casNumber ?? this.casNumber,
      cabinetId: cabinetId ?? this.cabinetId,
      shelfCode: shelfCode ?? this.shelfCode,
      hazardClass: hazardClass ?? this.hazardClass,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      rfidTag: rfidTag ?? this.rfidTag,
      notes: notes ?? this.notes,
      responsibleUsers: responsibleUsers ?? this.responsibleUsers,
    );
  }

  bool get isLowStock => quantity <= 1;
  bool get isExpired => expiryDate.isBefore(DateTime.now());
  bool get isExpiringSoon => expiryDate.isBefore(DateTime.now().add(const Duration(days: 30)));

  @override
  List<Object?> get props => [
        id,
        labId,
        name,
        casNumber,
        cabinetId,
        shelfCode,
        hazardClass,
        status,
        quantity,
        unit,
        expiryDate,
        rfidTag,
        notes,
        responsibleUsers,
      ];
}

class ChemicalResponsibleUser extends Equatable {
  final String id;
  final String name;
  final String role;
  final String? email;
  final String? phone;
  final String? responsibilityType;
  final String? notes;

  const ChemicalResponsibleUser({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.phone,
    this.responsibilityType,
    this.notes,
  });

  factory ChemicalResponsibleUser.fromJson(Map<String, dynamic> json) {
    return ChemicalResponsibleUser(
      id: json['id'].toString(),
      name: json['name'] as String? ?? 'Unknown',
      role: json['role'] as String? ?? 'undergraduate',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      responsibilityType: json['responsibilityType'] as String? ?? json['responsibility_type'] as String?,
      notes: json['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, role, email, phone, responsibilityType, notes];
}

class LabMember extends Equatable {
  final String id;
  final String name;
  final String username;
  final String role;
  final String? department;
  final String? phone;
  final String? email;
  final List<String> accessibleLabIds;

  const LabMember({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    this.department,
    this.phone,
    this.email,
    this.accessibleLabIds = const [],
  });

  factory LabMember.fromJson(Map<String, dynamic> json) {
    return LabMember(
      id: json['id'].toString(),
      name: json['name'] as String? ?? json['username'] as String? ?? 'Unknown',
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? 'undergraduate',
      department: json['department'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      accessibleLabIds: List<String>.from(json['accessible_lab_ids'] ?? const <String>[]),
    );
  }

  @override
  List<Object?> get props => [id, name, username, role, department, phone, email, accessibleLabIds];
}

enum ChemicalHazardClass {
  flammable,
  corrosive,
  toxic,
  oxidizer,
  compressedGas,
  irritant,
  other;

  static ChemicalHazardClass fromString(String? value) {
    return ChemicalHazardClass.values.firstWhere(
      (item) => item.name == value,
      orElse: () => ChemicalHazardClass.other,
    );
  }

  String get label {
    switch (this) {
      case ChemicalHazardClass.flammable:
        return 'Flammable';
      case ChemicalHazardClass.corrosive:
        return 'Corrosive';
      case ChemicalHazardClass.toxic:
        return 'Toxic';
      case ChemicalHazardClass.oxidizer:
        return 'Oxidizer';
      case ChemicalHazardClass.compressedGas:
        return 'Compressed gas';
      case ChemicalHazardClass.irritant:
        return 'Irritant';
      case ChemicalHazardClass.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ChemicalHazardClass.flammable:
        return Icons.local_fire_department;
      case ChemicalHazardClass.corrosive:
        return Icons.science;
      case ChemicalHazardClass.toxic:
        return Icons.warning_amber_rounded;
      case ChemicalHazardClass.oxidizer:
        return Icons.bolt;
      case ChemicalHazardClass.compressedGas:
        return Icons.air;
      case ChemicalHazardClass.irritant:
        return Icons.health_and_safety;
      case ChemicalHazardClass.other:
        return Icons.inventory_2_outlined;
    }
  }

  Color get color {
    switch (this) {
      case ChemicalHazardClass.flammable:
        return Colors.deepOrange;
      case ChemicalHazardClass.corrosive:
        return Colors.purple;
      case ChemicalHazardClass.toxic:
        return Colors.red;
      case ChemicalHazardClass.oxidizer:
        return Colors.amber.shade800;
      case ChemicalHazardClass.compressedGas:
        return Colors.blue;
      case ChemicalHazardClass.irritant:
        return Colors.teal;
      case ChemicalHazardClass.other:
        return Colors.grey;
    }
  }
}

enum ChemicalStatus {
  inStock,
  checkedOut,
  pendingReview,
  expired;

  static ChemicalStatus fromString(String? value) {
    return ChemicalStatus.values.firstWhere(
      (item) => item.name == value,
      orElse: () => ChemicalStatus.inStock,
    );
  }
}

class ChemicalLog extends Equatable {
  final String id;
  final String chemicalId;
  final ChemicalLogAction action;
  final double quantity;
  final String performedBy;
  final DateTime timestamp;
  final String? notes;

  const ChemicalLog({
    required this.id,
    required this.chemicalId,
    required this.action,
    required this.quantity,
    required this.performedBy,
    required this.timestamp,
    this.notes,
  });

  factory ChemicalLog.fromJson(Map<String, dynamic> json) {
    return ChemicalLog(
      id: json['id'].toString(),
      chemicalId: json['chemical_id'] as String? ?? '',
      action: ChemicalLogAction.fromString(json['action'] as String?),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      performedBy: json['performed_by'] as String? ?? 'system',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, chemicalId, action, quantity, performedBy, timestamp, notes];
}

enum ChemicalLogAction {
  checkIn,
  checkOut,
  audit,
  aiReview;

  static ChemicalLogAction fromString(String? value) {
    return ChemicalLogAction.values.firstWhere(
      (item) => item.name == value,
      orElse: () => ChemicalLogAction.audit,
    );
  }
}
