import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/evidence_actions_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/chemical.dart';
import '../bloc/chemicals_bloc.dart';

class ChemicalsPage extends StatefulWidget {
  const ChemicalsPage({super.key});

  @override
  State<ChemicalsPage> createState() => _ChemicalsPageState();
}

class _ChemicalsPageState extends State<ChemicalsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ChemicalsBloc>().add(LoadChemicals());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentLabId = authState.currentLabId ?? 'lab_yuanlou_806';
    final canManage = authState.user?.canManageChemicals('checkout') ?? false;

    return BlocBuilder<ChemicalsBloc, ChemicalsState>(
      builder: (context, state) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search name, CAS, or cabinet',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => context.read<ChemicalsBloc>().add(SearchChemicals(value)),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    EvidenceActionsCard(
                      title: 'AI evidence for chemicals',
                      description: 'Capture labels, cabinet status, and storage evidence.',
                      labId: currentLabId,
                      sceneType: 'chemical',
                      deviceType: 'chemical_storage',
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: state.filteredChemicals.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: Center(child: Text('No chemicals found for the current filter.')),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final chemical = state.filteredChemicals[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _ChemicalCard(
                              chemical: chemical,
                              canManage: canManage,
                              onTap: () => _showChemicalDetail(context, chemical, canManage),
                            ),
                          );
                        },
                        childCount: state.filteredChemicals.length,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showChemicalDetail(BuildContext context, Chemical chemical, bool canManage) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(chemical.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text('CAS: ${chemical.casNumber}'),
            Text('Cabinet: ${chemical.cabinetId} / ${chemical.shelfCode}'),
            Text('Stock: ${chemical.quantity} ${chemical.unit}'),
            Text('Hazard: ${chemical.hazardClass.label}'),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: canManage
                        ? () {
                            context.read<ChemicalsBloc>().add(
                                  CheckInChemical(
                                    chemicalId: chemical.id,
                                    quantity: 1,
                                    notes: 'Manual check-in from detail sheet',
                                  ),
                                );
                            Navigator.of(sheetContext).pop();
                          }
                        : null,
                    child: const Text('Check in'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: canManage
                        ? () {
                            context.read<ChemicalsBloc>().add(
                                  CheckOutChemical(
                                    chemicalId: chemical.id,
                                    quantity: 1,
                                    notes: 'Manual check-out from detail sheet',
                                  ),
                                );
                            Navigator.of(sheetContext).pop();
                          }
                        : null,
                    child: const Text('Check out'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChemicalCard extends StatelessWidget {
  final Chemical chemical;
  final bool canManage;
  final VoidCallback onTap;

  const _ChemicalCard({
    required this.chemical,
    required this.canManage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(chemical.hazardClass.icon, color: chemical.hazardClass.color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chemical.name, style: Theme.of(context).textTheme.titleSmall),
                  Text('CAS ${chemical.casNumber}'),
                  Text('${chemical.quantity} ${chemical.unit} | ${chemical.cabinetId}'),
                ],
              ),
            ),
            Icon(canManage ? Icons.chevron_right : Icons.lock_outline),
          ],
        ),
      ),
    );
  }
}
