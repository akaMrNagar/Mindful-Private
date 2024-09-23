/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindful/providers/permissions_provider.dart';
import 'package:mindful/ui/common/default_list_tile.dart';

class NotificationPermissionTile extends ConsumerWidget {
  const NotificationPermissionTile({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final havePermission = ref
        .watch(permissionProvider.select((v) => v.haveNotificationPermission));

    return DefaultListTile(
      titleText: "Send Notifications",
      accent: havePermission ? null : Theme.of(context).colorScheme.error,
      subtitleText: havePermission ? "Allowed" : "Not allowed",
      isSelected: havePermission,
      margin: const EdgeInsets.only(bottom: 2),
      onPressed: havePermission
          ? null
          : ref.read(permissionProvider.notifier).askNotificationPermission,
    );
  }
}