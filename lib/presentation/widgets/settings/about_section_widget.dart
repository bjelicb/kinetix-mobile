import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptic_feedback.dart';

/// Widget for about settings section
class AboutSectionWidget extends StatelessWidget {
  const AboutSectionWidget({super.key});

  void _showComingSoonSnackBar(BuildContext context, String message) {
    AppHaptic.selection();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListTile(
                title: const Text('App Version'),
                subtitle: Text('${snapshot.data!.version} (${snapshot.data!.buildNumber})'),
              );
            }
            return const ListTile(
              title: Text('App Version'),
              subtitle: Text('Loading...'),
            );
          },
        ),
        const Divider(height: 1),
        ListTile(
          title: const Text('Privacy Policy'),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: () => _showComingSoonSnackBar(context, 'Privacy Policy coming soon'),
        ),
        const Divider(height: 1),
        ListTile(
          title: const Text('Terms of Service'),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: () => _showComingSoonSnackBar(context, 'Terms of Service coming soon'),
        ),
        const Divider(height: 1),
        ListTile(
          title: const Text('Contact Support'),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: () => _showComingSoonSnackBar(context, 'Contact support coming soon'),
        ),
        const Divider(height: 1),
        ListTile(
          title: const Text('Open Source Licenses'),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: () => _showComingSoonSnackBar(context, 'Licenses coming soon'),
        ),
      ],
    );
  }
}

