import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/lab_config.dart';
import '../../../../core/constants/mock_data_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../domain/entities/chemical.dart';

part 'chemicals_event.dart';
part 'chemicals_state.dart';

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

  Future<void> _onLoadChemicals(
    LoadChemicals event,
    Emitter<ChemicalsState> emit,
  ) async {
    emit(state.copyWith(status: ChemicalsStatus.loading, errorMessage: null));

    try {
      final labId = MockDataProvider.currentLabId;
      final inventory = await apiService.getChemicalInventory();
      final filteredInventory = inventory
          .map(Chemical.fromJson)
          .where((chemical) => chemical.labId.isEmpty || chemical.labId == labId)
          .toList();

      final logs = await apiService.getChemicalLogs(limit: 20);
      final recentLogs = logs.map(ChemicalLog.fromJson).toList();

      emit(
        _buildState(
          state,
          chemicals: filteredInventory,
          recentLogs: recentLogs,
          status: ChemicalsStatus.loaded,
        ),
      );
    } catch (_) {
      final mockChemicals = _buildMockChemicals(MockDataProvider.currentLabId);
      final mockLogs = _buildMockLogs(mockChemicals);
      emit(
        _buildState(
          state,
          chemicals: mockChemicals,
          recentLogs: mockLogs,
          status: ChemicalsStatus.loaded,
        ),
      );
    }
  }

  void _onSearchChemicals(
    SearchChemicals event,
    Emitter<ChemicalsState> emit,
  ) {
    emit(
      _buildState(
        state.copyWith(searchQuery: event.query),
        chemicals: state.chemicals,
        recentLogs: state.recentLogs,
        status: state.status == ChemicalsStatus.initial ? ChemicalsStatus.loaded : state.status,
      ),
    );
  }

  void _onFilterByHazardClass(
    FilterByHazardClass event,
    Emitter<ChemicalsState> emit,
  ) {
    emit(
      _buildState(
        state.copyWith(selectedHazardClass: event.hazardClass),
        chemicals: state.chemicals,
        recentLogs: state.recentLogs,
        status: state.status == ChemicalsStatus.initial ? ChemicalsStatus.loaded : state.status,
      ),
    );
  }

  void _onScanRfidTag(
    ScanRfidTag event,
    Emitter<ChemicalsState> emit,
  ) {
    Chemical? scanned;
    for (final chemical in state.chemicals) {
      if (chemical.rfidTag == event.rfidTag) {
        scanned = chemical;
        break;
      }
    }

    emit(
      state.copyWith(
        status: ChemicalsStatus.loaded,
        isScanning: false,
        scannedChemical: scanned,
        errorMessage: scanned == null ? 'RFID tag not found in current lab inventory.' : null,
      ),
    );
  }

  void _onCheckInChemical(
    CheckInChemical event,
    Emitter<ChemicalsState> emit,
  ) {
    final updatedChemicals = state.chemicals.map((chemical) {
      if (chemical.id != event.chemicalId) return chemical;
      return chemical.copyWith(
        quantity: chemical.quantity + event.quantity,
        status: ChemicalStatus.inStock,
      );
    }).toList();

    final updatedLogs = [
      ChemicalLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        chemicalId: event.chemicalId,
        action: ChemicalLogAction.checkIn,
        quantity: event.quantity,
        performedBy: 'current_user',
        timestamp: DateTime.now(),
        notes: event.notes,
      ),
      ...state.recentLogs,
    ];

    emit(
      _buildState(
        state,
        chemicals: updatedChemicals,
        recentLogs: updatedLogs,
        status: ChemicalsStatus.loaded,
      ),
    );
  }

  void _onCheckOutChemical(
    CheckOutChemical event,
    Emitter<ChemicalsState> emit,
  ) {
    final updatedChemicals = state.chemicals.map((chemical) {
      if (chemical.id != event.chemicalId) return chemical;
      final nextQuantity = chemical.quantity - event.quantity;
      return chemical.copyWith(
        quantity: nextQuantity < 0 ? 0 : nextQuantity,
        status: nextQuantity <= 0 ? ChemicalStatus.checkedOut : chemical.status,
      );
    }).toList();

    final updatedLogs = [
      ChemicalLog(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        chemicalId: event.chemicalId,
        action: ChemicalLogAction.checkOut,
        quantity: event.quantity,
        performedBy: 'current_user',
        timestamp: DateTime.now(),
        notes: event.notes,
      ),
      ...state.recentLogs,
    ];

    emit(
      _buildState(
        state,
        chemicals: updatedChemicals,
        recentLogs: updatedLogs,
        status: ChemicalsStatus.loaded,
      ),
    );
  }

  ChemicalsState _buildState(
    ChemicalsState baseState, {
    required List<Chemical> chemicals,
    required List<ChemicalLog> recentLogs,
    required ChemicalsStatus status,
  }) {
    final query = baseState.searchQuery.trim().toLowerCase();
    final selectedHazardClass = baseState.selectedHazardClass;

    final filtered = chemicals.where((chemical) {
      final queryMatch = query.isEmpty ||
          chemical.name.toLowerCase().contains(query) ||
          chemical.casNumber.toLowerCase().contains(query) ||
          chemical.cabinetId.toLowerCase().contains(query);
      final hazardMatch = selectedHazardClass == null || chemical.hazardClass == selectedHazardClass;
      return queryMatch && hazardMatch;
    }).toList();

    return baseState.copyWith(
      status: status,
      chemicals: chemicals,
      filteredChemicals: filtered,
      recentLogs: recentLogs,
      errorMessage: null,
    );
  }

  List<Chemical> _buildMockChemicals(String labId) {
    final lab = LabConfig.getLabById(labId) ?? LabConfig.defaultLab;

    if (lab.id == 'lab_xixue_xinke') {
      return [
        Chemical(
          id: 'chem_xx_001',
          labId: lab.id,
          name: 'Acetone',
          casNumber: '67-64-1',
          cabinetId: 'CAB-A',
          shelfCode: 'A-01',
          hazardClass: ChemicalHazardClass.flammable,
          status: ChemicalStatus.inStock,
          quantity: 4,
          unit: 'bottles',
          expiryDate: DateTime.now().add(const Duration(days: 180)),
          rfidTag: 'RFID-XX-001',
          notes: 'Use with local ventilation.',
        ),
        Chemical(
          id: 'chem_xx_002',
          labId: lab.id,
          name: 'Nitric Acid',
          casNumber: '7697-37-2',
          cabinetId: 'CAB-B',
          shelfCode: 'B-03',
          hazardClass: ChemicalHazardClass.corrosive,
          status: ChemicalStatus.inStock,
          quantity: 2,
          unit: 'bottles',
          expiryDate: DateTime.now().add(const Duration(days: 90)),
          rfidTag: 'RFID-XX-002',
        ),
        Chemical(
          id: 'chem_xx_003',
          labId: lab.id,
          name: 'Hydrogen Peroxide',
          casNumber: '7722-84-1',
          cabinetId: 'CAB-C',
          shelfCode: 'C-02',
          hazardClass: ChemicalHazardClass.oxidizer,
          status: ChemicalStatus.pendingReview,
          quantity: 1,
          unit: 'bottle',
          expiryDate: DateTime.now().add(const Duration(days: 20)),
          rfidTag: 'RFID-XX-003',
          notes: 'Pending AI cabinet review.',
        ),
      ];
    }

    return [
      Chemical(
        id: 'chem_yl_001',
        labId: lab.id,
        name: 'Isopropyl Alcohol',
        casNumber: '67-63-0',
        cabinetId: 'CAB-01',
        shelfCode: '01-02',
        hazardClass: ChemicalHazardClass.flammable,
        status: ChemicalStatus.inStock,
        quantity: 6,
        unit: 'bottles',
        expiryDate: DateTime.now().add(const Duration(days: 120)),
        rfidTag: 'RFID-YL-001',
      ),
      Chemical(
        id: 'chem_yl_002',
        labId: lab.id,
        name: 'Copper Sulfate',
        casNumber: '7758-98-7',
        cabinetId: 'CAB-02',
        shelfCode: '02-01',
        hazardClass: ChemicalHazardClass.irritant,
        status: ChemicalStatus.inStock,
        quantity: 3,
        unit: 'boxes',
        expiryDate: DateTime.now().add(const Duration(days: 240)),
        rfidTag: 'RFID-YL-002',
      ),
      Chemical(
        id: 'chem_yl_003',
        labId: lab.id,
        name: 'Compressed Nitrogen',
        casNumber: '7727-37-9',
        cabinetId: 'CYL-01',
        shelfCode: 'G-01',
        hazardClass: ChemicalHazardClass.compressedGas,
        status: ChemicalStatus.inStock,
        quantity: 1,
        unit: 'cylinder',
        expiryDate: DateTime.now().add(const Duration(days: 365)),
        rfidTag: 'RFID-YL-003',
        notes: 'Verify valve closure after each session.',
      ),
    ];
  }

  List<ChemicalLog> _buildMockLogs(List<Chemical> chemicals) {
    return chemicals.take(3).map((chemical) {
      return ChemicalLog(
        id: 'log_${chemical.id}',
        chemicalId: chemical.id,
        action: ChemicalLogAction.audit,
        quantity: chemical.quantity,
        performedBy: 'system',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        notes: 'Inventory synced for ${chemical.cabinetId}.',
      );
    }).toList();
  }
}
