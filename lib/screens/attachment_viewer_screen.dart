import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

class AttachmentViewerScreen extends StatefulWidget {
  final List<String> attachmentPaths;
  final int initialIndex;

  const AttachmentViewerScreen({
    super.key,
    required this.attachmentPaths,
    this.initialIndex = 0,
  });

  @override
  State<AttachmentViewerScreen> createState() => _AttachmentViewerScreenState();
}

class _AttachmentViewerScreenState extends State<AttachmentViewerScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentPath = widget.attachmentPaths[_currentIndex];
    final isImage = _isImage(currentPath);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          p.basename(currentPath),
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          if (widget.attachmentPaths.length > 1)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_currentIndex + 1}/${widget.attachmentPaths.length}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ),
            ),
        ],
      ),
      body: isImage
          ? _buildImageViewer(context, currentPath)
          : _buildFileInfo(context, currentPath),
      bottomNavigationBar: isImage && widget.attachmentPaths.length > 1
          ? _buildNavigation(colorScheme)
          : null,
    );
  }

  bool _isImage(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.webp') ||
        ext.endsWith('.gif');
  }

  Widget _buildImageViewer(BuildContext context, String path) {
    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.file(
          File(path),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64),
                SizedBox(height: 16),
                Text('Unable to load image', style: TextStyle(color: Colors.white54)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFileInfo(BuildContext context, String path) {
    final colorScheme = Theme.of(context).colorScheme;
    final file = File(path);
    final fileName = p.basename(path);
    final fileExists = file.existsSync();
    final fileSize = fileExists ? _formatFileSize(file.lengthSync()) : 'Unknown';
    final fileExt = p.extension(path).replaceAll('.', '').toUpperCase();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _getFileIcon(fileExt),
              size: 48,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            fileName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '$fileExt • $fileSize',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _actionButton(
                context,
                icon: Icons.share_rounded,
                label: 'Share',
                onTap: () => _shareFile(context, path),
              ),
              const SizedBox(width: 16),
              _actionButton(
                context,
                icon: Icons.open_in_new_rounded,
                label: 'Open',
                onTap: () => _openFile(context, path),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigation(ColorScheme colorScheme) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: _currentIndex > 0
                ? () => setState(() => _currentIndex--)
                : null,
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: _currentIndex > 0 ? Colors.white : Colors.white30,
            ),
          ),
          Text(
            '${_currentIndex + 1} of ${widget.attachmentPaths.length}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          IconButton(
            onPressed: _currentIndex < widget.attachmentPaths.length - 1
                ? () => setState(() => _currentIndex++)
                : null,
            icon: Icon(
              Icons.arrow_forward_ios_rounded,
              color: _currentIndex < widget.attachmentPaths.length - 1
                  ? Colors.white
                  : Colors.white30,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String ext) {
    switch (ext) {
      case 'PDF':
        return Icons.picture_as_pdf_rounded;
      case 'DOC':
      case 'DOCX':
        return Icons.description_rounded;
      case 'XLS':
      case 'XLSX':
        return Icons.table_chart_rounded;
      case 'PPT':
      case 'PPTX':
        return Icons.slideshow_rounded;
      case 'ZIP':
      case 'RAR':
        return Icons.archive_rounded;
      case 'TXT':
        return Icons.article_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _shareFile(BuildContext context, String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File not found')),
        );
      }
      return;
    }

    try {
      await Share.shareXFiles([XFile(path)], text: p.basename(path));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot share file: $e')),
        );
      }
    }
  }

  Future<void> _openFile(BuildContext context, String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File not found')),
        );
      }
      return;
    }

    try {
      final result = await Share.shareXFiles([XFile(path)], text: 'Open with...');
      if (context.mounted && result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening ${p.basename(path)}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open file: $e')),
        );
      }
    }
  }
}
