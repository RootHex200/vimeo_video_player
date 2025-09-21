import 'dart:convert';

class VimeoMetadata {
  final String videoId;
  final String videoTitle;
  final Duration videoDuration;

  const VimeoMetadata({
    this.videoId = '',
    this.videoTitle = '',
    this.videoDuration = const Duration(),
  });

  factory VimeoMetadata.fromRawData(String rawData) {
    Map<String, dynamic> parsedData = jsonDecode(rawData);
    var durationInMs = (((parsedData['duration'] ?? 0) as double) * 1000).floor();
    return VimeoMetadata(
      videoId: parsedData['id']?.toString() ?? '',
      videoTitle: parsedData['title']?.toString() ?? '',
      videoDuration: Duration(milliseconds: durationInMs)
    );
  }

  @override
  String toString() {
    return '$runtimeType('
    'videoId: $videoId, '
    'videoTitle: $videoTitle, '
    'duration: ${videoDuration.inSeconds} sec.';
  }
}
