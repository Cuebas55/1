import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/download_item.dart';

class DownloadProvider with ChangeNotifier {
  List<DownloadItem> _downloads = [];
  static const String _storageKey = 'downloads_history';

  List<DownloadItem> get downloads => _downloads;
  
  List<DownloadItem> get completedDownloads =>
      _downloads.where((d) => d.isCompleted).toList();
  
  List<DownloadItem> get activeDownloads =>
      _downloads.where((d) => d.isDownloading).toList();

  DownloadProvider() {
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? downloadsJson = prefs.getString(_storageKey);
      
      if (downloadsJson != null) {
        final List<dynamic> decoded = json.decode(downloadsJson);
        _downloads = decoded
            .map((item) => DownloadItem.fromJson(item as Map<String, dynamic>))
            .toList();
        
        _downloads.sort((a, b) => b.downloadDate.compareTo(a.downloadDate));
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao carregar downloads: \$e');
      }
    }
  }

  Future<void> _saveDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = json.encode(
        _downloads.map((d) => d.toJson()).toList(),
      );
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao salvar downloads: \$e');
      }
    }
  }

  void addDownload(DownloadItem download) {
    _downloads.insert(0, download);
    notifyListeners();
    _saveDownloads();
  }

  void updateDownloadProgress(String id, double progress) {
    final index = _downloads.indexWhere((d) => d.id == id);
    if (index != -1) {
      _downloads[index].progress = progress;
      notifyListeners();
    }
  }

  void updateDownloadStatus(String id, String status) {
    final index = _downloads.indexWhere((d) => d.id == id);
    if (index != -1) {
      _downloads[index].status = status;
      notifyListeners();
      _saveDownloads();
    }
  }

  void removeDownload(String id) {
    _downloads.removeWhere((d) => d.id == id);
    notifyListeners();
    _saveDownloads();
  }

  void clearHistory() {
    _downloads.clear();
    notifyListeners();
    _saveDownloads();
  }
}
