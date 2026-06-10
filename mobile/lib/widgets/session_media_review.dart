import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/session.dart';
import '../models/settings.dart';
import '../theme/app_theme.dart';
import 'report_preview_widget.dart';

class SessionMediaReview extends StatefulWidget {
  const SessionMediaReview({
    super.key,
    required this.session,
    required this.settings,
    this.reportHeight = 380,
  });

  final InspectionSession session;
  final AppSettings settings;
  final double reportHeight;

  @override
  State<SessionMediaReview> createState() => _SessionMediaReviewState();
}

class _SessionMediaReviewState extends State<SessionMediaReview> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final photos = widget.session.media.where((m) => m.type == 'photo').toList();
    final videos = widget.session.media.where((m) => m.type == 'video').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _tabs,
          labelColor: p.primary,
          unselectedLabelColor: p.textMuted,
          indicatorColor: p.primary,
          tabs: [
            const Tab(text: 'Report'),
            Tab(text: 'Photos (${photos.length})'),
            Tab(text: 'Videos (${videos.length})'),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: widget.reportHeight,
          child: TabBarView(
            controller: _tabs,
            children: [
              ReportPreviewWidget(
                session: widget.session,
                settings: widget.settings,
                height: widget.reportHeight,
              ),
              _PhotosTab(photos: photos),
              _VideosTab(videos: videos),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotosTab extends StatelessWidget {
  const _PhotosTab({required this.photos});
  final List<MediaItem> photos;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    if (photos.isEmpty) {
      return Center(child: Text('No photos captured.', style: TextStyle(color: p.textMuted)));
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: photos.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (context, i) {
        final item = photos[i];
        final file = File(item.localPath);
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _FullPhotoScreen(path: item.localPath),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: file.existsSync()
                ? Image.file(file, width: 140, height: widgetHeight(context), fit: BoxFit.cover)
                : Container(
                    width: 140,
                    height: widgetHeight(context),
                    color: p.surfaceAlt,
                    child: Icon(Icons.broken_image, color: p.textMuted),
                  ),
          ),
        );
      },
    );
  }

  double widgetHeight(BuildContext context) => 320;
}

class _FullPhotoScreen extends StatelessWidget {
  const _FullPhotoScreen({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo')),
      body: InteractiveViewer(
        child: Center(child: Image.file(File(path))),
      ),
    );
  }
}

class _VideosTab extends StatelessWidget {
  const _VideosTab({required this.videos});
  final List<MediaItem> videos;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    if (videos.isEmpty) {
      return Center(child: Text('No videos recorded.', style: TextStyle(color: p.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: videos.length,
      itemBuilder: (context, i) => _VideoTile(item: videos[i], index: i + 1),
    );
  }
}

class _VideoTile extends StatefulWidget {
  const _VideoTile({required this.item, required this.index});
  final MediaItem item;
  final int index;

  @override
  State<_VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<_VideoTile> {
  VideoPlayerController? _controller;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final file = File(widget.item.localPath);
    if (!file.existsSync()) return;
    final c = VideoPlayerController.file(file);
    await c.initialize();
    if (!mounted) {
      c.dispose();
      return;
    }
    setState(() {
      _controller = c;
      _ready = true;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final transcript = widget.item.transcript.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: p.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Video ${widget.index}', style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
            const SizedBox(height: 8),
            if (_ready && _controller != null)
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller!),
                    IconButton(
                      iconSize: 48,
                      icon: Icon(
                        _controller!.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      onPressed: () {
                        setState(() {
                          _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                        });
                      },
                    ),
                  ],
                ),
              )
            else
              Container(
                height: 160,
                alignment: Alignment.center,
                color: p.surfaceAlt,
                child: Text(
                  File(widget.item.localPath).existsSync() ? 'Loading video…' : 'Video file missing',
                  style: TextStyle(color: p.textMuted),
                ),
              ),
            if (transcript.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Narration', style: TextStyle(fontWeight: FontWeight.w700, color: p.primary, fontSize: 13)),
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(maxHeight: 100),
                child: SingleChildScrollView(
                  child: Text(transcript, style: TextStyle(color: p.text, fontSize: 14, height: 1.4)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}