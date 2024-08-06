import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindful/config/app_routes.dart';
import 'package:mindful/core/extensions/ext_num.dart';
import 'package:mindful/core/services/method_channel_service.dart';
import 'package:mindful/providers/apps_provider.dart';
import 'package:mindful/ui/common/breathing_widget.dart';
import 'package:mindful/ui/common/rounded_container.dart';
import 'package:mindful/ui/common/styled_text.dart';
import 'package:mindful/ui/transitions/default_effects.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String nextScreenRoute = AppRoutes.homeScreen;

  @override
  void initState() {
    super.initState();
    _validateNextScreen();
    Future.delayed(
      1500.ms,
      () {
        nextScreenRoute == AppRoutes.homeScreen
            ? Navigator.of(context).pop()
            : Navigator.of(context).pushReplacementNamed(nextScreenRoute);
      },
    );
  }

  void _validateNextScreen() async {
    final isOnboardingDone =
        await MethodChannelService.instance.getOnboardingStatus();

    nextScreenRoute =
        isOnboardingDone ? AppRoutes.homeScreen : AppRoutes.onboardingScreen;

    if (isOnboardingDone) {
      ref.read(appsProvider.notifier).refreshDeviceApps();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            /// Breathing logo
            const BreathingWidget(
              dimension: 420,
              child: RoundedContainer(
                circularRadius: 120,
                padding: EdgeInsets.all(12),
                child: Icon(FluentIcons.weather_sunny_low_20_filled, size: 72),
              ),
            ),

            const Column(
              children: [
                /// Title
                StyledText(
                  "Mindful",
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),

                /// Tag line
                StyledText(
                  "Focus on what truly Matters",
                  fontSize: 16,
                  isSubtitle: true,
                ),
              ],
            ),

            const Divider(color: Colors.transparent),
            0.vBox,

            /// Make
            const StyledText("Made with ♥️ in 🇮🇳", fontSize: 14),
          ].animate(effects: DefaultEffects.transitionIn),
        ),
      ),
    );
  }
}