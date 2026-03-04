import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// 危化品实体
/// 
/// 支持 RFID 标签管理和全生命周期追踪
class Chemical extends Equatable {
  final String id;
  final String rfidTag;
  final String name;
  final String casNumber;
  final String specification;
  final double quantity;
  final String unit;
  final DateTime expiryDate;
  final String cabinetId;
  final ChemicalStatus status;
  final ChemicalHazardClass hazardClass;
  final List<String> incompatibleWith;
  final String? msdsUrl;
  final String? emergencyProcedure;
  
  const Chemical({
    required this.id,
    required this.rfidTag,
    required this.name,
    required this.casNumber,
    required this.specification,
    required this.quantity,
    required this.unit,
    required this.expiryDate,
    required this.cabinetId,
    required this.status,
    required this.hazardClass,
    this.incompatibleWith = const [],
    this.msdsUrl,
    this.emergencyProcedure,
  });
  
  /// 从 JSON 创建
  factory Chemical.fromJson(Map<String, dynamic> json) {
    return Chemical(
      id: json['id'] as String,
      rfidTag: json['rfid_tag'] as String,
      name: json['name'] as String,
      casNumber: json['cas_number'] as String,
      specification: json['specification'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      expiryDate: DateTime.parse(json['expiry_date'] as String),
      cabinetId: json['cabinet_id'] as String,
      status: ChemicalStatus.fromString(json['status'] as String),
      hazardClass: ChemicalHazardClass.fromString(json['hazard_class'] as String),
      incompatibleWith: List<String>.from(json['incompatible_with'] ?? []),
      msdsUrl: json['msds_url'] as String?,
      emergencyProcedure: json['emergency_procedure'] as String?,
    );
  }
  
  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rfid_tag': rfidTag,
      'name': name,
      'cas_number': casNumber,
      'specification': specification,
      'quantity': quantity,
      'unit': unit,
      'expiry_date': expiryDate.toIso8601String(),
      'cabinet_id': cabinetId,
      'status': status.name,
      'hazard_class': hazardClass.name,
      'incompatible_with': incompatibleWith,
      'msds_url': msdsUrl,
      'emergency_procedure': emergencyProcedure,
    };
  }
  
  /// 计算剩余有效期天数
  int get daysUntilExpiry {
    return expiryDate.difference(DateTime.now()).inDays;
  }
  
  /// 是否已过期
  bool get isExpired => daysUntilExpiry < 0;
  
  /// 是否即将过期 (30天内)
  bool get isExpiringSoon => daysUntilExpiry >= 0 && daysUntilExpiry <= 30;
  
  /// 复制并修改
  Chemical copyWith({
    String? id,
    String? rfidTag,
    String? name,
    String? casNumber,
    String? specification,
    double? quantity,
    String? unit,
    DateTime? expiryDate,
    String? cabinetId,
    ChemicalStatus? status,
    ChemicalHazardClass? hazardClass,
    List<String>? incompatibleWith,
    String? msdsUrl,
    String? emergencyProcedure,
  }) {
    return Chemical(
      id: id ?? this.id,
      rfidTag: rfidTag ?? this.rfidTag,
      name: name ?? this.name,
      casNumber: casNumber ?? this.casNumber,
      specification: specification ?? this.specification,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      cabinetId: cabinetId ?? this.cabinetId,
      status: status ?? this.status,
      hazardClass: hazardClass ?? this.hazardClass,
      incompatibleWith: incompatibleWith ?? this.incompatibleWith,
      msdsUrl: msdsUrl ?? this.msdsUrl,
      emergencyProcedure: emergencyProcedure ?? this.emergencyProcedure,
    );
  }
  
  @override
  List<Object?> get props => [id, rfidTag, name, status, quantity, expiryDate];
}

/// 危化品状态枚举
enum ChemicalStatus {
  normal,
  expired,
  expiringSoon,
  missing,
  lowStock,
  inUse;
  
  static ChemicalStatus fromString(String value) {
    return ChemicalStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => ChemicalStatus.normal,
    );
  }
  
  String get displayName {
    switch (this) {
      case ChemicalStatus.normal:
        return '正常';
      case ChemicalStatus.expired:
        return '已过期';
      case ChemicalStatus.expiringSoon:
        return '即将过期';
      case ChemicalStatus.missing:
        return '丢失';
      case ChemicalStatus.lowStock:
        return '库存不足';
      case ChemicalStatus.inUse:
        return '使用中';
    }
  }
}

/// 危化品危险等级枚举 (GHS 分类)
enum ChemicalHazardClass {
  explosive,      // 爆炸物
  flammable,      // 易燃物
  oxidizer,       // 氧化剂
  compressedGas,  // 压缩气体
  corrosive,      // 腐蚀性
  toxic,          // 毒性
  irritant,       // 刺激性
  environmental,  // 环境危害
  healthHazard,   // 健康危害
  nonHazardous;   // 非危险品
  
