import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moodiary/common/values/icons.dart';
import 'package:moodiary/components/base/button.dart';
import 'package:moodiary/components/mood_icon/mood_icon_view.dart';
import 'package:moodiary/l10n/l10n.dart';
import 'package:moodiary/utils/array_util.dart';

import 'analyse_logic.dart';

class AnalysePage extends StatelessWidget {
  const AnalysePage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Bind.find<AnalyseLogic>();
    final state = Bind.find<AnalyseLogic>().state;

    final size = MediaQuery.sizeOf(context);

    //柱状图
    Widget buildBarChart(
      Map<String, IconData> iconMap,
      Map<String, int> countMap,
      List<String> itemList,
    ) {
      //去重
      itemList = ArrayUtil.toSetList(itemList);
      return Card.filled(
        color: context.theme.colorScheme.surfaceContainer,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: AspectRatio(
            aspectRatio: 1.0,
            child:
                itemList.isNotEmpty
                    ? BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        borderData: FlBorderData(
                          show: true,
                          border: Border.symmetric(
                            horizontal: BorderSide(
                              color: context.theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1.0,
                              getTitlesWidget: (value, meta) {
                                return Text(value.toInt().toString());
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return SideTitleWidget(
                                  meta: meta,
                                  child: Icon(iconMap[itemList[value.toInt()]]),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          checkToShowHorizontalLine: (value) {
                            return value.toInt() == value;
                          },
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: context.theme.colorScheme.onSurface
                                  .withAlpha((255 * 0.2).toInt()),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        barGroups: List.generate(
                          itemList.length,
                          (index) => BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                fromY: 0,
                                toY: countMap[itemList[index]]!.toDouble(),
                                color: context.theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (state.finished) ...[
                          Text(
                            '暂无数据',
                            style: context.textTheme.titleLarge!.copyWith(
                              color: context.theme.colorScheme.onSurface,
                            ),
                          ),
                        ] else ...[
                          const CircularProgressIndicator(),
                        ],
                      ],
                    ),
          ),
        ),
      );
    }

    Widget buildMoodWrap(List<double> itemList) {
      return Card.filled(
        color: context.theme.colorScheme.surfaceContainer,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AspectRatio(
            aspectRatio: 1.0,
            child:
                itemList.isNotEmpty
                    ? Center(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: List.generate(state.moodList.length, (
                            index,
                          ) {
                            return MoodIconComponent(
                              value: state.moodList[index],
                            );
                          }),
                        ),
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (state.finished) ...[
                          Text(
                            '暂无数据',
                            style: context.textTheme.titleLarge!.copyWith(
                              color: context.theme.colorScheme.onSurface,
                            ),
                          ),
                        ] else ...[
                          const CircularProgressIndicator(),
                        ],
                      ],
                    ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingFunctionAnalysis),
        leading: const PageBackButton(),
      ),
      body: GetBuilder<AnalyseLogic>(
        builder: (_) {
          return ListView(
            padding: const EdgeInsets.all(4.0),
            children: [
              Card.filled(
                color: context.theme.colorScheme.surfaceContainer,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    spacing: 8.0,
                    children: [
                      IconButton.filled(
                        onPressed: () {
                          logic.openDatePicker(context);
                        },
                        icon: const Icon(Icons.date_range),
                      ),
                      Text(
                        '${state.dateRange[0].year}年${state.dateRange[0].month}月${state.dateRange[0].day}日 至 ${state.dateRange[1].year}年${state.dateRange[1].month}月${state.dateRange[1].day}日',
                      ),
                    ],
                  ),
                ),
              ),
              // Card.filled(
              //   color: context.theme.colorScheme.surfaceContainer,
              //   child: Padding(
              //     padding: const EdgeInsets.all(8.0),
              //     child: Column(
              //       children: [
              //         TextButton(
              //           onPressed: () {
              //             logic.getAi();
              //           },
              //           child: const Text('AI 分析'),
              //         ),
              //         if (state.reply != '') ...[Text(state.reply)],
              //       ],
              //     ),
              //   ),
              // ),
              GridView.count(
                crossAxisCount: size.width > 600 ? 2 : 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  buildBarChart(
                    WeatherIcon.map,
                    state.weatherMap,
                    state.weatherList,
                  ),
                  buildMoodWrap(state.moodList),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
