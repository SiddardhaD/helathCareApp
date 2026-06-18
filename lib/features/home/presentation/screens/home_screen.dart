import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../medications/domain/entities/medication.dart';
import '../../../medications/presentation/providers/medication_providers.dart';
import '../../../medications/presentation/screens/medication_detail_screen.dart';
import '../../../reminders/domain/entities/reminder.dart';
import '../../../reminders/presentation/providers/reminder_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final todayDosesAsync = ref.watch(todayDoseLogsProvider);
    final medsAsync = ref.watch(medicationListViewModelProvider);
    final remindersAsync = ref.watch(reminderListViewModelProvider);

    final lowStock = medsAsync.valueOrNull == null
        ? <Medication>[]
        : checkLowStockUseCase(medsAsync.valueOrNull!);

    final List<Reminder> upcomingReminders = remindersAsync.valueOrNull == null
        ? <Reminder>[]
        : ref.read(reminderListViewModelProvider.notifier).upcoming.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(medicationListViewModelProvider.notifier).refresh();
            await ref.read(reminderListViewModelProvider.notifier).refresh();
            ref.invalidate(todayDoseLogsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text('Hello, ${user?.displayName ?? "there"}', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 2),
              Text(DateFormat('EEEE, MMMM d').format(DateTime.now()), style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.lg),

              if (lowStock.isNotEmpty) ...[
                _AlertBanner(
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.warning,
                  bgColor: AppColors.warningLight,
                  message: lowStock.length == 1
                      ? '${lowStock.first.name} is running low'
                      : '${lowStock.length} medications are running low',
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              Text("Today's doses", style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              todayDosesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Could not load today\'s doses.', style: AppTextStyles.bodyMedium),
                data: (doses) {
                  if (doses.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        'No doses scheduled for today. Add a medication to get started.',
                        style: AppTextStyles.bodyMedium,
                      ),
                    );
                  }
                  return Column(
                    children: doses
                        .map((d) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: _DoseRow(doseLog: d.log, medication: d.medication),
                            ))
                        .toList(),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.lg),
              Text('Upcoming reminders', style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              if (upcomingReminders.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text('Nothing coming up in the next few days.', style: AppTextStyles.bodyMedium),
                )
              else
                ...upcomingReminders.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_outlined, color: AppColors.primary, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.title, style: AppTextStyles.bodyLarge),
                                  Text(
                                    DateFormat('EEE, MMM d • h:mm a').format(r.dateTime),
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String message;

  const _AlertBanner({required this.icon, required this.color, required this.bgColor, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}

class _DoseRow extends ConsumerWidget {
  final DoseLog doseLog;
  final Medication medication;

  const _DoseRow({required this.doseLog, required this.medication});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTaken = doseLog.status == DoseLogStatus.taken;
    final isMissed = doseLog.status == DoseLogStatus.missed;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MedicationDetailScreen(medicationId: medication.id)),
      ),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(medication.name, style: AppTextStyles.bodyLarge),
                  Text(
                    DateFormat('h:mm a').format(doseLog.scheduledFor) +
                        (medication.dosage != null ? ' • ${medication.dosage}' : ''),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            if (isTaken)
              const AppStatusBadge(label: 'Taken', status: AppBadgeStatus.success, icon: Icons.check_rounded)
            else if (isMissed)
              const AppStatusBadge(label: 'Missed', status: AppBadgeStatus.critical)
            else
              const AppStatusBadge(label: 'Pending', status: AppBadgeStatus.neutral),
          ],
        ),
      ),
    );
  }
}
