import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
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

  bool _isPersistedLabMember(LabMember member) => int.tryParse(member.id) != null;

  @override
  void initState() {
    super.initState();
    final labId = context.read<AuthBloc>().state.currentLabId;
    context.read<ChemicalsBloc>().add(LoadChemicals(labId: labId));
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

    return BlocListener<ChemicalsBloc, ChemicalsState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.actionMessage != current.actionMessage,
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
        if (state.actionMessage != null && state.actionMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.actionMessage!)),
          );
        }
      },
      child: BlocBuilder<ChemicalsBloc, ChemicalsState>(
        builder: (context, state) {
          final memberCards = [...state.labMembers]
            ..sort((a, b) => _memberPriority(a.role).compareTo(_memberPriority(b.role)));

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: context.l10n.t('chem.searchHint'),
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (value) => context.read<ChemicalsBloc>().add(SearchChemicals(value)),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      EvidenceActionsCard(
                        title: context.l10n.t('chem.evidenceTitle'),
                        description: context.l10n.t('chem.evidenceDesc'),
                        labId: currentLabId,
                        sceneType: 'chemical',
                        deviceType: 'chemical_storage',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _SectionHeader(
                        title: '实验室联系人',
                        subtitle: '值班教师、实验室管理员等联系人可直接修改并实时同步数据库。',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (memberCards.isEmpty)
                        const _EmptyInfo(text: '当前实验室暂无联系人数据。')
                      else
                        Column(
                          children: memberCards
                              .map(
                                (member) => Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                  child: _LabMemberTile(
                                    member: member,
                                    canEdit: canManage && _isPersistedLabMember(member),
                                    onEdit: () => _showMemberEditor(context, member),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          const Expanded(
                            child: _SectionHeader(
                              title: '试剂清单',
                              subtitle: '支持新增、编辑、删除、责任人指定，以及出入库管理。',
                            ),
                          ),
                          if (canManage)
                            FilledButton.icon(
                              onPressed: state.isSaving
                                  ? null
                                  : () => _showChemicalEditor(
                                        context,
                                        labId: currentLabId,
                                        labMembers: state.labMembers,
                                      ),
                              icon: const Icon(Icons.add),
                              label: const Text('新增'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: state.filteredChemicals.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                          child: Center(child: Text(context.l10n.t('chem.noResults'))),
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
                                onTap: () => _showChemicalDetail(
                                  context,
                                  chemical,
                                  canManage,
                                  state.labMembers,
                                  currentLabId,
                                ),
                                onEdit: canManage
                                    ? () => _showChemicalEditor(
                                          context,
                                          chemical: chemical,
                                          labId: currentLabId,
                                          labMembers: state.labMembers,
                                        )
                                    : null,
                                onDelete: canManage ? () => _deleteChemical(context, chemical) : null,
                              ),
                            );
                          },
                          childCount: state.filteredChemicals.length,
                        ),
                      ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.bottomSafeArea)),
            ],
          );
        },
      ),
    );
  }

  int _memberPriority(String role) {
    switch (role) {
      case 'admin':
        return 0;
      case 'teacher':
        return 1;
      case 'graduate':
        return 2;
      default:
        return 3;
    }
  }

  Future<void> _deleteChemical(BuildContext context, Chemical chemical) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除试剂'),
        content: Text('确定删除 ${chemical.name} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.t('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<ChemicalsBloc>().add(DeleteChemical(chemical.id));
    }
  }

  Future<void> _showMemberEditor(BuildContext context, LabMember member) async {
    final nameController = TextEditingController(text: member.name);
    final phoneController = TextEditingController(text: member.phone ?? '');
    final emailController = TextEditingController(text: member.email ?? '');
    final departmentController = TextEditingController(text: member.department ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('编辑联系人'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: '姓名')),
              const SizedBox(height: AppSpacing.md),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: '电话')),
              const SizedBox(height: AppSpacing.md),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: '邮箱')),
              const SizedBox(height: AppSpacing.md),
              TextField(controller: departmentController, decoration: const InputDecoration(labelText: '部门')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.t('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (saved == true && context.mounted) {
      context.read<ChemicalsBloc>().add(
            UpdateLabMemberProfile(
              userId: member.id,
              payload: {
                'name': nameController.text.trim(),
                'phone': phoneController.text.trim(),
                'email': emailController.text.trim(),
                'department': departmentController.text.trim(),
              },
            ),
          );
    }

    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    departmentController.dispose();
  }

  Future<void> _showChemicalEditor(
    BuildContext context, {
    Chemical? chemical,
    required String labId,
    required List<LabMember> labMembers,
  }) async {
    final selectableMembers = labMembers.where(_isPersistedLabMember).toList();
    final nameController = TextEditingController(text: chemical?.name ?? '');
    final casController = TextEditingController(text: chemical?.casNumber ?? '');
    final cabinetController = TextEditingController(text: chemical?.cabinetId ?? '');
    final shelfController = TextEditingController(text: chemical?.shelfCode ?? '');
    final quantityController = TextEditingController(text: chemical?.quantity.toString() ?? '1');
    final unitController = TextEditingController(text: chemical?.unit ?? 'bottle');
    final notesController = TextEditingController(text: chemical?.notes ?? '');
    var selectedHazard = chemical?.hazardClass ?? ChemicalHazardClass.other;
    final initialResponsibleId = chemical?.responsibleUsers.isNotEmpty == true
        ? chemical!.responsibleUsers.first.id
        : null;
    var selectedResponsibleId = selectableMembers.any((member) => member.id == initialResponsibleId)
        ? initialResponsibleId
        : (selectableMembers.isNotEmpty ? selectableMembers.first.id : null);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(chemical == null ? '新增试剂' : '编辑试剂'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: '名称')),
                const SizedBox(height: AppSpacing.md),
                TextField(controller: casController, decoration: const InputDecoration(labelText: 'CAS 号')),
                const SizedBox(height: AppSpacing.md),
                TextField(controller: cabinetController, decoration: const InputDecoration(labelText: '柜位')),
                const SizedBox(height: AppSpacing.md),
                TextField(controller: shelfController, decoration: const InputDecoration(labelText: '层位')),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: '库存数量'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(controller: unitController, decoration: const InputDecoration(labelText: '单位')),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<ChemicalHazardClass>(
                  initialValue: selectedHazard,
                  decoration: const InputDecoration(labelText: '危险类别'),
                  items: ChemicalHazardClass.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedHazard = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: selectedResponsibleId,
                  decoration: const InputDecoration(labelText: '责任人'),
                  items: selectableMembers
                      .map(
                        (member) => DropdownMenuItem(
                          value: member.id,
                          child: Text('${member.name} · ${member.role}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedResponsibleId = value);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: '备注'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.t('common.cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && context.mounted) {
      context.read<ChemicalsBloc>().add(
            SaveChemical(
              chemicalId: chemical?.id,
              payload: {
                'lab_id': labId,
                'name': nameController.text.trim(),
                'cas_number': casController.text.trim(),
                'cabinet_id': cabinetController.text.trim(),
                'shelf_code': shelfController.text.trim(),
                'quantity': double.tryParse(quantityController.text.trim()) ?? 0,
                'unit': unitController.text.trim().isEmpty ? 'bottle' : unitController.text.trim(),
                'hazard_class': selectedHazard.name,
                'status': chemical?.status.name ?? 'inStock',
                'notes': notesController.text.trim(),
                'responsible_user_ids': selectedResponsibleId == null ? <String>[] : <String>[selectedResponsibleId!],
              },
            ),
          );
    }

    nameController.dispose();
    casController.dispose();
    cabinetController.dispose();
    shelfController.dispose();
    quantityController.dispose();
    unitController.dispose();
    notesController.dispose();
  }

  void _showChemicalDetail(
    BuildContext context,
    Chemical chemical,
    bool canManage,
    List<LabMember> labMembers,
    String labId,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(chemical.name, style: Theme.of(context).textTheme.titleLarge),
                ),
                if (canManage)
                  IconButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _showChemicalEditor(
                        context,
                        chemical: chemical,
                        labId: labId,
                        labMembers: labMembers,
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(context.l10n.t('chem.cas', params: {'value': chemical.casNumber})),
            Text(context.l10n.t('chem.cabinet', params: {'cabinet': chemical.cabinetId, 'shelf': chemical.shelfCode})),
            Text(context.l10n.t('chem.stock', params: {'quantity': '${chemical.quantity}', 'unit': chemical.unit})),
            Text(context.l10n.t('chem.hazard', params: {'value': chemical.hazardClass.label})),
            if (chemical.responsibleUsers.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('责任人', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              ...chemical.responsibleUsers.map(
                (user) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('${user.name} · ${user.role}${user.phone != null ? ' · ${user.phone}' : ''}'),
                ),
              ),
            ],
            if (chemical.notes?.isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.md),
              Text('备注：${chemical.notes}'),
            ],
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
                                    notes: '手动入库',
                                  ),
                                );
                            Navigator.of(sheetContext).pop();
                          }
                        : null,
                    child: Text(context.l10n.t('chem.checkIn')),
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
                                    notes: '手动出库',
                                  ),
                                );
                            Navigator.of(sheetContext).pop();
                          }
                        : null,
                    child: Text(context.l10n.t('chem.checkOut')),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _EmptyInfo extends StatelessWidget {
  final String text;

  const _EmptyInfo({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text),
    );
  }
}

class _LabMemberTile extends StatelessWidget {
  final LabMember member;
  final bool canEdit;
  final VoidCallback onEdit;

  const _LabMemberTile({
    required this.member,
    required this.canEdit,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final title = switch (member.role) {
      'admin' => '实验室管理员',
      'teacher' => '值班教师',
      _ => member.role,
    };

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.background,
            child: Icon(Icons.person_outline, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  '${member.name} · ${member.phone ?? member.email ?? member.username}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          if (canEdit)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
    );
  }
}

class _ChemicalCard extends StatelessWidget {
  final Chemical chemical;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ChemicalCard({
    required this.chemical,
    required this.canManage,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final responsibleNames = chemical.responsibleUsers.map((item) => item.name).join('、');
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
                  const SizedBox(height: 4),
                  Text('CAS：${chemical.casNumber}'),
                  Text('${chemical.quantity} ${chemical.unit} | ${chemical.cabinetId}/${chemical.shelfCode}'),
                  if (responsibleNames.isNotEmpty) Text('责任人：$responsibleNames'),
                ],
              ),
            ),
            if (canManage) ...[
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.critical),
              ),
            ] else
              const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
