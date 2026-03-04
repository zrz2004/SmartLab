import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/services/api_service.dart';
import '../../domain/entities/chemical.dart';

part 'chemicals_event.dart';
part 'chemicals_state.dart';

/// 危化品管理 BLoC
class ChemicalsBloc extends Bloc<ChemicalsEvent, ChemicalsState> {
  final ApiService apiService;
  
  ChemicalsBloc({
    required this.apiService,
  }) : super(const ChemicalsState()) {
    on<LoadChemicals>(_onLoadChemicals);
    on<SearchChemicals>(_onSearchChemicals);
    on<FilterByHazardClass>(_onFilterByHazardClass);
    on<ScanRfidTag>(_onScanRfidTag);
    on<CheckInChemical>(_onCheckInChemical);
    on<CheckOutChemical>(_onCheckOutChemical);
  }
  
  void _onLoadChemicals(
    LoadChemicals event,
    Emitter<ChemicalsState> emit,
  ) {
    emit(state.copyWith(status: ChemicalsStatus.loading));
    
    // 模拟数据
    final chemicals = [
      Chemical(
        id: 'chem_001',
        name: '盐酸',
        casNumber: '7647-01-0',
        hazardClass: ChemicalHazardClass.corrosive,
        quantity: 500,
        unit: 'mL',
        cabinetId: 'A区-1号柜-2层',
        rfidTag: 'RFID-001-HCL',
        specification: '分析纯',
        status: ChemicalStatus.normal,
        expiryDate: DateTime.now().add(const Duration(days: 365)),
      ),
      Chemical(
        id: 'chem_002',
        name: '丙酮',
        casNumber: '67-64-1',
        hazardClass: ChemicalHazardClass.flammable,
        quantity: 1000,
        unit: 'mL',
        cabinetId: 'B区-2号柜-1层',
        rfidTag: 'RFID-002-ACE',
        specification: '分析纯',
        status: ChemicalStatus.normal,
        expiryDate: DateTime.now().add(const Duration(days: 180)),
      ),
      Chemical(
        id: 'chem_003',
        name: '氢氧化钠',
        casNumber: '1310-73-2',
        hazardClass: ChemicalHazardClass.corrosive,
        quantity: 250,
        unit: 'g',
        cabinetId: 'A区-1号柜-3层',
        rfidTag: 'RFID-003-NaOH',
        specification: '分析纯',
        status: ChemicalStatus.normal,
        expiryDate: DateTime.now().add(const Duration(days: 730)),
      ),
      Chemical(
        id: 'chem_004',
        name: '甲醇',
        casNumber: '67-56-1',
        hazardClass: ChemicalHazardClass.toxic,
        quantity: 500,
        unit: 'mL',
        cabinetId: 'C区-危险品柜-1层',
        rfidTag: 'RFID-004-MeOH',
        specification: '分析纯',
        status: ChemicalStatus.expiringSoon,
        expiryDate: DateTime.now().add(const Duration(days: 90)),
      ),
      Chemical(
        id: 'chem_005',
        name: '硫酸',
        casNumber: '7664-93-9',
        hazardClass: ChemicalHazardClass.corrosive,
        quantity: 300,
        unit: 'mL',
        cabinetId: 'A区-1号柜-1层',
        rfidTag: 'RFID-005-H2SO4',
        specification: '分析纯',
        status: ChemicalStatus.normal,
        expiryDate: DateTime.now().add(const Duration(days: 500)),
      ),
    ];
    
    emit(state.copyWith(
      status: ChemicalsStatus.loaded,
      chemicals: chemicals,
      filteredChemicals: List<Chemical>.from(chemicals),
    ));
  }
  
  void _onSearchChemicals(
    SearchChemicals event,
    Emitter<ChemicalsState> emit,
  ) {
    final query = event.query.toLowerCase();
    
    if (query.isEmpty) {
      emit(state.copyWith(
        filteredChemicals: state.chemicals,
        searchQuery: '',
      ));
      return;
    }
    
    final filtered = state.chemicals.where((chemical) {
      return chemical.name.toLowerCase().contains(query) ||
          chemical.casNumber.contains(query) ||
          chemical.cabinetId.toLowerCase().contains(query);
    }).toList();
    
    emit(state.copyWith(
      filteredChemicals: filtered,
      searchQuery: query,
    ));
  }
  
  void _onFilterByHazardClass(
    FilterByHazardClass event,
    Emitter<ChemicalsState> emit,
  ) {
    if (event.hazardClass == null) {
      emit(state.copyWith(
        filteredChemicals: state.chemicals,
        selectedHazardClass: null,
      ));
      return;
    }
    
    final filtered = state.chemicals.where((chemical) {
      return chemical.hazardClass == event.hazardClass;
    }).toList();
    
    emit(state.copyWith(
      filteredChemicals: filtered,
      selectedHazardClass: event.hazardClass,
    ));
  }
  
  Future<void> _onScanRfidTag(
    ScanRfidTag event,
    Emitter<ChemicalsState> emit,
  ) async {
    emit(state.copyWith(isScanning: true));
    
    // 模拟 NFC 扫描
    await Future.delayed(const Duration(seconds: 1));
    
    final chemical = state.chemicals.firstWhere(
      (c) => c.rfidTag == event.rfidTag,
      orElse: () => state.chemicals.first,
    );
    
    emit(state.copyWith(
      isScanning: false,
      scannedChemical: chemical,
    ));
  }
  
  Future<void> _onCheckInChemical(
    CheckInChemical event,
    Emitter<ChemicalsState> emit,
  ) async {
    // 记录入库操作
    final log = ChemicalLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chemicalId: event.chemicalId,
      chemicalName: '危化品',
      action: ChemicalLogAction.checkedIn,
      operatorId: 'user_001',
      operatorName: '张润哲',
      timestamp: DateTime.now(),
      quantityChange: event.quantity,
      remarks: event.notes,
    );
    
    emit(state.copyWith(
      recentLogs: [log, ...state.recentLogs],
    ));
  }
  
  Future<void> _onCheckOutChemical(
    CheckOutChemical event,
    Emitter<ChemicalsState> emit,
  ) async {
    // 记录出库操作
    final log = ChemicalLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chemicalId: event.chemicalId,
      chemicalName: '危化品',
      action: ChemicalLogAction.checkedOut,
      operatorId: 'user_001',
      operatorName: '张润哲',
      timestamp: DateTime.now(),
      quantityChange: -event.quantity,
      remarks: event.notes,
    );
    
    emit(state.copyWith(
      recentLogs: [log, ...state.recentLogs],
    ));
  }
}
