part of 'chemicals_bloc.dart';

enum ChemicalsStatus { initial, loading, loaded, error }

const Object _selectedHazardClassSentinel = Object();
const Object _errorMessageSentinel = Object();

class ChemicalsState extends Equatable {
  final ChemicalsStatus status;
  final List<Chemical> chemicals;
  final List<Chemical> filteredChemicals;
  final String searchQuery;
  final ChemicalHazardClass? selectedHazardClass;
  final bool isScanning;
  final Chemical? scannedChemical;
  final List<ChemicalLog> recentLogs;
  final String? errorMessage;
  
  const ChemicalsState({
    this.status = ChemicalsStatus.initial,
    this.chemicals = const [],
    this.filteredChemicals = const [],
    this.searchQuery = '',
    this.selectedHazardClass,
    this.isScanning = false,
    this.scannedChemical,
    this.recentLogs = const [],
    this.errorMessage,
  });
  
  ChemicalsState copyWith({
    ChemicalsStatus? status,
    List<Chemical>? chemicals,
    List<Chemical>? filteredChemicals,
    String? searchQuery,
    Object? selectedHazardClass = _selectedHazardClassSentinel,
    bool? isScanning,
    Chemical? scannedChemical,
    List<ChemicalLog>? recentLogs,
    Object? errorMessage = _errorMessageSentinel,
  }) {
    return ChemicalsState(
      status: status ?? this.status,
      chemicals: chemicals ?? this.chemicals,
      filteredChemicals: filteredChemicals ?? this.filteredChemicals,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedHazardClass: identical(selectedHazardClass, _selectedHazardClassSentinel)
          ? this.selectedHazardClass
          : selectedHazardClass as ChemicalHazardClass?,
      isScanning: isScanning ?? this.isScanning,
      scannedChemical: scannedChemical ?? this.scannedChemical,
      recentLogs: recentLogs ?? this.recentLogs,
      errorMessage: identical(errorMessage, _errorMessageSentinel) ? this.errorMessage : errorMessage as String?,
    );
  }
  
  /// 获取各类危险品数量统计
  Map<ChemicalHazardClass, int> get hazardClassCounts {
    final counts = <ChemicalHazardClass, int>{};
    for (final chemical in chemicals) {
      counts[chemical.hazardClass] = (counts[chemical.hazardClass] ?? 0) + 1;
    }
    return counts;
  }
  
  /// 获取即将过期的危险品
  List<Chemical> get expiringChemicals {
    final threshold = DateTime.now().add(const Duration(days: 30));
    return chemicals.where((c) => c.expiryDate.isBefore(threshold)).toList();
  }
  
  @override
  List<Object?> get props => [
    status,
    chemicals,
    filteredChemicals,
    searchQuery,
    selectedHazardClass,
    isScanning,
    scannedChemical,
    recentLogs,
  ];
}
