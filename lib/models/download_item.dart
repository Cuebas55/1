import 'dart:io';

class DownloadItem {
  final String id;
  final String url;
  final String filename;
  final String type;
  final String quality;
  String filePath;
  final DateTime downloadDate;
  double progress;
  String status;

  DownloadItem({
    required this.id,
    required this.url,
    required this.filename,
    required this.type,
    required this.quality,
    required this.filePath,
    required this.downloadDate,
    this.progress = 0.0,
    this.status = 'downloading',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'filename': filename,
      'type': type,
      'quality': quality,
      'filePath': filePath,
      'downloadDate': downloadDate.toIso8601String(),
      'progress': progress,
      'status': status,
    };
  }

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      id: json['id'] as String,
      url: json['url'] as String,
      filename: json['filename'] as String,
      type: json['type'] as String,
      quality: json['quality'] as String,
      filePath: json['filePath'] as String,
      downloadDate: DateTime.parse(json['downloadDate'] as String),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'downloading',
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isDownloading => status == 'downloading';

  File get file => File(filePath);
  
  String get fileSize {
    if (!isCompleted || !file.existsSync()) return '0 MB';
    final bytes = file.lengthSync();
    final mb = bytes / (1024 * 1024);
    return '\${mb.toStringAsFixed(2)} MB';
  }
}
