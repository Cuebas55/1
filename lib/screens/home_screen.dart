import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../providers/download_provider.dart';
import '../services/download_service.dart';
import '../services/permission_service.dart';
import '../models/download_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  final DownloadService _downloadService = DownloadService();
  
  String _selectedType = 'video';
  String _selectedQuality = '720p';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermissions = await PermissionService.hasStoragePermissions();
    if (!hasPermissions && mounted) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissões Necessárias'),
        content: const Text(
          'Este app precisa de permissão para acessar o armazenamento '
          'e salvar os arquivos baixados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await PermissionService.requestStoragePermissions();
            },
            child: const Text('Permitir'),
          ),
        ],
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      setState(() {
        _urlController.text = clipboardData!.text!;
      });
    }
  }

  Future<void> _startDownload() async {
    final url = _urlController.text.trim();
    
    if (url.isEmpty) {
      _showSnackBar('Por favor, insira uma URL');
      return;
    }

    // Validar se a URL é suportada
    if (!_downloadService.isUrlSupported(url)) {
      _showSnackBar('Esta plataforma não é suportada. Suporte: YouTube, Instagram, Twitter, TikTok, Facebook, Reddit, Vimeo, Twitch');
      return;
    }

    // Verificar permissões
    final hasPermissions = await PermissionService.hasStoragePermissions();
    if (!hasPermissions) {
      _showSnackBar('Permissões de armazenamento necessárias');
      _showPermissionDialog();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<DownloadProvider>(context, listen: false);
      final downloadId = DateTime.now().millisecondsSinceEpoch.toString();
      final platform = _downloadService.detectPlatform(url);

      final downloadItem = DownloadItem(
        id: downloadId,
        url: url,
        filename: _selectedType == 'video' 
            ? '${platform.displayName}_video_$downloadId.mp4' 
            : '${platform.displayName}_audio_$downloadId.mp3',
        type: _selectedType,
        quality: _selectedQuality,
        filePath: '',
        downloadDate: DateTime.now(),
        status: 'downloading',
      );

      provider.addDownload(downloadItem);

      String filePath;
      if (_selectedType == 'video') {
        filePath = await _downloadService.downloadVideo(
          url: url,
          quality: _selectedQuality,
          onProgress: (progress) {
            provider.updateDownloadProgress(downloadId, progress);
          },
        );
      } else {
        filePath = await _downloadService.downloadAudio(
          url: url,
          onProgress: (progress) {
            provider.updateDownloadProgress(downloadId, progress);
          },
        );
      }

      final index = provider.downloads.indexWhere((d) => d.id == downloadId);
      if (index != -1) {
        provider.downloads[index].filePath = filePath;
        provider.updateDownloadStatus(downloadId, 'completed');
      }

      if (mounted) {
        _showSnackBar('✅ Download concluído! Salvo em: MediaGrabber');
        _urlController.clear();
      }
    } on DioException catch (e) {
      // Atualizar status como falho
      final provider = Provider.of<DownloadProvider>(context, listen: false);
      final downloadId = DateTime.now().millisecondsSinceEpoch.toString();
      provider.updateDownloadStatus(downloadId, 'failed');
      
      if (mounted) {
        String errorMsg = 'Erro de conexão';
        if (e.type == DioExceptionType.connectionTimeout) {
          errorMsg = 'Tempo de conexão esgotado. Verifique sua internet.';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          errorMsg = 'Tempo de resposta esgotado. Tente novamente.';
        } else if (e.response?.statusCode == 404) {
          errorMsg = 'Vídeo/áudio não encontrado ou privado.';
        } else if (e.response?.statusCode == 403) {
          errorMsg = 'Acesso negado. O vídeo pode ser restrito.';
        }
        _showSnackBar('❌ $errorMsg');
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('não é suportada')) {
          _showSnackBar('❌ Plataforma não suportada');
        } else if (errorMsg.contains('URL')) {
          _showSnackBar('❌ URL inválida ou não encontrada');
        } else {
          _showSnackBar('❌ Erro: ${e.toString().replaceAll('Exception: ', '')}');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Grabber', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cloud_download, color: Theme.of(context).colorScheme.primary, size: 28),
                          const SizedBox(width: 12),
                          const Text('Cole a URL do vídeo/música', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          hintText: 'https://...',
                          prefixIcon: const Icon(Icons.link),
                          suffixIcon: IconButton(icon: const Icon(Icons.paste), onPressed: _pasteFromClipboard, tooltip: 'Colar'),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Formato', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTypeButton('Vídeo', Icons.videocam, 'video')),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTypeButton('Áudio', Icons.music_note, 'audio')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedType == 'video')
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Qualidade', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedQuality,
                          decoration: const InputDecoration(prefixIcon: Icon(Icons.high_quality)),
                          items: ['720p', '1080p', '4K'].map((quality) => DropdownMenuItem(value: quality, child: Text(quality))).toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => _selectedQuality = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _startDownload,
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : const Icon(Icons.download, size: 28),
                  label: Text(_isLoading ? 'Baixando...' : 'Baixar', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
              _buildRecentDownloads(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, IconData icon, String type) {
    final isSelected = _selectedType == type;
    return Material(
      color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 32),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentDownloads() {
    return Consumer<DownloadProvider>(
      builder: (context, provider, _) {
        final recentDownloads = provider.completedDownloads.take(3).toList();
        if (recentDownloads.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Downloads Recentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...recentDownloads.map((download) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(download.type == 'video' ? Icons.videocam : Icons.music_note, color: Colors.white),
                ),
                title: Text(download.filename, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${download.type == 'video' ? 'Vídeo' : 'Áudio'} • ${download.fileSize}'),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
            )),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
