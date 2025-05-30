import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moodiary/common/models/isar/diary.dart';
import 'package:moodiary/common/values/border.dart';
import 'package:moodiary/common/values/diary_type.dart';
import 'package:moodiary/components/base/image.dart';
import 'package:moodiary/components/base/text.dart';
import 'package:moodiary/components/diary_card/basic_card_logic.dart';
import 'package:moodiary/utils/file_util.dart';

class ListDiaryCardComponent extends StatelessWidget with BasicCardLogic {
  const ListDiaryCardComponent({
    super.key,
    required this.diary,
    required this.tag,
  });

  final Diary diary;

  final String tag;

  @override
  Widget build(BuildContext context) {
    Widget buildImage() {
      return AspectRatio(
        aspectRatio: 1.0,
        child: ClipRRect(
          borderRadius: AppBorderRadius.mediumBorderRadius,
          child: MoodiaryImage(
            imagePath: FileUtil.getRealPath('image', diary.imageName.first),
            size: 132,
          ),
        ),
      );
    }

    return Card.filled(
      color: context.theme.colorScheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: AppBorderRadius.mediumBorderRadius,
        onTap: () async {
          await toDiary(diary);
        },
        child: SizedBox(
          height: 132.0,
          child: Row(
            children: [
              if (diary.imageName.isNotEmpty && int.parse(tag) & 1 == 0) ...[
                buildImage(),
              ],
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4.0,
                    children: [
                      if (diary.title.isNotEmpty) ...[
                        EllipsisText(
                          diary.title.trim(),
                          style: context.textTheme.titleMedium?.copyWith(
                            color: context.theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                        ),
                      ],
                      Expanded(
                        child: EllipsisText(
                          diary.contentText.trim().removeLineBreaks(),
                          maxLines: diary.title.isNotEmpty ? 3 : 4,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Row(
                        spacing: 4.0,
                        children: [
                          Text(
                            DateFormat.yMMMMEEEEd().add_Hms().format(
                              diary.time,
                            ),
                            style: context.textTheme.labelSmall?.copyWith(
                              color: context.theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          FaIcon(
                            DiaryType.fromValue(diary.type).icon,
                            size: 10,
                            color: context.theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (diary.imageName.isNotEmpty && int.parse(tag) & 1 == 1) ...[
                buildImage(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
