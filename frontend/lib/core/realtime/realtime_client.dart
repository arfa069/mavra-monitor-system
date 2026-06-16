import '../platform/platform_capabilities.dart';

enum RealtimeTransport { serverSentEvents, polling }

class RealtimeMessage {
  const RealtimeMessage({required this.type, required this.payload});

  factory RealtimeMessage.fromJson(Map<String, Object?> json) {
    return RealtimeMessage(
      type: json['type']?.toString() ?? 'message',
      payload: json['payload'] is Map<String, Object?>
          ? json['payload']! as Map<String, Object?>
          : <String, Object?>{},
    );
  }

  final String type;
  final Map<String, Object?> payload;
}

abstract class RealtimeClient {
  const RealtimeClient();

  static RealtimeTransport transportFor(PlatformCapabilities capabilities) {
    return capabilities.realtimeMode == RealtimeMode.polling
        ? RealtimeTransport.polling
        : RealtimeTransport.serverSentEvents;
  }

  Stream<RealtimeMessage> connect(String channel);
}

typedef PollRealtime = Future<List<RealtimeMessage>> Function();

class PollingRealtimeClient extends RealtimeClient {
  const PollingRealtimeClient({required this.poll});

  final PollRealtime poll;

  Future<List<RealtimeMessage>> pollOnce() => poll();

  @override
  Stream<RealtimeMessage> connect(String channel) async* {
    final messages = await poll();
    for (final message in messages) {
      yield message;
    }
  }
}
