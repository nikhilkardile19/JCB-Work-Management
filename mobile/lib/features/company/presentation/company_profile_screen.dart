import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/application/auth_providers.dart';
import '../../license/presentation/license_widgets.dart';
import '../application/company_providers.dart';
import '../domain/company.dart';
import '../domain/permissions.dart';
import 'company_profile_form.dart';

/// Company details; owners/admins can edit.
class CompanyProfileScreen extends ConsumerStatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  ConsumerState<CompanyProfileScreen> createState() =>
      _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends ConsumerState<CompanyProfileScreen> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final membership = ref.watch(currentMembershipProvider);
    final canEdit = membership?.can(Permission.manageCompany) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit company' : 'Company profile'),
        actions: [
          if (canEdit && !_editing)
            IconButton(
              key: const Key('company_edit'),
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                if (await ensureCanWrite(context, ref)) {
                  setState(() => _editing = true);
                }
              },
            ),
        ],
      ),
      body: membership == null
          ? const EmptyView(title: 'No company selected')
          : _editing
          ? ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page,
                0,
                AppSpace.page,
                AppSpace.xxl,
              ),
              children: [
                CompanyProfileForm(
                  initial: membership.company.profile,
                  submitLabel: 'Save changes',
                  onSubmit: (profile) async {
                    await ref
                        .read(companyRepositoryProvider)
                        .updateProfile(
                          uid: ref.read(authStateProvider).value!.uid,
                          membership: membership,
                          profile: profile,
                        );
                    if (!context.mounted) return;
                    setState(() => _editing = false);
                    showAppSnackBar(
                      context,
                      'Company profile saved',
                      tone: StatusTone.success,
                    );
                  },
                ),
              ],
            )
          : _Details(membership: membership),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.membership});

  final CompanyMembership membership;

  @override
  Widget build(BuildContext context) {
    final p = membership.company.profile;
    final rows = <(IconData, String, String?)>[
      (Icons.business_outlined, 'Company name', p.name),
      (Icons.place_outlined, 'Address', p.address),
      (Icons.receipt_outlined, 'GSTIN', p.gstin),
      (Icons.person_outline, 'Contact person', p.contactPerson),
      (Icons.phone_outlined, 'Phone', p.phone),
      (Icons.alternate_email, 'Email', p.email),
      (Icons.tag, 'Invoice prefix', p.invoicePrefix),
      (Icons.currency_rupee, 'Currency', p.currency),
      (Icons.badge_outlined, 'Your role', membership.role.label),
    ];
    return ListView(
      padding: const EdgeInsets.all(AppSpace.page),
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (icon, label, value) in rows)
                ListTile(
                  leading: Icon(icon),
                  title: Text(label),
                  subtitle: Text(
                    (value == null || value.isEmpty) ? 'Not provided' : value,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
