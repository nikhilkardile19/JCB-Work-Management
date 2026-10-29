import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/application/auth_providers.dart';
import '../application/company_providers.dart';
import '../domain/company.dart';

/// Shown when the user belongs to more than one company and none is selected.
class SelectCompanyScreen extends ConsumerWidget {
  const SelectCompanyScreen({super.key});

  static (String, StatusTone) _statusLook(CompanyStatus s) => switch (s) {
    CompanyStatus.active => ('Active', StatusTone.success),
    CompanyStatus.pending => ('Pending', StatusTone.warning),
    CompanyStatus.suspended => ('Suspended', StatusTone.danger),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final list = ref.watch(membershipsProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose company'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpace.page),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
        itemBuilder: (context, i) {
          final m = list[i];
          final (label, tone) = _statusLook(m.company.status);
          return AppCard(
            key: Key('company_${m.companyId}'),
            onTap: user == null
                ? null
                : () => ref
                      .read(companyRepositoryProvider)
                      .selectCompany(user.uid, m.companyId),
            child: Row(
              children: [
                const Icon(Icons.business_outlined),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.company.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(m.role.label),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                StatusChip(label: label, tone: tone),
              ],
            ),
          );
        },
      ),
    );
  }
}
