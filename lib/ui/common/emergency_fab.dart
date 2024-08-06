import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:mindful/core/extensions/ext_build_context.dart';
import 'package:mindful/core/services/method_channel_service.dart';
import 'package:mindful/core/utils/tags.dart';
import 'package:mindful/ui/dialogs/confirmation_dialog.dart';

class EmergencyFAB extends StatelessWidget {
  const EmergencyFAB({super.key});

  void _useEmergency(BuildContext context) async {
    int leftPasses =
        await MethodChannelService.instance.getLeftEmergencyPasses();

    if (!context.mounted) return;

    if (leftPasses <= 0) {
      context.showSnackAlert(
        "You have used all your emergency passes. The blocked apps cannot be unblocked until midnight.",
      );
      return;
    }

    final confirmed = await showConfirmationDialog(
      context: context,
      icon: FluentIcons.fire_20_filled,
      heroTag: AppTags.emergencyTileTag,
      title: "Emergency",
      info:
          "This will pause the app blocker for 5 minutes. You have $leftPasses emergency passes remaining. After using all passes, the app cannot be unblocked until midnight. Do you still want to proceed?",
      positiveLabel: "Use anyway",
    );

    if (!confirmed) return;
    final success = await MethodChannelService.instance.useEmergencyPass();

    if (!success && context.mounted) {
      context.showSnackAlert(
        "The app blocker is already paused. If notifications are enabled, you will receive a notification about the remaining time.",
        icon: FluentIcons.fire_16_filled,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: FloatingActionButton.extended(
        heroTag: AppTags.emergencyTileTag,
        label: const Text("Emergency"),
        icon: const Icon(FluentIcons.fire_20_filled),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        onPressed: () => _useEmergency(context),
      ),
    );
  }
}