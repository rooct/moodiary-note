import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moodiary/utils/file_util.dart';
import 'package:moodiary/utils/notice_util.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class BackupSyncLogic extends GetxController {
  Future<void> exportFile2() async {
    toast.info(message: '正在处理中');
    final dataPath = FileUtil.getRealPath('', '');
    final zipPath = FileUtil.getCachePath('');
    final isolateParams = {'zipPath': zipPath, 'dataPath': dataPath};
    final path = await FileUtil.zipFileUseRust(isolateParams);
    final res = await Share.shareXFiles([XFile(path)]);
    if (res.status == ShareResultStatus.success) {
      await File(path).delete();
    }
  }

  // Export to local path
  // Export to local path with full error handling and permission checks
  Future<void> exportFile() async {
    try {
      // Step 1: Initial notification
      toast.info(message: '准备导出数据...');

      // Step 2: Check and request storage permission (Android only)
      if (Platform.isAndroid) {
        final status = await Permission.storage.status;
        if (!status.isGranted) {
          final result = await Permission.storage.request();
          if (!result.isGranted) {
            toast.error(message: '存储权限被拒绝，无法导出文件');
            return;
          }
        }
      }

      // Step 3: Prepare source files
      toast.info(message: '正在压缩数据...');
      final dataPath = FileUtil.getRealPath('', '');
      final zipPath = FileUtil.getCachePath('');

      final isolateParams = {'zipPath': zipPath, 'dataPath': dataPath};
      final path = await FileUtil.zipFileUseRust(isolateParams);

      // Verify the zip file was created
      final zipFile = File(path);
      if (!await zipFile.exists()) {
        throw Exception('压缩文件创建失败');
      }

      // Step 4: Determine target directory
      toast.info(message: '准备存储位置...');
      Directory targetDir;

      try {
        // Try downloads directory first
        targetDir =
            (await getDownloadsDirectory()) ??
            await getApplicationDocumentsDirectory();

        // For Android 10+, verify we can write to this directory
        if (Platform.isAndroid) {
          final testFile = File('${targetDir.path}/.temp_test');
          try {
            await testFile.writeAsString('test', flush: true);
            await testFile.delete();
          } catch (e) {
            // Fallback to app documents directory if downloads isn't writable
            targetDir = await getApplicationDocumentsDirectory();
          }
        }
      } catch (e) {
        // Fallback to app documents directory if any error occurs
        targetDir = await getApplicationDocumentsDirectory();
      }

      // Step 5: Create backup directory
      final backupDir = Directory('${targetDir.path}/MoodiaryBackups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Step 6: Generate unique filename
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'moodiary_backup_$timestamp.zip';
      final targetPath = '${backupDir.path}/$fileName';

      // Step 7: Copy the file with progress feedback
      toast.info(message: '正在保存文件...');
      await zipFile.copy(targetPath);

      // Verify the copy was successful
      final savedFile = File(targetPath);
      if (!await savedFile.exists()) {
        throw Exception('文件保存失败');
      }

      // Step 8: Clean up
      await zipFile.delete();

      // Step 9: Success notification with path
      // 替换原来的 toast.success 调用
      Get.snackbar(
        '导出成功',
        '文件已保存至: $targetPath',
        snackPosition: SnackPosition.bottom,
        duration: Duration(seconds: 5),
        mainButton: TextButton(
          onPressed: () async {
            if (Platform.isAndroid) {
              await OpenFile.open(targetPath);
            } else {
              Get.dialog(
                AlertDialog(
                  title: Text('文件路径'),
                  content: SelectableText(targetPath),
                  actions: [
                    TextButton(child: Text('关闭'), onPressed: () => Get.back()),
                  ],
                ),
              );
            }
          },
          child: Text('查看'),
        ),
      );
    } on PlatformException catch (e) {
      toast.error(message: '系统错误: ${e.message}');
    } on IOException catch (e) {
      toast.error(message: '文件读写错误: $e');
    } catch (e) {
      toast.error(message: '导出失败: ${e.toString()}');
    } finally {
      // Any cleanup if needed
    }
  }

  //导入
  Future<void> import() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['zip'],
      type: FileType.custom,
    );
    if (result != null) {
      toast.info(message: '数据导入中，请不要离开页面');
      await FileUtil.extractFile(result.files.single.path!);
      toast.success(message: '导入成功，请重启应用');
    } else {
      toast.info(message: '取消文件选择');
    }
  }
}
