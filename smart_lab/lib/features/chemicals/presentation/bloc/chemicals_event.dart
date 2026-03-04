part of 'chemicals_bloc.dart';

sealed class ChemicalsEvent extends Equatable {
  const ChemicalsEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadChemicals extends ChemicalsEvent {}

class SearchChemicals extends ChemicalsEvent {
  final String query;
  
  const SearchChemicals(this.query);
  
  @override
  List<Object?> get props => [query];
}

class FilterByHazardClass extends ChemicalsEvent {
  final ChemicalHazardClass? hazardClass;
  
  const FilterByHazardClass(this.hazardClass);
  
  @override
  List<Object?> get props => [hazardClass];
}

class ScanRfidTag extends ChemicalsEvent {
  final String rfidTag;
  
  const ScanRfidTag(this.rfidTag);
  
  @override
  List<Object?> get props => [rfidTag];
}

class CheckInChemical extends ChemicalsEvent {
  final String chemicalId;
  final double quantity;
  final String? notes;
  
  const CheckInChemical({
    required this.chemicalId,
    required this.quantity,
    this.notes,
  });
  
  @override
  List<Object?> get props => [chemicalId, quantity, notes];
}

class CheckOutChemical extends ChemicalsEvent {
  final String chemicalId;
  final double quantity;
  final String? notes;
  
  const CheckOutChemical({
    required this.chemicalId,
    required this.quantity,
    this.notes,
  });
  
  @override
  List<Object?> get props => [chemicalId, quantity, notes];
}
