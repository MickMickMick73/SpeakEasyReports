import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../app_state.dart';
import '../models/session.dart';
import '../services/speech_service.dart';
import '../theme/app_theme.dart';
import 'review_screen.dart';

enum _CameraState { loading, ready, unavailable }

class InspectScreen extends StatefulWidget {
  const InspectScreen({super.key, required this.state});

  final AppState state;

  @override
  State<InspectScreen> createState() => _InspectScreenState();
}

class _InspectScreenState extends State<InspectScreen> {
  CameraController? _camera;
  _CameraState _cameraState = _CameraState.loading;
  String? _cameraError;
  bool _recording = false;
  bool _busy = false;
  String _liveTranscript = '';
  final _speech = SpeechService();
  final _picker = ImagePicker();
  final List<String> _segments = [];

  @override
  void initState() {
    super.initState();
    _initCamera();
    _speech.initialize();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraState = _CameraState.unavailable;
            _cameraError = 'No camera detected on this device.';
          });
        }
        return;
      }

      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(back, ResolutionPreset.medium, enableAudio: true);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _cameraState = _CameraState.ready;
        _cameraError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraState = _CameraState.unavailable;
          _cameraError = 'Camera unavailable on this device.';
        });
      }
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _addPhoto(String path) async {
    final s = widget.state.activeSession!;
    s.media.add(MediaItem(id: const Uuid().v4(), type: 'photo', localPath: path));
    await widget.state.saveSession(s);
    if (mounted) setState(() {});
  }

  Future<void> _takePhoto() async {
    if (_busy || _recording) return;

    if (_cameraState == _CameraState.ready && _camera != null && _camera!.value.isInitialized) {
      setState(() => _busy = true);
      try {
        final file = await _camera!.takePicture();
        await _addPhoto(file.path);
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }

    await _pickPhotoFromGallery();
  }

  Future<void> _pickPhotoFromGallery() async {
    if (_busy || _recording) return;
    setState(() => _busy = true);
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) await _addPhoto(image.path);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleRecord() async {
    if (_cameraState != _CameraState.ready || _camera == null || !_camera!.value.isInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video recording needs a working camera. Use photos for now.')),
        );
      }
      return;
    }
    if (_busy) return;

    if (!_recording) {
      setState(() {
        _busy = true;
        _liveTranscript = '';
        _segments.clear();
      });
      await _camera!.startVideoRecording();
      await Future.delayed(const Duration(milliseconds: 900));
      await _speech.startListening(onResult: (text, isFinal) {
        setState(() => _liveTranscript = [..._segments, if (!isFinal) text else ''].where((e) => e.isNotEmpty).join(' '));
        if (isFinal && text.trim().isNotEmpty) _segments.add(text.trim());
      });
      setState(() {
        _recording = true;
        _busy = false;
      });
      return;
    }

    setState(() => _busy = true);
    await _speech.stop();
    final video = await _camera!.stopVideoRecording();
    final s = widget.state.activeSession!;
    final transcript = [..._segments, _liveTranscript].join(' ').trim();
    s.media.add(MediaItem(
      id: const Uuid().v4(),
      type: 'video',
      localPath: video.path,
      transcript: transcript,
      transcriptSegments: _segments.map((t) => TranscriptSegment(text: t)).toList(),
      recordingEndedAt: DateTime.now().toIso8601String(),
    ));
    await widget.state.saveSession(s);
    setState(() {
      _recording = false;
      _busy = false;
      _liveTranscript = '';
    });
  }

  Future<void> _finish() async {
    if (_recording) await _toggleRecord();
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReviewScreen(state: widget.state)));
  }

  Widget _buildPreviewArea() {
    if (_cameraState == _CameraState.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_cameraState == _CameraState.unavailable) {
      return Container(
        color: AppColors.surfaceAlt,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off_outlined, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              _cameraError ?? 'Camera not available',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Emulators and PCs without a camera can still add photos from the gallery and finish the inspection.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    final previewSize = _camera!.value.previewSize;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewSize?.height ?? 1,
          height: previewSize?.width ?? 1,
          child: CameraPreview(_camera!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state.activeSession!;
    final photos = s.media.where((m) => m.type == 'photo').length;
    final videos = s.media.where((m) => m.type == 'video').length;
    final canRecord = _cameraState == _CameraState.ready;

    return Scaffold(
      appBar: AppBar(title: Text(s.clientName.isEmpty ? 'Inspect' : s.clientName)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildPreviewArea()),
            if (_recording)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxHeight: 72),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.danger, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _liveTranscript.isEmpty ? 'Speak — your words appear here…' : _liveTranscript,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Text('$photos photos · $videos videos', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (!canRecord)
                    TextButton(
                      onPressed: _busy || _recording ? null : _pickPhotoFromGallery,
                      child: const Text('Gallery'),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy || _recording ? null : _takePhoto,
                      icon: const Icon(Icons.camera_alt, size: 20),
                      label: Text(canRecord ? 'Photo' : 'Add photo'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _busy || !canRecord ? null : _toggleRecord,
                      icon: Icon(_recording ? Icons.stop : Icons.videocam, size: 20),
                      label: Text(_recording ? 'Stop' : 'Record'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _recording ? AppColors.danger : AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _busy ? null : _finish,
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('Finish'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}