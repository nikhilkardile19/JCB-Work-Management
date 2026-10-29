import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../work/application/work_providers.dart';

/// What the app stores where, and why it asks for permissions
/// (sprint doc §4.14).
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy and permissions')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.page,
          0,
          AppSpace.page,
          AppSpace.xxl,
        ),
        children: [
          const SectionHeader('Permissions'),
          const _Item(
            icon: Icons.photo_camera_outlined,
            title: 'Camera',
            body:
                "Meter and receipt photos are taken with your phone's camera app, "
                'only when you tap "Take photo". The app never uses the camera '
                'on its own.',
          ),
          const _Item(
            icon: Icons.location_on_outlined,
            title: 'Location (optional)',
            body:
                'When you take a meter or receipt photo, the app records where '
                'it was taken as evidence for your client. Location is read only '
                'at that moment, never in the background. If you say no, you can '
                'still save every entry.',
          ),
          const SizedBox(height: AppSpace.sm),
          AppButton(
            key: const Key('privacy_settings'),
            label: 'Open app permission settings',
            icon: Icons.settings_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: () => ref.read(locationServiceProvider).openSettings(),
          ),
          const SectionHeader('Stays on this phone'),
          const _Item(
            icon: Icons.phone_android_outlined,
            title: 'Photos and PDFs',
            body:
                'Meter photos, fuel receipts, invoice PDFs and report PDFs are '
                'kept in the app’s private storage and are not uploaded. They '
                'are lost if the app is uninstalled, its data is cleared, or the '
                'phone is lost — share important PDFs to keep a copy.',
          ),
          const _Item(
            icon: Icons.backup_outlined,
            title: 'No phone backup',
            body:
                'Android backup is turned off for this app, because a restored '
                'copy would carry this phone’s license registration to another '
                'phone. Your records are safe on the server once synced.',
          ),
          const SectionHeader('Synced to your company'),
          const _Item(
            icon: Icons.cloud_outlined,
            title: 'Business records',
            body:
                'Company details, clients, sites, machines, operators, petrol '
                'pumps, work logs (meter readings, times and photo locations), '
                'fuel entries, invoices, payments and their history are stored '
                "on your company's secure server so other phones can see them. "
                'Each person only sees what their role allows.',
          ),
          const _Item(
            icon: Icons.badge_outlined,
            title: 'Your account and this phone',
            body:
                'Your sign-in email, your role, and an ID for this app '
                "installation (to register the phone on your company's license). "
                'No contacts, messages or other apps are read.',
          ),
          const SectionHeader('Your choices'),
          const _Item(
            icon: Icons.manage_accounts_outlined,
            title: 'Access and deletion',
            body:
                'Your company owner or admin can change your role or turn off '
                'your access. To have your account or company data deleted, ask '
                'your company owner to contact JCB Works support.',
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: AppCard(
        child: MergeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: AppSpace.xxs),
                    Text(body, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
