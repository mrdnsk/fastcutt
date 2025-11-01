import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../models/clip.dart';
import '../widgets/timeline_widget.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  bool snapEnabled = true;
  VideoPlayerController? _controller;
  final List<MediaClip> _clips = [];
  bool _isExporting = false;
  String? _lastExportPath;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // =========================
  // IMPORT VIDEO
  // =========================
  Future<void> _importVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    // узнаём длительность через временный контроллер
    final tempCtrl = VideoPlayerController.file(File(path));
    await tempCtrl.initialize();
    final dur = tempCtrl.value.duration;
    await tempCtrl.dispose();

    final clip = MediaClip(
      path: path,
      start: Duration.zero,
      end: dur,
      position: Duration.zero,
    );

    setState(() {
      _clips
        ..clear()
        ..add(clip);
    });

    await _initPlayerForClip(clip);
  }

  Future<void> _initPlayerForClip(MediaClip clip) async {
    _controller?.dispose();
    final ctrl = VideoPlayerController.file(File(clip.path));
    await ctrl.initialize();
    ctrl.setLooping(true);
    setState(() {
      _controller = ctrl;
    });
    ctrl.play();
  }

  // =========================
  // EXPORT (FAKE / COPY)
  // =========================
  Future<void> _exportVideo() async {
    if (_clips.isEmpty) return;
    final clip = _clips.first;

    setState(() {
      _isExporting = true;
    });

    final dir = await getTemporaryDirectory();
    final outPath = '${dir.path}/fastcut_export.mp4';

    bool success = false;
    try {
      await File(clip.path).copy(outPath);
      success = true;
    } catch (e) {
      success = false;
    }

    setState(() {
      _isExporting = false;
      _lastExportPath = success ? outPath : null;
    });

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) {
        final ok = _lastExportPath != null;
        return AlertDialog(
          backgroundColor: const Color(0xFF1B1B22),
          title: Text(
            ok ? 'Export complete' : 'Export failed',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            ok
                ? 'Saved to: $_lastExportPath'
                : 'Export is disabled on this build.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }

  // =========================
  // WHEN CLIP MOVED ON TIMELINE
  // =========================
  void _onTimelineClipMoved(String clipId, Duration newPosition) {
    setState(() {
      final idx = _clips.indexWhere((c) => c.id == clipId);
      if (idx != -1) {
        _clips[idx] = _clips[idx].copyWith(position: newPosition);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = _controller != null && _controller!.value.isInitialized;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E12),
        elevation: 0,
        title: const Text('FastCut'),
        actions: [
          IconButton(
            onPressed: _importVideo,
            icon: const Icon(Icons.add_to_photos_outlined),
            tooltip: 'Import',
          ),
          IconButton(
            onPressed: _isExporting ? null : _exportVideo,
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_rounded),
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        children: [
          // PREVIEW
          AspectRatio(
            aspectRatio: 9 / 16,
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: hasVideo
                  ? Center(child: VideoPlayer(_controller!))
                  : const Center(
                      child: Text(
                        'Import video',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
            ),
          ),

          // PLAY CONTROLS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  onPressed: () {
                    if (hasVideo) {
                      _controller!.seekTo(Duration.zero);
                    }
                  },
                  icon: const Icon(Icons.fast_rewind)),
              IconButton(
                  onPressed: () {
                    if (!hasVideo) return;
                    if (_controller!.value.isPlaying) {
                      _controller!.pause();
                    } else {
                      _controller!.play();
                    }
                    setState(() {});
                  },
                  icon: Icon(
                    hasVideo && _controller!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                  )),
              IconButton(
                  onPressed: () {}, icon: const Icon(Icons.fast_forward)),
            ],
          ),
          const SizedBox(height: 8),

          // TIMELINE
          Expanded(
            child: TimelineWidget(
              clips: _clips,
              snapEnabled: snapEnabled,
              onToggleSnap: () {
                setState(() {
                  snapEnabled = !snapEnabled;
                });
              },
              onClipMoved: _onTimelineClipMoved,
            ),
          ),

          // BOTTOM TOOLBAR
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: const Color(0xFF101017),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    onPressed: () {}, icon: const Icon(Icons.content_cut)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.link)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.title)),
                IconButton(
                    onPressed: () {}, icon: const Icon(Icons.graphic_eq)),
                IconButton(
                  onPressed: () {
                    setState(() {
                      snapEnabled = !snapEnabled;
                    });
                  },
                  icon: Icon(
                    Icons.push_pin,
                    color: snapEnabled ? Colors.white : Colors.white30,
                  ),
                  tooltip: 'Snap on/off',
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.undo)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.redo)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
