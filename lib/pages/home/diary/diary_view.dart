import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moodiary/common/values/view_mode.dart';
import 'package:moodiary/components/base/loading.dart';
import 'package:moodiary/components/base/sheet.dart';
import 'package:moodiary/components/base/text.dart';
import 'package:moodiary/components/category_choice_sheet/category_choice_sheet_view.dart';
import 'package:moodiary/components/diary_tab_view/diary_tab_view_view.dart';
import 'package:moodiary/components/keepalive/keepalive.dart';
import 'package:moodiary/components/scroll/fix_scroll.dart';
import 'package:moodiary/components/search_sheet/search_sheet_view.dart';
import 'package:moodiary/components/sync_dash_board/sync_dash_board_view.dart';
import 'package:moodiary/l10n/l10n.dart';
import 'package:moodiary/utils/webdav_util.dart';

import 'diary_logic.dart';

class DiaryPage extends StatelessWidget {
  const DiaryPage({super.key});

  Widget _buildSyncingButton({
    required BuildContext context,
    required Function() onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: context.theme.colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: const MoodiarySyncing(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logic = Get.put(DiaryLogic());
    final state = Bind.find<DiaryLogic>().state;

    //生成TabBar
    Widget buildTabBar() {
      final List<Widget> allTabs = [];
      //默认的全部tab
      allTabs.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Tab(text: context.l10n.categoryAll),
        ),
      );
      //根据分类生成分类Tab
      allTabs.addAll(
        List.generate(state.categoryList.length, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Tab(text: state.categoryList[index].categoryName),
          );
        }),
      );
      return Row(
        children: [
          IconButton(
            onPressed: () {
              showFloatingModalBottomSheet(
                context: context,
                builder: (context) {
                  return const CategoryChoiceSheetComponent();
                },
              );
            },
            icon: const Icon(Icons.menu_open_rounded),
          ),
          Expanded(
            child: TabBar(
              controller: logic.tabController,
              isScrollable: true,
              dividerHeight: .0,
              tabAlignment: TabAlignment.start,
              indicatorSize: TabBarIndicatorSize.label,
              splashFactory: NoSplash.splashFactory,
              dragStartBehavior: DragStartBehavior.start,
              unselectedLabelStyle: context.textTheme.labelSmall,
              labelStyle: context.textTheme.labelMedium,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              indicator: ShapeDecoration(
                shape: const StadiumBorder(),
                color: context.theme.colorScheme.primaryContainer,
              ),
              indicatorWeight: .0,
              unselectedLabelColor: context.theme.colorScheme.onSurface
                  .withValues(alpha: 0.8),
              labelColor: context.theme.colorScheme.onPrimaryContainer,
              labelPadding: EdgeInsets.zero,
              indicatorPadding: const EdgeInsets.symmetric(vertical: 12.0),
              tabs: allTabs,
            ),
          ),
        ],
      );
    }

    // 单个页面
    Widget buildDiaryView(int index, key, String? categoryId) {
      return KeepAliveWrapper(
        child: PrimaryScrollWrapper(
          key: key,
          child: DiaryTabViewComponent(categoryId: categoryId),
        ),
      );
    }

    Widget buildTabBarView() {
      final List<Widget> allViews = [];
      // 添加全部日记页面
      allViews.add(buildDiaryView(0, state.keyMap['default'], null));
      // 添加分类日记页面
      allViews.addAll(
        List.generate(state.categoryList.length, (index) {
          return buildDiaryView(
            index + 1,
            state.keyMap[state.categoryList[index].id],
            state.categoryList[index].id,
          );
        }),
      );

      return NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification.metrics.axis == Axis.horizontal) {
            logic.checkPageChange();
          }
          return true;
        },
        child: TabBarView(
          controller: logic.tabController,
          dragStartBehavior: DragStartBehavior.start,
          children: allViews,
        ),
      );
    }

    final title = Obx(() {
      return AdaptiveText(
        state.customTitleName.value.isNotEmpty
            ? state.customTitleName.value
            : context.l10n.appName,
        style: context.textTheme.titleLarge?.copyWith(
          color: context.theme.colorScheme.onSurface,
        ),
      );
    });

    final hitokoto = Obx(() {
      return AdaptiveText(
        state.hitokoto.value,
        style: context.textTheme.labelSmall?.copyWith(
          color: context.theme.colorScheme.onSurfaceVariant,
        ),
      );
    });
    return GetBuilder<DiaryLogic>(
      builder: (_) {
        return NestedScrollView(
          key: state.nestedScrollKey,
          headerSliverBuilder: (context, _) {
            return [
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
                sliver: SliverAppBar(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, hitokoto],
                  ),
                  pinned: true,
                  actions: [
                    Obx(() {
                      return WebDavUtil().syncingDiaries.isNotEmpty
                          ? _buildSyncingButton(
                            context: context,
                            onTap: () {
                              showFloatingModalBottomSheet(
                                context: context,
                                builder: (context) {
                                  return const SyncDashBoardComponent();
                                },
                              );
                            },
                          )
                          : IconButton(
                            onPressed: () {
                              showFloatingModalBottomSheet(
                                context: context,
                                builder: (context) {
                                  return const SyncDashBoardComponent();
                                },
                              );
                            },
                            tooltip: context.l10n.dataSync,
                            icon: const Icon(Icons.cloud_sync_rounded),
                          );
                    }),
                    IconButton(
                      onPressed: () {
                        showFloatingModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return const SearchSheetComponent();
                          },
                        );
                      },
                      icon: const Icon(Icons.search_rounded),
                      tooltip: context.l10n.diaryPageSearchButton,
                    ),
                    PopupMenuButton(
                      offset: const Offset(0, 46),
                      tooltip: context.l10n.diaryPageViewModeButton,
                      icon: const Icon(Icons.more_vert_rounded),
                      itemBuilder: (context) {
                        return <PopupMenuEntry<String>>[
                          CheckedPopupMenuItem(
                            checked:
                                state.viewModeType.value == ViewModeType.list,
                            onTap: () async {
                              await logic.changeViewMode(ViewModeType.list);
                            },
                            child: Text(context.l10n.diaryViewModeList),
                          ),
                          const PopupMenuDivider(),
                          CheckedPopupMenuItem(
                            checked:
                                state.viewModeType.value == ViewModeType.grid,
                            onTap: () async {
                              await logic.changeViewMode(ViewModeType.grid);
                            },
                            child: Text(context.l10n.diaryViewModeGrid),
                          ),
                        ];
                      },
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(46.0),
                    child: buildTabBar(),
                  ),
                ),
              ),
            ];
          },
          body: buildTabBarView(),
        );
      },
    );
  }
}
