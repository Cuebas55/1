import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CobaltApiService {
  final Dio _dio = Dio();
  static const String _baseUrl = 'https://api.cobalt.tools';
  
  CobaltApiService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  /// Detecta a plataforma e valida a URL
  PlatformType detectPlatform(String url) {
    url = url.toLowerCase();
    
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return PlatformType.youtube;
    } else if (url.contains('instagram.com')) {
      return PlatformType.instagram;
    } else if (url.contains('twitter.com') || url.contains('x.com')) {
      return PlatformType.twitter;
    } else if (url.contains('tiktok.com')) {
      return PlatformType.tiktok;
    } else if (url.contains('facebook.com') || url.contains('fb.watch')) {
      return PlatformType.facebook;
    } else if (url.contains('reddit.com')) {
      return PlatformType.reddit;
    } else if (url.contains('vimeo.com')) {
      return PlatformType.vimeo;
    } else if (url.contains('twitch.tv')) {
      return PlatformType.twitch;
    }
    
    return PlatformType.unknown;
  }

  /// Valida se a URL é suportada
  bool isUrlSupported(String url) {
    return detectPlatform(url) != PlatformType.unknown;
  }

  /// Busca informações sobre o vídeo/áudio
  Future<MediaInfo> getMediaInfo(String url) async {
    try {
      final response = await _dio.post(
        '/api/json',
        data: {
          'url': url,
          'isAudioOnly': false,
          'filenamePattern': 'basic',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        return MediaInfo(
          url: url,
          platform: detectPlatform(url),
          title: _extractTitle(url),
          downloadUrl: data['url'] as String?,
          audioUrl: data['audio'] as String?,
          status: data['status'] as String? ?? 'success',
          error: data['error'] as String?,
        );
      } else {
        throw Exception('Falha ao buscar informações: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao buscar informações: $e');
      }
      throw Exception('Não foi possível obter informações do vídeo: $e');
    }
  }

  /// Faz o download de vídeo
  Future<String> downloadVideo({
    required String url,
    required String quality,
    required String savePath,
    required Function(double) onProgress,
  }) async {
    try {
      // Primeiro, obter o link de download real
      final mediaInfo = await getMediaInfo(url);
      
      if (mediaInfo.downloadUrl == null) {
        throw Exception('URL de download não encontrada');
      }

      // Fazer o download do arquivo
      await _dio.download(
        mediaInfo.downloadUrl!,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
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
    required String savePath,
    required Function(double) onProgress,
  }) async {
    try {
      // Buscar informações com modo de áudio apenas
      final response = await _dio.post(
        '/api/json',
        data: {
          'url': url,
          'isAudioOnly': true,
          'audioFormat': 'mp3',
          'filenamePattern': 'basic',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Falha ao buscar informações de áudio');
      }

      final data = response.data;
      final audioUrl = data['url'] as String?;

      if (audioUrl == null) {
        throw Exception('URL de áudio não encontrada');
      }

      // Fazer o download do arquivo de áudio
      await _dio.download(
        audioUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      return savePath;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro no download de áudio: $e');
      }
      rethrow;
    }
  }

  String _extractTitle(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return 'media';
    
    final platform = detectPlatform(url);
    return '${platform.displayName}_${DateTime.now().millisecondsSinceEpoch}';
  }
}

class MediaInfo {
  final String url;
  final PlatformType platform;
  final String title;
  final String? downloadUrl;
  final String? audioUrl;
  final String status;
  final String? error;

  MediaInfo({
    required this.url,
    required this.platform,
    required this.title,
    this.downloadUrl,
    this.audioUrl,
    required this.status,
    this.error,
  });

  bool get isSuccess => status == 'success' || status == 'stream';
  bool get hasError => error != null;
}

enum PlatformType {
  youtube,
  instagram,
  twitter,
  tiktok,
  facebook,
  reddit,
  vimeo,
  twitch,
  unknown;

  String get displayName {
    switch (this) {
      case PlatformType.youtube:
        return 'YouTube';
      case PlatformType.instagram:
        return 'Instagram';
      case PlatformType.twitter:
        return 'Twitter';
      case PlatformType.tiktok:
        return 'TikTok';
      case PlatformType.facebook:
        return 'Facebook';
      case PlatformType.reddit:
        return 'Reddit';
      case PlatformType.vimeo:
        return 'Vimeo';
      case PlatformType.twitch:
        return 'Twitch';
      case PlatformType.unknown:
        return 'Desconhecido';
    }
  }
}