  static ChemicalHazardClass fromString(String value) {
    return ChemicalHazardClass.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => ChemicalHazardClass.nonHazardous,
    );
  }
  
  String get displayName {
    switch (this) {
      case ChemicalHazardClass.explosive:
        return '爆炸物';
      case ChemicalHazardClass.flammable:
        return '易燃';
      case ChemicalHazardClass.oxidizer:
        return '氧化剂';
      case ChemicalHazardClass.compressedGas:
        return '压缩气体';
      case ChemicalHazardClass.corrosive:
        return '腐蚀性';
      case ChemicalHazardClass.toxic:
        return '剧毒';
      case ChemicalHazardClass.irritant:
        return '刺激性';
      case ChemicalHazardClass.environmental:
        return '环境危害';
      case ChemicalHazardClass.healthHazard:
        return '健康危害';
      case ChemicalHazardClass.nonHazardous:
        return '普通';
    }
  }
  
  /// 获取 GHS 图标名称
  String get ghsIconName {
    switch (this) {
      case ChemicalHazardClass.explosive:
        return 'ghs_explosive';
      case ChemicalHazardClass.flammable:
        return 'ghs_flammable';
      case ChemicalHazardClass.oxidizer:
        return 'ghs_oxidizer';
      case ChemicalHazardClass.compressedGas:
        return 'ghs_gas';
      case ChemicalHazardClass.corrosive:
        return 'ghs_corrosive';
      case ChemicalHazardClass.toxic:
        return 'ghs_toxic';
      case ChemicalHazardClass.irritant:
        return 'ghs_irritant';
      case ChemicalHazardClass.environmental:
        return 'ghs_environment';
      case ChemicalHazardClass.healthHazard:
        return 'ghs_health';
      case ChemicalHazardClass.nonHazardous:
        return 'ghs_none';
    }
  }
  
  /// 获取危险类别颜色
  Color get color {
    switch (this) {
      case ChemicalHazardClass.explosive:
        return const Color(0xFFE53935); // 红色
      case ChemicalHazardClass.flammable:
        return const Color(0xFFFF5722); // 深橙色
      case ChemicalHazardClass.oxidizer:
        return const Color(0xFFFFB300); // 琥珀色
      case ChemicalHazardClass.compressedGas:
        return const Color(0xFF039BE5); // 浅蓝色
      case ChemicalHazardClass.corrosive:
        return const Color(0xFF7B1FA2); // 紫色
      case ChemicalHazardClass.toxic:
        return const Color(0xFF880E4F); // 深紫红
      case ChemicalHazardClass.irritant:
        return const Color(0xFFFFA000); // 橙色
      case ChemicalHazardClass.environmental:
        return const Color(0xFF43A047); // 绿色
      case ChemicalHazardClass.healthHazard:
        return const Color(0xFFD32F2F); // 深红色
      case ChemicalHazardClass.nonHazardous:
        return const Color(0xFF757575); // 灰色
    }
  }
  
  /// 获取危险类别图标
  IconData get icon {
    switch (this) {
      case ChemicalHazardClass.explosive:
        return Icons.flash_on;
      case ChemicalHazardClass.flammable:
        return Icons.local_fire_department;
      case ChemicalHazardClass.oxidizer:
        return Icons.bubble_chart;
      case ChemicalHazardClass.compressedGas:
        return Icons.propane_tank;
      case ChemicalHazardClass.corrosive:
        return Icons.science;
      case ChemicalHazardClass.toxic:
        return Icons.warning;
      case ChemicalHazardClass.irritant:
        return Icons.report_problem;
      case ChemicalHazardClass.environmental:
        return Icons.eco;
      case ChemicalHazardClass.healthHazard:
        return Icons.health_and_safety;
      case ChemicalHazardClass.nonHazardous:
        return Icons.verified;
    }
  }
}

/// 危化品操作日志
class ChemicalLog extends Equatable {
  final String id;
  final String chemicalId;
  final String chemicalName;
  final ChemicalLogAction action;
  final String operatorId;
  final String operatorName;
  final DateTime timestamp;
  final double? quantityChange;
  final String? remarks;
  
  const ChemicalLog({
    required this.id,
    required this.chemicalId,
    required this.chemicalName,
    required this.action,
    required this.operatorId,
    required this.operatorName,
    required this.timestamp,
    this.quantityChange,
    this.remarks,
  });
  
  factory ChemicalLog.fromJson(Map<String, dynamic> json) {
    return ChemicalLog(
      id: json['id'] as String,
      chemicalId: json['chemical_id'] as String,
      chemicalName: json['chemical_name'] as String,
      action: ChemicalLogAction.fromString(json['action'] as String),
      operatorId: json['operator_id'] as String,
      operatorName: json['operator_name'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      quantityChange: (json['quantity_change'] as num?)?.toDouble(),
      remarks: json['remarks'] as String?,
    );
  }
  
  @override
  List<Object?> get props => [id, chemicalId, action, timestamp];
}

/// 危化品操作类型枚举
enum ChemicalLogAction {
  checkedIn,    // 入库
  checkedOut,   // 出库
  returned,     // 归还
  disposed,     // 处置
  transferred,  // 转移
  inventoried;  // 盘点
  
  static ChemicalLogAction fromString(String value) {
    return ChemicalLogAction.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => ChemicalLogAction.inventoried,
    );
  }
  
  String get displayName {
    switch (this) {
      case ChemicalLogAction.checkedIn:
        return '入库';
      case ChemicalLogAction.checkedOut:
        return '出库';
      case ChemicalLogAction.returned:
        return '归还';
      case ChemicalLogAction.disposed:
        return '处置';
      case ChemicalLogAction.transferred:
        return '转移';
      case ChemicalLogAction.inventoried:
        return '盘点';
    }
  }
}
