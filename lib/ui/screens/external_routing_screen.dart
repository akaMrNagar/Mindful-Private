import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindful/core/services/mindful_native_plugin.dart';
import 'package:mindful/providers/apps_provider.dart';
import 'package:mindful/ui/screens/app_dashboard/app_dashboard.dart';
import 'package:mindful/ui/screens/home/home.dart';

import 'package:mindful/ui/widgets/async_error_indicator.dart';
import 'package:mindful/ui/widgets/async_loading_indicator.dart';

/// This screen is responsible for forwarding the user to [AppDashboard]
/// when the user clicks on the setting button of the TLE dialog.
class ExternalRoutingScreen extends ConsumerWidget {
  const ExternalRoutingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(appsProvider).when(
          loading: () => const AsyncLoadingIndicator(),
          error: (e, st) => AsyncErrorIndicator(e, st),
          data: (appsMap) {
            final target = MindfulNativePlugin.instance.targetedAppPackage;
            if (target.isNotEmpty && appsMap.containsKey(target)) {
              return AppDashboard(app: appsMap[target]!);
            }
            return const Home();
          },
        );
  }
}