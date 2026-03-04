import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/chemical.dart';
import '../bloc/chemicals_bloc.dart';

/// 危化品管理页面
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
    return BlocBuilder<ChemicalsBloc, ChemicalsState>(
      builder: (context, state) {
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 搜索栏
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '搜索危化品名称、CAS号...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: AppColors.inputBackground,
                          border: OutlineInputBorder(
                            borderRadius: AppSpacing.borderRadiusMd,
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                        onChanged: (value) {
                          context.read<ChemicalsBloc>().add(SearchChemicals(value));
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // NFC 扫描按钮
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                      child: IconButton(
                        onPressed: () => _showNfcScanSheet(context),
                        icon: const Icon(
                          Icons.nfc,
                          color: Colors.white,
                        ),
                        tooltip: 'RFID 扫描',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 危险类别筛选
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: '全部',
                        isSelected: state.selectedHazardClass == null,
                        onTap: () {
                          context.read<ChemicalsBloc>().add(
                            const FilterByHazardClass(null),
                          );
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ...ChemicalHazardClass.values.map((hazard) => Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: _FilterChip(
                          label: hazard.displayName,
                          isSelected: state.selectedHazardClass == hazard,
                          color: hazard.color,
                          onTap: () {
                            context.read<ChemicalsBloc>().add(
                              FilterByHazardClass(hazard),
                            );
                          },
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ),
            
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.lg),
            ),
            
            // 即将过期警告
            if (state.expiringChemicals.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _ExpiryWarningCard(
                    count: state.expiringChemicals.length,
                    onTap: () {
                      // TODO: 跳转到过期列表
                    },
                  ),
                ),
              ),
            
            if (state.expiringChemicals.isNotEmpty)
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.lg),
              ),
            
            // 危化品列表
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final chemical = state.filteredChemicals[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ChemicalCard(
                        chemical: chemical,
                        onTap: () => _showChemicalDetail(context, chemical),
                      ),
                    );
                  },
                  childCount: state.filteredChemicals.length,
                ),
              ),
            ),
            
            // 底部间距
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.bottomSafeArea),
            ),
          ],
        );
      },
    );
  }
  
  void _showNfcScanSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.nfc,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '请将手机靠近 RFID 标签',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '正在搜索附近的 NFC 标签...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.xl),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showChemicalDetail(BuildContext context, Chemical chemical) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _ChemicalDetailSheet(
          chemical: chemical,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

/// 筛选 Chip
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;
  
  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? (color ?? AppColors.primary).withOpacity(0.15) 
              : Colors.white,
          borderRadius: AppSpacing.borderRadiusSm,
          border: Border.all(
            color: isSelected 
                ? (color ?? AppColors.primary) 
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected 
                ? (color ?? AppColors.primary) 
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// 过期警告卡片
class _ExpiryWarningCard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  
  const _ExpiryWarningCard({
    required this.count,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                '有 $count 种危化品即将过期 (30天内)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.warning,
            ),
          ],
        ),
      ),
    );
  }
}

/// 危化品卡片
class _ChemicalCard extends StatelessWidget {
  final Chemical chemical;
  final VoidCallback onTap;
  
  const _ChemicalCard({
    required this.chemical,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 危险类别图标
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: chemical.hazardClass.color.withOpacity(0.15),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Icon(
                    chemical.hazardClass.icon,
                    color: chemical.hazardClass.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chemical.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'CAS: ${chemical.casNumber}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: chemical.hazardClass.color.withOpacity(0.15),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Text(
                    chemical.hazardClass.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: chemical.hazardClass.color,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // 信息行
            Row(
              children: [
                _InfoItem(
                  icon: Icons.inventory_2_outlined,
                  label: '库存',
                  value: '${chemical.quantity.toStringAsFixed(0)} ${chemical.unit}',
                ),
                const SizedBox(width: AppSpacing.lg),
                _InfoItem(
                  icon: Icons.location_on_outlined,
                  label: '位置',
                  value: chemical.cabinetId,
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            // RFID 标签
            Row(
              children: [
                Icon(
                  Icons.nfc,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  chemical.rfidTag,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                Text(
                  '状态: ${chemical.status.displayName}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
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

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// 危化品详情 Sheet
class _ChemicalDetailSheet extends StatelessWidget {
  final Chemical chemical;
  final ScrollController scrollController;
  
  const _ChemicalDetailSheet({
    required this.chemical,
    required this.scrollController,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ListView(
        controller: scrollController,
        children: [
          // 拖动指示器
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // 标题
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: chemical.hazardClass.color.withOpacity(0.15),
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: Icon(
                  chemical.hazardClass.icon,
                  color: chemical.hazardClass.color,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chemical.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'CAS: ${chemical.casNumber}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // 详细信息
          _DetailSection(
            title: '基本信息',
            items: [
              ('危险类别', chemical.hazardClass.displayName),
              ('当前库存', '${chemical.quantity.toStringAsFixed(0)} ${chemical.unit}'),
              ('存放位置', chemical.cabinetId),
              ('RFID 标签', chemical.rfidTag),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          _DetailSection(
            title: '有效期',
            items: [
              ('到期日期', _formatDate(chemical.expiryDate)),
              ('剩余天数', '${chemical.expiryDate.difference(DateTime.now()).inDays} 天'),
              ('当前状态', chemical.status.displayName),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: 入库操作
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('入库'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    // TODO: 领用操作
                  },
                  icon: const Icon(Icons.remove),
                  label: const Text('领用'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<(String, String)> items;
  
  const _DetailSection({
    required this.title,
    required this.items,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          child: Column(
            children: items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.$1,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    item.$2,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
}
