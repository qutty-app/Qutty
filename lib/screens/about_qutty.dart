import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/widgets/logo/logo.dart';

class SettingsAbout extends StatefulWidget {
  const SettingsAbout({super.key});

  @override
  State<SettingsAbout> createState() => _SettingsAboutState();
}

class _SettingsAboutState extends State<SettingsAbout> {
  bool _versionWithBuildNumber = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.commonSettings)),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          String version = l10n.commonLoading;

          if (snapshot.hasData) {
            version = snapshot.data!.version;
          }

          final displayVersion =
              (snapshot.hasData && _versionWithBuildNumber)
                  ? '${snapshot.data!.version} BN-${snapshot.data!.buildNumber}'
                  : version;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  children: [
                    Logo(variant: LogoVariant.textWithBgAlt, height: 128),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Card(
                elevation: 0,
                color: scheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(l10n.aboutTerms),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.push('/settings/tos');
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      title: Text(l10n.aboutLicenses),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.push('/settings/licenses');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _versionWithBuildNumber = true;
                    });
                  },
                  onLongPress: () {
                    context.push('/settings/dev');
                  },
                  child: Text(
                    l10n.aboutCopyright(displayVersion),
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
