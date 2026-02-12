import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class PermissionService {
  static Future<bool> requestStoragePermissions() async {
    try {
      if (await _isAndroid13OrHigher()) {
        final statuses = await [
          Permission.videos,
          Permission.audio,
          Permission.photos,
        ].request();
        
        return statuses.values.every((status) => status.isGranted);
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao solicitar permissões: \$e');
      }
      return false;
    }
  }

  static Future<bool> hasStoragePermissions() async {
    try {
      if (await _isAndroid13OrHigher()) {
        final videos = await Permission.videos.isGranted;
        final audio = await Permission.audio.isGranted;
        final photos = await Permission.photos.isGranted;
        return videos && audio && photos;
      } else {
        return await Permission.storage.isGranted;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao verificar permissões: \$e');
      }
      return false;
    }
  }

  static Future<bool> _isAndroid13OrHigher() async {
    return true;
  }
}
