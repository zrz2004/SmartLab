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
    on<SaveChemical>(_onSaveChemical);
    on<DeleteChemical>(_onDeleteChemical);
    on<UpdateLabMemberProfile>(_onUpdateLabMemberProfile);
  }

  Future<void> _onLoadChemicals(
    LoadChemicals event,
    Emitter<ChemicalsState> emit,
  ) async {
    emit(state.copyWith(status: ChemicalsStatus.loading, errorMessage: null, actionMessage: null));

    final labId = _resolveCurrentLabId(event.labId);

    List<Chemical> chemicals;
    try {
      final inventory = await apiService.getChemicalInventory();
      chemicals = <Chemical>[];

      for (final item in inventory) {
        final chemical = Chemical.fromJson(item);
        if (chemical.labId.isNotEmpty && chemical.labId != labId) {
          continue;
        }

        try {
          final responsibilities = await apiService.getChemicalResponsibilities(chemical.id);
          chemicals.add(
            chemical.copyWith(
              responsibleUsers: responsibilities
                  .map(ChemicalResponsibleUser.fromJson)
                  .toList(),
            ),
          );
        } catch (_) {
          chemicals.add(chemical);
        }
      }
    } catch (_) {
      chemicals = _buildMockChemicals(labId);
    }

    List<LabMember> labMembers;
    try {
      labMembers = (await apiService.getLabUsers(labId: labId))
          .map(LabMember.fromJson)
          .toList();
    } catch (_) {
      labMembers = _buildMockMembers(labId);
    }

    List<ChemicalLog> recentLogs;
    try {
      recentLogs = (await apiService.getChemicalLogs(limit: 20))
          .map(ChemicalLog.fromJson)
          .toList();
    } catch (_) {
      recentLogs = _buildMockLogs(chemicals);
    }

    emit(
      _buildState(
        state,
        chemicals: chemicals,
        recentLogs: recentLogs,
        labMembers: labMembers,
        cabinets: _buildCabinetSummaries(chemicals),
        status: ChemicalsStatus.loaded,
        currentLabId: labId,
      ),
    );
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
        labMembers: state.labMembers,
        cabinets: state.cabinets,
        status: state.status == ChemicalsStatus.initial ? ChemicalsStatus.loaded : state.status,
        currentLabId: _resolveCurrentLabId(null),
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
        labMembers: state.labMembers,
        cabinets: state.cabinets,
        status: state.status == ChemicalsStatus.initial ? ChemicalsStatus.loaded : state.status,
        currentLabId: _resolveCurrentLabId(null),
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

  Future<void> _onCheckInChemical(
    CheckInChemical event,
    Emitter<ChemicalsState> emit,
  ) async {
    try {
      final response = await apiService.checkInChemical(
        chemicalId: event.chemicalId,
        quantity: event.quantity,
        notes: event.notes,
      );
      final updatedChemical = Chemical.fromJson(
        Map<String, dynamic>.from(response['chemical'] as Map),
      );
      final updatedLog = ChemicalLog.fromJson(
        Map<String, dynamic>.from(response['log'] as Map),
      );
      final updatedChemicals = state.chemicals.map((chemical) {
        if (chemical.id != event.chemicalId) return chemical;
        return updatedChemical;
      }).toList();
      emit(
        _buildState(
          state.copyWith(actionMessage: '试剂已入库'),
          chemicals: updatedChemicals,
          recentLogs: [updatedLog, ...state.recentLogs],
          labMembers: state.labMembers,
          cabinets: _buildCabinetSummaries(updatedChemicals),
          status: ChemicalsStatus.loaded,
          currentLabId: _resolveCurrentLabId(null),
        ),
      );
      return;
    } catch (_) {}

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
        state.copyWith(actionMessage: '试剂已入库'),
        chemicals: updatedChemicals,
        recentLogs: updatedLogs,
        labMembers: state.labMembers,
        cabinets: _buildCabinetSummaries(updatedChemicals),
        status: ChemicalsStatus.loaded,
        currentLabId: _resolveCurrentLabId(null),
      ),
    );
  }

  Future<void> _onCheckOutChemical(
    CheckOutChemical event,
    Emitter<ChemicalsState> emit,
  ) async {
    try {
      final response = await apiService.checkOutChemical(
        chemicalId: event.chemicalId,
        quantity: event.quantity,
        notes: event.notes,
      );
      final updatedChemical = Chemical.fromJson(
        Map<String, dynamic>.from(response['chemical'] as Map),
      );
      final updatedLog = ChemicalLog.fromJson(
        Map<String, dynamic>.from(response['log'] as Map),
      );
      final updatedChemicals = state.chemicals.map((chemical) {
        if (chemical.id != event.chemicalId) return chemical;
        return updatedChemical;
      }).toList();
      emit(
        _buildState(
          state.copyWith(actionMessage: '试剂已出库'),
          chemicals: updatedChemicals,
          recentLogs: [updatedLog, ...state.recentLogs],
          labMembers: state.labMembers,
          cabinets: _buildCabinetSummaries(updatedChemicals),
          status: ChemicalsStatus.loaded,
          currentLabId: _resolveCurrentLabId(null),
        ),
      );
      return;
    } catch (_) {}

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
        state.copyWith(actionMessage: '试剂已出库'),
        chemicals: updatedChemicals,
        recentLogs: updatedLogs,
        labMembers: state.labMembers,
        cabinets: _buildCabinetSummaries(updatedChemicals),
        status: ChemicalsStatus.loaded,
        currentLabId: _resolveCurrentLabId(null),
      ),
    );
  }

  Future<void> _onSaveChemical(
    SaveChemical event,
    Emitter<ChemicalsState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, errorMessage: null, actionMessage: null));
    try {
      final labId = _resolveLabIdFromPayload(event.payload);
      final response = event.chemicalId == null
          ? await apiService.createChemical(payload: event.payload)
          : await apiService.updateChemical(
              chemicalId: event.chemicalId!,
              payload: event.payload,
            );
      final savedChemical = Chemical.fromJson(response);
      final nextChemicals = _upsertChemical(state.chemicals, savedChemical, labId);
      emit(
        _buildState(
          state.copyWith(
            isSaving: false,
            actionMessage: event.chemicalId == null ? '试剂已新增' : '试剂已更新',
          ),
          chemicals: nextChemicals,
          recentLogs: state.recentLogs,
          labMembers: state.labMembers,
          cabinets: _buildCabinetSummaries(nextChemicals),
          status: ChemicalsStatus.loaded,
          currentLabId: labId,
        ),
      );

      add(LoadChemicals(labId: labId));
    } catch (error) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteChemical(
    DeleteChemical event,
    Emitter<ChemicalsState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, errorMessage: null, actionMessage: null));
    try {
      await apiService.deleteChemical(event.chemicalId);
      final nextChemicals = state.chemicals
          .where((chemical) => chemical.id != event.chemicalId)
          .toList();
      emit(
        _buildState(
          state.copyWith(isSaving: false, actionMessage: '试剂已删除'),
          chemicals: nextChemicals,
          recentLogs: state.recentLogs,
          labMembers: state.labMembers,
          cabinets: _buildCabinetSummaries(nextChemicals),
          status: ChemicalsStatus.loaded,
          currentLabId: _resolveCurrentLabId(null),
        ),
      );
      add(LoadChemicals(labId: _resolveCurrentLabId(null)));
    } catch (error) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateLabMemberProfile(
    UpdateLabMemberProfile event,
    Emitter<ChemicalsState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, errorMessage: null, actionMessage: null));
    try {
      final response = await apiService.updateLabUser(
        userId: event.userId,
        payload: event.payload,
      );
      final updatedMember = LabMember.fromJson(response);
      final nextMembers = state.labMembers
          .map((member) => member.id == updatedMember.id ? updatedMember : member)
          .toList();
      final nextChemicals = state.chemicals
          .map(
            (chemical) => chemical.copyWith(
              responsibleUsers: chemical.responsibleUsers
                  .map(
                    (user) => user.id == updatedMember.id
                        ? ChemicalResponsibleUser(
                            id: user.id,
                            name: updatedMember.name,
                            role: updatedMember.role,
                            email: updatedMember.email,
                            phone: updatedMember.phone,
                            responsibilityType: user.responsibilityType,
                            notes: user.notes,
                          )
                        : user,
                  )
                  .toList(),
            ),
          )
          .toList();
      emit(
        _buildState(
          state.copyWith(isSaving: false, actionMessage: '联系人已更新'),
          chemicals: nextChemicals,
          recentLogs: state.recentLogs,
          labMembers: nextMembers,
          cabinets: _buildCabinetSummaries(nextChemicals),
          status: ChemicalsStatus.loaded,
          currentLabId: _resolveCurrentLabId(null),
        ),
      );
      add(LoadChemicals(labId: _resolveCurrentLabId(null)));
    } catch (error) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  ChemicalsState _buildState(
    ChemicalsState baseState, {
    required List<Chemical> chemicals,
    required List<ChemicalLog> recentLogs,
    required List<LabMember> labMembers,
    required List<Map<String, dynamic>> cabinets,
    required ChemicalsStatus status,
    required String currentLabId,
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
      labMembers: labMembers,
      cabinets: cabinets,
      errorMessage: null,
      actionMessage: baseState.actionMessage,
      currentLabId: currentLabId,
    );
  }

  String _resolveLabIdFromPayload(Map<String, dynamic> payload) {
    final payloadLabId = payload['lab_id'];
    if (payloadLabId is String && payloadLabId.isNotEmpty) {
      return payloadLabId;
    }
    return _resolveCurrentLabId(null);
  }

  String _resolveCurrentLabId(String? preferredLabId) {
    if (preferredLabId != null && preferredLabId.isNotEmpty) {
      return preferredLabId;
    }
    if (state.currentLabId.isNotEmpty) {
      return state.currentLabId;
    }
    return MockDataProvider.currentLabId;
  }

  List<Chemical> _upsertChemical(
    List<Chemical> source,
    Chemical savedChemical,
    String targetLabId,
  ) {
    final retained = source.where((chemical) => chemical.id != savedChemical.id).toList();
    if (savedChemical.labId.isNotEmpty && savedChemical.labId != targetLabId) {
      return retained;
    }
    return [savedChemical, ...retained];
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
          responsibleUsers: const [
            ChemicalResponsibleUser(
              id: 'staff_teacher',
              name: '值班教师',
              role: 'teacher',
              email: 'teacher@smartlab.edu',
              responsibilityType: 'custodian',
            ),
          ],
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
        responsibleUsers: const [
          ChemicalResponsibleUser(
            id: 'staff_admin',
            name: '实验室管理员',
            role: 'admin',
            email: 'admin@smartlab.edu',
            responsibilityType: 'custodian',
          ),
        ],
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

  List<LabMember> _buildMockMembers(String labId) {
    const members = [
      LabMember(
        id: 'staff_admin',
        name: '实验室管理员',
        username: 'admin',
        role: 'admin',
        email: 'admin@smartlab.edu',
        phone: '13800000001',
        accessibleLabIds: ['lab_yuanlou_806', 'lab_xixue_xinke'],
      ),
      LabMember(
        id: 'staff_teacher',
        name: '值班教师',
        username: 'teacher',
        role: 'teacher',
        email: 'teacher@smartlab.edu',
        phone: '13800000002',
        accessibleLabIds: ['lab_yuanlou_806', 'lab_xixue_xinke'],
      ),
    ];
    return members.where((member) => member.accessibleLabIds.contains(labId)).toList();
  }

  List<Map<String, dynamic>> _buildCabinetSummaries(List<Chemical> chemicals) {
    final cabinets = <String, Map<String, dynamic>>{};
    for (final chemical in chemicals) {
      final cabinet = cabinets.putIfAbsent(
        chemical.cabinetId,
        () => {
          'cabinetId': chemical.cabinetId,
          'shelves': <String>{},
          'chemicalCount': 0,
          'lowStockCount': 0,
          'pendingReviewCount': 0,
        },
      );
      (cabinet['shelves'] as Set<String>).add(chemical.shelfCode);
      cabinet['chemicalCount'] = (cabinet['chemicalCount'] as int) + 1;
      if (chemical.isLowStock) {
        cabinet['lowStockCount'] = (cabinet['lowStockCount'] as int) + 1;
      }
      if (chemical.status == ChemicalStatus.pendingReview || chemical.isExpiringSoon) {
        cabinet['pendingReviewCount'] = (cabinet['pendingReviewCount'] as int) + 1;
      }
    }

    return cabinets.values.map((item) {
      return {
        ...item,
        'shelves': ((item['shelves'] as Set<String>).toList()..sort()).join(', '),
      };
    }).toList();
  }
}
