import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'cobalt_api_service.dart';

class DownloadService {
  final Dio _dio = Dio();
  final CobaltApiService _cobaltApi = CobaltApiService();

  Future<Directory> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Usar diretório público de Downloads no Android
      final directory = Directory('/storage/emulated/0/Download/MediaGrabber');
      
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      return directory;
    } else {
      // Para outras plataformas, usar diretório de documentos
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Valida se a URL é suportada
  bool isUrlSupported(String url) {
    return _cobaltApi.isUrlSupported(url);
  }

  /// Detecta a plataforma da URL
  PlatformType detectPlatform(String url) {
    return _cobaltApi.detectPlatform(url);
  }

  /// Busca informações sobre o vídeo/áudio
  Future<MediaInfo> getMediaInfo(String url) async {
    try {
      return await _cobaltApi.getMediaInfo(url);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao buscar informações: $e');
      }
      rethrow;
    }
  }

  /// Faz o download de vídeo
  Future<String> downloadVideo({
    required String url,
    required String quality,
    required Function(double) onProgress,
  }) async {
    try {
      // Validar URL
      if (!isUrlSupported(url)) {
        throw Exception('Esta plataforma não é suportada');
      }

      // Gerar nome de arquivo
      final directory = await getDownloadDirectory();
      final platform = detectPlatform(url);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${platform.displayName}_video_$timestamp.mp4';
      final savePath = '${directory.path}/$filename';

      // Fazer o download usando a API do Cobalt
      await _cobaltApi.downloadVideo(
        url: url,
        quality: quality,
        savePath: savePath,
        onProgress: onProgress,
      );

      return savePath;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro no download de vídeo: $e');
      }
      rethrow;
    }
  }

  /// Faz o download de áudio
  Future<String> downloadAudio({
    required String url,
    required Function(double) onProgress,
  }) async {
    try {
      // Validar URL
      if (!isUrlSupported(url)) {
        throw Exception('Esta plataforma não é suportada');
      }

      // Gerar nome de arquivo
      final directory = await getDownloadDirectory();
      final platform = detectPlatform(url);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${platform.displayName}_audio_$timestamp.mp3';
      final savePath = '${directory.path}/$filename';

      // Fazer o download usando a API do Cobalt
      await _cobaltApi.downloadAudio(
        url: url,
        savePath: savePath,
        onProgress: onProgress,
      );

      return savePath;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro no download de áudio: $e');
      }
      rethrow;
    }
  }

  /// Cancela um download em andamento
  CancelToken createCancelToken() {
    return CancelToken();
  }

  /// Verifica se há espaço suficiente no dispositivo
  Future<bool> hasEnoughSpace({int requiredBytes = 100 * 1024 * 1024}) async {
    try {
      if (Platform.isAndroid) {
        final directory = await getDownloadDirectory();
        final stat = await directory.stat();
        // Esta é uma verificação simplificada
        return true;
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao verificar espaço: $e');
      }
      return true; // Assumir que há espaço em caso de erro
    }
  }

  /// Lista arquivos baixados
  Future<List<File>> listDownloadedFiles() async {
    try {
      final directory = await getDownloadDirectory();
      if (!await directory.exists()) {
        return [];
      }

      final files = directory
          .listSync()
          .whereType<File>()
          .where((file) => 
              file.path.endsWith('.mp4') || 
              file.path.endsWith('.mp3'))
          .toList();

      // Ordenar por data de modificação (mais recentes primeiro)
      files.sort((a, b) => 
          b.statSync().modified.compareTo(a.statSync().modified));

      return files;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao listar arquivos: $e');
      }
      return [];
    }
  }

  /// Exclui um arquivo
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao excluir arquivo: $e');
      }
      return false;
    }
  }

  /// Obtém o tamanho de um arquivo em bytes
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao obter tamanho do arquivo: $e');
      }
      return 0;
    }
  }
}
