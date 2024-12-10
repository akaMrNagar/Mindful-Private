/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */
import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mindful/core/enums/sorting_type.dart';
import 'package:mindful/models/filter_model.dart';
import 'package:mindful/ui/common/default_list_tile.dart';
import 'package:mindful/ui/common/rounded_container.dart';

class SearchFilterPanel extends StatefulWidget {
  const SearchFilterPanel({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  final FilterModel filter;
  final ValueChanged<FilterModel> onFilterChanged;

  @override
  State<SearchFilterPanel> createState() => _SearchFilterPanelState();
}

class _SearchFilterPanelState extends State<SearchFilterPanel> {
  Timer? _debouncer;

  void _onQueryChanged(String text) {
    _debouncer?.cancel();
    _debouncer = Timer(250.ms, () => _onQuerySubmitted(text));
  }

  void _onQuerySubmitted(String text) => widget.onFilterChanged(
        widget.filter.copyWith(query: text),
      );

  @override
  void dispose() {
    _debouncer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DefaultListTile(
            color: Theme.of(context).colorScheme.secondaryContainer,
            title: TextField(
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration.collapsed(
                hintText: "Search apps...",
              ),
              onChanged: _onQueryChanged,
              onSubmitted: _onQuerySubmitted,
            ),
          ),
        ),
        RoundedContainer(
          color: Theme.of(context).colorScheme.secondaryContainer,
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(left: 4),
          circularRadius: 40,
          child: Icon(
            [
              FluentIcons.phone_screen_time_20_regular,
              FluentIcons.earth_20_regular,
              FluentIcons.text_case_lowercase_20_regular,
            ][widget.filter.sorting.index],
            size: 20,
          ),
          onPressed: () => widget.onFilterChanged(
            widget.filter.copyWith(
              sorting: SortingType.values[(widget.filter.sorting.index + 1) %
                  SortingType.values.length],
            ),
          ),
        ),
        RoundedContainer(
          color: Theme.of(context).colorScheme.secondaryContainer,
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(left: 4),
          circularRadius: 40,
          child: Icon(
            widget.filter.reverse
                ? FluentIcons.arrow_up_20_regular
                : FluentIcons.arrow_down_20_regular,
            size: 20,
          ),
          onPressed: () => widget.onFilterChanged(
            widget.filter.copyWith(reverse: !widget.filter.reverse),
          ),
        ),
      ],
    );
  }
}