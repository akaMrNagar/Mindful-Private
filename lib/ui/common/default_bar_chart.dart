/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mindful/core/enums/usage_type.dart';
import 'package:mindful/core/extensions/ext_int.dart';
import 'package:mindful/core/utils/app_constants.dart';
import 'package:mindful/core/utils/utils.dart';
import 'package:mindful/ui/common/styled_text.dart';

class DefaultBarChart extends StatelessWidget {
  /// Base bar chart used for displaying app/device usage convert the [data] to percentage range from 0% - 100%
  const DefaultBarChart({
    super.key,
    required this.usageType,
    required this.selectedBar,
    required this.data,
    required this.onBarTap,
    this.height = 232,
    this.width = double.infinity,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
  });

  final double height;
  final double width;
  final EdgeInsets padding;

  final List<int> data;
  final UsageType usageType;
  final int selectedBar;
  final Function(int barIndex) onBarTap;

  @override
  Widget build(BuildContext context) {
    final unselectedGrad = [
      Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
      Theme.of(context).colorScheme.secondaryContainer,
    ];
    final selectedGrad = [
      Theme.of(context).colorScheme.primary.withOpacity(0.7),
      Theme.of(context).colorScheme.primary,
    ];

    final dataMax = data.fold(0, (p, e) => math.max(p, e));
    // adding one to show bar chart if all values are zeroes
    final barMaxHeight = (dataMax * 1.17) + 1.0;

    return Semantics(
      excludeSemantics: true,
      child: Container(
        height: height,
        width: width,
        padding: padding,
        child: BarChart(
          BarChartData(
            barGroups: List.generate(
              data.length,
              (index) {
                final isSelected = selectedBar == index;
                final toPercentY = data[index] / barMaxHeight * 100;
                return BarChartGroupData(
                  groupVertically: true,
                  x: index,
                  barRods: [
                    BarChartRodData(
                      width: 26,
                      toY: toPercentY,
                      gradient: LinearGradient(
                        colors: isSelected ? selectedGrad : unselectedGrad,
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ],
                );
              },
            ),
            maxY: 100,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 24.9,
              getDrawingHorizontalLine: (s) => FlLine(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                strokeWidth: 0.5,
                dashArray: [6, 6],
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: _generateTitles(dataMax, context),
            barTouchData: BarTouchData(
              touchExtraThreshold:
                  const EdgeInsets.symmetric(vertical: 200, horizontal: 12),
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return null;
                },
              ),
              touchCallback: (tEvent, tResponse) {
                if (!tEvent.isInterestedForInteractions) {
                  final touchedIndex = tResponse?.spot?.touchedBarGroupIndex;
                  if (touchedIndex != null &&
                      touchedIndex != selectedBar &&
                      touchedIndex <= todayOfWeek) {
                    onBarTap(touchedIndex);
                  }
                }
              },
            ),
          ),
          swapAnimationCurve: AppConstants.defaultCurve,
          swapAnimationDuration:  AppConstants.defaultAnimDuration,
        ),
      ),
    );
  }

  FlTitlesData _generateTitles(int dataMax, BuildContext context) {
    return FlTitlesData(
      show: true,
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          interval: 25,
          getTitlesWidget: (yPos, meta) => FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: StyledText(
              _generateSideLabels(context, yPos * dataMax ~/ 100),
              color: Theme.of(context).hintColor,
            ),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 24,
          getTitlesWidget: (value, meta) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: StyledText(
                AppConstants.daysShort(context)[value.toInt()],
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _generateSideLabels(BuildContext context, int yData) {
    return switch (usageType) {
      /// Screen usage labels [yData] is in seconds
      UsageType.screenUsage => (yData.inHours > 1)
          ? "${yData.inHours.round()}h"
          : yData.inMinutes >= 1
              ? "${yData.inMinutes}m"
              : "${yData}s",

      /// Network usage labels [yData] is in KBs
      UsageType.networkUsage => (yData.gb >= 1)
          ? "${yData.gb.round()}gb"
          : (yData.mb >= 1)
              ? "${yData.mb}mb"
              : "${yData}kb",
    };
  }
}
