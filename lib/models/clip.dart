import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class MediaClip {
  final String id;
  final String path;
  final Duration start;
  final Duration end;
  Duration position;
  bool linkedToAudio;
  bool fadeIn;
  bool fadeOut;

  MediaClip({
    String? id,
    required this.path,
    required this.start,
    required this.end,
    required this.position,
    this.linkedToAudio = true,
    this.fadeIn = false,
    this.fadeOut = false,
  }) : id = id ?? _uuid.v4();

  Duration get duration => end - start;

  MediaClip copyWith({
    Duration? start,
    Duration? end,
    Duration? position,
    bool? linkedToAudio,
    bool? fadeIn,
    bool? fadeOut,
  }) {
    return MediaClip(
      id: id,
      path: path,
      start: start ?? this.start,
      end: end ?? this.end,
      position: position ?? this.position,
      linkedToAudio: linkedToAudio ?? this.linkedToAudio,
      fadeIn: fadeIn ?? this.fadeIn,
      fadeOut: fadeOut ?? this.fadeOut,
    );
  }
}