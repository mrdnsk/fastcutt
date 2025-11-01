import 'package:flutter/material.dart';
import '../models/clip.dart';

class TimelineWidget extends StatefulWidget {
  final List<MediaClip> clips;
  final bool snapEnabled;
  final VoidCallback onToggleSnap;
  final void Function(String clipId, Duration newPosition) onClipMoved;

  const TimelineWidget({
    super.key,
    required this.clips,
    required this.snapEnabled,
    required this.onToggleSnap,
    required this.onClipMoved,
  });

  @override
  State<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  double scale = 1.0;
  double baseScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (_) => baseScale = scale,
      onScaleUpdate: (d) {
        setState(() {
          scale = (baseScale * d.scale).clamp(0.5, 3.0);
        });
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1B1B22),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  Row(
                    children: [
                      _trackHeader(icon: Icons.movie, label: 'V1'),
                      const SizedBox(width: 8),
                      Expanded(child: _clipsRow()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trackHeader({required IconData icon, required String label}) {
    return Container(
      width: 54,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF14141B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.white70),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _clipsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: widget.clips.map((clip) {
          final width =
              120 * scale * (clip.duration.inMilliseconds / 1000).clamp(0.5, 10);
          return GestureDetector(
            onPanUpdate: (details) {
              final dx = details.delta.dx;
              final secondsDelta = dx / 8;
              var newPos = clip.position +
                  Duration(milliseconds: (secondsDelta * 1000).toInt());
              if (widget.snapEnabled &&
                  newPos.inMilliseconds.abs() < 200) {
                newPos = Duration.zero;
              }
              widget.onClipMoved(clip.id, newPos);
            },
            child: Container(
              width: width,
              height: 40,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  clip.path.split('/').last,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}